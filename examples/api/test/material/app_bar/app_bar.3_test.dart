// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/app_bar/app_bar.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int listLengthToTest = 3;
  testWidgets('Check initial visibility of the crucial widgets', (WidgetTester tester) async {
    await tester.pumpWidget(const example.AppBarApp());

    expect(find.descendant(
          of: find.byType(DefaultTabController),
          matching: find.widgetWithText(AppBar, 'AppBar Sample'),
        ), findsOne);

    expect(find.descendant(
          of: find.byType(DefaultTabController),
          matching: find.widgetWithText(TabBar, 'Cloud'),
        ), findsOne);

    expect(find.descendant(
          of: find.byType(DefaultTabController),
          matching: find.widgetWithText(TabBar, 'Beach'),
        ), findsOne);

    expect(find.descendant(
          of: find.byType(DefaultTabController),
          matching: find.widgetWithText(TabBar, 'Sunny'),
        ), findsOne);

    // Only items with text "Beach $index" should be visible in the initial state.
    // Checking the visibility of several items on the list.
    for (int index = 0; index < listLengthToTest; index++){
      expect(
        find.descendant(
          of: find.byType(TabBarView),
          matching: find.widgetWithText(ListTile, 'Beach $index'),
        ), findsOne);
    }
    expect(find.widgetWithText(ListTile, 'Cloud 0'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Sunny 0'), findsNothing);
  });

  testWidgets('Click the Cloud and Sunny tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const example.AppBarApp());

    // Only items with text "Beach $index" should be visible in the initial state.
    expect(find.widgetWithText(ListTile, 'Beach 0'), findsOne);
    expect(find.widgetWithText(ListTile, 'Cloud 0'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Sunny 0'), findsNothing);

    // Click the "Cloud" tab.
    final Finder cloudTabFinder = find.descendant(
      of: find.byType(DefaultTabController),
      matching: find.widgetWithText(Tab, 'Cloud'));

    await tester.tap(cloudTabFinder);
    await tester.pumpAndSettle();

    for (int index = 0; index < listLengthToTest; index++){
      expect(
        find.descendant(
          of: find.byType(TabBarView),
          matching: find.widgetWithText(ListTile, 'Cloud $index'),
        ), findsOne);
    }
    expect(find.widgetWithText(ListTile, 'Beach 0'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Sunny 0'), findsNothing);

    // Click the "Sunny" tab.
    final Finder sunnyTabFinder = find.descendant(
      of: find.byType(DefaultTabController),
      matching: find.widgetWithText(Tab, 'Sunny'));

    await tester.tap(sunnyTabFinder);
    await tester.pumpAndSettle();

    for (int index = 0; index < listLengthToTest; index++){
      expect(
        find.descendant(
          of: find.byType(TabBarView),
          matching: find.widgetWithText(ListTile, 'Sunny $index'),
        ), findsOne);
    }
    expect(find.widgetWithText(ListTile, 'Beach 0'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Cloud 0'), findsNothing);
  });

  testWidgets(
    'AppBar elevates when nested scroll view is scrolled underneath the AppBar', (WidgetTester tester) async {
      Material getMaterial() => tester.widget<Material>(find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(Material),
      ));

      await tester.pumpWidget(
        const example.AppBarApp(),
      );

      // Starts with the base elevation.
      expect(getMaterial().elevation, 0.0);

      await tester.fling(find.text('Beach 3'), const Offset(0.0, -600.0), 2000.0);
      await tester.pumpAndSettle();

      // After scrolling it should be the scrolledUnderElevation.
      expect(getMaterial().elevation, 4.0);
  });
}
