// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/raw_tooltip/raw_tooltip.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RawTooltip text is visible when tapping button', (
    WidgetTester tester,
  ) async {
    const String rawTooltipText = 'I am a RawTooltip message';

    await tester.pumpWidget(const example.RawTooltipExampleApp());

    // The tooltip is not visible before tapping the button.
    expect(find.text(rawTooltipText), findsNothing);
    // Tap on the button and wait for the tooltip to appear.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(rawTooltipText), findsOneWidget);
    // Tap anywhere and wait for the tooltip to disappear.
    await tester.tap(find.byType(Scaffold));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(rawTooltipText), findsNothing);
  });

  testWidgets('RawTooltip text appears when hovering over the container', (
    WidgetTester tester,
  ) async {
    const String rawTooltipText = 'I am a RawTooltip message';

    await tester.pumpWidget(const example.RawTooltipExampleApp());

    expect(find.text(rawTooltipText), findsNothing);

    final Finder containerFinder = find.byType(Container);
    expect(containerFinder, findsWidgets);

    final Offset hoverTarget = tester.getCenter(containerFinder.first);

    final TestGesture pointer = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await pointer.addPointer();
    await tester.pump();

    await pointer.moveTo(hoverTarget);
    await tester.pumpAndSettle();

    expect(find.text(rawTooltipText), findsOneWidget);

    await pointer.moveTo(const Offset(0, 0));
    await tester.pumpAndSettle();
    expect(find.text(rawTooltipText), findsNothing);

    await pointer.moveTo(hoverTarget);
    await tester.pumpAndSettle();

    expect(find.text(rawTooltipText), findsOneWidget);

    addTearDown(pointer.removePointer);
  });
}
