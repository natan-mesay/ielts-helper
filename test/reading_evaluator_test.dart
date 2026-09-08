import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/reading/models/reading_question.dart';
import 'package:ielts_prep_app/features/reading/services/reading_evaluator.dart';

void main() {
  group('ReadingEvaluator Tests', () {
    test('Multiple choice evaluation', () {
      const mcQ = ReadingQuestion(
        number: 1,
        type: QuestionType.multipleChoice,
        prompt: 'Choose the correct letter',
        options: ['A) First', 'B) Second', 'C) Third', 'D) Fourth'],
        acceptedAnswers: ['B', 'B) Second'],
      );

      expect(ReadingEvaluator.evaluate(mcQ, 'B'), isTrue);
      expect(ReadingEvaluator.evaluate(mcQ, 'b'), isTrue);
      expect(ReadingEvaluator.evaluate(mcQ, 'B) Second'), isTrue);
      expect(ReadingEvaluator.evaluate(mcQ, 'A'), isFalse);
      expect(ReadingEvaluator.evaluate(mcQ, ''), isFalse);
      expect(ReadingEvaluator.evaluate(mcQ, null), isFalse);
    });

    test('True / False / Not Given evaluation', () {
      const tfQ = ReadingQuestion(
        number: 2,
        type: QuestionType.trueFalseNotGiven,
        prompt: 'Statement',
        acceptedAnswers: ['TRUE', 'T'],
      );

      expect(ReadingEvaluator.evaluate(tfQ, 'TRUE'), isTrue);
      expect(ReadingEvaluator.evaluate(tfQ, 'True'), isTrue);
      expect(ReadingEvaluator.evaluate(tfQ, 'true'), isTrue);
      expect(ReadingEvaluator.evaluate(tfQ, 'T'), isTrue);
      expect(ReadingEvaluator.evaluate(tfQ, 't'), isTrue);
      expect(ReadingEvaluator.evaluate(tfQ, 'FALSE'), isFalse);
      expect(ReadingEvaluator.evaluate(tfQ, 'NOT GIVEN'), isFalse);

      const ngQ = ReadingQuestion(
        number: 3,
        type: QuestionType.trueFalseNotGiven,
        prompt: 'Statement NG',
        acceptedAnswers: ['NOT GIVEN', 'NG'],
      );

      expect(ReadingEvaluator.evaluate(ngQ, 'NOT GIVEN'), isTrue);
      expect(ReadingEvaluator.evaluate(ngQ, 'not given'), isTrue);
      expect(ReadingEvaluator.evaluate(ngQ, 'NG'), isTrue);
      expect(ReadingEvaluator.evaluate(ngQ, 'ng'), isTrue);
      expect(ReadingEvaluator.evaluate(ngQ, 'TRUE'), isFalse);
    });

    test('Fill in the blank evaluation', () {
      const blankQ = ReadingQuestion(
        number: 4,
        type: QuestionType.fillInBlank,
        prompt: 'Fill in blank',
        acceptedAnswers: ['dedication', 'professional dedication'],
        wordLimit: 2,
      );

      // Exact match
      expect(ReadingEvaluator.evaluate(blankQ, 'dedication'), isTrue);
      // Case insensitive
      expect(ReadingEvaluator.evaluate(blankQ, 'Dedication'), isTrue);
      // Trailing spaces
      expect(ReadingEvaluator.evaluate(blankQ, '  dedication  '), isTrue);
      // Punctuation
      expect(ReadingEvaluator.evaluate(blankQ, 'dedication.'), isTrue);
      expect(ReadingEvaluator.evaluate(blankQ, '"dedication"'), isTrue);
      // Two-word variant
      expect(ReadingEvaluator.evaluate(blankQ, 'professional dedication'), isTrue);

      // Exceeds word limit (3 words when limit is 2)
      expect(
        ReadingEvaluator.evaluate(blankQ, 'requires professional dedication'),
        isFalse,
      );

      // Wrong answer
      expect(ReadingEvaluator.evaluate(blankQ, 'intelligence'), isFalse);
    });

    test('Fill in the blank with article tolerance', () {
      const articleQ = ReadingQuestion(
        number: 5,
        type: QuestionType.fillInBlank,
        prompt: 'The rule of ______',
        acceptedAnswers: ['law', 'the law'],
        wordLimit: 2,
      );

      expect(ReadingEvaluator.evaluate(articleQ, 'law'), isTrue);
      expect(ReadingEvaluator.evaluate(articleQ, 'the law'), isTrue);
      expect(ReadingEvaluator.evaluate(articleQ, 'The Law'), isTrue);
    });
  });
}
