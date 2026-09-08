class MiniTestCalculation {
  final int correct;
  final int total;
  final int scaledRaw;
  final double bandScore;
  final String bandRange;
  final double percentage;

  const MiniTestCalculation({
    required this.correct,
    required this.total,
    required this.scaledRaw,
    required this.bandScore,
    required this.bandRange,
    required this.percentage,
  });

  factory MiniTestCalculation.zero() {
    return const MiniTestCalculation(
      correct: 0,
      total: 0,
      scaledRaw: 0,
      bandScore: 2.0,
      bandRange: '2.0 - 2.5',
      percentage: 0.0,
    );
  }
}

class BandScoreCalculator {
  /// Converts an official Cambridge Academic raw score out of 40 to Band 1.0 - 9.0
  static double rawToBand(int rawScore) {
    final clamped = rawScore.clamp(0, 40);
    if (clamped >= 39) return 9.0;
    if (clamped >= 37) return 8.5;
    if (clamped >= 35) return 8.0;
    if (clamped >= 33) return 7.5;
    if (clamped >= 30) return 7.0;
    if (clamped >= 27) return 6.5;
    if (clamped >= 23) return 6.0;
    if (clamped >= 19) return 5.5;
    if (clamped >= 15) return 5.0;
    if (clamped >= 13) return 4.5;
    if (clamped >= 10) return 4.0;
    if (clamped >= 8) return 3.5;
    if (clamped >= 6) return 3.0;
    if (clamped >= 4) return 2.5;
    return 2.0;
  }

  /// Calculates scaled band and conservative confidence range for mini-tests (e.g. 10-14 questions)
  static MiniTestCalculation calculateMiniTest(int correct, int total) {
    if (total <= 0) return MiniTestCalculation.zero();

    // Project raw score to standard 40-question scale
    final scaledRaw = ((correct / total) * 40).round().clamp(0, 40);
    final projectedBand = rawToBand(scaledRaw);

    // Confidence interval (standard error margin +-0.5 band on single passage)
    final lowerBand = (projectedBand - 0.5).clamp(2.0, 9.0);
    final upperBand = (projectedBand + 0.5).clamp(2.0, 9.0);

    return MiniTestCalculation(
      correct: correct,
      total: total,
      scaledRaw: scaledRaw,
      bandScore: projectedBand,
      bandRange:
          '${lowerBand.toStringAsFixed(1)} - ${upperBand.toStringAsFixed(1)}',
      percentage: (correct / total) * 100,
    );
  }
}
