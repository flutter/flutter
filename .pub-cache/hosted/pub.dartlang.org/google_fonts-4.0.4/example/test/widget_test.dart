// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// Consider `flutter test --no-test-assets` if assets are not required.
void main() {
  testWidgets('Can specify text style', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Text('Hello', style: GoogleFonts.aBeeZee())),
    );
  });

  testWidgets('Can specify text theme', (WidgetTester tester) async {
    final baseTheme = ThemeData.dark();

    await tester.pumpWidget(
      MaterialApp(
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.aBeeZeeTextTheme(baseTheme.textTheme),
        ),
      ),
    );
  });
}
