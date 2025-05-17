// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/reorderable_list/reorderable_list_view.reorderable_list_view_separated.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> longPressDrag(WidgetTester tester, Offset start, Offset end) async {
    final TestGesture drag = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await drag.moveTo(end);
    await tester.pump(kPressTimeout);
    await drag.up();
  }

  testWidgets('Reorder list item with separators', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ReorderableApp());

    const double appBarHeight = kToolbarHeight; // Default 56.0
    const double itemHeight = 56.0; // Card with ListTile
    const double separatorHeight = 16.0; // Divider

    // Initial position of 'Item 2'
    // Item 0: appBarHeight + itemHeight/2
    // Item 1: appBarHeight + itemHeight + separatorHeight + itemHeight/2
    // Item 2: appBarHeight + itemHeight + separatorHeight + itemHeight + separatorHeight + itemHeight/2
    const double initialItem2CenterY =
        appBarHeight +
        itemHeight +
        separatorHeight +
        itemHeight +
        separatorHeight +
        (itemHeight / 2);
    expect(tester.getCenter(find.text('Item 2')).dy, initialItem2CenterY);

    // Original position of 'Item 1'
    const double originalItem1CenterY =
        appBarHeight + itemHeight + separatorHeight + (itemHeight / 2);
    expect(tester.getCenter(find.text('Item 1')).dy, originalItem1CenterY);

    // Drag 'Item 2' to where 'Item 1' was.
    await longPressDrag(
      tester,
      tester.getCenter(find.text('Item 2')), // Start drag on Item 2
      tester.getCenter(find.text('Item 1')), // Move to original Item 1 position
    );
    await tester.pumpAndSettle();

    // After reorder, 'Item 2' should now be at the data index 1.
    // New list of items: [Item 0, Item 2, Item 1, ...]
    // New center of 'Item 2' will be at the original position of 'Item 1'.
    const double newItem2CenterY = appBarHeight + itemHeight + separatorHeight + (itemHeight / 2);
    expect(tester.getCenter(find.text('Item 2')).dy, newItem2CenterY);

    // Verify 'Item 1' has moved down.
    // Item 1 is now at data index 2.
    // Center: appBarHeight + itemHeight + separatorHeight + itemHeight + separatorHeight + itemHeight/2
    const double newItem1CenterY =
        appBarHeight +
        itemHeight +
        separatorHeight +
        itemHeight +
        separatorHeight +
        (itemHeight / 2);
    expect(tester.getCenter(find.text('Item 1')).dy, newItem1CenterY);
  });
}
