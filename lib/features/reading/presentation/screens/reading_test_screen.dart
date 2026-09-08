import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/reading_test.dart';
import '../../models/reading_test_result.dart';
import '../../services/band_score_calculator.dart';
import '../../services/reading_evaluator.dart';
import '../../services/reading_service.dart';
import '../widgets/passage_view.dart';
import '../widgets/question_drawer.dart';
import 'reading_result_screen.dart';

class ReadingTestScreen extends StatefulWidget {
  final ReadingTest test;

  const ReadingTestScreen({
    super.key,
    required this.test,
  });

  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  final ReadingService _readingService = ReadingService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _paragraphKeys = {};

  final Map<int, String> _userAnswers = {};
  int _currentQuestionIndex = 0;

  late int _remainingSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.test.estimatedMinutes * 60;

    // Create GlobalKeys for each paragraph for auto-scroll
    for (final letter in widget.test.paragraphs.keys) {
      _paragraphKeys[letter] = GlobalKey();
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToParagraph(String letter) {
    final key = _paragraphKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Aligns near top
      );
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Time is Up!'),
        content: const Text(
          'The 20-minute test period has expired. Let\'s see how you performed!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Reading Test?'),
        content: const Text(
          'Your current progress on this passage will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Test'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onAnswerChanged(int questionNumber, String answer) {
    setState(() {
      _userAnswers[questionNumber] = answer;
    });
  }

  void _promptSubmit() {
    final total = widget.test.questions.length;
    final answered = _userAnswers.values
        .where((ans) => ans.trim().isNotEmpty)
        .length;
    final unanswered = total - answered;

    if (unanswered > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text(
            'You still have $unanswered question(s) left blank. In IELTS, there is no negative marking for incorrect answers.\n\nAre you sure you want to submit now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Review Questions'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitTest();
              },
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
    } else {
      _submitTest();
    }
  }

  void _submitTest() async {
    _timer?.cancel();

    final questions = widget.test.questions;
    final questionResults = <int, bool>{};
    int correctCount = 0;

    for (final q in questions) {
      final userAns = _userAnswers[q.number];
      final isCorrect = ReadingEvaluator.evaluate(q, userAns);
      questionResults[q.number] = isCorrect;
      if (isCorrect) correctCount++;
    }

    final total = questions.length;
    final calculation = BandScoreCalculator.calculateMiniTest(correctCount, total);

    final testResult = ReadingTestResult(
      testId: widget.test.id,
      testTitle: widget.test.title,
      completedAt: DateTime.now(),
      elapsedSeconds: _elapsedSeconds,
      userAnswers: Map.from(_userAnswers),
      questionResults: questionResults,
      correctCount: correctCount,
      totalQuestions: total,
      scaledRawScore: calculation.scaledRaw,
      bandScore: calculation.bandScore,
      bandRange: calculation.bandRange,
    );

    await _readingService.saveResult(testResult);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReadingResultScreen(
          test: widget.test,
          result: testResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowTime = _remainingSeconds <= 180; // 3 minutes or less

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.test.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLowTime
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLowTime
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isLowTime
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimer(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLowTime
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Submit Button
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: _promptSubmit,
              child: const Text('Submit'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            // Reading passage content
            Positioned.fill(
              child: PassageView(
                test: widget.test,
                paragraphKeys: _paragraphKeys,
                scrollController: _scrollController,
              ),
            ),

            // Persistent Floating Question Drawer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuestionDrawer(
                questions: widget.test.questions,
                userAnswers: _userAnswers,
                currentIndex: _currentQuestionIndex,
                onIndexChanged: (idx) {
                  setState(() => _currentQuestionIndex = idx);
                },
                onAnswerChanged: _onAnswerChanged,
                onJumpToEvidence: _jumpToParagraph,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
