// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scroll_view/custom_scroll_view.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget tree is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CustomScrollViewExampleApp());

    expect(find.byType(Scaffold), findsOne);

    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(AppBar),
      ),
      findsOne,
      reason: 'Expected to have an Appbar in the Scaffold',
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
      findsOne,
      reason: 'Expected an IconButton in the AppBar',
    );

    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(CustomScrollView),
      ),
      findsOne,
      reason: 'Expected a CustomScrollView in the Scaffold',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverList),
      ),
      findsOne,
      reason: 'Expected one, initial (bottom) SliverList in the CustomScrollView',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: 0'),
      ),
      findsOne,
      reason: 'Expected element with text "Item: 0" in the CustomScrollView',
    );
  });

  testWidgets('IconButton click extends existing SliverList', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CustomScrollViewExampleApp());

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverList),
      ),
      findsOne,
      reason: 'Expected one, initial (bottom) SliverList in the CustomScrollView',
    );

    expect(
      find.descendant(
        of: find.byType(SliverList),
        matching: find.byType(Container),
      ),
      findsOne,
      reason: 'Expected one, initial (bottom) Container in the SliverList',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: 1'),
      ),
      findsNothing,
      reason: 'Expected no element with text "Item: 1" in the CustomScrollView',
    );

    // Tap the IconButton in the AppBar
    final Finder iconButtonFinder = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconButton),
    );
    await tester.tap(iconButtonFinder);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SliverList),
        matching: find.byType(Container),
      ),
      findsExactly(2),
      reason: 'Expected additional Container in the SliverList after the IconButton click',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: 1'),
      ),
      findsOne,
      reason: 'Expected element with text "Item: 1" in the CustomScrollView',
    );
  });
  testWidgets('IconButton click and mouse scroll reveals additional SliverList', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CustomScrollViewExampleApp());

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: -1'),
      ),
      findsNothing,
      reason: 'Expected no element with text "Item: -1" in the CustomScrollView',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: 1'),
      ),
      findsNothing,
      reason: 'Expected no element with text "Item: 1" in the CustomScrollView',
    );

    // First check before we start
    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverList),
      ),
      findsOne,
      reason: 'Expected to have only one, initial (bottom) SliverList in the CustomScrollView',
    );

    // Second check before we start.
    // Initially, mouse scroll event should do nothing.
    // It should not reveal additional (top) SliverList
    // because additional SliverList does not exists yet.
    final Offset location = tester.getCenter(find.byType(CustomScrollView));
    final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
    testPointer.hover(location);
    await tester.sendEventToBinding(
      PointerScrollEvent(position: location, scrollDelta: const Offset(0, -1)),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverList),
      ),
      findsOne,
      reason: 'Still expected to have only one, initial (bottom), SliverList in the CustomScrollView',
    );

    // Tap the IconButton in the AppBar
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pump();

    testPointer.hover(location);
    await tester.sendEventToBinding(
      PointerScrollEvent(position: location, scrollDelta: const Offset(0, -1)),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverList),
      ),
      findsExactly(2),
      reason: 'Expected to have two, top and bottom SliverList in the CustomScrollView',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: -1'),
      ),
      findsOne,
      reason: 'Expected element with text "Item: -1" in the CustomScrollView',
    );

    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Item: 1'),
      ),
      findsOne,
      reason: 'Expected element with text "Item: 1" in the CustomScrollView',
    );
  });
}
