import 'dart:math';
import '../models/srs_card.dart';

/// Spaced Repetition Engine implementing SuperMemo SM-2 algorithm
/// adapted for active-recall language acquisition.
class SrsEngine {
  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;
  static const int masteryIntervalThreshold = 21; // 21+ days = mastered

  /// Process a review for a card with quality rating [0..5]
  static SrsCard reviewCard({
    required SrsCard card,
    required int quality,
    DateTime? reviewTime,
  }) {
    final now = reviewTime ?? DateTime.now();
    // Clamp rating between 0 and 5
    final q = quality.clamp(0, 5);

    int newRepetition;
    int newInterval;
    int newLapseCount = card.lapseCount;
    double newEaseFactor;
    SrsState newState;

    if (q >= 3) {
      // Successful recall
      if (card.repetition == 0) {
        newInterval = 1;
        newRepetition = 1;
      } else if (card.repetition == 1) {
        newInterval = 6;
        newRepetition = 2;
      } else {
        final calculatedInterval = (card.intervalDays * card.easeFactor).round();
        newInterval = max(1, calculatedInterval);
        newRepetition = card.repetition + 1;
      }

      // Calculate new ease factor: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
      newEaseFactor = max(minEaseFactor, card.easeFactor + delta);

      newState = newInterval >= masteryIntervalThreshold
          ? SrsState.mastered
          : SrsState.review;
    } else {
      // Failed recall / Lapse
      newRepetition = 0;
      newInterval = 1;
      newLapseCount += 1;
      // Penalize ease factor on lapse
      newEaseFactor = max(minEaseFactor, card.easeFactor - 0.2);
      newState = SrsState.learning;
    }

    // Schedule next review date (at start of day + interval days)
    final newDueDate = now.add(Duration(days: newInterval));

    return card.copyWith(
      repetition: newRepetition,
      easeFactor: double.parse(newEaseFactor.toStringAsFixed(2)),
      intervalDays: newInterval,
      dueDate: newDueDate,
      lastReviewed: now,
      lapseCount: newLapseCount,
      state: newState,
    );
  }

  /// Categorize review items for today's study deck
  static Map<String, List<SrsCard>> partitionDeck(List<SrsCard> allCards) {
    final dueCards = <SrsCard>[];
    final newCards = <SrsCard>[];
    final learningCards = <SrsCard>[];
    final masteredCards = <SrsCard>[];

    for (final card in allCards) {
      if (card.state == SrsState.mastered) {
        if (card.isDue) {
          dueCards.add(card);
        } else {
          masteredCards.add(card);
        }
      } else if (card.state == SrsState.newCard) {
        newCards.add(card);
      } else if (card.state == SrsState.learning) {
        learningCards.add(card);
      } else {
        if (card.isDue) {
          dueCards.add(card);
        }
      }
    }

    return {
      'due': dueCards,
      'new': newCards,
      'learning': learningCards,
      'mastered': masteredCards,
    };
  }
}
