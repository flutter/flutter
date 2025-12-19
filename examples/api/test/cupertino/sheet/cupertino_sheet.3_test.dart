// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/cupertino/sheet/cupertino_sheet.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tap on button displays cupertino sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CupertinoSheetApp());

    final Finder dialogTitle = find.text('Scrollable Sheet');
    expect(dialogTitle, findsNothing);

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    expect(dialogTitle, findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(dialogTitle, findsNothing);
  });

  testWidgets('Drag on nav bar triggers drag only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CupertinoSheetApp());

    final Finder dialogTitle = find.text('Scrollable Sheet');
    expect(dialogTitle, findsNothing);

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    expect(dialogTitle, findsOneWidget);

    final RenderBox box =
        tester.renderObject(find.text('Scrollable Sheet')) as RenderBox;
    final Offset navbarOffset = box.localToGlobal(Offset.zero);
    final double initialSheetHeight = navbarOffset.dy;

    final TestGesture gesture = await tester.startGesture(navbarOffset);
    await gesture.moveBy(const Offset(0, -50));
    await tester.pump();

    // Upwards drag triggers stretch, and not scroll.
    final double currentSheetHeight = box.localToGlobal(Offset.zero).dy;
    expect(currentSheetHeight, lessThan(initialSheetHeight));

    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();

    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();

    final double finalSheetHeight = box.localToGlobal(Offset.zero).dy;
    expect(finalSheetHeight, greaterThan(initialSheetHeight));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
