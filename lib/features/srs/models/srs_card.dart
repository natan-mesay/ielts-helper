enum SrsState {
  newCard,
  learning,
  review,
  mastered,
}

class SrsCard {
  final String vocabId;
  final int repetition;
  final double easeFactor;
  final int intervalDays;
  final DateTime dueDate;
  final DateTime? lastReviewed;
  final int lapseCount;
  final SrsState state;

  const SrsCard({
    required this.vocabId,
    this.repetition = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    required this.dueDate,
    this.lastReviewed,
    this.lapseCount = 0,
    this.state = SrsState.newCard,
  });

  factory SrsCard.initial(String vocabId) {
    return SrsCard(
      vocabId: vocabId,
      dueDate: DateTime.now(),
      state: SrsState.newCard,
    );
  }

  bool get isDue {
    final now = DateTime.now();
    return dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now);
  }

  SrsCard copyWith({
    String? vocabId,
    int? repetition,
    double? easeFactor,
    int? intervalDays,
    DateTime? dueDate,
    DateTime? lastReviewed,
    int? lapseCount,
    SrsState? state,
  }) {
    return SrsCard(
      vocabId: vocabId ?? this.vocabId,
      repetition: repetition ?? this.repetition,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      dueDate: dueDate ?? this.dueDate,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      lapseCount: lapseCount ?? this.lapseCount,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vocab_id': vocabId,
      'repetition': repetition,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'due_date': dueDate.toIso8601String(),
      'last_reviewed': lastReviewed?.toIso8601String(),
      'lapse_count': lapseCount,
      'state': state.name,
    };
  }

  factory SrsCard.fromJson(Map<String, dynamic> json) {
    return SrsCard(
      vocabId: json['vocab_id'] as String? ?? '',
      repetition: (json['repetition'] as num?)?.toInt() ?? 0,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastReviewed: json['last_reviewed'] != null
          ? DateTime.tryParse(json['last_reviewed'] as String)
          : null,
      lapseCount: (json['lapse_count'] as num?)?.toInt() ?? 0,
      state: SrsState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SrsState.newCard,
      ),
    );
  }
}
