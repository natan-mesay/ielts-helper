import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/study_session_controller.dart';
import '../widgets/cloze_card_view.dart';
import '../widgets/feedback_sheet.dart';
import '../widgets/typing_input_area.dart';
import 'session_summary_screen.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String? topic;
  final int cardLimit;

  const FlashcardStudyScreen({
    super.key,
    this.topic,
    this.cardLimit = 15,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  late final StudySessionController _controller;
  bool _shakeCard = false;

  @override
  void initState() {
    super.initState();
    _controller = StudySessionController();
    _controller.startSession(topic: widget.topic, cardLimit: widget.cardLimit);
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnswerSubmitted(String answer) async {
    FocusScope.of(context).unfocus();
    final result = await _controller.submitAnswer(answer);
    if (!result.isSuccessful) {
      setState(() {
        _shakeCard = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _shakeCard = false;
          });
        }
      });
    }
  }

  void _handleDontKnow() async {
    FocusScope.of(context).unfocus();
    await _controller.dontKnow();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Assembling IELTS study deck...', style: TextStyle(color: AppTheme.textSecondaryLight)),
            ],
          ),
        ),
      );
    }

    if (_controller.isCompleted) {
      return SessionSummaryScreen(
        correctCount: _controller.correctCount,
        typoCount: _controller.typoCount,
        incorrectCount: _controller.incorrectCount,
        totalCards: _controller.initialTotalCards > 0
            ? _controller.initialTotalCards
            : _controller.totalCards,
        streak: _controller.streak,
        topic: widget.topic ?? 'Daily Queue',
      );
    }

    final prompt = _controller.currentPrompt;
    if (prompt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: const Center(child: Text('No vocabulary cards found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimaryLight),
          onPressed: () => _confirmExit(context),
        ),
        title: Column(
          children: [
            Text(
              widget.topic ?? 'Daily Active Recall',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                width: 160,
                child: LinearProgressIndicator(
                  value: _controller.progress,
                  backgroundColor: AppTheme.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Streak Icon
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 2),
                Text(
                  '${_controller.streak}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                children: [
                  // Progress counter & timer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Card ${_controller.currentIndex + 1} of ${_controller.totalCards}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_controller.pendingRelearnCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_controller.pendingRelearnCount} to repeat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${_controller.secondsElapsed}s',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cloze Card View with Shake Animation on typo/incorrect
                  ClozeCardView(
                    prompt: prompt,
                    hintLevel: _controller.hintLevel,
                  )
                      .animate(target: _shakeCard ? 1.0 : 0.0)
                      .shakeX(duration: 400.ms, hz: 4),

                  const SizedBox(height: 12),

                  // Typing Input Area
                  TypingInputArea(
                    onSubmit: _handleAnswerSubmitted,
                    onHint: _controller.requestHint,
                    onSkip: _controller.skipCard,
                    onDontKnow: _handleDontKnow,
                    currentHintLevel: _controller.hintLevel,
                    isEvaluated: _controller.lastEvaluation != null,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Feedback Banner
          if (_controller.lastEvaluation != null)
            FeedbackSheet(
              result: _controller.lastEvaluation!,
              prompt: prompt,
              onContinue: _controller.nextCard,
            ).animate().slideY(begin: 1.0, end: 0.0, duration: 250.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Study Session?'),
        content: const Text('Your card reviews up to this point have been saved into your Spaced Repetition queue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
