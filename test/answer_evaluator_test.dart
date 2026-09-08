import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/flashcards/models/cloze_prompt.dart';
import 'package:ielts_prep_app/features/flashcards/services/answer_evaluator.dart';
import 'package:ielts_prep_app/models/vocabulary_item.dart';

void main() {
  group('AnswerEvaluator Tests', () {
    const vocab = VocabularyItem(
      id: 'test-01',
      term: 'abduction',
      partOfSpeech: 'noun',
      definition: 'kidnapping',
      pronunciation: '',
      synonyms: 'kidnapping',
      example: 'The abduction shocked the local community.',
      topic: 'Crime & Punishment',
      subtopic: 'Major Crimes',
      category: 'Word Power',
      sourceUrl: '',
    );

    const prompt = ClozePrompt(
      item: vocab,
      sentenceWithBlank: 'The [ _____ ] shocked the local community.',
      prefix: 'The',
      suffix: 'shocked the local community.',
      targetWord: 'abduction',
      alternativeAnswers: ['kidnapping'],
      partOfSpeech: 'noun',
      definition: 'kidnapping',
      pronunciation: '',
      exampleFull: 'The abduction shocked the local community.',
    );

    test('exact match is evaluated as correct', () {
      final res = AnswerEvaluator.evaluate(
        userInput: 'abduction',
        prompt: prompt,
        hintLevel: 0,
        secondsElapsed: 5,
      );

      expect(res.type, EvaluationType.correct);
      expect(res.qualityRating, 5);
      expect(res.isSuccessful, true);
    });

    test('case-insensitive and trimmed match is correct', () {
      final res = AnswerEvaluator.evaluate(
        userInput: '  ABDUCTION  ',
        prompt: prompt,
        hintLevel: 0,
        secondsElapsed: 7,
      );

      expect(res.type, EvaluationType.correct);
      expect(res.isSuccessful, true);
    });

    test('alternative synonym match is correct', () {
      final res = AnswerEvaluator.evaluate(
        userInput: 'kidnapping',
        prompt: prompt,
        hintLevel: 1,
        secondsElapsed: 8,
      );

      expect(res.type, EvaluationType.correct);
      expect(res.isSuccessful, true);
      expect(res.message, contains('synonym'));
    });

    test('single character typo on long word flags closeTypo', () {
      // "abductoin" vs "abduction" (Levenshtein distance = 1)
      final res = AnswerEvaluator.evaluate(
        userInput: 'abductoin',
        prompt: prompt,
        hintLevel: 0,
        secondsElapsed: 6,
      );

      expect(res.type, EvaluationType.closeTypo);
      expect(res.editDistance, 1);
      expect(res.message, contains('spelling'));
    });

    test('completely wrong word is evaluated as incorrect', () {
      final res = AnswerEvaluator.evaluate(
        userInput: 'burglary',
        prompt: prompt,
        hintLevel: 0,
        secondsElapsed: 4,
      );

      expect(res.type, EvaluationType.incorrect);
      expect(res.isSuccessful, false);
      expect(res.qualityRating, 1);
    });

    test('empty answer is evaluated as incorrect with rating 0', () {
      final res = AnswerEvaluator.evaluate(
        userInput: '',
        prompt: prompt,
        hintLevel: 0,
        secondsElapsed: 2,
      );

      expect(res.type, EvaluationType.incorrect);
      expect(res.qualityRating, 0);
    });
  });
}
