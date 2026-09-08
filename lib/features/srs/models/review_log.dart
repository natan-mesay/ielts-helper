class ReviewLog {
  final int? id;
  final String vocabId;
  final int rating;
  final String userInput;
  final bool isCorrect;
  final int hintLevel;
  final int timeSpentSeconds;
  final DateTime reviewedAt;

  const ReviewLog({
    this.id,
    required this.vocabId,
    required this.rating,
    required this.userInput,
    required this.isCorrect,
    required this.hintLevel,
    required this.timeSpentSeconds,
    required this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vocab_id': vocabId,
      'rating': rating,
      'user_input': userInput,
      'is_correct': isCorrect ? 1 : 0,
      'hint_level': hintLevel,
      'time_spent_seconds': timeSpentSeconds,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }

  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: (map['id'] as num?)?.toInt(),
      vocabId: map['vocab_id'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      userInput: map['user_input'] as String? ?? '',
      isCorrect: (map['is_correct'] as num?)?.toInt() == 1,
      hintLevel: (map['hint_level'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (map['time_spent_seconds'] as num?)?.toInt() ?? 0,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
