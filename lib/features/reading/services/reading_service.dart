import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_test.dart';
import '../models/reading_test_result.dart';

class ReadingService {
  static const String _historyKey = 'ielts_reading_history_v1';
  List<ReadingTest>? _cachedTests;

  /// Loads all reading practice tests from assets
  Future<List<ReadingTest>> loadTests() async {
    if (_cachedTests != null) return _cachedTests!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/reading_tests.json');
      final dynamic decoded = json.decode(jsonString);

      if (decoded is List) {
        _cachedTests = decoded
            .map((item) => ReadingTest.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _cachedTests = [];
      }
    } catch (e) {
      _cachedTests = [];
    }

    return _cachedTests!;
  }

  /// Retrieves a specific test by ID
  Future<ReadingTest?> getTestById(String id) async {
    final tests = await loadTests();
    try {
      return tests.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Saves a completed test result to local storage
  Future<void> saveResult(ReadingTestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_historyKey) ?? [];
    existing.add(json.encode(result.toJson()));
    await prefs.setStringList(_historyKey, existing);
  }

  /// Retrieves all historical test results
  Future<List<ReadingTestResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];
    return rawList
        .map((str) {
          try {
            return ReadingTestResult.fromJson(
                json.decode(str) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ReadingTestResult>()
        .toList();
  }

  /// Gets the best result for a given test ID
  Future<ReadingTestResult?> getBestResultForTest(String testId) async {
    final history = await getHistory();
    final testResults = history.where((r) => r.testId == testId).toList();
    if (testResults.isEmpty) return null;
    testResults.sort((a, b) => b.bandScore.compareTo(a.bandScore));
    return testResults.first;
  }
}
