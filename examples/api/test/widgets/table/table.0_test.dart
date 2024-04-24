// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/table/table.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Table example has correct view on screen', (WidgetTester tester) async {
    await tester.pumpWidget(const example.TableExampleApp());

    // Check if appbar is visible with given title
    expect(find.widgetWithText(AppBar, 'Table Sample'), findsOneWidget);

    // Check if table is visible
    expect(find.byType(Table), findsOneWidget);
    final Table table = tester.widget<Table>(find.byType(Table));

    // Check the defined columnWidths
    expect(table.columnWidths, const <int, TableColumnWidth>{
      0: IntrinsicColumnWidth(),
      1: FlexColumnWidth(),
      2: FixedColumnWidth(64),
    });

    // There are only 2 TableRow as children of Table
    expect(table.children.length, 2);

    for (int i = 0; i < table.children.length; i++) {
      // Both table has 3 child widgets
      expect(table.children[i].children.length, 3);

      if (i == 0) {
        // `columnWidth` at index 0 is set to `IntrinsicColumnWidth()`.
        // Second `TableRow` contains widget with 128 width at index 0.
        // So both TableRow's first widget width should be 128
        final Size baseSize = tester.getSize(find.byWidget(table.children[i].children.first));
        expect(baseSize.width, equals(128));
      }
      if (i == 2) {
        // `columnWidth` at index 2 is set to `FixedColumnWidth(64)`.
        // So both TableRow's 3rd widget width should be 64
        final Size baseSize = tester.getSize(find.byWidget(table.children[i].children[2]));
        expect(baseSize.width, equals(64));
      }
    }
  });
}
