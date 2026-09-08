import '../../../../models/vocabulary_item.dart';
import '../models/cloze_prompt.dart';

class ClozeGenerator {
  static const String blankToken = '[ _____ ]';

  /// Generates a ClozePrompt from a VocabularyItem
  static ClozePrompt generate(VocabularyItem item) {
    final term = item.cleanTerm;
    final example = item.example.trim();
    final definition = item.definition.trim();

    String sentenceWithBlank = '';
    String prefix = '';
    String suffix = '';
    String targetWord = term;

    // Check if example sentence exists and contains the term
    if (example.isNotEmpty) {
      final match = _findTermInSentence(example, term);
      if (match != null) {
        prefix = example.substring(0, match.start).trimLeft();
        suffix = example.substring(match.end).trimRight();
        targetWord = example.substring(match.start, match.end);
        sentenceWithBlank = '$prefix $blankToken $suffix'.trim();
      }
    }

    // If no match found in example, construct an academic context sentence
    if (sentenceWithBlank.isEmpty) {
      final contextSentence = _buildContextSentence(item);
      final match = _findTermInSentence(contextSentence, term);
      if (match != null) {
        prefix = contextSentence.substring(0, match.start).trimLeft();
        suffix = contextSentence.substring(match.end).trimRight();
        targetWord = contextSentence.substring(match.start, match.end);
        sentenceWithBlank = '$prefix $blankToken $suffix'.trim();
      } else {
        // Fallback cloze frame
        prefix = 'In IELTS Academic contexts,';
        suffix = definition.isNotEmpty
            ? 'refers to: "$definition".'
            : 'is an essential concept in ${item.topic}.';
        sentenceWithBlank = '$prefix $blankToken $suffix';
        targetWord = term;
      }
    }

    // Alternatives: e.g. synonyms or clean root
    final alternatives = <String>[];
    if (item.synonyms.isNotEmpty) {
      for (final s in item.synonyms.split(RegExp(r'[,;/]'))) {
        final cleanS = s.trim();
        if (cleanS.isNotEmpty && cleanS.toLowerCase() != targetWord.toLowerCase()) {
          alternatives.add(cleanS);
        }
      }
    }

    return ClozePrompt(
      item: item,
      sentenceWithBlank: sentenceWithBlank,
      prefix: prefix,
      suffix: suffix,
      targetWord: targetWord,
      alternativeAnswers: alternatives,
      partOfSpeech: item.partOfSpeech.isNotEmpty ? item.partOfSpeech : 'vocabulary',
      definition: definition.isNotEmpty ? definition : 'Key concept in ${item.topic}',
      pronunciation: item.pronunciation,
      exampleFull: example.isNotEmpty ? example : sentenceWithBlank.replaceAll(blankToken, targetWord),
    );
  }

  static Match? _findTermInSentence(String sentence, String term) {
    // 1. Exact term match with word boundaries
    final escapedTerm = RegExp.escape(term);
    var reg = RegExp('\\b$escapedTerm\\b', caseSensitive: false);
    var match = reg.firstMatch(sentence);
    if (match != null) return match;

    // 2. Try match without 'to ' prefix if it is a verb (e.g. "to abduct" -> "abduct")
    if (term.toLowerCase().startsWith('to ')) {
      final verbOnly = term.substring(3).trim();
      final escapedVerb = RegExp.escape(verbOnly);
      reg = RegExp('\\b$escapedVerb\\w*', caseSensitive: false);
      match = reg.firstMatch(sentence);
      if (match != null) return match;
    }

    // 3. Try inflection match on stem (for words >= 5 characters)
    if (term.length >= 5) {
      final stem = term.length > 6 ? term.substring(0, term.length - 2) : term.substring(0, term.length - 1);
      final escapedStem = RegExp.escape(stem);
      reg = RegExp('\\b$escapedStem\\w*', caseSensitive: false);
      match = reg.firstMatch(sentence);
      if (match != null) return match;
    }

    return null;
  }

  static String _buildContextSentence(VocabularyItem item) {
    final term = item.cleanTerm;
    final def = item.definition.toLowerCase().trim();
    final topic = item.topic;

    if (def.isNotEmpty) {
      return 'The term $term is widely defined as $def in academic discussions regarding $topic.';
    }
    return 'Candidates aiming for band 7+ frequently utilize the word $term when discussing $topic in writing.';
  }
}
