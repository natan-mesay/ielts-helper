import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/srs/models/srs_card.dart';
import 'package:ielts_prep_app/features/srs/services/srs_engine.dart';

void main() {
  group('SrsEngine SM-2 Tests', () {
    test('initial card has repetition 0 and default easeFactor 2.5', () {
      final card = SrsCard.initial('test_01');
      expect(card.repetition, 0);
      expect(card.easeFactor, 2.5);
      expect(card.intervalDays, 0);
      expect(card.state, SrsState.newCard);
    });

    test('first successful review (quality >= 3) schedules 1 day interval', () {
      final initial = SrsCard.initial('test_01');
      final reviewed = SrsEngine.reviewCard(card: initial, quality: 5);

      expect(reviewed.repetition, 1);
      expect(reviewed.intervalDays, 1);
      expect(reviewed.easeFactor, 2.6); // 2.5 + (0.1 - 0) = 2.6
      expect(reviewed.state, SrsState.review);
    });

    test('second consecutive successful review schedules 6 days interval', () {
      var card = SrsCard.initial('test_01');
      card = SrsEngine.reviewCard(card: card, quality: 5);
      card = SrsEngine.reviewCard(card: card, quality: 4);

      expect(card.repetition, 2);
      expect(card.intervalDays, 6);
      expect(card.state, SrsState.review);
    });

    test('third consecutive successful review scales interval by ease factor', () {
      var card = SrsCard.initial('test_01');
      card = SrsEngine.reviewCard(card: card, quality: 5); // int=1, ef=2.6
      card = SrsEngine.reviewCard(card: card, quality: 5); // int=6, ef=2.7
      card = SrsEngine.reviewCard(card: card, quality: 5); // int=(6 * 2.7)=16

      expect(card.repetition, 3);
      expect(card.intervalDays, (6 * 2.7).round());
      expect(card.state, SrsState.review);
    });

    test('lapse (quality < 3) resets interval to 1 and repetition to 0', () {
      var card = SrsCard.initial('test_01');
      card = SrsEngine.reviewCard(card: card, quality: 5);
      card = SrsEngine.reviewCard(card: card, quality: 5);
      expect(card.repetition, 2);

      // Now fail
      final failed = SrsEngine.reviewCard(card: card, quality: 1);
      expect(failed.repetition, 0);
      expect(failed.intervalDays, 1);
      expect(failed.lapseCount, 1);
      expect(failed.state, SrsState.learning);
    });

    test('ease factor never drops below minimum 1.3', () {
      var card = SrsCard.initial('test_01');
      for (var i = 0; i < 15; i++) {
        card = SrsEngine.reviewCard(card: card, quality: 0);
      }

      expect(card.easeFactor, greaterThanOrEqualTo(SrsEngine.minEaseFactor));
      expect(card.easeFactor, 1.3);
    });
  });
}
