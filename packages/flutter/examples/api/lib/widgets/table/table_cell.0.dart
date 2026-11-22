// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [TableCell] with [TableCell.colSpan] and
/// [TableCell.rowSpan].

void main() => runApp(const TableCellSpanExampleApp());

class TableCellSpanExampleApp extends StatelessWidget {
  const TableCellSpanExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      // WidgetsApp does not install a [DefaultTextStyle], so without this the
      // labels below fall back to a style with no color and are invisible
      // against the white background.
      textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 14.0),
      builder: (BuildContext context, Widget? child) {
        return const TableCellSpanExample();
      },
    );
  }
}

class TableCellSpanExample extends StatelessWidget {
  const TableCellSpanExample({super.key});

  Widget cell(String text, {int colSpan = 1, int rowSpan = 1}) {
    return TableCell(
      colSpan: colSpan,
      rowSpan: rowSpan,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(BorderSide(color: Color(0xFF000000))),
        ),
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Every row must have exactly three children. A slot that a colSpan
    // or rowSpan covers holds a [TableCell.none] placeholder.
    return Center(
      child: Table(
        textDirection: TextDirection.ltr,
        border: TableBorder.all(color: const Color(0xFF000000)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          // Header row 1: '2026 Sales Performance' spans all three columns,
          // so the two slots it covers hold placeholders.
          TableRow(
            children: <Widget>[
              cell('2026 Sales Performance', colSpan: 3),
              TableCell.none,
              TableCell.none,
            ],
          ),
          // Header row 2: regular column headers.
          TableRow(
            children: <Widget>[
              cell('Quarter'),
              cell('Product'),
              cell('Revenue'),
            ],
          ),
          // 'Q1' spans two rows, so the slot it covers in the next row
          // holds a placeholder.
          TableRow(
            children: <Widget>[
              cell('Q1', rowSpan: 2),
              cell('Widgets'),
              cell(r'$18,600'),
            ],
          ),
          TableRow(
            children: <Widget>[
              TableCell.none,
              cell('Gidgets'),
              cell(r'$12,000'),
            ],
          ),
          // The total cell spans the first two columns, so the slot it
          // covers holds a placeholder.
          TableRow(
            children: <Widget>[
              cell('Total Q1 Revenue', colSpan: 2),
              TableCell.none,
              cell(r'$30,600'),
            ],
          ),
        ],
      ),
    );
  }
}
