class VocabularyItem {
  final String id;
  final String term;
  final String partOfSpeech;
  final String definition;
  final String pronunciation;
  final String synonyms;
  final String example;
  final String topic;
  final String subtopic;
  final String category;
  final String sourceUrl;

  const VocabularyItem({
    required this.id,
    required this.term,
    required this.partOfSpeech,
    required this.definition,
    required this.pronunciation,
    required this.synonyms,
    required this.example,
    required this.topic,
    required this.subtopic,
    required this.category,
    required this.sourceUrl,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String? ?? '',
      term: json['term'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ?? 'noun',
      definition: json['definition'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
      synonyms: json['synonyms'] as String? ?? '',
      example: json['example'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      subtopic: json['subtopic'] as String? ?? '',
      category: json['category'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'part_of_speech': partOfSpeech,
      'definition': definition,
      'pronunciation': pronunciation,
      'synonyms': synonyms,
      'example': example,
      'topic': topic,
      'subtopic': subtopic,
      'category': category,
      'source_url': sourceUrl,
    };
  }

  /// Clean display term without parentheses
  String get cleanTerm {
    return term.replaceAll(RegExp(r'\(.*?\)'), '').trim();
  }
}

class TopicInfo {
  final String category;
  final String topic;
  final String url;
  final int itemCount;

  const TopicInfo({
    required this.category,
    required this.topic,
    required this.url,
    required this.itemCount,
  });

  factory TopicInfo.fromJson(Map<String, dynamic> json) {
    return TopicInfo(
      category: json['category'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      url: json['url'] as String? ?? '',
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'topic': topic,
      'url': url,
      'item_count': itemCount,
    };
  }
}
