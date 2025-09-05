// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:high_contrast_override/main.dart';

void main() {
  testWidgets('High contrast override example loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HighContrastOverrideExample());

    // Verify that the app loads with expected elements
    expect(find.text('High Contrast Override Demo'), findsOneWidget);
    expect(find.text('Force High Contrast'), findsOneWidget);
    expect(find.text('High Contrast Status'), findsOneWidget);
  });
}
