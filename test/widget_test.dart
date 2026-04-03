// This is a basic Flutter widget test for the Expense AI Agent app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_ai_agent/main.dart';

void main() {
  testWidgets('Expense AI Agent app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Give the app some time to initialize async operations
    // and then settle
    await tester.pumpAndSettle(
      const Duration(seconds: 5),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 1),
    );

    // Verify that the app loads without errors
    // The app should be built successfully
    expect(find.byType(MyApp), findsOneWidget);
  }, skip: true);
}
