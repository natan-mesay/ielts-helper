class ReadingTestResult {
  final String testId;
  final String testTitle;
  final DateTime completedAt;
  final int elapsedSeconds;
  final Map<int, String> userAnswers;
  final Map<int, bool> questionResults;
  final int correctCount;
  final int totalQuestions;
  final int scaledRawScore;
  final double bandScore;
  final String bandRange;

  const ReadingTestResult({
    required this.testId,
    required this.testTitle,
    required this.completedAt,
    required this.elapsedSeconds,
    required this.userAnswers,
    required this.questionResults,
    required this.correctCount,
    required this.totalQuestions,
    required this.scaledRawScore,
    required this.bandScore,
    required this.bandRange,
  });

  double get accuracyPercentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory ReadingTestResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['user_answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = rawAnswers.map(
      (k, v) => MapEntry(int.tryParse(k) ?? 0, v.toString()),
    );

    final rawResults = json['question_results'] as Map<String, dynamic>? ?? {};
    final parsedResults = rawResults.map(
      (k, v) => MapEntry(int.tryParse(k) ?? 0, v as bool? ?? false),
    );

    return ReadingTestResult(
      testId: json['test_id'] as String? ?? '',
      testTitle: json['test_title'] as String? ?? '',
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? '') ??
          DateTime.now(),
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
      userAnswers: parsedAnswers,
      questionResults: parsedResults,
      correctCount: json['correct_count'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      scaledRawScore: json['scaled_raw_score'] as int? ?? 0,
      bandScore: (json['band_score'] as num?)?.toDouble() ?? 0.0,
      bandRange: json['band_range'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'test_title': testTitle,
      'completed_at': completedAt.toIso8601String(),
      'elapsed_seconds': elapsedSeconds,
      'user_answers':
          userAnswers.map((k, v) => MapEntry(k.toString(), v)),
      'question_results':
          questionResults.map((k, v) => MapEntry(k.toString(), v)),
      'correct_count': correctCount,
      'total_questions': totalQuestions,
      'scaled_raw_score': scaledRawScore,
      'band_score': bandScore,
      'band_range': bandRange,
    };
  }
}
