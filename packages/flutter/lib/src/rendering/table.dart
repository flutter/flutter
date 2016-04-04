// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// Parent data used by [RenderTable] for its children.
class TableCellParentData extends BoxParentData {
  TableCellVerticalAlignment verticalAlignment;

  /// The column that the child was in the last time it was laid out.
  int x;

  /// The row that the child was in the last time it was laid out.
  int y;

  @override
  String toString() => '${super.toString()}; $verticalAlignment';
}

/// Base class to describe how wide a column in a [RenderTable] should be.
abstract class TableColumnWidth {
  const TableColumnWidth();

  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  double flex(Iterable<RenderBox> cells) => null;

  @override
  String toString() => '$runtimeType';
}

/// Sizes the column according to the intrinsic dimensions of all the
/// cells in that column.
///
/// This is a very expensive way to size a column.
class IntrinsicColumnWidth extends TableColumnWidth { 
  const IntrinsicColumnWidth();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double result = 0.0;
    for (RenderBox cell in cells)
      result = math.max(result, cell.getMinIntrinsicWidth(const BoxConstraints()));
    return result;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double result = 0.0;
    for (RenderBox cell in cells)
      result = math.max(result, cell.getMaxIntrinsicWidth(const BoxConstraints()));
    return result;
  }
}

/// Sizes the column to a specific number of pixels.
///
/// This is the cheapest way to size a column.
class FixedColumnWidth extends TableColumnWidth {
  const FixedColumnWidth(this.value);
  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return value;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return value;
  }

  @override
  String toString() => '$runtimeType($value)';
}

/// Sizes the column to a fraction of the table's constraints' maxWidth.
///
/// This is a cheap way to size a column.
class FractionColumnWidth extends TableColumnWidth {
  const FractionColumnWidth(this.value);
  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite)
      return 0.0;
    return value * containerWidth;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite)
      return 0.0;
    return value * containerWidth;
  }

  @override
  String toString() => '$runtimeType($value)';
}

/// Sizes the column by taking a part of the remaining space once all
/// the other columns have been laid out.
///
/// For example, if two columns have FlexColumnWidth(), then half the
/// space will go to one and half the space will go to the other.
///
/// This is a cheap way to size a column.
class FlexColumnWidth extends TableColumnWidth {
  const FlexColumnWidth([this.value = 1.0]);
  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 0.0;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 0.0;
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    return value;
  }

  @override
  String toString() => '$runtimeType($value)';
}

/// Sizes the column such that it is the size that is the maximum of
/// two column width specifications.
///
/// For example, to have a column be 10% of the container width or
/// 100px, whichever is bigger, you could use:
///
///     const MaxColumnWidth(const FixedColumnWidth(100.0), FractionColumnWidth(0.1))
///
/// Both specifications are evaluated, so if either specification is
/// expensive, so is this.
class MaxColumnWidth extends TableColumnWidth {
  const MaxColumnWidth(this.a, this.b);
  final TableColumnWidth a;
  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth)
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth)
    );
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    double aFlex = a.flex(cells);
    if (aFlex == null)
      return b.flex(cells);
    return math.max(aFlex, b.flex(cells));
  }

  @override
  String toString() => '$runtimeType($a, $b)';
}

/// Sizes the column such that it is the size that is the minimum of
/// two column width specifications.
///
/// For example, to have a column be 10% of the container width but
/// never bigger than 100px, you could use:
///
///     const MinColumnWidth(const FixedColumnWidth(100.0), FractionColumnWidth(0.1))
///
/// Both specifications are evaluated, so if either specification is
/// expensive, so is this.
class MinColumnWidth extends TableColumnWidth {
  const MinColumnWidth(this.a, this.b); // at most as big as a or b
  final TableColumnWidth a;
  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth)
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth)
    );
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    double aFlex = a.flex(cells);
    if (aFlex == null)
      return b.flex(cells);
    return math.min(aFlex, b.flex(cells));
  }

  @override
  String toString() => '$runtimeType($a, $b)';
}

/// Border specification for [RenderTable].
///
/// This is like [Border], with the addition of two sides: the inner
/// horizontal borders and the inner vertical borders.
class TableBorder extends Border {
  const TableBorder({
    BorderSide top: BorderSide.none,
    BorderSide right: BorderSide.none,
    BorderSide bottom: BorderSide.none,
    BorderSide left: BorderSide.none,
    this.horizontalInside: BorderSide.none,
    this.verticalInside: BorderSide.none
  }) : super(
    top: top,
    right: right,
    bottom: bottom,
    left: left
  );

