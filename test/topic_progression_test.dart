import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/srs/models/srs_card.dart';
import 'package:ielts_prep_app/services/vocabulary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Topic Progression & 15-Card Batching Tests', () {
    test('Session 1 returns first 15 unstudied words for Advertising', () async {
      final vocabService = VocabularyService();
      final allCards = <String, SrsCard>{};

      final queueSession1 = await vocabService.buildStudyQueue(
        srsCards: allCards,
        filterTopic: 'Advertising',
        maxCards: 15,
      );

      expect(queueSession1.length, 15);
      expect(queueSession1.first.id, 'IELTS-VOCAB-0001');
      expect(queueSession1.last.id, 'IELTS-VOCAB-0015');
    });

    test('Session 2 includes the remaining unstudied words (16-25) without repeating only the first 15', () async {
      final vocabService = VocabularyService();

      // Simulate cards 1..15 as reviewed with due date tomorrow
      final srsCards = <String, SrsCard>{};
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      for (int i = 1; i <= 15; i++) {
        final id = 'IELTS-VOCAB-${i.toString().padLeft(4, '0')}';
        srsCards[id] = SrsCard(
          vocabId: id,
          repetition: 1,
          easeFactor: 2.5,
          intervalDays: 1,
          dueDate: tomorrow,
          lastReviewed: DateTime.now(),
          lapseCount: 0,
          state: SrsState.review,
        );
      }

      final queueSession2 = await vocabService.buildStudyQueue(
        srsCards: srsCards,
        filterTopic: 'Advertising',
        maxCards: 15,
      );

      expect(queueSession2.length, 15);

      // Verify remaining unstudied cards 16 to 25 are included!
      final queueIds = queueSession2.map((e) => e.id).toSet();
      for (int i = 16; i <= 25; i++) {
        final id = 'IELTS-VOCAB-${i.toString().padLeft(4, '0')}';
        expect(
          queueIds.contains(id),
          isTrue,
          reason: 'Expected unstudied card $id to be in session 2',
        );
      }

      // Remaining 5 cards are filled from cards 1..15 (hardest/oldest)
      final fillCardsCount = queueSession2.where((e) => e.id.compareTo('IELTS-VOCAB-0015') <= 0).length;
      expect(fillCardsCount, 5);
    });

    test('loadTopics dynamic word counts match actual vocabulary items in dataset', () async {
      final vocabService = VocabularyService();
      final topics = await vocabService.loadTopics();
      final advTopic = topics.firstWhere((t) => t.topic.toLowerCase() == 'advertising');

      final allVocab = await vocabService.loadVocabulary();
      final actualAdvCount = allVocab.where((v) => v.topic.toLowerCase() == 'advertising').length;

      expect(advTopic.itemCount, actualAdvCount);
      expect(advTopic.itemCount, 25);
    });
  });
}
