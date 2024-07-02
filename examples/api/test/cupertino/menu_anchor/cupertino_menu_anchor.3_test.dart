// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/menu_anchor/cupertino_menu_anchor.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('CupertinoBackButtonMenu displays correct number of menu items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: Center(child: example.CupertinoHistoryMenu(depth: 3))),
    );

    final Finder menuItemsFinder = find.byType(CupertinoMenuItem);

    expect(menuItemsFinder, findsNWidgets(0));
    expect(find.text('View 2'), findsOneWidget);

    final Offset center = tester.getCenter(find.byType(example.CupertinoHistoryMenu));

    // Press down on the back button to open the menu.
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(menuItemsFinder, findsNWidgets(3));
    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsOneWidget);
    expect(find.text('View 2'), findsNWidgets(2));
  });

  testWidgets('CupertinoBackButtonMenu allows navigation to previous views',
      (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoHistoryMenuApp());

    final Finder pushButtonFinder = find.text('Push Next View');
    final Finder navBarFinder = find.byType(CupertinoNavigationBar);

    // Start on page 0, with no back button or menu.
    expect(pushButtonFinder, findsOneWidget);
    expect(navBarFinder, findsOneWidget);
    expect(find.text('View 0'), findsOneWidget); // Text in the navigation bar
    expect(find.byType(example.CupertinoHistoryMenu), findsNothing);

    // Push to page 1, which should have a back button and menu.
    await tester.tap(pushButtonFinder);
    await tester.pumpAndSettle();

    expect(pushButtonFinder, findsOneWidget);
    expect(find.text('View 0'), findsOneWidget); // Text in back button menu
    expect(find.text('View 1'), findsOneWidget);
    expect(find.byType(example.CupertinoHistoryMenu), findsOneWidget);

    await tester.tap(pushButtonFinder);
    await tester.pumpAndSettle();

    expect(pushButtonFinder, findsOneWidget);
    expect(find.text('View 1'), findsOneWidget);
    expect(find.text('View 2'), findsOneWidget);
    expect(find.byType(example.CupertinoHistoryMenu), findsOneWidget);

    // Test regular back button function. This should pop back to page 1.
    await tester.tap(find.text('View 1'));
    await tester.pump();

    // Make sure the menu closes when the back button is first tapped.
    expect(find.byType(CupertinoMenuItem), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(CupertinoMenuItem), findsNothing);
    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsOneWidget);
    expect(find.byType(example.CupertinoHistoryMenu), findsOneWidget);

    // Test regular back button function. This should pop back to page 0.
    await tester.tap(find.text('View 0'));
    await tester.pumpAndSettle();

    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsNothing);

    // Push to View 5
    await tester.tap(pushButtonFinder); // 1
    await tester.pumpAndSettle();
    await tester.tap(pushButtonFinder); // 2
    await tester.pumpAndSettle();
    await tester.tap(pushButtonFinder); // 3
    await tester.pumpAndSettle();
    await tester.tap(pushButtonFinder); // 4
    await tester.pumpAndSettle();
    await tester.tap(pushButtonFinder); // 5
    await tester.pumpAndSettle();

    // Only back button and title should be visible.
    expect(find.text('View 0'), findsNothing);
    expect(find.text('View 1'), findsNothing);
    expect(find.text('View 4'), findsOneWidget); // Back button
    expect(find.text('View 5'), findsOneWidget); // Title

    // Press down on the back button to open the menu.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(
        find.text('View 4'),
        warnIfMissed: true,
      ),
      pointer: 7,
    );

    addTearDown(gesture.removePointer);

    await tester.pumpAndSettle();

    // Menu should be open with 5 items.
    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsOneWidget);
    expect(find.text('View 2'), findsOneWidget);
    expect(find.text('View 3'), findsOneWidget);
    expect(find.text('View 4'), findsNWidgets(2));

    // Tap on third view
    await tester.tap(find.text('View 3'));
    await tester.pumpAndSettle();

    // Should have popped to 3 and closed the menu.
    expect(find.byType(CupertinoMenuItem), findsNothing);
    expect(find.text('View 2'), findsOneWidget);
    expect(find.text('View 3'), findsOneWidget);

    await gesture.up();
    await tester.pump();

    // Open the menu again.
    await gesture.down(tester.getCenter(find.text('View 2')));
    await tester.pumpAndSettle();

    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsOneWidget);
    expect(find.text('View 2'), findsNWidgets(2));

    // Tap on first view
    await tester.tap(find.text('View 0'));
    await tester.pumpAndSettle();

    // Should have popped to 0 and closed the menu. Since we're at the root,
    // there should be no back button.
    expect(find.text('View 0'), findsOneWidget);
    expect(find.text('View 1'), findsNothing);
    expect(find.byType(example.CupertinoHistoryMenu), findsNothing);
  });
}
