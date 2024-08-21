// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scroll_view/custom_scroll_view.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('What should be visible in the initial state.', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CustomScrollViewExampleApp());

    expect(find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.add),
        ), findsOne);
    expect(find.byType(SliverList), findsOne);
    // Initial state should present only "Item: 0" on the SliverList.
    expect(find.widgetWithText(SliverList, 'Item: 0'), findsOne);
    expect(find.widgetWithText(SliverList, 'Item: -1'), findsNothing);
    expect(find.widgetWithText(SliverList, 'Item: 1'), findsNothing);
});

  testWidgets('IconButton click and scroll adds elements to the screen.', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CustomScrollViewExampleApp());

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // 'Item: -1' is invisible before scrolling
    expect(find.widgetWithText(SliverList, 'Item: -1'), findsNothing);
    expect(find.widgetWithText(SliverList, 'Item: 1'), findsOne);

    // Scroll the updated screen.
    final Offset location = tester.getCenter(find.byType(CustomScrollView));
    final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
    testPointer.hover(location);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: location,
        scrollDelta: const Offset(0, -1),
      ),
    );
    await tester.pump();

    // An additional SliverList appears.
    expect(find.byType(SliverList), findsExactly(2));

    // All items are visible.
    expect(find.widgetWithText(SliverList, 'Item: -1'), findsOne);
    expect(find.widgetWithText(SliverList, 'Item: 0'), findsOne);
    expect(find.widgetWithText(SliverList, 'Item: 1'), findsOne);
  });
}
