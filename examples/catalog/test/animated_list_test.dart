// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/animated_list.dart' as animated_list_sample;

void main() {
  testWidgets('animated_list sample app smoke test', (WidgetTester tester) async {
    animated_list_sample.main();
    await tester.pump();

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);

    final Finder insertButton = find.byTooltip('insert a new item');
    final Finder removeButton = find.byTooltip('remove the selected item');
    expect(insertButton, findsOneWidget);
    expect(removeButton, findsOneWidget);

    // Remove items 0, 1, 2.
    await tester.tap(find.text('Item 0'));
    await tester.tap(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 1'));
    await tester.tap(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 2'));
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    // Append items 3, 4, 5, 6.
    await tester.tap(insertButton);
    await tester.tap(insertButton);
    await tester.tap(insertButton);
    await tester.tap(insertButton);
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsNothing);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 3'), findsOneWidget);
    expect(find.text('Item 4'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 6'), findsOneWidget);

    // Insert items 7, 8 at item 3's position (at the top)
    await tester.tap(find.text('Item 3'));
    await tester.tap(insertButton);
    await tester.tap(insertButton);
    await tester.pumpAndSettle();

    expect(find.text('Item 7'), findsOneWidget);
    expect(find.text('Item 8'), findsOneWidget);

    // Scroll to the end.
    await tester.fling(find.text('Item 7'), const Offset(0.0, -200.0), 1000.0);
    await tester.pumpAndSettle();
    expect(find.text('Item 6'), findsOneWidget);
    expect(find.text('Item 8'), findsNothing);
  });
}
