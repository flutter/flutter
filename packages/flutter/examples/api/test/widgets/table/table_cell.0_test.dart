// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/table/table_cell.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Table cell spans are arranged with placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TableCellSpanExampleApp());

    final Table table = tester.widget<Table>(find.byType(Table));

    // Check the defined columnWidths.
    expect(table.columnWidths, const <int, TableColumnWidth>{
      0: FixedColumnWidth(96),
      1: FlexColumnWidth(),
      2: FlexColumnWidth(),
    });

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

    // Spanning cells: region totals (rowSpan: 2), half-year sales
    // (colSpan: 2), 3,900 (rowSpan: 2), full year 2026 (colSpan: 2).
    expect(spanningCount, 4);
    // Placeholders: one in row 0, one in row 1, none in rows 2-3, two in row 4.
    expect(placeholderCount, 4);
  });

  testWidgets('Spans cover multiple columns and rows in layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TableCellSpanExampleApp());
    await tester.pumpAndSettle();

    // The spanning header starts in column 1 and covers two columns, so
    // its rendered width is wider than one column of the table.
    final Rect spanningHeader = tester.getRect(find.text('Half-year sales'));
    final Rect product = tester.getRect(find.text('Product'));

    expect(spanningHeader.width, greaterThan(product.width));

    // The row-spanning cell in the last column covers two rows, so it is
    // taller than the regular header cell in the first column.
    final Rect regionTotals = tester.getRect(find.text('Region totals'));
    final Rect h2 = tester.getRect(find.text('2026 overall'));
    expect(regionTotals.height, greaterThan(h2.height));
  });
}
