import '../models/reading_question.dart';

class ReadingEvaluator {
  /// Evaluates whether the user's answer is correct for the given question
  static bool evaluate(ReadingQuestion question, String? userAnswer) {
    if (userAnswer == null) return false;
    final trimmed = userAnswer.trim();
    if (trimmed.isEmpty) return false;

    switch (question.type) {
      case QuestionType.multipleChoice:
        final normalizedUser = _extractLetterOrClean(trimmed);
        return question.acceptedAnswers.any(
          (ans) => _extractLetterOrClean(ans) == normalizedUser,
        );

      case QuestionType.trueFalseNotGiven:
        final normalizedUser = _normalizeTFNG(trimmed);
        return question.acceptedAnswers.any(
          (ans) => _normalizeTFNG(ans) == normalizedUser,
        );

      case QuestionType.yesNoNotGiven:
        final normalizedUser = _normalizeYNNG(trimmed);
        return question.acceptedAnswers.any(
          (ans) => _normalizeYNNG(ans) == normalizedUser,
        );

      case QuestionType.matchingHeadings:
        final normalizedUser = _normalizeRoman(trimmed);
        return question.acceptedAnswers.any(
          (ans) => _normalizeRoman(ans) == normalizedUser,
        );

      case QuestionType.fillInBlank:
        return _evaluateFillInBlank(question, trimmed);
    }
  }

  static bool _evaluateFillInBlank(ReadingQuestion question, String userRaw) {
    // 1. Clean user text: lowercase, remove non-alphanumeric punctuation except hyphens
    final cleaned = _cleanText(userRaw);
    if (cleaned.isEmpty) return false;

    // 2. Check word count limit (strict IELTS rule: NO MORE THAN N WORDS)
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (question.wordLimit > 0 && words.length > question.wordLimit) {
      return false;
    }

    // 3. Match against accepted answer variants
    for (final accepted in question.acceptedAnswers) {
      final cleanedAccepted = _cleanText(accepted);
      if (cleanedAccepted == cleaned) {
        return true;
      }
      // Also check if accepted has optional articles, e.g. "the law" vs "law"
      if (_matchesWithoutArticles(cleaned, cleanedAccepted)) {
        return true;
      }
    }

    return false;
  }

  static String _cleanText(String text) {
    return text
        .trim()
        .toLowerCase()
        // Replace punctuation (except hyphens) with space
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        // Collapse multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _matchesWithoutArticles(String textA, String textB) {
    String strip(String s) => s.replaceAll(RegExp(r'^(the|a|an)\s+'), '').trim();
    return strip(textA) == strip(textB);
  }

  static String _extractLetterOrClean(String text) {
    final clean = text.trim().toUpperCase();
    if (clean.length == 1) return clean;
    // If option was formatted as "A) Something", extract "A"
    final match = RegExp(r'^([A-D])[\)\.\s]').firstMatch(clean);
    if (match != null) {
      return match.group(1)!;
    }
    return clean;
  }

  static String _normalizeTFNG(String text) {
    final upper = text.trim().toUpperCase();
    if (upper == 'T' || upper == 'TRUE') return 'TRUE';
    if (upper == 'F' || upper == 'FALSE') return 'FALSE';
    if (upper == 'NG' || upper == 'NOT GIVEN' || upper == 'NOTGIVEN') {
      return 'NOT GIVEN';
    }
    return upper;
  }

  static String _normalizeYNNG(String text) {
    final upper = text.trim().toUpperCase();
    if (upper == 'Y' || upper == 'YES') return 'YES';
    if (upper == 'N' || upper == 'NO') return 'NO';
    if (upper == 'NG' || upper == 'NOT GIVEN' || upper == 'NOTGIVEN') {
      return 'NOT GIVEN';
    }
    return upper;
  }

  static String _normalizeRoman(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'[\.\)]'), '');
  }
}
