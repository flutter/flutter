// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/tabs/tab_bar.onScrollControllerCreated.Scrollbar.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TabBar onScrollControllerCreated expose controller and '
      'manipulate with Scrollbar to control scroll programmatically', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TabBarApp());
    // Wait for microtask to ensure the controller is exposed.
    await tester.pump();
    // Wait for Scrollbar to rebuild with the exposed controller.
    await tester.pump();

    // Verify the TabBar has 10 tabs and is scrollable.
    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs.length, 10);
    expect(tabBar.isScrollable, true);

    // Verify all tabs are present.
    for (int i = 0; i < 10; i++) {
      expect(find.text('Tab $i'), findsOneWidget);
    }

    // Verify Scrollbar is present.
    final Finder scrollbarFinder = find.byType(Scrollbar);
    expect(scrollbarFinder, findsOneWidget);

    // Verify Scrollbar has controller set.
    final Scrollbar scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
    expect(scrollbar.controller, isNotNull);

    // Get initial position of Tab 0 to verify it moves after scrolling.
    final Offset initialTab0Position = tester.getTopLeft(find.text('Tab 0'));

    // Use the exposed controller to programmatically scroll the TabBar.
    // This demonstrates the purpose of onScrollControllerCreated.
    scrollbar.controller!.jumpTo(100);
    await tester.pump();

    // Verify Tab 0 has moved to the left (scrolled right).
    final Offset afterScrollTab0Position = tester.getTopLeft(
      find.text('Tab 0'),
    );
    expect(afterScrollTab0Position.dx, lessThan(initialTab0Position.dx));
  });
}
