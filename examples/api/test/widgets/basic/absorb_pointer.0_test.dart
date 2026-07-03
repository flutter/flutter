// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/basic/absorb_pointer.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AbsorbPointer absorbs taps over the overlapping region', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AbsorbPointerApp());

    final Finder absorbPointer = find.descendant(
      of: find.byType(example.AbsorbPointerExample),
      matching: find.byType(AbsorbPointer),
    );

    // Tapping the overlapping region does nothing: the AbsorbPointer claims
    // the hit, so neither its child button nor the button behind it in the
    // stack receives the tap.
    await tester.tapAt(tester.getCenter(absorbPointer));
    await tester.pump();
    expect(find.text('Taps received: 0'), findsNWidgets(2));

    // The part of the button behind that the AbsorbPointer does not cover
    // still receives taps.
    await tester.tapAt(
      tester.getCenter(absorbPointer) + const Offset(-75.0, 0.0),
    );
    await tester.pump();
    expect(find.text('Taps received: 1'), findsOneWidget);
  });

  testWidgets('IgnorePointer passes taps through to the widget behind', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AbsorbPointerApp());

    final Finder ignorePointer = find.descendant(
      of: find.byType(example.AbsorbPointerExample),
      matching: find.byType(IgnorePointer),
    );

    // Tapping the overlapping region taps the button behind: the
    // IgnorePointer is invisible to hit testing, so the pointer event goes
    // through to the next target in the stack.
    await tester.tapAt(tester.getCenter(ignorePointer));
    await tester.pump();
    expect(find.text('Taps received: 1'), findsOneWidget);
  });
}
