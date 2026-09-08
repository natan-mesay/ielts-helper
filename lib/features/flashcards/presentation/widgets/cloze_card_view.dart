import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/cloze_prompt.dart';

class ClozeCardView extends StatelessWidget {
  final ClozePrompt prompt;
  final int hintLevel;

  const ClozeCardView({
    super.key,
    required this.prompt,
    required this.hintLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top badges: Topic and Part of Speech
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prompt.item.topic.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prompt.partOfSpeech.toLowerCase(),
                    style: const TextStyle(
                      color: AppTheme.accentDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${prompt.letterCount} letters',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sentence with Highlighted Blank
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.6,
                  color: AppTheme.textPrimaryLight,
                ),
                children: [
                  TextSpan(text: '${prompt.prefix} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _buildBlankPlaceholder(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: ' ${prompt.suffix}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progressive Hint Sections
            if (hintLevel >= 1) ...[
              _buildHintItem(
                icon: Icons.lightbulb_outline,
                title: 'Definition',
                content: prompt.definition,
                color: AppTheme.warning,
              ),
            ],
            if (hintLevel >= 2) ...[
              const SizedBox(height: 10),
              _buildHintItem(
                icon: Icons.text_fields_outlined,
                title: 'Letter Clue',
                content: 'Starts with "${prompt.firstLetter}", ends with "${prompt.lastLetter}" (${prompt.letterCount} letters total)',
                color: AppTheme.primaryLight,
              ),
            ],
            if (hintLevel >= 3 && prompt.pronunciation.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildHintItem(
                icon: Icons.record_voice_over_outlined,
                title: 'Pronunciation Note',
                content: prompt.pronunciation,
                color: AppTheme.accentDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildBlankPlaceholder() {
    if (hintLevel >= 2) {
      final middleDashes = List.filled(prompt.letterCount - 2 > 0 ? prompt.letterCount - 2 : 1, '·').join(' ');
      return '${prompt.firstLetter} $middleDashes ${prompt.lastLetter}';
    }
    return '______';
  }

  Widget _buildHintItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
