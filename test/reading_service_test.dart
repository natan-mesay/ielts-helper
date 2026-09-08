import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/reading/models/reading_test.dart';
import 'package:ielts_prep_app/features/reading/models/reading_test_result.dart';
import 'package:ielts_prep_app/features/reading/services/reading_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reading Model & Service Tests', () {
    test('ReadingTest deserializes correctly from json', () {
      final jsonMap = {
        'id': 'TEST-001',
        'title': 'Test Title',
        'topic': 'Science',
        'category': 'Recent',
        'estimated_minutes': 20,
        'paragraphs': {
          'A': 'Paragraph A content with multiple words.',
          'B': 'Paragraph B content.',
        },
        'questions': [
          {
            'number': 1,
            'type': 'multiple_choice',
            'prompt': 'Prompt text',
            'options': ['A', 'B'],
            'accepted_answers': ['A'],
            'evidence_paragraph': 'Paragraph A',
            'explanation': 'Because of A',
          }
        ]
      };

      final test = ReadingTest.fromJson(jsonMap);
      expect(test.id, 'TEST-001');
      expect(test.title, 'Test Title');
      expect(test.paragraphs.length, 2);
      expect(test.questions.length, 1);
      expect(test.wordCount, greaterThan(5));
      expect(test.fullPassageText, contains('[A]'));
    });

    test('ReadingTestResult toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final result = ReadingTestResult(
        testId: 'TEST-001',
        testTitle: 'Test Title',
        completedAt: now,
        elapsedSeconds: 840,
        userAnswers: {1: 'TRUE', 2: 'nurses'},
        questionResults: {1: true, 2: true},
        correctCount: 2,
        totalQuestions: 2,
        scaledRawScore: 40,
        bandScore: 9.0,
        bandRange: '8.5 - 9.0',
      );

      final jsonMap = result.toJson();
      final restored = ReadingTestResult.fromJson(jsonMap);

      expect(restored.testId, 'TEST-001');
      expect(restored.correctCount, 2);
      expect(restored.bandScore, 9.0);
      expect(restored.userAnswers[1], 'TRUE');
      expect(restored.formattedTime, '14:00');
      expect(restored.accuracyPercentage, 100.0);
    });

    test('ReadingService loads reading_tests.json from assets', () async {
      final service = ReadingService();
      final tests = await service.loadTests();
      expect(tests.length, greaterThanOrEqualTo(2));
      expect(tests.first.id, 'READING-1516');
      expect(tests.first.questions.length, 13);
      expect(tests[1].id, 'READING-1540');
      expect(tests[1].questions.length, 13);
    });
  });
}
