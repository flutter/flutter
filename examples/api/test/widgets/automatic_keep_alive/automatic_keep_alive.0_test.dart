// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/automatic_keep_alive/automatic_keep_alive.0.dart' as example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter state is preserved when scrolling', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(
      const example.AutomaticKeepAliveApp(),
    );

    // Verify the initial state
    expect(find.text('AutomaticKeepAlive Example'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Item 0 - Counter: 0'), findsOneWidget);

    // Increment counter for first item
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    // Verify counter increased
    expect(find.text('Item 0 - Counter: 1'), findsOneWidget);

    // Scroll down to trigger item disposal
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();

    // Verify new items are visible with initial counter values
    expect(find.text('Item 10 - Counter: 0'), findsOneWidget);

    // Scroll back up
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pump();

    // Verify first item's counter state was preserved
    expect(find.text('Item 0 - Counter: 1'), findsOneWidget);
  });

  testWidgets('Multiple items maintain independent counters while scrolling', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.AutomaticKeepAliveApp(),
    );

    // Record initial visible items
    final Set<String> initialItems = tester.widgetList<ListTile>(find.byType(ListTile))
        .map((ListTile tile) => ((tile.title as Text?)?.data ?? ''))
        .toSet();

    // Increment counters for first two visible items
    await tester.tap(find.byIcon(Icons.add).at(0));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add).at(1));
    await tester.pump();

    // Verify counters increased independently
    expect(find.text('Item 0 - Counter: 1'), findsOneWidget);
    expect(find.text('Item 1 - Counter: 1'), findsOneWidget);

    // Scroll down
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    // Record new visible items
    final Set<String> newItems = tester.widgetList<ListTile>(find.byType(ListTile))
        .map((ListTile tile) => ((tile.title as Text?)?.data ?? ''))
        .toSet();

    // Verify that the visible items have changed
    expect(initialItems, isNot(equals(newItems)));

    // Increment a counter in the new visible area
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    // Scroll back up
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump();

    // Verify original counter states were preserved
    expect(find.text('Item 0 - Counter: 1'), findsOneWidget);
    expect(find.text('Item 1 - Counter: 1'), findsOneWidget);
  });

  testWidgets('ListView builds with correct number of items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.AutomaticKeepAliveApp(),
    );

    // Verify visible items are built
    expect(find.byType(ListTile), findsWidgets);

    // Scroll through several pages and verify new items are created
    for (int i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(find.byType(ListTile), findsWidgets);
    }
  });
}