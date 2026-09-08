import 'package:flutter/material.dart';
import '../../models/reading_test.dart';
import '../../models/reading_test_result.dart';
import 'reading_test_screen.dart';

class ReadingResultScreen extends StatefulWidget {
  final ReadingTest test;
  final ReadingTestResult result;

  const ReadingResultScreen({
    super.key,
    required this.test,
    required this.result,
  });

  @override
  State<ReadingResultScreen> createState() => _ReadingResultScreenState();
}

class _ReadingResultScreenState extends State<ReadingResultScreen> {
  String _filter = 'ALL'; // 'ALL', 'CORRECT', 'INCORRECT'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = widget.test.questions;

    final filteredQuestions = questions.where((q) {
      final isCorrect = widget.result.questionResults[q.number] ?? false;
      if (_filter == 'CORRECT') return isCorrect;
      if (_filter == 'INCORRECT') return !isCorrect;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Banner Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.test.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Band ${widget.result.bandScore.toStringAsFixed(1)}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Estimated Range: ${widget.result.bandRange}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricItem(
                        context,
                        label: 'Raw Score',
                        value: '${widget.result.correctCount}/${widget.result.totalQuestions}',
                        icon: Icons.checklist,
                      ),
                      _buildMetricItem(
                        context,
                        label: 'Accuracy',
                        value: '${widget.result.accuracyPercentage.toStringAsFixed(0)}%',
                        icon: Icons.percent,
                      ),
                      _buildMetricItem(
                        context,
                        label: 'Time',
                        value: widget.result.formattedTime,
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Chips
            Row(
              children: [
                ChoiceChip(
                  label: Text('All (${questions.length})'),
                  selected: _filter == 'ALL',
                  onSelected: (val) => setState(() => _filter = 'ALL'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Incorrect (${widget.result.totalQuestions - widget.result.correctCount})'),
                  selected: _filter == 'INCORRECT',
                  selectedColor: theme.colorScheme.errorContainer,
                  onSelected: (val) => setState(() => _filter = 'INCORRECT'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Correct (${widget.result.correctCount})'),
                  selected: _filter == 'CORRECT',
                  onSelected: (val) => setState(() => _filter = 'CORRECT'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detailed Question Review Cards
            ...filteredQuestions.map((q) {
              final isCorrect = widget.result.questionResults[q.number] ?? false;
              final userAns = widget.result.userAnswers[q.number] ?? '(No answer)';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCorrect
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.error.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Q${q.number}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (q.evidenceParagraph.isNotEmpty)
                            Text(
                              q.evidenceParagraph,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q.prompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Answer:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  userAns.isEmpty ? '(Left Blank)' : userAns,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accepted Answer:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  q.acceptedAnswers.join(' / '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (q.explanation.isNotEmpty) ...[
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                q.explanation,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ReadingTestScreen(test: widget.test),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retake Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back to Reading Hub'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
