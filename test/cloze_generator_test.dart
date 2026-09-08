import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/flashcards/services/cloze_generator.dart';
import 'package:ielts_prep_app/models/vocabulary_item.dart';

void main() {
  group('ClozeGenerator Tests', () {
    test('masks term when found in example sentence', () {
      const item = VocabularyItem(
        id: 'vocab-01',
        term: 'detrimental',
        partOfSpeech: 'adjective',
        definition: 'causing damage or harm',
        pronunciation: '',
        synonyms: 'harmful',
        example: 'Smoking is known to be detrimental to public health.',
        topic: 'Health',
        subtopic: 'Habits',
        category: 'Word Power',
        sourceUrl: '',
      );

      final prompt = ClozeGenerator.generate(item);

      expect(prompt.sentenceWithBlank, contains('[ _____ ]'));
      expect(prompt.sentenceWithBlank, isNot(contains('detrimental')));
      expect(prompt.targetWord.toLowerCase(), 'detrimental');
      expect(prompt.letterCount, 11);
      expect(prompt.firstLetter, 'D');
      expect(prompt.lastLetter, 'L');
    });

    test('generates academic context frame when example is absent', () {
      const item = VocabularyItem(
        id: 'vocab-02',
        term: 'biodiversity',
        partOfSpeech: 'noun',
        definition: 'the variety of plant and animal life',
        pronunciation: '',
        synonyms: '',
        example: '',
        topic: 'Environment',
        subtopic: 'Ecology',
        category: 'Word Power',
        sourceUrl: '',
      );

      final prompt = ClozeGenerator.generate(item);

      expect(prompt.sentenceWithBlank, contains('[ _____ ]'));
      expect(prompt.sentenceWithBlank, isNot(contains('biodiversity')));
      expect(prompt.targetWord.toLowerCase(), 'biodiversity');
      expect(prompt.letterCount, 12);
    });

    test('all items in authentic dataset generate valid cloze prompts without fallback', () async {
      final file = File('assets/data/ielts_vocabulary.json');
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      final list = (jsonDecode(content) as List)
          .map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, 853);

      for (final item in list) {
        final prompt = ClozeGenerator.generate(item);
        // Ensure cloze blank is present
        expect(prompt.sentenceWithBlank, contains(ClozeGenerator.blankToken),
            reason: 'Missing blank in term: ${item.term}');
        // Ensure sentence is not falling back to the generic frame
        expect(prompt.sentenceWithBlank.startsWith('In IELTS Academic contexts,'), isFalse,
            reason: 'Fell back to fallback frame for term: ${item.term}');
        expect(prompt.targetWord.isNotEmpty, isTrue);
        expect(prompt.definition.isNotEmpty, isTrue);
      }
    });
  });
}
