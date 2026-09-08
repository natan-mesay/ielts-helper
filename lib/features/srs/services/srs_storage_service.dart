import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
import '../models/srs_card.dart';
import '../models/review_log.dart';

class SrsStorageService {
  static const String _cardsKey = 'ielts_srs_cards_v1';
  static const String _streakKey = 'ielts_study_streak';
  static const String _lastStudyDateKey = 'ielts_last_study_date';
  static const String _migrationDoneKey = 'ielts_sqlite_migrated_v1';

  final AppDatabase _db;
  final SharedPreferences? _prefsInstance;
  bool _migrationAttempted = false;

  SrsStorageService([this._prefsInstance, AppDatabase? database])
      : _db = database ?? AppDatabase.instance;

  Future<SharedPreferences> get _prefs async =>
      _prefsInstance ?? await SharedPreferences.getInstance();

  /// Migrates legacy SharedPreferences data to SQLite if present
  Future<void> _checkMigration() async {
    if (_migrationAttempted) return;
    _migrationAttempted = true;

    try {
      final prefs = await _prefs;
      final migrated = prefs.getBool(_migrationDoneKey) ?? false;
      if (migrated) return;

      final jsonString = prefs.getString(_cardsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final legacyCards = decoded.values
            .map((v) => SrsCard.fromJson(v as Map<String, dynamic>))
            .toList();
        if (legacyCards.isNotEmpty) {
          await _db.upsertCards(legacyCards);
        }
      }

      final legacyStreak = prefs.getInt(_streakKey);
      if (legacyStreak != null) {
        await _db.setMetadata('streak', legacyStreak.toString());
      }

      final legacyDate = prefs.getString(_lastStudyDateKey);
      if (legacyDate != null) {
        await _db.setMetadata('last_study_date', legacyDate);
      }

      await prefs.setBool(_migrationDoneKey, true);
    } catch (_) {
      // Fallback silently if migration encounters issues
    }
  }

  /// Load all stored SRS cards from SQLite
  Future<Map<String, SrsCard>> loadCards() async {
    await _checkMigration();
    try {
      final dbCards = await _db.getAllCards();
      if (dbCards.isNotEmpty) {
        return dbCards;
      }
    } catch (_) {}

    // Fallback to SharedPreferences if database query fails
    final prefs = await _prefs;
    final jsonString = prefs.getString(_cardsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) =>
          MapEntry(key, SrsCard.fromJson(value as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  /// Save or update a single card
  Future<void> saveCard(SrsCard card) async {
    try {
      await _db.upsertCard(card);
    } catch (_) {}

    // Also keep SharedPreferences in sync as backup
    try {
      final prefs = await _prefs;
      final current = await loadCards();
      current[card.vocabId] = card;
      final encoded = jsonEncode(current.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_cardsKey, encoded);
    } catch (_) {}
  }

  /// Batch save cards
  Future<void> saveCards(List<SrsCard> cards) async {
    try {
      await _db.upsertCards(cards);
    } catch (_) {}

    try {
      final prefs = await _prefs;
      final current = await loadCards();
      for (final card in cards) {
        current[card.vocabId] = card;
      }
      final encoded = jsonEncode(current.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_cardsKey, encoded);
    } catch (_) {}
  }

  /// Get card for a given vocabId, or return an initial new card
  Future<SrsCard> getOrCreateCard(String vocabId) async {
    await _checkMigration();
    try {
      final card = await _db.getCard(vocabId);
      if (card != null) return card;
    } catch (_) {}

    final cards = await loadCards();
    return cards[vocabId] ?? SrsCard.initial(vocabId);
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
    await _checkMigration();
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
    await _checkMigration();
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
    await prefs.remove(_cardsKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_lastStudyDateKey);
    await prefs.remove(_migrationDoneKey);
  }
}
