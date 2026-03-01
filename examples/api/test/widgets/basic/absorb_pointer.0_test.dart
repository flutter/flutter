// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/basic/absorb_pointer.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AbsorbPointer prevents hit testing on its child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AbsorbPointerApp());

    // Verify initial state: Switch is ON by default (isAbsorbing = true)
    final Finder switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    // Buttons should be clickable when Switch is ON
    await tester.tap(find.text('Button 1'));
    await tester.pumpAndSettle(); // Wait for SnackBar animation

    expect(find.text('Button 1 Pressed'), findsOneWidget);

    // Dismiss SnackBar for next test
    ScaffoldMessenger.of(
      tester.element(find.text('Button 1')),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // Toggle the Switch to OFF (isAbsorbing = false)
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    // Buttons should NOT be clickable when Switch is OFF
    await tester.tap(find.text('Button 2'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify that NO SnackBar appeared
    expect(find.text('Button 2 Pressed'), findsNothing);
  });
}
