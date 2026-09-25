// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/tabs/tab_bar.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Expected mask displays when switching tabs in the TabBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const example.TabBarApp());
    await tester.pump();

    final TabBar primaryTabBar = tester.widget<TabBar>(
      find.byType(TabBar).last,
    );
    expect(primaryTabBar.tabs.length, 20);

    // In initialization, the first tab is selected, the right mask should be displayed.
    String tabBarText = 'Tab 0';
    expect(find.text(tabBarText), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // Tap the last visible tab on screen.
    final Finder lastVisibleTabFinder = find.byElementPredicate((
      Element element,
    ) {
      if (element.widget is! Tab) {
        return false;
      }
      final RenderBox box = element.renderObject! as RenderBox;
      final Offset center = box.localToGlobal(box.size.center(Offset.zero));
      return center.dx >= 0 && center.dx <= tester.view.physicalSize.width;
    }).last;

    await tester.tap(lastVisibleTabFinder);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);

    // Jump to the end of the scrollable to verify the right mask is hidden.
    final ScrollableState scrollable = tester.state(
      find.byType(Scrollable).last,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    tabBarText = 'Tab 19';
    final Finder currentTab = find.text(tabBarText);
    expect(currentTab, findsOneWidget);

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
