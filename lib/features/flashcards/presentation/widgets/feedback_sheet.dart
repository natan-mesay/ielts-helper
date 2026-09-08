import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/cloze_prompt.dart';
import '../../services/answer_evaluator.dart';

class FeedbackSheet extends StatelessWidget {
  final EvaluationResult result;
  final ClozePrompt prompt;
  final VoidCallback onContinue;

  const FeedbackSheet({
    super.key,
    required this.result,
    required this.prompt,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String statusTitle;

    switch (result.type) {
      case EvaluationType.correct:
        bg = const Color(0xFFF0FDF4); // soft emerald
        border = AppTheme.accent;
        icon = Icons.check_circle;
        statusTitle = 'Correct!';
        break;
      case EvaluationType.closeTypo:
        bg = const Color(0xFFFFFBEB); // soft amber
        border = AppTheme.warning;
        icon = Icons.error_outline;
        statusTitle = 'Spelling Alert';
        break;
      case EvaluationType.incorrect:
        bg = const Color(0xFFFEF2F2); // soft rose
        border = AppTheme.error;
        icon = Icons.cancel;
        statusTitle = 'Needs Review';
        break;
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.70, // Never exceed 70% of screen height
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: border, width: 2.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, -4),
            blurRadius: 18,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header with flexible layout to avoid width overflow
              Row(
                children: [
                  Icon(icon, color: border, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: border,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (result.type != EvaluationType.correct) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: border.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 14, color: border),
                      const SizedBox(width: 5),
                      Text(
                        'Will repeat this session',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: border,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Target Word Showcase (Wrap to avoid width overflow on long words)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border.withValues(alpha: 0.3)),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      prompt.targetWord,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (prompt.pronunciation.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prompt.pronunciation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (prompt.partOfSpeech.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prompt.partOfSpeech.toLowerCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Meaning / Definition Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: border.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 14,
                          color: border,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'MEANING:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: border,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt.definition.isNotEmpty
                          ? prompt.definition
                          : prompt.item.definition,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: border,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
