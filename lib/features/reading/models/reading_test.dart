import 'reading_question.dart';

class ReadingTest {
  final String id;
  final String title;
  final String topic;
  final String category;
  final int estimatedMinutes;
  final Map<String, String> paragraphs;
  final List<ReadingQuestion> questions;

  const ReadingTest({
    required this.id,
    required this.title,
    required this.topic,
    required this.category,
    this.estimatedMinutes = 20,
    required this.paragraphs,
    required this.questions,
  });

  String get fullPassageText {
    return paragraphs.entries
        .map((entry) => '[${entry.key}]\n${entry.value}')
        .join('\n\n');
  }

  int get wordCount {
    final full = paragraphs.values.join(' ');
    if (full.trim().isEmpty) return 0;
    return full.trim().split(RegExp(r'\s+')).length;
  }

  factory ReadingTest.fromJson(Map<String, dynamic> json) {
    final rawParagraphs = json['paragraphs'] as Map<String, dynamic>? ?? {};
    final parsedParagraphs = rawParagraphs.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final parsedQuestions = rawQuestions
        .map((q) => ReadingQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return ReadingTest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Test',
      topic: json['topic'] as String? ?? 'Academic Reading',
      category: json['category'] as String? ?? 'Practice Tests',
      estimatedMinutes: json['estimated_minutes'] as int? ?? 20,
      paragraphs: parsedParagraphs,
      questions: parsedQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'category': category,
      'estimated_minutes': estimatedMinutes,
      'paragraphs': paragraphs,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
