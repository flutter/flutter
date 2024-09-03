// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('date picker can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, DatePickerUseCase());
    expect(find.text('Show Date Picker'), findsOneWidget);

    await tester.tap(find.text('Show Date Picker'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('datepicker has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, DatePickerUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('DatePicker Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
