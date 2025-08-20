// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/text_field/text_field.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextFieldExampleApp', () {
    Future<void> pressShiftEnter(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    }

    testWidgets('displays correct label', (WidgetTester tester) async {
      await tester.pumpWidget(const example.TextFieldExampleApp());

      expect(
        find.text(
          'Please submit some text\n\n'
          'Press Shift+Enter for a new line\n'
          'Press Enter to submit',
        ),
        findsOneWidget,
      );
    });

    testWidgets('adds new line when Shift+Enter is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(const example.TextFieldExampleApp());

      final Finder textFieldFinder = find.byType(TextField);

      await tester.enterText(textFieldFinder, 'Hello');
      expect(find.descendant(of: textFieldFinder, matching: find.text('Hello')), findsOneWidget);

      await pressShiftEnter(tester);

      expect(find.descendant(of: textFieldFinder, matching: find.text('Hello\n')), findsOneWidget);
    });

    testWidgets('displays entered text when TextField is submitted', (WidgetTester tester) async {
      await tester.pumpWidget(const example.TextFieldExampleApp());

      final Finder textFieldFinder = find.byType(TextField);

      await tester.enterText(textFieldFinder, 'Hello');
      expect(find.descendant(of: textFieldFinder, matching: find.text('Hello')), findsOneWidget);

      await pressShiftEnter(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.descendant(of: textFieldFinder, matching: find.text('')), findsOneWidget);
      expect(find.text('Submitted text:\n\nHello\n'), findsOneWidget);
    });
  });
}
