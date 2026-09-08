import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ielts_prep_app/core/database/app_database.dart';
import 'package:ielts_prep_app/features/srs/models/srs_card.dart';
import 'package:ielts_prep_app/features/srs/models/review_log.dart';
import 'package:ielts_prep_app/features/srs/services/srs_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await AppDatabase.instance.clearAll();
  });

  group('AppDatabase & SQLite Tests', () {
    test('upsertCard and getCard works with SQLite', () async {
      final db = AppDatabase.instance;
      final card = SrsCard(
        vocabId: 'TEST-001',
        repetition: 2,
        easeFactor: 2.6,
        intervalDays: 6,
        dueDate: DateTime(2026, 9, 10),
        lastReviewed: DateTime(2026, 9, 4),
        lapseCount: 1,
        state: SrsState.review,
      );

      await db.upsertCard(card);
      final fetched = await db.getCard('TEST-001');

      expect(fetched, isNotNull);
      expect(fetched!.vocabId, 'TEST-001');
      expect(fetched.repetition, 2);
      expect(fetched.easeFactor, 2.6);
      expect(fetched.intervalDays, 6);
      expect(fetched.lapseCount, 1);
      expect(fetched.state, SrsState.review);
    });

    test('upsertCards batch and getAllCards works', () async {
      final db = AppDatabase.instance;
      final cards = [
        SrsCard.initial('BATCH-001'),
        SrsCard.initial('BATCH-002'),
      ];

      await db.upsertCards(cards);
      final all = await db.getAllCards();

      expect(all.containsKey('BATCH-001'), isTrue);
      expect(all.containsKey('BATCH-002'), isTrue);
    });

    test('insertReviewLog and query logs works like Anki revlog', () async {
      final db = AppDatabase.instance;
      final log1 = ReviewLog(
        vocabId: 'LOG-001',
        rating: 1,
        userInput: 'wrongans',
        isCorrect: false,
        hintLevel: 0,
        timeSpentSeconds: 5,
        reviewedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final log2 = ReviewLog(
        vocabId: 'LOG-001',
        rating: 5,
        userInput: 'correctans',
        isCorrect: true,
        hintLevel: 0,
        timeSpentSeconds: 3,
        reviewedAt: DateTime.now(),
      );

      await db.insertReviewLog(log1);
      await db.insertReviewLog(log2);

      final history = await db.getReviewLogsForCard('LOG-001');
      expect(history.length, 2);
      expect(history[0].isCorrect, isFalse);
      expect(history[0].userInput, 'wrongans');
      expect(history[1].isCorrect, isTrue);
      expect(history[1].rating, 5);
    });

    test('SrsStorageService automatically migrates legacy SharedPreferences data', () async {
      SharedPreferences.setMockInitialValues({
        'ielts_srs_cards_v1': '{"LEGACY-001": {"vocab_id": "LEGACY-001", "repetition": 1, "ease_factor": 2.5, "interval_days": 1, "due_date": "2026-09-08T00:00:00.000", "lapse_count": 0, "state": "learning"}}',
        'ielts_study_streak': 5,
        'ielts_last_study_date': '2026-09-07T00:00:00.000',
      });

      final storage = SrsStorageService();
      final cards = await storage.loadCards();
      expect(cards.containsKey('LEGACY-001'), isTrue);
      expect(cards['LEGACY-001']!.vocabId, 'LEGACY-001');

      final streak = await storage.getStreak();
      expect(streak, 5);
    });
  });
}