  factory TableBorder.all({
    Color color: const Color(0xFF000000),
    double width: 1.0
  }) {
    final BorderSide side = new BorderSide(color: color, width: width);
    return new TableBorder(top: side, right: side, bottom: side, left: side, horizontalInside: side, verticalInside: side);
  }

  factory TableBorder.symmetric({
    BorderSide inside: BorderSide.none,
    BorderSide outside: BorderSide.none
  }) {
    return new TableBorder(
      top: outside,
      right: outside,
      bottom: outside,
      left: outside,
      horizontalInside: inside,
      verticalInside: inside
    );
  }

  final BorderSide horizontalInside;

  final BorderSide verticalInside;

  @override
  TableBorder scale(double t) {
    return new TableBorder(
      top: top.copyWith(width: t * top.width),
      right: right.copyWith(width: t * right.width),
      bottom: bottom.copyWith(width: t * bottom.width),
      left: left.copyWith(width: t * left.width),
      horizontalInside: horizontalInside.copyWith(width: t * horizontalInside.width),
      verticalInside: verticalInside.copyWith(width: t * verticalInside.width)
    );
  }

  static TableBorder lerp(TableBorder a, TableBorder b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return new TableBorder(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
      horizontalInside: BorderSide.lerp(a.horizontalInside, b.horizontalInside, t),
      verticalInside: BorderSide.lerp(a.verticalInside, b.verticalInside, t)
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (super != other)
      return false;
    final TableBorder typedOther = other;
    return horizontalInside == typedOther.horizontalInside &&
           verticalInside == typedOther.verticalInside;
  }

  @override
  int get hashCode => hashValues(super.hashCode, horizontalInside, verticalInside);

  @override
  String toString() => 'TableBorder($top, $right, $bottom, $left, $horizontalInside, $verticalInside)';
}

/// Vertical alignment options for cells in [RenderTable] objects.
///
/// This is specified using [TableCellParentData] objects on the
/// [RenderObject.parentData] of the children of the [RenderTable].
enum TableCellVerticalAlignment {
  /// Cells with this alignment are placed with their top at the top of the row.
  top,

  /// Cells with this alignment are vertically centered in the row.
  middle,

  /// Cells with this alignment are placed with their bottom at the bottom of the row.
  bottom,

  /// Cells with this alignment are aligned such that they all share the same
  /// baseline. Cells with no baseline are top-aligned instead. The baseline
  /// used is specified by [RenderTable.baseline]. It is not valid to use the
  /// baseline value if [RenderTable.baseline] is not specified.
  baseline,

  /// Cells with this alignment are sized to be as tall as the row, then made to fit the row.
  /// If all the cells have this alignment, then the row will have zero height.
  fill
}

/// A table where the columns and rows are sized to fit the contents of the cells.
class RenderTable extends RenderBox {
  RenderTable({
    int columns,
    int rows,
    Map<int, TableColumnWidth> columnWidths,
    TableColumnWidth defaultColumnWidth: const FlexColumnWidth(1.0),
    TableBorder border,
    List<Decoration> rowDecorations,
    Decoration defaultRowDecoration,
    TableCellVerticalAlignment defaultVerticalAlignment: TableCellVerticalAlignment.top,
    TextBaseline textBaseline,
    List<List<RenderBox>> children
  }) {
    assert(columns == null || columns >= 0);
    assert(rows == null || rows >= 0);
    assert(rows == null || children == null);
    assert(defaultColumnWidth != null);
    _columns = columns ?? (children != null && children.length > 0 ? children.first.length : 0);
    _rows = rows ?? 0;
    _children = new List<RenderBox>()..length = _columns * _rows;
    _columnWidths = columnWidths ?? new HashMap<int, TableColumnWidth>();
    _defaultColumnWidth = defaultColumnWidth;
    _border = border;
    this.rowDecorations = rowDecorations; // must use setter to initialize box painters
    _defaultVerticalAlignment = defaultVerticalAlignment;
    _textBaseline = textBaseline;
    if (children != null) {
      for (List<RenderBox> row in children)
        addRow(row);
    }
  }

  // Children are stored in row-major order.
  // _children.length must be rows * columns
  List<RenderBox> _children = const <RenderBox>[];

