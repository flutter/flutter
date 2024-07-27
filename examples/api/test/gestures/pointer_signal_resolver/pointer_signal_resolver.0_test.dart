// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/gestures/pointer_signal_resolver/pointer_signal_resolver.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late final Color initialOuterColor;
  late final Color initialInnerColor;

  setUpAll(() {
    initialOuterColor = const HSVColor.fromAHSV(0.2, 120.0, 1, 1).toColor();
    initialInnerColor = const HSVColor.fromAHSV(1, 60.0, 1, 1).toColor();
  });
  testWidgets('Widgets visibility', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

    // There is a ColorChanger on the Stack twice
    expect(
        find.descendant(
            of: find.byType(Stack),
            matching: find.byType(example.ColorChanger)),
        findsExactly(2));

    // There is one nested ColorChanger inside the other ColorChanger
    expect(
        find.descendant(
            of: find.byType(example.ColorChanger),
            matching: find.byType(example.ColorChanger)),
        findsOneWidget);

    // There is a Switch on the Stack
    expect(
        find.descendant(of: find.byType(Stack), matching: find.byType(Switch)),
        findsOneWidget);

    // Verify initial Color of first (outer) BoxDecoration
    final DecoratedBox outerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .first);

    expect((outerDecoratedBox.decoration as BoxDecoration).color,
        initialOuterColor);

    // Verify initial Color of last (inner) BoxDecoration
    final DecoratedBox innerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .last);

    expect((innerDecoratedBox.decoration as BoxDecoration).color,
        initialInnerColor);
  });

  testWidgets('Widget interactions - Switch is switching',
      (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

    // Verify the Switch is off
    final Switch switchWidget = tester.widget(find.byType(Switch));
    expect(switchWidget.value, isFalse);

    // Toggle the Switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify the Switch state has changed
    final Switch switchedWidget = tester.widget(find.byType(Switch));
    expect(switchedWidget.value, isTrue);
  });

  testWidgets('Mouse scroll changes colors when Switch is off',
      (WidgetTester tester) async {
    await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

    // Verify the Switch is off
    final Switch switchWidget = tester.widget(find.byType(Switch));
    expect(switchWidget.value, isFalse);

    // Simulate pointer signal event
    final Offset location =
        tester.getCenter(find.byType(example.ColorChanger).first);
    final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
    testPointer.hover(location);
    await tester.sendEventToBinding(PointerScrollEvent(
        position: location, scrollDelta: const Offset(0, 10)));

    // Wait for the color to change
    await tester.pump();

    // Both, inner and outer DecoratedBox, should change when the switch is off

    // Verify initial Color of last (inner) BoxDecoration
    final DecoratedBox innerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .last);

    expect(
        (innerDecoratedBox.decoration as BoxDecoration).color !=
            initialInnerColor,
        true);

    // Verify initial Color of first (outer) BoxDecoration
    final DecoratedBox outerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .first);

    expect(
        (outerDecoratedBox.decoration as BoxDecoration).color !=
            initialOuterColor,
        true);
  });

  testWidgets('Mouse scroll changes colors when Switch is on',
      (WidgetTester tester) async {
    await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

    // Verify the Switch is off
    final Switch switchWidget = tester.widget(find.byType(Switch));
    expect(switchWidget.value, isFalse);

    // Toggle the Switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify the Switch state has changed
    final Switch switchedWidget = tester.widget(find.byType(Switch));
    expect(switchedWidget.value, isTrue);

    // Simulate pointer signal event
    final Offset location =
        tester.getCenter(find.byType(example.ColorChanger).first);
    final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
    testPointer.hover(location);
    await tester.sendEventToBinding(PointerScrollEvent(
        position: location, scrollDelta: const Offset(0, 10)));

    // Wait for the color to change
    await tester.pump();

    // Verify initial Color of last (inner) BoxDecoration
    final DecoratedBox innerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .last);

    // The inner BoxDecoration should always change regardless of the switch status
    expect(
        (innerDecoratedBox.decoration as BoxDecoration).color !=
            initialInnerColor,
        true);

    // Verify initial Color of first (outer) BoxDecoration
    final DecoratedBox outerDecoratedBox = tester.widget(find
        .descendant(
          of: find.byType(example.ColorChanger),
          matching: find.byType(DecoratedBox),
        )
        .first);

    // Switch disables changes on outer BoxDecoration so the color should be initial
    expect((outerDecoratedBox.decoration as BoxDecoration).color,
        initialOuterColor);
  });
}
