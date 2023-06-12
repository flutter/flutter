// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_snapshot_analysis.ascii_table;

import 'dart:math' as math;

/// A row in the [AsciiTable].
abstract class Row {
  String render(List<int> widths, List<AlignmentDirection> alignments);

  /// Compute the total width of the row given [widths] of individual
  /// columns.
  ///
  /// Note: there is a border on the left and right of each column
  /// plus whitespace around it.
  static int totalWidth(List<int> widths) =>
      widths.fold<int>(0, (sum, width) => sum + width + 3) + 1;
}

enum Separator {
  /// Line separator looks like this: `+-------+------+`
  line,

  /// Wave separator looks like this: `~~~~~~~~~~~~~~~~`.
  wave,
}

/// A separator row in the [AsciiTable].
class SeparatorRow extends Row {
  final Separator filler;
  SeparatorRow(this.filler);

  @override
  String render(List<int> widths, List<AlignmentDirection> alignments) {
    final sb = StringBuffer();
    switch (filler) {
      case Separator.line:
        sb.write('+');
        for (var i = 0; i < widths.length; i++) {
          sb.write('-' * (widths[i] + 2));
          sb.write('+');
        }
        break;

      case Separator.wave:
        sb.write('~' * Row.totalWidth(widths));
        break;
    }
    return sb.toString();
  }
}

/// A separator row in the [AsciiTable].
class TextSeparatorRow extends Row {
  final Text text;
  TextSeparatorRow(String text)
      : text = Text(value: text, direction: AlignmentDirection.center);

  @override
  String render(List<int> widths, List<AlignmentDirection> alignments) {
    return text.render(Row.totalWidth(widths));
  }
}

class NormalRow extends Row {
  final List<dynamic> columns;
  NormalRow(this.columns);

  @override
  String render(List<int> widths, List<AlignmentDirection> alignments) {
    final sb = StringBuffer();
    sb.write('|');
    for (var i = 0; i < widths.length; i++) {
      sb.write(' ');
      final text = columns[i] is Text
          ? columns[i]
          : Text(value: columns[i], direction: alignments[i]);
      sb.write(text.render(widths[i]));
      sb.write(' |');
    }
    return sb.toString();
  }
}

enum AlignmentDirection { left, right, center }

/// A chunk of text aligned in the given direction within a cell.
class Text {
  final String value;
  final AlignmentDirection direction;

  Text({required this.value, required this.direction});
  Text.left(String value)
      : this(value: value, direction: AlignmentDirection.left);
  Text.right(String value)
      : this(value: value, direction: AlignmentDirection.right);
  Text.center(String value)
      : this(value: value, direction: AlignmentDirection.center);

  String render(int width) {
    if (value.length > width) {
      // Narrowed column.
      return '${value.substring(0, width - 2)}..';
    }
    switch (direction) {
      case AlignmentDirection.left:
        return value.padRight(width);
      case AlignmentDirection.right:
        return value.padLeft(width);
      case AlignmentDirection.center:
        final diff = width - value.length;
        return ' ' * (diff ~/ 2) + value + (' ' * (diff - diff ~/ 2));
    }
  }

  int get length => value.length;
}

class AsciiTable {
  static const int unlimitedWidth = 0;

  final int maxWidth;

  final List<Row> rows = <Row>[];

  AsciiTable({List<dynamic>? header, this.maxWidth = unlimitedWidth}) {
    if (header != null) {
      addSeparator();
      addRow(header);
      addSeparator();
    }
  }

  void addRow(List<dynamic> columns) => rows.add(NormalRow(columns));

  void addSeparator([Separator filler = Separator.line]) =>
      rows.add(SeparatorRow(filler));

  void addTextSeparator(String text) => rows.add(TextSeparatorRow(text));

  void render() {
    // We assume that the first row gives us alignment directions that
    // subsequent rows would follow.
    List<AlignmentDirection> alignments = rows
        .whereType<NormalRow>()
        .first
        .columns
        .map((v) => v is Text ? v.direction : AlignmentDirection.left)
        .toList();
    List<int> widths =
        List<int>.filled(rows.whereType<NormalRow>().first.columns.length, 0);

    // Compute max width for each column in the table.
    for (var row in rows.whereType<NormalRow>()) {
      assert(row.columns.length == widths.length);
      for (var i = 0; i < widths.length; i++) {
        widths[i] = math.max(row.columns[i].length, widths[i]);
      }
    }

    if (maxWidth > 0) {
      for (var i = 0; i < widths.length; i++) {
        widths[i] = math.min(widths[i], maxWidth);
      }
    }

    for (var row in rows) {
      print(row.render(widths, alignments));
    }
  }
}
