import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../features/srs/models/srs_card.dart';
import '../../features/srs/models/review_log.dart';

class AppDatabase {
  static const String _dbFileName = 'ielts_app_v1.db';
  static const int _dbVersion = 1;

  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._();
  AppDatabase.forDatabase(this._db);

  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Visible for testing to inject custom/in-memory database instance
  @visibleForTesting
  static void setInstance(AppDatabase? customInstance) {
    _instance = customInstance;
  }

  /// Creates a clean in-memory database instance for testing
  @visibleForTesting
  static Future<AppDatabase> openInMemory() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: _dbVersion,
      onCreate: (db, version) async {
        final instance = AppDatabase._();
        await instance._onCreate(db, version);
      },
    );
    return AppDatabase.forDatabase(db);
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase({String? customPath}) async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, _dbFileName);
    }

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE srs_cards (
        vocab_id TEXT PRIMARY KEY,
        repetition INTEGER NOT NULL,
        ease_factor REAL NOT NULL,
        interval_days INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        last_reviewed TEXT,
        lapse_count INTEGER NOT NULL,
        state TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE review_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vocab_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        user_input TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        hint_level INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_review_logs_vocab ON review_logs(vocab_id)
    ''');

    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- SRS Card CRUD Operations ---

  Future<void> upsertCard(SrsCard card) async {
    final db = await database;
    await db.insert(
      'srs_cards',
      {
        'vocab_id': card.vocabId,
        'repetition': card.repetition,
        'ease_factor': card.easeFactor,
        'interval_days': card.intervalDays,
        'due_date': card.dueDate.toIso8601String(),
        'last_reviewed': card.lastReviewed?.toIso8601String(),
        'lapse_count': card.lapseCount,
        'state': card.state.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertCards(List<SrsCard> cards) async {
    final db = await database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert(
        'srs_cards',
        {
          'vocab_id': card.vocabId,
          'repetition': card.repetition,
          'ease_factor': card.easeFactor,
          'interval_days': card.intervalDays,
          'due_date': card.dueDate.toIso8601String(),
          'last_reviewed': card.lastReviewed?.toIso8601String(),
          'lapse_count': card.lapseCount,
          'state': card.state.name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<SrsCard?> getCard(String vocabId) async {
    final db = await database;
    final results = await db.query(
      'srs_cards',
      where: 'vocab_id = ?',
      whereArgs: [vocabId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _mapToSrsCard(results.first);
  }

  Future<Map<String, SrsCard>> getAllCards() async {
    final db = await database;
    final results = await db.query('srs_cards');
    final map = <String, SrsCard>{};
    for (final row in results) {
      final card = _mapToSrsCard(row);
      map[card.vocabId] = card;
    }
    return map;
  }

  SrsCard _mapToSrsCard(Map<String, dynamic> row) {
    return SrsCard(
      vocabId: row['vocab_id'] as String,
      repetition: (row['repetition'] as num).toInt(),
      easeFactor: (row['ease_factor'] as num).toDouble(),
      intervalDays: (row['interval_days'] as num).toInt(),
      dueDate: DateTime.tryParse(row['due_date'] as String) ?? DateTime.now(),
      lastReviewed: row['last_reviewed'] != null
          ? DateTime.tryParse(row['last_reviewed'] as String)
          : null,
      lapseCount: (row['lapse_count'] as num).toInt(),
      state: SrsState.values.firstWhere(
        (e) => e.name == row['state'],
        orElse: () => SrsState.newCard,
      ),
    );
  }

  // --- Review Logs (Anki Revlog) Operations ---

  Future<int> insertReviewLog(ReviewLog log) async {
    final db = await database;
    return await db.insert('review_logs', log.toMap());
  }

  Future<List<ReviewLog>> getReviewLogsForCard(String vocabId) async {
    final db = await database;
    final results = await db.query(
      'review_logs',
      where: 'vocab_id = ?',
      whereArgs: [vocabId],
      orderBy: 'reviewed_at ASC',
    );
    return results.map((r) => ReviewLog.fromMap(r)).toList();
  }

  Future<List<ReviewLog>> getAllReviewLogs() async {
    final db = await database;
    final results = await db.query('review_logs', orderBy: 'reviewed_at DESC');
    return results.map((r) => ReviewLog.fromMap(r)).toList();
  }

  // --- App Metadata (Streak, Settings) Operations ---

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final results = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('srs_cards');
    await db.delete('review_logs');
    await db.delete('app_metadata');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
