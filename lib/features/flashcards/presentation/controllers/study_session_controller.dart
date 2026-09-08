import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../services/vocabulary_service.dart';
import '../../../srs/models/review_log.dart';
import '../../../srs/services/srs_engine.dart';
import '../../../srs/services/srs_storage_service.dart';
import '../../models/cloze_prompt.dart';
import '../../services/answer_evaluator.dart';
import '../../services/cloze_generator.dart';

class StudySessionController extends ChangeNotifier {
  final VocabularyService _vocabService;
  final SrsStorageService _storageService;

  StudySessionController({
    VocabularyService? vocabService,
    SrsStorageService? storageService,
  })  : _vocabService = vocabService ?? VocabularyService(),
        _storageService = storageService ?? SrsStorageService();

  List<ClozePrompt> _prompts = [];
  int _initialTotalCards = 0;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isCompleted = false;

  final Set<String> _pendingRelearnIds = <String>{};
  final Set<String> _clearedCardIds = <String>{};

  int _hintLevel = 0;
  EvaluationResult? _lastEvaluation;
  Timer? _timer;
  int _secondsElapsed = 0;

  // Session Statistics
  int _correctCount = 0;
  int _typoCount = 0;
  int _incorrectCount = 0;
  int _streak = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;
  int get currentIndex => _currentIndex;
  int get totalCards => _prompts.length;
  int get initialTotalCards => _initialTotalCards;
  int get pendingRelearnCount => _pendingRelearnIds.length;
  double get progress => _initialTotalCards > 0
      ? (_clearedCardIds.length / _initialTotalCards).clamp(0.0, 1.0)
      : 0.0;
  ClozePrompt? get currentPrompt =>
      _prompts.isNotEmpty && _currentIndex < _prompts.length
          ? _prompts[_currentIndex]
          : null;
  int get hintLevel => _hintLevel;
  EvaluationResult? get lastEvaluation => _lastEvaluation;
  int get correctCount => _correctCount;
  int get typoCount => _typoCount;
  int get incorrectCount => _incorrectCount;
  int get streak => _streak;
  int get secondsElapsed => _secondsElapsed;

  /// Start a study session for a given topic or all due cards (default 15 cards)
  Future<void> startSession({String? topic, int cardLimit = 15}) async {
    _isLoading = true;
    _isCompleted = false;
    _currentIndex = 0;
    _correctCount = 0;
    _typoCount = 0;
    _incorrectCount = 0;
    _lastEvaluation = null;
    _hintLevel = 0;
    _pendingRelearnIds.clear();
    _clearedCardIds.clear();
    notifyListeners();

    _streak = await _storageService.getStreak();
    final allSrsCards = await _storageService.loadCards();

    final items = await _vocabService.buildStudyQueue(
      srsCards: allSrsCards,
      filterTopic: topic,
      maxCards: cardLimit,
    );

    _prompts = items.map((item) => ClozeGenerator.generate(item)).toList();
    _initialTotalCards = _prompts.length;
    _isLoading = false;
    _startCardTimer();
    notifyListeners();
  }

  void _startCardTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  /// Request the next tier of hints
  void requestHint() {
    if (_hintLevel < 3) {
      _hintLevel++;
      notifyListeners();
    }
  }

  /// Submit an active-recall answer
  Future<EvaluationResult> submitAnswer(String answer) async {
    if (currentPrompt == null) {
      throw StateError('No active prompt');
    }

    _timer?.cancel();
    final prompt = currentPrompt!;

    final result = AnswerEvaluator.evaluate(
      userInput: answer,
      prompt: prompt,
      hintLevel: _hintLevel,
      secondsElapsed: _secondsElapsed,
    );

    _lastEvaluation = result;

    // Record review attempt into database (Anki-style revlog)
    final log = ReviewLog(
      vocabId: prompt.item.id,
      rating: result.qualityRating,
      userInput: answer,
      isCorrect: result.type == EvaluationType.correct,
      hintLevel: _hintLevel,
      timeSpentSeconds: _secondsElapsed,
      reviewedAt: DateTime.now(),
    );
    await _storageService.insertReviewLog(log);

    if (result.type == EvaluationType.correct) {
      _correctCount++;
      _clearedCardIds.add(prompt.item.id);
      _pendingRelearnIds.remove(prompt.item.id);

      await _recordSrsReview(prompt.item.id, result.qualityRating);
    } else {
      if (result.type == EvaluationType.closeTypo) {
        _typoCount++;
        await _recordSrsReview(prompt.item.id, 2);
      } else {
        _incorrectCount++;
        await _recordSrsReview(prompt.item.id, 1);
      }

      // Anki-style Intra-Session Re-learning:
      // Re-insert card ~3 cards ahead (or at end if fewer remain) so user repeats it
      _pendingRelearnIds.add(prompt.item.id);
      final insertIndex = min(_currentIndex + 4, _prompts.length);
      _prompts.insert(insertIndex, prompt);
    }

    notifyListeners();
    return result;
  }

  /// Skip current card (defers to end of queue if more cards remain, or reveals answer)
  Future<void> skipCard() async {
    if (currentPrompt == null) return;
    _timer?.cancel();
    if (_prompts.length > _currentIndex + 1) {
      final current = _prompts.removeAt(_currentIndex);
      _prompts.add(current);
      _lastEvaluation = null;
      _hintLevel = 0;
      _startCardTimer();
      notifyListeners();
    } else {
      await dontKnow();
    }
  }

  /// User doesn't know the word: reveals the answer and schedules for intra-session re-learning
  Future<void> dontKnow() async {
    if (currentPrompt == null) return;
    _timer?.cancel();
    final prompt = currentPrompt!;

    _incorrectCount++;
    await _recordSrsReview(prompt.item.id, 0);

    // Record to review logs
    final log = ReviewLog(
      vocabId: prompt.item.id,
      rating: 0,
      userInput: '',
      isCorrect: false,
      hintLevel: _hintLevel,
      timeSpentSeconds: _secondsElapsed,
      reviewedAt: DateTime.now(),
    );
    await _storageService.insertReviewLog(log);

    // Re-insert card ~3 cards ahead for intra-session repetition
    _pendingRelearnIds.add(prompt.item.id);
    final insertIndex = min(_currentIndex + 4, _prompts.length);
    _prompts.insert(insertIndex, prompt);

    _lastEvaluation = EvaluationResult(
      type: EvaluationType.incorrect,
      normalizedInput: '',
      targetWord: prompt.targetWord,
      qualityRating: 0,
      message: 'Word revealed. Added to session re-learning queue.',
    );
    notifyListeners();
  }

  Future<void> _recordSrsReview(String vocabId, int quality) async {
    final existingCard = await _storageService.getOrCreateCard(vocabId);
    final updatedCard = SrsEngine.reviewCard(
      card: existingCard,
      quality: quality,
    );
    await _storageService.saveCard(updatedCard);
    _streak = await _storageService.recordStudySession();
  }

  /// Move to next flashcard or complete session
  void nextCard() {
    _lastEvaluation = null;
    _hintLevel = 0;

    if (_currentIndex < _prompts.length - 1) {
      _currentIndex++;
      _startCardTimer();
    } else {
      // Check if any pending re-learn cards remain
      if (_pendingRelearnIds.isNotEmpty) {
        final remainingPending = _prompts
            .where((p) => _pendingRelearnIds.contains(p.item.id))
            .toSet()
            .toList();
        if (remainingPending.isNotEmpty) {
          _prompts.addAll(remainingPending);
          _currentIndex++;
          _startCardTimer();
          notifyListeners();
          return;
        }
      }
      _isCompleted = true;
      _timer?.cancel();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
