// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text form field use case renders form and validates fields', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, TextFormFieldUseCase());
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsExactly(2));

    // Test the enabled text form field
    {
      final Finder finder = find.byKey(const Key('enabled text form field'));
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.enterText(finder, 'abc');
      await tester.pumpAndSettle();
      expect(find.text('abc'), findsOneWidget);
    }

    // Test the disabled text form field
    {
      final Finder finder = find.byKey(const Key('disabled text form field'));
      final TextFormField textField = tester.widget<TextFormField>(finder);
      expect(textField.enabled, isFalse);
    }

    // Test form validation on empty input
    {
      final Finder finder = find.byKey(const Key('enabled text form field'));
      await tester.enterText(finder, '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit button')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter some text'), findsOneWidget);
      expect(find.text('Validation failed'), findsOneWidget);
    }

    // Test successful form submission feedback
    {
      final Finder finder = find.byKey(const Key('enabled text form field'));
      await tester.enterText(finder, 'test@example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit button')));
      await tester.pumpAndSettle();
      expect(find.text('Form submitted successfully!'), findsWidgets);
    }
  });

  testWidgets('text form field demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextFormFieldUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('TextFormField Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
