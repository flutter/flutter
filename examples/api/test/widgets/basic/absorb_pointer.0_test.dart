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

    // Verify initial state: Switch is ON by default (the Buttons are clickable)
    final Finder switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(find.text('No button pressed yet'), findsOneWidget);

    // Button 1 should be clickable when Switch is ON
    await tester.tap(find.text('Button 1'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(find.text('Button 1 Pressed'), findsOneWidget);

    // Button 2 should be clickable when Switch is ON
    await tester.tap(find.text('Button 2'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(find.text('Button 2 Pressed'), findsOneWidget);

    // Toggle the Switch to OFF (enable AbsorbPointer)
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Buttons are disabled'), findsOneWidget);

    // Buttons should NOT be clickable when Switch is OFF
    await tester.tap(find.text('Button 1'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Buttons are disabled'), findsOneWidget);

    await tester.tap(find.text('Button 2'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Buttons are disabled'), findsOneWidget);
  });
}
