import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
import '../models/srs_card.dart';
import '../models/review_log.dart';

class SrsStorageService {
  static const String _streakKey = 'ielts_study_streak';
  static const String _lastStudyDateKey = 'ielts_last_study_date';

  final AppDatabase _db;
  final SharedPreferences? _prefsInstance;

  SrsStorageService([this._prefsInstance, AppDatabase? database])
      : _db = database ?? AppDatabase.instance;

  Future<SharedPreferences> get _prefs async =>
      _prefsInstance ?? await SharedPreferences.getInstance();

  /// Load all stored SRS cards from SQLite
  Future<Map<String, SrsCard>> loadCards() async {
    try {
      return await _db.getAllCards();
    } catch (_) {
      return {};
    }
  }

  /// Save or update a single card directly in SQLite (O(1) write)
  Future<void> saveCard(SrsCard card) async {
    try {
      await _db.upsertCard(card);
    } catch (_) {}
  }

  /// Batch save cards via atomic SQLite batch transaction
  Future<void> saveCards(List<SrsCard> cards) async {
    if (cards.isEmpty) return;
    try {
      await _db.upsertCards(cards);
    } catch (_) {}
  }

  /// Get card for a given vocabId, or return an initial new card
  Future<SrsCard> getOrCreateCard(String vocabId) async {
    try {
      final card = await _db.getCard(vocabId);
      if (card != null) return card;
    } catch (_) {}

    return SrsCard.initial(vocabId);
  }

  /// Record an Anki-style review attempt in review_logs table
  Future<int> insertReviewLog(ReviewLog log) async {
    try {
      return await _db.insertReviewLog(log);
    } catch (_) {
      return -1;
    }
  }

  /// Get all review history logs for a specific card
  Future<List<ReviewLog>> getReviewLogsForCard(String vocabId) async {
    try {
      return await _db.getReviewLogsForCard(vocabId);
    } catch (_) {
      return [];
    }
  }

  /// Get all review history logs across all cards
  Future<List<ReviewLog>> getAllReviewLogs() async {
    try {
      return await _db.getAllReviewLogs();
    } catch (_) {
      return [];
    }
  }

  /// Get current study streak
  Future<int> getStreak() async {
    try {
      final metaStreak = await _db.getMetadata('streak');
      if (metaStreak != null) {
        return int.tryParse(metaStreak) ?? 0;
      }
    } catch (_) {}

    final prefs = await _prefs;
    return prefs.getInt(_streakKey) ?? 0;
  }

  /// Record a study session and update streak
  Future<int> recordStudySession() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String? lastDateStr;
    try {
      lastDateStr = await _db.getMetadata('last_study_date');
    } catch (_) {}

    final prefs = await _prefs;
    lastDateStr ??= prefs.getString(_lastStudyDateKey);

    int currentStreak = await getStreak();

    if (lastDateStr == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = today.difference(lastDay).inDays;

        if (diff == 0) {
          // Already studied today
          return currentStreak;
        } else if (diff == 1) {
          // Studied yesterday -> streak increment
          currentStreak += 1;
        } else {
          // Missed a day -> reset to 1
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }
    }

    try {
      await _db.setMetadata('last_study_date', today.toIso8601String());
      await _db.setMetadata('streak', currentStreak.toString());
    } catch (_) {}

    await prefs.setString(_lastStudyDateKey, today.toIso8601String());
    await prefs.setInt(_streakKey, currentStreak);
    return currentStreak;
  }

  /// Clear all SRS data (useful for reset/testing)
  Future<void> clearAll() async {
    try {
      await _db.clearAll();
    } catch (_) {}

    final prefs = await _prefs;
    await prefs.remove(_streakKey);
    await prefs.remove(_lastStudyDateKey);
  }
}
