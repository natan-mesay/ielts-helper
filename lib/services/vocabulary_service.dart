import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/vocabulary_item.dart';
import '../features/srs/models/srs_card.dart';

class VocabularyService {
  static const String _vocabAssetPath = 'assets/data/ielts_vocabulary.json';
  static const String _topicsAssetPath = 'assets/data/ielts_vocabulary_topics.json';

  List<VocabularyItem>? _cachedVocabulary;
  List<TopicInfo>? _cachedTopics;

  /// Loads all vocabulary items from asset bundle
  Future<List<VocabularyItem>> loadVocabulary() async {
    if (_cachedVocabulary != null) {
      return _cachedVocabulary!;
    }

    try {
      final jsonString = await rootBundle.loadString(_vocabAssetPath);
      final List<dynamic> decoded = jsonDecode(jsonString);
      _cachedVocabulary = decoded.map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedVocabulary!;
    } catch (e) {
      return [];
    }
  }

  /// Loads all topic categories from asset bundle with accurate dynamic word counts
  Future<List<TopicInfo>> loadTopics() async {
    if (_cachedTopics != null) {
      return _cachedTopics!;
    }

    try {
      final jsonString = await rootBundle.loadString(_topicsAssetPath);
      final List<dynamic> decoded = jsonDecode(jsonString);
      final rawTopics = decoded.map((e) => TopicInfo.fromJson(e as Map<String, dynamic>)).toList();

      final vocab = await loadVocabulary();
      final countMap = <String, int>{};
      for (final item in vocab) {
        final key = item.topic.trim().toLowerCase();
        countMap[key] = (countMap[key] ?? 0) + 1;
      }

      _cachedTopics = rawTopics.map((t) {
        final actualCount = countMap[t.topic.trim().toLowerCase()];
        if (actualCount != null && actualCount > 0) {
          return TopicInfo(
            category: t.category,
            topic: t.topic,
            url: t.url,
            itemCount: actualCount,
          );
        }
        return t;
      }).toList();

      return _cachedTopics!;
    } catch (e) {
      return [];
    }
  }

  /// Filter vocabulary by specific topic
  Future<List<VocabularyItem>> getByTopic(String topic) async {
    final all = await loadVocabulary();
    return all.where((item) => item.topic.toLowerCase() == topic.toLowerCase()).toList();
  }

  /// Filter vocabulary by category
  Future<List<VocabularyItem>> getByCategory(String category) async {
    final all = await loadVocabulary();
    return all.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Build a study queue combining SRS due cards, new/unstudied cards, and hardest cards
  Future<List<VocabularyItem>> buildStudyQueue({
    required Map<String, SrsCard> srsCards,
    String? filterTopic,
    int maxCards = 15,
  }) async {
    var pool = await loadVocabulary();
    if (filterTopic != null && filterTopic.isNotEmpty && filterTopic != 'All Topics') {
      pool = pool.where((item) => item.topic.toLowerCase() == filterTopic.toLowerCase()).toList();
    }

    if (pool.isEmpty) return [];

    final learningDueItems = <VocabularyItem>[];
    final reviewDueItems = <VocabularyItem>[];
    final unstudiedItems = <VocabularyItem>[];
    final otherStudiedItems = <VocabularyItem>[];

    for (final item in pool) {
      final card = srsCards[item.id];
      if (card == null || card.state == SrsState.newCard) {
        unstudiedItems.add(item);
      } else if (card.isDue) {
        if (card.state == SrsState.learning) {
          learningDueItems.add(item);
        } else {
          reviewDueItems.add(item);
        }
      } else {
        otherStudiedItems.add(item);
      }
    }

    final queue = <VocabularyItem>[];

    // Priority 1: Lapsed / Learning cards that are due
    queue.addAll(learningDueItems);

    // Priority 2: Review cards that are due
    if (queue.length < maxCards) {
      final needed = maxCards - queue.length;
      queue.addAll(reviewDueItems.take(needed));
    }

    // Priority 3: Unstudied new cards from this pool (e.g. cards 16 to 25 in session 2)
    if (queue.length < maxCards) {
      final needed = maxCards - queue.length;
      queue.addAll(unstudiedItems.take(needed));
    }

    // Priority 4 (Fallback only when queue is still below maxCards AND unstudied items are exhausted):
    // E.g., re-practicing a topic where all cards were studied once, or only a few are due today.
    // Prioritizes hardest words (lowest ease factor, highest lapses) or oldest reviewed cards.
    if (queue.length < maxCards && otherStudiedItems.isNotEmpty) {
      final queueIds = queue.map((e) => e.id).toSet();
      final candidates = otherStudiedItems.where((item) => !queueIds.contains(item.id)).toList();

      candidates.sort((a, b) {
        final cardA = srsCards[a.id]!;
        final cardB = srsCards[b.id]!;
        if (cardA.easeFactor != cardB.easeFactor) {
          return cardA.easeFactor.compareTo(cardB.easeFactor); // lowest ease factor first
        }
        if (cardA.lapseCount != cardB.lapseCount) {
          return cardB.lapseCount.compareTo(cardA.lapseCount); // highest lapse first
        }
        final dateA = cardA.lastReviewed ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = cardB.lastReviewed ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB); // oldest review first
      });

      final needed = maxCards - queue.length;
      queue.addAll(candidates.take(needed));
    }

    // If still empty (e.g. brand new pool with no SRS cards):
    if (queue.isEmpty) {
      queue.addAll(pool.take(maxCards));
    }

    return queue.take(maxCards).toList();
  }
}
