// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/text_button/text_button.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {

  // The app being tested loads images via HTTP which the test
  // framework defeats by default.
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('TextButtonExample smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const example.TextButtonExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Enabled'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Disabled'));
    await tester.pumpAndSettle();

    // TextButton.icon buttons are _TextButtonWithIcons rather than TextButtons.
    // For the purposes of this test, just tapping in the right place is OK.

    await tester.tap(find.text('TextButton.icon #1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TextButton.icon #2'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'TextButton #3'));
    await tester.pumpAndSettle();


    await tester.tap(find.widgetWithText(TextButton, 'TextButton #4'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'TextButton #5'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'TextButton #6'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'TextButton #7'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'TextButton #8'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton).last); // Smiley image button
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(0)); // Dark Mode Switch
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(1)); // RTL Text Switch
    await tester.pumpAndSettle();
  });
}
