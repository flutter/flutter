// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/reorderable_list/reorderable_list_view.separated.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example separates each pair of items with a divider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ReorderableApp());

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.byType(Divider), findsAtLeast(2));

    // Separator 0 is the boundary between items 0 and 1, so it occupies the gap
    // between the two tiles rather than any space inside either of them.
    final Finder firstItem = find.ancestor(
      of: find.text('Item 0'),
      matching: find.byType(ListTile),
    );
    final Finder secondItem = find.ancestor(
      of: find.text('Item 1'),
      matching: find.byType(ListTile),
    );
    final double firstSeparatorCenter = tester
        .getCenter(find.byType(Divider).first)
        .dy;
    expect(
      firstSeparatorCenter,
      greaterThan(tester.getBottomLeft(firstItem).dy),
    );
    expect(firstSeparatorCenter, lessThan(tester.getTopLeft(secondItem).dy));
  });

  testWidgets('Example thickens the separators on even boundaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ReorderableApp());

    final List<Divider> separators = tester
        .widgetList<Divider>(find.byType(Divider))
        .toList();
    expect(separators.length, greaterThan(1));

    // The list starts unscrolled, so the separators onstage are boundaries 0, 1,
    // 2, ... in order, and each one is built from its own boundary index.
    for (int i = 0; i < separators.length; i += 1) {
      expect(
        separators[i].thickness,
        i.isEven ? 4.0 : 1.0,
        reason: 'separator at boundary $i',
      );
    }
  });
}
