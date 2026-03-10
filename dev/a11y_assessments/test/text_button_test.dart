// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text field label is visible', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    expect(find.text('City'), findsOneWidget);
  });

  testWidgets('text button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('submit causes snackbar to show', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    final Finder textFormField = find.byType(TextFormField);
    final Finder submitButton = find.text('Submit');

    // Enter text in field and submit.
    await tester.enterText(textFormField, 'test text');
    await tester.tap(submitButton);
    await tester.pump();

    // Verify that the snackbar is visible.
    expect(find.text('Form submitted'), findsOneWidget);
  });

  testWidgets('text button demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('TextButton Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  testWidgets('submit empty field causes error to show', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    final Finder submitButton = find.text('Submit');

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter some text'), findsOneWidget);
    expect(find.bySemanticsLabel('Please enter some text in City'), findsOne);
  });
}
