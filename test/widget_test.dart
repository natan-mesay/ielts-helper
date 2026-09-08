import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/main.dart';

void main() {
  testWidgets('App initializes with title and loads dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const IeltsPrepApp());
    expect(find.text('iils'), findsOneWidget);
    expect(find.text('Active Recall & Spaced Repetition'), findsOneWidget);
  });
}
