// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/sliver_expansion_panel_list/sliver_expansion_panel_list.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverExpansionPanel can be expanded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SliverExpansionPanelListExampleApp());

    // Verify the first panel is collapsed.
    expect(
      tester.widget<ExpandIcon>(find.byType(ExpandIcon).first).isExpanded,
      false,
    );

    // Tap to expand the first panel.
    await tester.tap(find.byType(ExpandIcon).first);
    await tester.pumpAndSettle();

    // Verify that the first panel is expanded.
    expect(
      tester.widget<ExpandIcon>(find.byType(ExpandIcon).first).isExpanded,
      true,
    );
  });

  testWidgets('Tap to delete a SliverExpansionPanel', (
    WidgetTester tester,
  ) async {
    const int index = 3;

    await tester.pumpWidget(const example.SliverExpansionPanelListExampleApp());

    expect(find.widgetWithText(ListTile, 'Panel $index'), findsOneWidget);
    expect(
      tester.widget<ExpandIcon>(find.byType(ExpandIcon).at(index)).isExpanded,
      false,
    );

    // Tap to expand the panel at index 3.
    await tester.tap(find.byType(ExpandIcon).at(index));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ExpandIcon>(find.byType(ExpandIcon).at(index)).isExpanded,
      true,
    );

    // Tap to delete the panel at index 3.
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    // Verify that the panel at index 3 is deleted.
    expect(find.widgetWithText(ListTile, 'Panel $index'), findsNothing);
  });

  testWidgets('SliverExpansionPanelList is scrollable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SliverExpansionPanelListExampleApp());

    expect(find.byType(CustomScrollView), findsOneWidget);

    // Expand some the panels.
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.byType(ExpandIcon).at(i));
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    // Check panel 2 position.
    Offset tilePosition = tester.getBottomLeft(
      find.widgetWithText(ListTile, 'Panel 2'),
    );
    expect(tilePosition.dy, 448.0);

    // Scroll up.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify panel 2 position is updated after scrolling.
    tilePosition = tester.getBottomLeft(
      find.widgetWithText(ListTile, 'Panel 2'),
    );
    expect(tilePosition.dy, 168.0);
  });

  testWidgets('Add a SliverExpansionPanel', (WidgetTester tester) async {
    await tester.pumpWidget(const example.SliverExpansionPanelListExampleApp());

    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify a new panel is added
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Panel 10'),
      500,
    );
    expect(find.widgetWithText(ListTile, 'Panel 10'), findsOneWidget);
  });
}
