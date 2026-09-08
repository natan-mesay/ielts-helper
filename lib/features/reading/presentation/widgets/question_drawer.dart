import 'package:flutter/material.dart';
import '../../models/reading_question.dart';
import 'question_card.dart';

class QuestionDrawer extends StatefulWidget {
  final List<ReadingQuestion> questions;
  final Map<int, String> userAnswers;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final void Function(int questionNumber, String answer) onAnswerChanged;
  final void Function(String paragraphLetter)? onJumpToEvidence;

  const QuestionDrawer({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onAnswerChanged,
    this.onJumpToEvidence,
  });

  @override
  State<QuestionDrawer> createState() => _QuestionDrawerState();
}

class _QuestionDrawerState extends State<QuestionDrawer> {
  late PageController _pageController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant QuestionDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != widget.currentIndex) {
        _pageController.animateToPage(
          widget.currentIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showQuestionGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question Navigator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(widget.questions.length, (idx) {
                    final qNum = widget.questions[idx].number;
                    final isAnswered =
                        (widget.userAnswers[qNum]?.trim().isNotEmpty ?? false);
                    final isCurrent = idx == widget.currentIndex;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onIndexChanged(idx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : isAnswered
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: theme.colorScheme.onPrimary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          '$qNum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : isAnswered
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Answered', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Unanswered', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.questions.length;
    final answeredCount = widget.userAnswers.values
        .where((ans) => ans.trim().isNotEmpty)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Header Bar
          InkWell(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Drag indicator
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Clickable Question Chip
                  ActionChip(
                    avatar: const Icon(Icons.grid_view, size: 14),
                    label: Text(
                      'Q ${widget.currentIndex + 1} of $total',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _showQuestionGrid(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($answeredCount/$total answered)',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isCollapsed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Drawer Body (Collapsible)
          if (!_isCollapsed) ...[
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: widget.onIndexChanged,
                itemBuilder: (context, idx) {
                  final q = widget.questions[idx];
                  return QuestionCard(
                    question: q,
                    currentAnswer: widget.userAnswers[q.number] ?? '',
                    onAnswerChanged: (ans) =>
                        widget.onAnswerChanged(q.number, ans),
                    onJumpToEvidence: q.evidenceParagraph.isNotEmpty
                        ? () {
                            final match = RegExp(r'[A-G]').firstMatch(q.evidenceParagraph);
                            if (match != null) {
                              widget.onJumpToEvidence?.call(match.group(0)!);
                            }
                          }
                        : null,
                  );
                },
              ),
            ),

            // Navigation Bottom Bar: Previous / Next
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: widget.currentIndex > 0
                        ? () => widget.onIndexChanged(widget.currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: const Text('Previous'),
                  ),
                  TextButton.icon(
                    onPressed: widget.currentIndex < total - 1
                        ? () => widget.onIndexChanged(widget.currentIndex + 1)
                        : null,
                    icon: const Text('Next'),
                    label: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
