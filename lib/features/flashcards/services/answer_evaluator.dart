import 'dart:math';
import '../models/cloze_prompt.dart';

enum EvaluationType {
  correct,
  closeTypo,
  incorrect,
}

class EvaluationResult {
  final EvaluationType type;
  final String normalizedInput;
  final String targetWord;
  final int qualityRating; // 0..5 for SM-2
  final String message;
  final int editDistance;

  const EvaluationResult({
    required this.type,
    required this.normalizedInput,
    required this.targetWord,
    required this.qualityRating,
    required this.message,
    this.editDistance = 0,
  });

  bool get isSuccessful => type == EvaluationType.correct;
}

class AnswerEvaluator {
  /// Normalize a string for relaxed comparison
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Evaluates user input against the ClozePrompt
  static EvaluationResult evaluate({
    required String userInput,
    required ClozePrompt prompt,
    required int hintLevel,
    required int secondsElapsed,
  }) {
    final normUser = normalize(userInput);
    final normTarget = normalize(prompt.targetWord);

    if (normUser.isEmpty) {
      return EvaluationResult(
        type: EvaluationType.incorrect,
        normalizedInput: normUser,
        targetWord: prompt.targetWord,
        qualityRating: 0,
        message: 'No answer provided. The word is: "${prompt.targetWord}".',
      );
    }

    // 1. Exact match with target word
    if (normUser == normTarget) {
      final q = _calculateQuality(
        isCorrect: true,
        hintLevel: hintLevel,
        secondsElapsed: secondsElapsed,
      );
      return EvaluationResult(
        type: EvaluationType.correct,
        normalizedInput: normUser,
        targetWord: prompt.targetWord,
        qualityRating: q,
        message: 'Spot on! Correct academic usage.',
      );
    }

    // 2. Exact match with any accepted alternatives
    for (final alt in prompt.alternativeAnswers) {
      if (normUser == normalize(alt)) {
        final q = _calculateQuality(
          isCorrect: true,
          hintLevel: hintLevel,
          secondsElapsed: secondsElapsed,
        );
        return EvaluationResult(
          type: EvaluationType.correct,
          normalizedInput: normUser,
          targetWord: prompt.targetWord,
          qualityRating: q,
          message: 'Correct! "$alt" is an accepted synonym.',
        );
      }
    }

    // 3. Compute Damerau-Levenshtein distance (supports transpositions)
    final dist = damerauLevenshteinDistance(normUser, normTarget);

    // If word is 5+ letters and edit distance is 1 (or 8+ letters and dist <= 2)
    final isClose = (normTarget.length >= 5 && dist == 1) || (normTarget.length >= 8 && dist <= 2);

    if (isClose) {
      return EvaluationResult(
        type: EvaluationType.closeTypo,
        normalizedInput: normUser,
        targetWord: prompt.targetWord,
        qualityRating: 2, // SM-2 repeat grade
        editDistance: dist,
        message: 'Almost there! Check the exact spelling: "${prompt.targetWord}".',
      );
    }

    // 4. Incorrect
    return EvaluationResult(
      type: EvaluationType.incorrect,
      normalizedInput: normUser,
      targetWord: prompt.targetWord,
      qualityRating: 1,
      editDistance: dist,
      message: 'Not quite. The correct academic term is "${prompt.targetWord}".',
    );
  }

  static int _calculateQuality({
    required bool isCorrect,
    required int hintLevel,
    required int secondsElapsed,
  }) {
    if (!isCorrect) return 1;

    if (hintLevel == 0) {
      return secondsElapsed <= 10 ? 5 : 4;
    } else if (hintLevel == 1) {
      return 4;
    } else {
      return 3;
    }
  }

  /// Damerau-Levenshtein distance: includes insertions, deletions, substitutions, and transpositions
  static int damerauLevenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;

    if (m == 0) return n;
    if (n == 0) return m;

    final d = List.generate(m + 1, (i) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = min(
          d[i - 1][j] + 1, // deletion
          min(
            d[i][j - 1] + 1, // insertion
            d[i - 1][j - 1] + cost, // substitution
          ),
        );

        // Transposition check
        if (i > 1 && j > 1 && s1[i - 1] == s2[j - 2] && s1[i - 2] == s2[j - 1]) {
          d[i][j] = min(d[i][j], d[i - 2][j - 2] + cost);
        }
      }
    }

    return d[m][n];
  }
}
