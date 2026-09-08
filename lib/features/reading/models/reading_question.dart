enum QuestionType {
  multipleChoice,
  trueFalseNotGiven,
  yesNoNotGiven,
  fillInBlank,
  matchingHeadings,
}

class ReadingQuestion {
  final int number;
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final List<String> acceptedAnswers;
  final int wordLimit;
  final String evidenceParagraph;
  final String explanation;

  const ReadingQuestion({
    required this.number,
    required this.type,
    required this.prompt,
    this.options = const [],
    required this.acceptedAnswers,
    this.wordLimit = 2,
    this.evidenceParagraph = '',
    this.explanation = '',
  });

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) {
    QuestionType parseType(String? typeStr) {
      switch (typeStr?.toLowerCase()) {
        case 'multiple_choice':
        case 'multiplechoice':
          return QuestionType.multipleChoice;
        case 'true_false_not_given':
        case 'tfng':
          return QuestionType.trueFalseNotGiven;
        case 'yes_no_not_given':
        case 'ynng':
          return QuestionType.yesNoNotGiven;
        case 'matching_headings':
        case 'matchingheadings':
          return QuestionType.matchingHeadings;
        case 'fill_in_blank':
        case 'fillinblank':
        case 'summary':
        case 'sentence_completion':
        default:
          return QuestionType.fillInBlank;
      }
    }

    final acceptedList = <String>[];
    if (json['accepted_answers'] != null) {
      acceptedList.addAll(
        (json['accepted_answers'] as List).map((e) => e.toString()),
      );
    } else if (json['correct_answer'] != null) {
      acceptedList.add(json['correct_answer'].toString());
    }

    return ReadingQuestion(
      number: json['number'] as int? ?? 1,
      type: parseType(json['type'] as String?),
      prompt: json['prompt'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      acceptedAnswers: acceptedList,
      wordLimit: json['word_limit'] as int? ?? 2,
      evidenceParagraph: json['evidence_paragraph'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'type': type.name,
      'prompt': prompt,
      'options': options,
      'accepted_answers': acceptedAnswers,
      'word_limit': wordLimit,
      'evidence_paragraph': evidenceParagraph,
      'explanation': explanation,
    };
  }
}
