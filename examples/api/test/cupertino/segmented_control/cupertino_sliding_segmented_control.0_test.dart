// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/segmented_control/cupertino_sliding_segmented_control.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can change a selected segmented control', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SegmentedControlApp());

    expect(find.text('Selected Segment: midnight'), findsOneWidget);
    await tester.tap(find.text('Cerulean'));
    await tester.pumpAndSettle();
    expect(find.text('Selected Segment: cerulean'), findsOneWidget);
  });

  testWidgets('Can toggle momentary mode', (WidgetTester tester) async {
    await tester.pumpWidget(const example.SegmentedControlApp());

    // Verify momentary mode is initially off.
    expect(find.text('Momentary mode: '), findsOneWidget);
    final CupertinoSwitch momentarySwitch = tester.widget(
      find.byType(CupertinoSwitch),
    );
    expect(momentarySwitch.value, isFalse);

    // Toggle momentary mode on.
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();

    // Verify switch is now on.
    final CupertinoSwitch updatedSwitch = tester.widget(
      find.byType(CupertinoSwitch),
    );
    expect(updatedSwitch.value, isTrue);

    // In momentary mode, tapping a segment should change the selection.
    expect(find.text('Selected Segment: midnight'), findsOneWidget);
    await tester.tap(find.text('Cerulean'));
    await tester.pumpAndSettle();
    expect(find.text('Selected Segment: cerulean'), findsOneWidget);
  });
}