  int get columns => _columns;
  int _columns;
  void set columns(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == columns)
      return;
    int oldColumns = columns;
    List<RenderBox> oldChildren = _children;
    _columns = value;
    _children = new List<RenderBox>()..length = columns * rows;
    int columnsToCopy = math.min(columns, oldColumns);
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columnsToCopy; x += 1)
        _children[x + y * columns] = oldChildren[x + y * oldColumns];
    }
    if (oldColumns > columns) {
      for (int y = 0; y < rows; y += 1) {
        for (int x = columns; x < oldColumns; x += 1) {
          int xy = x + y * oldColumns;
          if (oldChildren[xy] != null)
            dropChild(oldChildren[xy]);
        }
      }
    }
    markNeedsLayout();
  }

  int get rows => _rows;
  int _rows;
  void set rows(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == rows)
      return;
    if (_rows > value) {
      for (int xy = columns * value; xy < _children.length; xy += 1) {
        if (_children[xy] != null)
          dropChild(_children[xy]);
      }
    }
    _rows = value;
    _children.length = columns * rows;
    markNeedsLayout();
  }

  Map<int, TableColumnWidth> get columnWidths => new Map<int, TableColumnWidth>.unmodifiable(_columnWidths);
  Map<int, TableColumnWidth> _columnWidths;
  void set columnWidths(Map<int, TableColumnWidth> value) {
    value ??= new HashMap<int, TableColumnWidth>();
    if (_columnWidths == value)
      return;
    _columnWidths = value;
    markNeedsLayout();
  }

  void setColumnWidth(int column, TableColumnWidth value) {
    if (_columnWidths[column] == value)
      return;
    _columnWidths[column] = value;
    markNeedsLayout();
  }

  TableColumnWidth get defaultColumnWidth => _defaultColumnWidth;
  TableColumnWidth _defaultColumnWidth;
  void set defaultColumnWidth(TableColumnWidth value) {
    assert(value != null);
    if (defaultColumnWidth == value)
      return;
    _defaultColumnWidth = value;
    markNeedsLayout();
  }

  TableBorder get border => _border;
  TableBorder _border;
  void set border(TableBorder value) {
    if (border == value)
      return;
    _border = value;
    markNeedsPaint();
  }
 
  List<Decoration> get rowDecorations => new List<Decoration>.unmodifiable(_rowDecorations ?? const <Decoration>[]);
  List<Decoration> _rowDecorations;
  List<BoxPainter> _rowDecorationPainters;
  void set rowDecorations(List<Decoration> value) {
    if (_rowDecorations == value)
      return;
    _removeListenersIfNeeded();
    _rowDecorations = value;
    _rowDecorationPainters = _rowDecorations != null ? new List<BoxPainter>(_rowDecorations.length) : null;
    _addListenersIfNeeded();
  }

  void _removeListenersIfNeeded() {
    Set<Decoration> visitedDecorations = new Set<Decoration>();
    if (_rowDecorations != null && attached) {
      for (Decoration decoration in _rowDecorations) {
        if (decoration != null && decoration.needsListeners && visitedDecorations.add(decoration))
          decoration.removeChangeListener(markNeedsPaint);
      }
    }
  }

  void _addListenersIfNeeded() {
    Set<Decoration> visitedDecorations = new Set<Decoration>();
    if (_rowDecorations != null && attached) {
      for (Decoration decoration in _rowDecorations) {
        if (decoration != null && decoration.needsListeners && visitedDecorations.add(decoration))
          decoration.addChangeListener(markNeedsPaint);
      }
    }
  }

  TableCellVerticalAlignment get defaultVerticalAlignment => _defaultVerticalAlignment;
  TableCellVerticalAlignment _defaultVerticalAlignment;
  void set defaultVerticalAlignment (TableCellVerticalAlignment value) {
    if (_defaultVerticalAlignment == value)
      return;
    _defaultVerticalAlignment = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  void set textBaseline (TextBaseline value) {
    if (_textBaseline == value)
      return;
    _textBaseline = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableCellParentData)
      child.parentData = new TableCellParentData();
  }

  void setFlatChildren(int columns, List<RenderBox> cells) {
    if (cells == _children && columns == _columns)
      return;
    assert(columns >= 0);
    // consider the case of a newly empty table
    if (columns == 0 || cells.length == 0) {
      assert(cells == null || cells.length == 0);
      _columns = columns;
      if (_children.length == 0) {
        assert(_rows == 0);
        return;
      }
      for (RenderBox oldChild in _children) {
        if (oldChild != null)
          dropChild(oldChild);
      }
      _rows = 0;
      _children.clear();
      markNeedsLayout();
      return;
    }
    assert(cells != null);
    assert(cells.length % columns == 0);
    // remove cells that are moving away
    for (int y = 0; y < _rows; y += 1) {
      for (int x = 0; x < _columns; x += 1) {
        int xyOld = x + y * _columns;
        int xyNew = x + y * columns;
        if (_children[xyOld] != null && (x >= columns || xyNew >= cells.length || _children[xyOld] != cells[xyNew]))
          dropChild(_children[xyOld]);
      }
    }
    // adopt cells that are arriving
    int y = 0;
    while (y * columns < cells.length) {
      for (int x = 0; x < columns; x += 1) {
        int xyNew = x + y * columns;
        int xyOld = x + y * _columns;
        if (cells[xyNew] != null && (x >= _columns || y >= _rows || _children[xyOld] != cells[xyNew]))
          adoptChild(cells[xyNew]);
      }
      y += 1;
    }
    // update our internal values
    _columns = columns;
    _rows = cells.length ~/ columns;
    _children = cells.toList();
    assert(_children.length == rows * columns);
    markNeedsLayout();
  }

  void setChildren(List<List<RenderBox>> cells) {
    // TODO(ianh): Make this smarter, like setFlatChildren
    if (cells == null) {
      setFlatChildren(0, null);
      return;
    }
    for (RenderBox oldChild in _children) {
      if (oldChild != null)
        dropChild(oldChild);
    }
    _children.clear();
    _columns = cells.length > 0 ? cells.first.length : 0;
    _rows = 0;
    for (List<RenderBox> row in cells)
      addRow(row);
    assert(_children.length == rows * columns);
  }

  void addRow(List<RenderBox> cells) {
    assert(cells.length == columns);
    assert(_children.length == rows * columns);
    _rows += 1;
    _children.addAll(cells);
    for (RenderBox cell in cells) {
      if (cell != null)
        adoptChild(cell);
    }
    markNeedsLayout();
  }

  void setChild(int x, int y, RenderBox value) {
    assert(x != null);
    assert(y != null);
    assert(x >= 0 && x < columns && y >= 0 && y < rows);
    assert(_children.length == rows * columns);
    final int xy = x + y * columns;
    RenderBox oldChild = _children[xy];
    if (oldChild == value)
      return;
    if (oldChild != null)
      dropChild(oldChild);
    _children[xy] = value;
    if (value != null)
      adoptChild(value);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children)
      child?.attach(owner);
    _addListenersIfNeeded();
  }

  @override
  void detach() {
    _removeListenersIfNeeded();
    for (RenderBox child in _children)
      child?.detach();
    super.detach();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    assert(_children.length == rows * columns);
    for (RenderBox child in _children) {
      if (child != null)
        visitor(child);
    }
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    assert(_children.length == rows * columns);
    double totalMinWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      Iterable<RenderBox> columnCells = column(x);
      totalMinWidth += columnWidth.minIntrinsicWidth(columnCells, constraints.maxWidth);
    }
    return constraints.constrainWidth(totalMinWidth);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    assert(_children.length == rows * columns);
    double totalMaxWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      Iterable<RenderBox> columnCells = column(x);
      totalMaxWidth += columnWidth.maxIntrinsicWidth(columnCells, constraints.maxWidth);
    }
    return constraints.constrainWidth(totalMaxWidth);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    // winner of the 2016 world's most expensive intrinsic dimension function award
    // honorable mention, most likely to improve if taught about memoization award
    assert(constraints.debugAssertIsNormalized);
    assert(_children.length == rows * columns);
    final List<double> widths = computeColumnWidths(constraints);
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      double rowHeight = 0.0;
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        RenderBox child = _children[xy];
        if (child != null)
          rowHeight = math.max(rowHeight, child.getMaxIntrinsicHeight(new BoxConstraints.tightFor(width: widths[x])));
      }
      rowTop += rowHeight;
    }
    return constraints.constrainHeight(rowTop);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return getMinIntrinsicHeight(constraints);
  }

  double _baselineDistance;
  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    // returns the baseline of the first cell that has a baseline in the first row
    assert(!needsLayout);
    return _baselineDistance;
  }

  Iterable<RenderBox> column(int x) sync* {
    for (int y = 0; y < rows; y += 1) {
      final int xy = x + y * columns;
      RenderBox child = _children[xy];
      if (child != null)
        yield child;
    }
  }

  Iterable<RenderBox> row(int y) sync* {
    final int start = y * columns;
    final int end = (y + 1) * columns;
    for (int xy = start; xy < end; xy += 1) {
      RenderBox child = _children[xy];
      if (child != null)
        yield child;
    }
  }

  List<double> computeColumnWidths(BoxConstraints constraints) {
    assert(_children.length == rows * columns);
    final List<double> widths = new List<double>(columns);
    final List<double> flexes = new List<double>(columns);
    double totalMinWidth = 0.0;
    double totalMaxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
    double totalFlex = 0.0;
    for (int x = 0; x < columns; x += 1) {
      TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      Iterable<RenderBox> columnCells = column(x);
      double minIntrinsicWidth = columnWidth.minIntrinsicWidth(columnCells, constraints.maxWidth);
      widths[x] = minIntrinsicWidth;
      totalMinWidth += minIntrinsicWidth;
      if (!constraints.maxWidth.isFinite) {
        double maxIntrinsicWidth = columnWidth.maxIntrinsicWidth(columnCells, constraints.maxWidth);
        assert(minIntrinsicWidth <= maxIntrinsicWidth);
        totalMaxWidth += maxIntrinsicWidth;
      }
      double flex = columnWidth.flex(columnCells);
      if (flex != null) {
        assert(flex != 0.0);
        flexes[x] = flex;
        totalFlex += flex;
      }
    }
    assert(!widths.any((double value) => value == null));
    // table is going to be the biggest of:
    //  - the incoming minimum width
    //  - the sum of the cells' minimum widths
    //  - the incoming maximum width if it is finite, or else the table's ideal shrink-wrap width
    double tableWidth = math.max(constraints.minWidth, math.max(totalMinWidth, totalMaxWidth));
    double remainingWidth = tableWidth - totalMinWidth;
    if (remainingWidth > 0.0) {
      if (totalFlex > 0.0) {
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            widths[x] += math.max((flexes[x] / totalFlex) * remainingWidth - widths[x], 0.0);
          }
        }
      } else {
        for (int x = 0; x < columns; x += 1)
          widths[x] += remainingWidth / columns;
      }
    }
    return widths;
  }

  // cache the table geometry for painting purposes
  List<double> _rowTops = <double>[];
  List<double> _columnLefts;

  @override
  void performLayout() {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      // TODO(ianh): if columns is zero, this should be zero width
      // TODO(ianh): if columns is not zero, this should be based on the column width specifications
      size = constraints.constrain(const Size(double.INFINITY, 0.0));
      return;
    }
    final List<double> widths = computeColumnWidths(constraints);
    final List<double> positions = new List<double>(columns);
    _rowTops.clear();
    positions[0] = 0.0;
    for (int x = 1; x < columns; x += 1)
      positions[x] = positions[x-1] + widths[x-1];
    _columnLefts = positions;
    assert(!positions.any((double value) => value == null));
    _baselineDistance = null;
    // then, lay out each row
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      _rowTops.add(rowTop);
      double rowHeight = 0.0;
      bool haveBaseline = false;
      double beforeBaselineDistance = 0.0;
      double afterBaselineDistance = 0.0;
      List<double> baselines = new List<double>(columns);
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        RenderBox child = _children[xy];
        if (child != null) {
          TableCellParentData childParentData = child.parentData;
          assert(childParentData != null);
          childParentData.x = x;
          childParentData.y = y;
          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(textBaseline != null);
              child.layout(new BoxConstraints.tightFor(width: widths[x]), parentUsesSize: true);
              double childBaseline = child.getDistanceToBaseline(textBaseline, onlyReal: true);
              if (childBaseline != null) {
                beforeBaselineDistance = math.max(beforeBaselineDistance, childBaseline);
                afterBaselineDistance = math.max(afterBaselineDistance, child.size.height - childBaseline);
                baselines[x] = childBaseline;
                haveBaseline = true;
              } else {
                rowHeight = math.max(rowHeight, child.size.height);
                childParentData.offset = new Offset(positions[x], rowTop);
              }
              break;
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
              child.layout(new BoxConstraints.tightFor(width: widths[x]), parentUsesSize: true);
              rowHeight = math.max(rowHeight, child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }
      if (haveBaseline) {
        if (y == 0)
          _baselineDistance = beforeBaselineDistance;
        rowHeight = math.max(rowHeight, beforeBaselineDistance + afterBaselineDistance);
      }
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        RenderBox child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData;
          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              if (baselines[x] != null)
                childParentData.offset = new Offset(positions[x], rowTop + beforeBaselineDistance - baselines[x]);
              break;
            case TableCellVerticalAlignment.top:
              childParentData.offset = new Offset(positions[x], rowTop);
              break;
            case TableCellVerticalAlignment.middle:
              childParentData.offset = new Offset(positions[x], rowTop + (rowHeight - child.size.height) / 2.0);
              break;
            case TableCellVerticalAlignment.bottom:
              childParentData.offset = new Offset(positions[x], rowTop + rowHeight - child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              child.layout(new BoxConstraints.tightFor(width: widths[x], height: rowHeight));
              childParentData.offset = new Offset(positions[x], rowTop);
              break;
          }
        }
      }
      rowTop += rowHeight;
    }
    _rowTops.add(rowTop);
    size = constraints.constrain(new Size(positions.last + widths.last, rowTop));
    assert(_rowTops.length == rows + 1);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    assert(_children.length == rows * columns);
    for (int index = _children.length - 1; index >= 0; index -= 1) {
      RenderBox child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData;
        Point transformed = new Point(position.x - childParentData.offset.dx,
                                      position.y - childParentData.offset.dy);
        if (child.hitTest(result, position: transformed))
          return true;
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    Canvas canvas;
    assert(_children.length == rows * columns);
    if (rows * columns == 0)
      return;
    assert(_rowTops.length == rows + 1);
    canvas = context.canvas;
    if (_rowDecorations != null) {
      for (int y = 0; y < rows; y += 1) {
        if (_rowDecorations.length <= y)
          break;
        _rowDecorationPainters[y] ??= _rowDecorations[y].createBoxPainter();
        _rowDecorationPainters[y].paint(canvas, new Rect.fromLTRB(
          offset.dx,
          offset.dy + _rowTops[y],
          offset.dx + size.width,
          offset.dy + _rowTops[y+1]
        ));
      }
    }
    for (int index = 0; index < _children.length; index += 1) {
      RenderBox child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData; 
        context.paintChild(child, childParentData.offset + offset);
      }
    }
    canvas = context.canvas;
    Rect bounds = offset & size;
    if (border != null) {
      switch (border.verticalInside.style) {
        case BorderStyle.solid:
          Paint paint = new Paint()
            ..color = border.verticalInside.color
            ..strokeWidth = border.verticalInside.width
            ..style = PaintingStyle.stroke;
          Path path = new Path();
          for (int x = 1; x < columns; x += 1) {
            path.moveTo(bounds.left + _columnLefts[x], bounds.top);
            path.lineTo(bounds.left + _columnLefts[x], bounds.bottom);
          }
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none: break;
      }
      switch (border.horizontalInside.style) {
        case BorderStyle.solid:
          Paint paint = new Paint()
            ..color = border.horizontalInside.color
            ..strokeWidth = border.horizontalInside.width
            ..style = PaintingStyle.stroke;
          Path path = new Path();
          for (int y = 1; y < rows; y += 1) {
            path.moveTo(bounds.left, bounds.top + _rowTops[y]);
            path.lineTo(bounds.right, bounds.top + _rowTops[y]);
          }
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none: break;
      }
      border.paint(canvas, bounds);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (border != null)
      description.add('border: $border');
    if (_columnWidths.length > 0)
      description.add('specified column widths: $_columnWidths');
    description.add('default column width: $defaultColumnWidth');
    description.add('table size: $columns\u00D7$rows');
    if (!needsLayout) {
      description.add('column offsets: ${ _columnLefts ?? "unknown" }');
      description.add('row offsets: ${ _rowTops ?? "unknown" }');
    }
  }

  @override
  String debugDescribeChildren(String prefix) {
    StringBuffer result = new StringBuffer();
    result.writeln('$prefix \u2502');
    int lastIndex = _children.length - 1;
    if (lastIndex < 0) {
      result.writeln('$prefix \u2514\u2500table is empty');
    } else {
      for (int y = 0; y < rows; y += 1) {
        for (int x = 0; x < columns; x += 1) {
          final int xy = x + y * columns;
          RenderBox child = _children[xy];
          if (child != null) {
            if (xy < lastIndex) {
              result.write('${child.toStringDeep("$prefix \u251C\u2500child ($x, $y): ", "$prefix \u2502")}');
            } else {
              result.write('${child.toStringDeep("$prefix \u2514\u2500child ($x, $y): ", "$prefix  ")}');
            }
          } else {
            if (xy < lastIndex) {
              result.writeln('$prefix \u251C\u2500child ($x, $y) is null');
            } else {
              result.writeln('$prefix \u2514\u2500child ($x, $y) is null');
            }
          }
        }
      }
    }
    return result.toString();
  }
}
