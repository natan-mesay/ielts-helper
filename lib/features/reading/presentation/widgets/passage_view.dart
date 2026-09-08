import 'package:flutter/material.dart';
import '../../models/reading_test.dart';

class PassageView extends StatefulWidget {
  final ReadingTest test;
  final Map<String, GlobalKey> paragraphKeys;
  final ScrollController scrollController;

  const PassageView({
    super.key,
    required this.test,
    required this.paragraphKeys,
    required this.scrollController,
  });

  @override
  State<PassageView> createState() => _PassageViewState();
}

class _PassageViewState extends State<PassageView> {
  double _fontSize = 16.0;

  void _increaseFontSize() {
    if (_fontSize < 22.0) {
      setState(() => _fontSize += 1.5);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 13.0) {
      setState(() => _fontSize -= 1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedParagraphKeys = widget.test.paragraphs.keys.toList()..sort();

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 260), // extra padding for bottom drawer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.test.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.test.topic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Font size controls
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.text_decrease, size: 18),
                      onPressed: _decreaseFontSize,
                      tooltip: 'Decrease text size',
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.text_increase, size: 18),
                      onPressed: _increaseFontSize,
                      tooltip: 'Increase text size',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.test.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.test.wordCount} words',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.test.questions.length} questions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Paragraphs with sticky labels
          ...sortedParagraphKeys.map((letter) {
            final text = widget.test.paragraphs[letter] ?? '';
            final key = widget.paragraphKeys[letter];

            return Container(
              key: key,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Paragraph $letter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.65,
                      letterSpacing: 0.1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
