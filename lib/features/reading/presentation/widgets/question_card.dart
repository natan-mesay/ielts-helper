import 'package:flutter/material.dart';
import '../../models/reading_question.dart';

class QuestionCard extends StatefulWidget {
  final ReadingQuestion question;
  final String currentAnswer;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback? onJumpToEvidence;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
    this.onJumpToEvidence,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentAnswer);
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.number != widget.question.number ||
        oldWidget.currentAnswer != widget.currentAnswer) {
      if (_textController.text != widget.currentAnswer) {
        _textController.text = widget.currentAnswer;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalseNotGiven:
        return 'True / False / Not Given';
      case QuestionType.yesNoNotGiven:
        return 'Yes / No / Not Given';
      case QuestionType.matchingHeadings:
        return 'Matching Headings';
      case QuestionType.fillInBlank:
        return 'Sentence Completion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Question meta header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getTypeLabel(widget.question.type),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.question.evidenceParagraph.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.my_location, size: 14),
                  label: Text(
                    'Jump to ${widget.question.evidenceParagraph}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: widget.onJumpToEvidence,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Question prompt text
          Text(
            widget.question.prompt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Interactive input matching question type
          _buildInputControl(context),
        ],
      ),
    );
  }

  Widget _buildInputControl(BuildContext context) {
    switch (widget.question.type) {
      case QuestionType.trueFalseNotGiven:
        return _buildTFNGControl(context, isYesNo: false);
      case QuestionType.yesNoNotGiven:
        return _buildTFNGControl(context, isYesNo: true);
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceControl(context);
      case QuestionType.fillInBlank:
      case QuestionType.matchingHeadings:
        return _buildFillBlankControl(context);
    }
  }

  Widget _buildTFNGControl(BuildContext context, {required bool isYesNo}) {
    final theme = Theme.of(context);
    final options = isYesNo
        ? const ['YES', 'NO', 'NOT GIVEN']
        : const ['TRUE', 'FALSE', 'NOT GIVEN'];

    return Row(
      children: options.map((opt) {
        final isSelected = widget.currentAnswer.toUpperCase() == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
                foregroundColor: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => widget.onAnswerChanged(opt),
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceControl(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: widget.question.options.map((opt) {
        final letterMatch = RegExp(r'^([A-D])[\)\.\s]').firstMatch(opt);
        final optionLetter = letterMatch != null ? letterMatch.group(1)! : opt;

        final isSelected = widget.currentAnswer.toUpperCase() == optionLetter ||
            widget.currentAnswer == opt;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => widget.onAnswerChanged(optionLetter),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      optionLetter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillBlankControl(BuildContext context) {
    final theme = Theme.of(context);
    final wordCount = _textController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final isOverLimit = widget.question.wordLimit > 0 && wordCount > widget.question.wordLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Instruction: NO MORE THAN ${widget.question.wordLimit} WORDS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              '$wordCount / ${widget.question.wordLimit} words',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.outline,
              ),
            ),
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _textController.clear();
                      widget.onAnswerChanged('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            widget.onAnswerChanged(val);
            setState(() {});
          },
        ),
      ],
    );
  }
}
