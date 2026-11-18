// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/table/table_cell.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Table cell spans are arranged with placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TableCellSpanExampleApp());

    final Table table = tester.widget<Table>(find.byType(Table));

    // The table has five rows.
    expect(table.children.length, 5);

    // Every row still has one child per column; the slots covered by a
    // span hold a TableCell.none placeholder.
    for (final TableRow row in table.children) {
      expect(row.children.length, 3);
    }

    int placeholderCount = 0;
    int spanningCount = 0;
    for (final TableRow row in table.children) {
      for (final Widget child in row.children) {
        if (child is TableCell && child == TableCell.none) {
          placeholderCount += 1;
        }
        if (child is TableCell && (child.colSpan > 1 || child.rowSpan > 1)) {
          spanningCount += 1;
        }
      }
    }

    // Spanning cells: 2026 Sales Performance (colSpan: 3), Q1 (rowSpan: 2),
    // Total Q1 Revenue (colSpan: 2).
    expect(spanningCount, 3);
    // Placeholders: two in row 0, one in row 3, one in row 4.
    expect(placeholderCount, 4);
  });

  testWidgets('Spans cover multiple columns and rows in layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TableCellSpanExampleApp());
    await tester.pumpAndSettle();

    // The spanning header covers three columns, so its rendered width is
    // wider than a single column of the table.
    final Rect spanningHeader = tester.getRect(
      find.text('2026 Sales Performance'),
    );
    final Rect product = tester.getRect(find.text('Product'));

    expect(spanningHeader.width, greaterThan(product.width));

    // The row-spanning cell is middle-aligned within the two rows it
    // covers, so its center sits below the center of the header row above
    // the rows it covers.
    final Rect q1 = tester.getRect(find.text('Q1'));
    expect(q1.center.dy, greaterThan(product.center.dy));

    // And its center sits above the last row it covers (the total row).
    final Rect total = tester.getRect(find.text('Total Q1 Revenue'));
    expect(q1.center.dy, lessThan(total.center.dy));
  });
}
