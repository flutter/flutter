// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TableCell] with [TableCell.colSpan] and
/// [TableCell.rowSpan].

void main() => runApp(const TableCellSpanExampleApp());

class TableCellSpanExampleApp extends StatelessWidget {
  const TableCellSpanExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('TableCell Spanning Sample')),
        body: const TableCellSpanExample(),
      ),
    );
  }
}

class TableCellSpanExample extends StatelessWidget {
  const TableCellSpanExample({super.key});

  @override
  Widget build(BuildContext context) {
    const ColorScheme colors = ColorScheme.light(
      primary: Color(0xFF1E5BB8),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      surfaceContainerHighest: Color(0xFFE7ECF5),
    );

    TextStyle header() {
      return TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w600);
    }

    TextStyle body({bool bold = false}) {
      return TextStyle(color: colors.onSurface, fontWeight: bold ? FontWeight.w600 : null);
    }

    Widget cell(
      String text, {
      Color? background,
      TextStyle? style,
      int colSpan = 1,
      int rowSpan = 1,
      Alignment alignment = Alignment.centerLeft,
    }) {
      return TableCell(
        colSpan: colSpan,
        rowSpan: rowSpan,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: background,
          alignment: alignment,
          child: Text(text, style: style),
        ),
      );
    }

    // Every row must have exactly three children. A slot that a colSpan
    // or rowSpan covers holds a [TableCell.none] placeholder.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Table(
          border: TableBorder.all(color: colors.primary),
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            // Header row 1: '2026 Sales Performance' spans all three columns,
            // so the two slots it covers hold placeholders.
            TableRow(
              decoration: BoxDecoration(color: colors.primary),
              children: <Widget>[
                cell(
                  '2026 Sales Performance',
                  background: colors.primary,
                  style: header(),
                  colSpan: 3,
                  alignment: Alignment.center,
                ),
                TableCell.none,
                TableCell.none,
              ],
            ),
            // Header row 2: regular column headers.
            TableRow(
              children: <Widget>[
                cell('Quarter', background: colors.primary, style: header()),
                cell('Product', background: colors.primary, style: header()),
                cell('Revenue', background: colors.primary, style: header()),
              ],
            ),
            // 'Q1' spans two rows, so the slot it covers in the next row
            // holds a placeholder.
            TableRow(
              children: <Widget>[
                cell(
                  'Q1',
                  background: colors.surfaceContainerHighest,
                  style: body(bold: true),
                  rowSpan: 2,
                  alignment: Alignment.center,
                ),
                cell('Widgets', background: colors.surface, style: body()),
                cell(r'$18,600', background: colors.surface, style: body(), alignment: Alignment.centerRight),
              ],
            ),
            TableRow(
              children: <Widget>[
                TableCell.none,
                cell('Gidgets', background: colors.surface, style: body()),
                cell(r'$12,000', background: colors.surface, style: body(), alignment: Alignment.centerRight),
              ],
            ),
            // The total cell spans the first two columns, so the slot it
            // covers holds a placeholder.
            TableRow(
              children: <Widget>[
                cell(
                  'Total Q1 Revenue',
                  background: colors.surfaceContainerHighest,
                  style: body(bold: true),
                  colSpan: 2,
                ),
                TableCell.none,
                cell(
                  r'$30,600',
                  background: colors.surfaceContainerHighest,
                  style: body(bold: true),
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
