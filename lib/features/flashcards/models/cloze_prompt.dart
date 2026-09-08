import '../../../../models/vocabulary_item.dart';

class ClozePrompt {
  final VocabularyItem item;
  final String sentenceWithBlank;
  final String prefix;
  final String suffix;
  final String targetWord;
  final List<String> alternativeAnswers;
  final String partOfSpeech;
  final String definition;
  final String pronunciation;
  final String exampleFull;
  final int hintLevel;

  const ClozePrompt({
    required this.item,
    required this.sentenceWithBlank,
    required this.prefix,
    required this.suffix,
    required this.targetWord,
    this.alternativeAnswers = const [],
    required this.partOfSpeech,
    required this.definition,
    required this.pronunciation,
    required this.exampleFull,
    this.hintLevel = 0,
  });

  int get letterCount => targetWord.replaceAll(' ', '').length;
  String get firstLetter => targetWord.isNotEmpty ? targetWord[0].toUpperCase() : '';
  String get lastLetter => targetWord.isNotEmpty ? targetWord[targetWord.length - 1].toUpperCase() : '';

  ClozePrompt withHintLevel(int level) {
    return ClozePrompt(
      item: item,
      sentenceWithBlank: sentenceWithBlank,
      prefix: prefix,
      suffix: suffix,
      targetWord: targetWord,
      alternativeAnswers: alternativeAnswers,
      partOfSpeech: partOfSpeech,
      definition: definition,
      pronunciation: pronunciation,
      exampleFull: exampleFull,
      hintLevel: level,
    );
  }
}
