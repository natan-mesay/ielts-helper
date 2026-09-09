import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ielts_prep_app/core/database/app_database.dart';
import 'package:ielts_prep_app/features/flashcards/presentation/controllers/study_session_controller.dart';
import 'package:ielts_prep_app/features/srs/models/srs_card.dart';
import 'package:ielts_prep_app/features/srs/services/srs_storage_service.dart';
import 'package:ielts_prep_app/models/vocabulary_item.dart';
import 'package:ielts_prep_app/services/vocabulary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVocabService extends VocabularyService {
  final List<VocabularyItem> items;
  MockVocabService(this.items);

  @override
  Future<List<VocabularyItem>> buildStudyQueue({
    required Map<String, SrsCard> srsCards,
    String? filterTopic,
    int maxCards = 15,
  }) async {
    return items.take(maxCards).toList();
  }
}

VocabularyItem _createItem({
  required String id,
  required String term,
  required String definition,
  required String example,
}) {
  return VocabularyItem(
    id: id,
    term: term,
    definition: definition,
    partOfSpeech: 'noun',
    pronunciation: '',
    synonyms: '',
    example: example,
    topic: 'Science',
    subtopic: '',
    category: 'Word Power',
    sourceUrl: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await AppDatabase.openInMemory();
    AppDatabase.setInstance(db);
  });

  tearDown(() async {
    await db.clearAll();
  });

  test('StudySessionController re-queues incorrect words for intra-session re-learning', () async {
    final testItems = [
      _createItem(
        id: 'ITEM-1',
        term: 'abundant',
        definition: 'existing or available in large quantities',
        example: 'There is [ _____ ] evidence.',
      ),
      _createItem(
        id: 'ITEM-2',
        term: 'scarcity',
        definition: 'state of being in short supply',
        example: 'Water [ _____ ] is a problem.',
      ),
      _createItem(
        id: 'ITEM-3',
        term: 'hypothesis',
        definition: 'a proposed explanation',
        example: 'The [ _____ ] was tested.',
      ),
    ];

    final mockVocabService = MockVocabService(testItems);
    final storageService = SrsStorageService();
    final controller = StudySessionController(
      vocabService: mockVocabService,
      storageService: storageService,
    );

    await controller.startSession(cardLimit: 3);

    expect(controller.totalCards, 3);
    expect(controller.initialTotalCards, 3);
    expect(controller.currentIndex, 0);
    expect(controller.currentPrompt!.targetWord, 'abundant');

    // 1. Submit wrong answer for card 1
    final result1 = await controller.submitAnswer('completely_wrong');
    expect(result1.isSuccessful, isFalse);
    expect(controller.pendingRelearnCount, 1);
    expect(controller.incorrectCount, 1);

    // Prompt 1 should be re-inserted into queue
    expect(controller.totalCards, 4);

    // Check review log was persisted in SQLite
    final logs = await storageService.getReviewLogsForCard('ITEM-1');
    expect(logs.length, 1);
    expect(logs.first.isCorrect, isFalse);

    // Advance to Card 2
    controller.nextCard();
    expect(controller.currentIndex, 1);
    expect(controller.currentPrompt!.targetWord, 'scarcity');

    // 2. Answer Card 2 correctly
    final result2 = await controller.submitAnswer('scarcity');
    expect(result2.isSuccessful, isTrue);
    expect(controller.pendingRelearnCount, 1); // ITEM-1 is still pending!

    // Advance to Card 3
    controller.nextCard();
    expect(controller.currentIndex, 2);
    expect(controller.currentPrompt!.targetWord, 'hypothesis');

    // 3. Answer Card 3 correctly
    final result3 = await controller.submitAnswer('hypothesis');
    expect(result3.isSuccessful, isTrue);

    // Advance to Card 4 (Re-learning ITEM-1!)
    controller.nextCard();
    expect(controller.currentIndex, 3);
    expect(controller.currentPrompt!.targetWord, 'abundant');
    expect(controller.pendingRelearnCount, 1);

    // 4. Now answer Card 1 correctly upon re-test
    final result4 = await controller.submitAnswer('abundant');
    expect(result4.isSuccessful, isTrue);
    expect(controller.pendingRelearnCount, 0); // Cleared from relearn queue!

    // Advance to complete session
    controller.nextCard();
    expect(controller.isCompleted, isTrue);
    expect(controller.correctCount, 3);
  });

  test('dontKnow() also re-queues word for session re-learning', () async {
    final testItems = [
      _createItem(
        id: 'ITEM-1',
        term: 'crucial',
        definition: 'of great importance',
        example: 'This is a [ _____ ] step.',
      ),
      _createItem(
        id: 'ITEM-2',
        term: 'vital',
        definition: 'absolutely necessary',
        example: 'Water is [ _____ ] for life.',
      ),
    ];

    final mockVocabService = MockVocabService(testItems);
    final storageService = SrsStorageService();
    final controller = StudySessionController(
      vocabService: mockVocabService,
      storageService: storageService,
    );

    await controller.startSession(cardLimit: 2);
    expect(controller.totalCards, 2);

    await controller.dontKnow();
    expect(controller.pendingRelearnCount, 1);
    expect(controller.totalCards, 3); // re-queued!

    final logs = await storageService.getReviewLogsForCard('ITEM-1');
    expect(logs.length, 1);
    expect(logs.first.rating, 0);
  });
}
