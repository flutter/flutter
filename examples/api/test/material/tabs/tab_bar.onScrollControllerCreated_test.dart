// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/tabs/tab_bar.onScrollControllerCreated.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'TabBar onScrollControllerCreated controls scroll programmatically',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.TabBarApp());

      // Verify the TabBar has 10 tabs.
      final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 10);
      expect(tabBar.isScrollable, true);

      // Verify all tabs are present.
      for (int i = 0; i < 10; i++) {
        expect(find.text('Tab $i'), findsOneWidget);
      }

      // Find the FloatingActionButton.
      final Finder fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Initially, the icon should be forward arrow (not on right side yet).
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Get initial position of Tab 0 to verify it moves after scrolling.
      final Offset initialTab0Position = tester.getTopLeft(find.text('Tab 0'));

      // Tap the FAB to scroll to the right (to maxScrollExtent).
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify Tab 0 has moved to the left (scrolled right).
      final Offset afterFirstTapTab0Position = tester.getTopLeft(
        find.text('Tab 0'),
      );
      expect(afterFirstTapTab0Position.dx, lessThan(initialTab0Position.dx));

      // Verify the icon changed to back arrow.
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap again to scroll back to the left (to minScrollExtent).
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify Tab 0 moved back to the right (scrolled left).
      final Offset afterSecondTapTab0Position = tester.getTopLeft(
        find.text('Tab 0'),
      );
      expect(
        afterSecondTapTab0Position.dx,
        greaterThan(afterFirstTapTab0Position.dx),
      );

      // Verify the icon changed back to forward arrow.
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    },
  );
}
