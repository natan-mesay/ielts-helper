import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/flashcards/presentation/widgets/typing_input_area.dart';

void main() {
  group('TypingInputArea Widget Tests', () {
    testWidgets('renders Hint, Don\'t Know, Skip, and Check buttons', (tester) async {
      bool hintPressed = false;
      bool dontKnowPressed = false;
      bool skipPressed = false;
      String submitted = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypingInputArea(
              onSubmit: (val) => submitted = val,
              onHint: () => hintPressed = true,
              onSkip: () => skipPressed = true,
              onDontKnow: () => dontKnowPressed = true,
              currentHintLevel: 0,
              isEvaluated: false,
            ),
          ),
        ),
      );

      // Verify all buttons exist
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text("Don't Know"), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);

      // Tap Don't Know
      await tester.tap(find.text("Don't Know"));
      await tester.pump();
      expect(dontKnowPressed, isTrue);

      // Tap Hint
      await tester.tap(find.text('Hint'));
      await tester.pump();
      expect(hintPressed, isTrue);

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipPressed, isTrue);

      // Enter text and tap Check
      await tester.enterText(find.byType(TextField), 'campaign');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(submitted, 'campaign');
    });

    testWidgets('renders without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypingInputArea(
              onSubmit: (_) {},
              onHint: () {},
              onSkip: () {},
              onDontKnow: () {},
              currentHintLevel: 2,
              isEvaluated: false,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Don't Know"), findsOneWidget);
      expect(find.text('Hint (2/3)'), findsOneWidget);
    });
  });
}
