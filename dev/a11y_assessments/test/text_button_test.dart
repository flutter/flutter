// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Action Disabled'), findsOneWidget);
  });

  testWidgets('snackbar shows on button press', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());

    await tester.tap(find.text('Action'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Text button is pressed'), findsOneWidget);
  });
}
