// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui show ClipOp;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'box.dart';
import 'object.dart';
import 'table_border.dart';

/// Parent data used by [RenderTable] for its children.
class TableCellParentData extends BoxParentData {
  /// Where this cell should be placed vertically.
  ///
  /// When using [TableCellVerticalAlignment.baseline], the text baseline must be set as well.
  TableCellVerticalAlignment? verticalAlignment;

  /// The column that the child was in the last time it was laid out.
  int? x;

  /// The row that the child was in the last time it was laid out.
  int? y;

  /// The number of columns this cell should span.
  ///
  /// Must be either 0 (hidden placeholder cell) or >= 1 (normal or spanning cell).
  /// A hidden cell must have both [colSpan] and [rowSpan] set to 0.
  int get colSpan => _colSpan;
  int _colSpan = 1;
  set colSpan(int value) {
    assert(value >= 0, 'colSpan must be 0 (hidden) or >= 1, got $value.');
    _colSpan = value;
  }

  /// The number of rows this cell should span.
  ///
  /// Must be either 0 (hidden placeholder cell) or >= 1 (normal or spanning cell).
  /// A hidden cell must have both [colSpan] and [rowSpan] set to 0.
  int get rowSpan => _rowSpan;
  int _rowSpan = 1;
  set rowSpan(int value) {
    assert(value >= 0, 'rowSpan must be 0 (hidden) or >= 1, got $value.');
    _rowSpan = value;
  }

  /// Whether this cell is visible (not hidden by spanning cells).
  /// Hidden cells have both [rowSpan] and [colSpan] set to 0.
  bool get _isVisible => rowSpan != 0 && colSpan != 0;

  /// Whether this cell spans multiple rows or columns.
  bool get _hasSpan => colSpan > 1 || rowSpan > 1;

  @override
  String toString() =>
      '${super.toString()}; '
      '${verticalAlignment == null ? "default vertical alignment" : "$verticalAlignment"}'
      '${colSpan <= 1 ? '' : '; $colSpan cols'}'
      '${rowSpan <= 1 ? '' : '; $rowSpan rows'}'
      '${_isVisible ? '' : '; hidden'}';
}

/// Base class to describe how wide a column in a [RenderTable] should be.
///
/// To size a column to a specific number of pixels, use a [FixedColumnWidth].
/// This is the cheapest way to size a column.
///
/// Other algorithms that are relatively cheap include [FlexColumnWidth], which
/// distributes the space equally among the flexible columns,
/// [FractionColumnWidth], which sizes a column based on the size of the
/// table's container.
@immutable
abstract class TableColumnWidth {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TableColumnWidth();

  /// The smallest width that the column can have.
  ///
  /// The `cells` argument is an iterable that provides all the cells
  /// in the table for this column. Walking the cells is by definition
  /// O(N), so algorithms that do that should be considered expensive.
  ///
  /// The `containerWidth` argument is the `maxWidth` of the incoming
  /// constraints for the table, and might be infinite.
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  /// The ideal width that the column should have. This must be equal
  /// to or greater than the [minIntrinsicWidth]. The column might be
  /// bigger than this width, e.g. if the column is flexible or if the
  /// table's width ends up being forced to be bigger than the sum of
  /// all the maxIntrinsicWidth values.
  ///
  /// The `cells` argument is an iterable that provides all the cells
  /// in the table for this column. Walking the cells is by definition
  /// O(N), so algorithms that do that should be considered expensive.
  ///
  /// The `containerWidth` argument is the `maxWidth` of the incoming
  /// constraints for the table, and might be infinite.
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  /// The flex factor to apply to the cell if there is any room left
  /// over when laying out the table. The remaining space is
  /// distributed to any columns with flex in proportion to their flex
  /// value (higher values get more space).
  ///
  /// The `cells` argument is an iterable that provides all the cells
  /// in the table for this column. Walking the cells is by definition
  /// O(N), so algorithms that do that should be considered expensive.
  double? flex(Iterable<RenderBox> cells) => null;

  @override
  String toString() => objectRuntimeType(this, 'TableColumnWidth');
}

/// Sizes the column according to the intrinsic dimensions of all the
/// cells in that column.
///
/// This is a very expensive way to size a column.
///
/// A flex value can be provided. If specified (and non-null), the
/// column will participate in the distribution of remaining space
/// once all the non-flexible columns have been sized.
class IntrinsicColumnWidth extends TableColumnWidth {
  /// Creates a column width based on intrinsic sizing.
  ///
  /// This sizing algorithm is very expensive.
  ///
  /// The `flex` argument specifies the flex factor to apply to the column if
  /// there is any room left over when laying out the table. If `flex` is
  /// null (the default), the table will not distribute any extra space to the
  /// column.
  const IntrinsicColumnWidth({this._flex});

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var result = 0.0;
    for (final cell in cells) {
      result = math.max(result, cell.getMinIntrinsicWidth(double.infinity));
    }
    return result;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var result = 0.0;
    for (final cell in cells) {
      result = math.max(result, cell.getMaxIntrinsicWidth(double.infinity));
    }
    return result;
  }

  final double? _flex;

  @override
  double? flex(Iterable<RenderBox> cells) => _flex;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'IntrinsicColumnWidth')}(flex: ${_flex?.toStringAsFixed(1)})';
}

/// Sizes the column to a specific number of pixels.
///
/// This is the cheapest way to size a column.
class FixedColumnWidth extends TableColumnWidth {
  /// Creates a column width based on a fixed number of logical pixels.
  const FixedColumnWidth(this.value);

  /// The width the column should occupy in logical pixels.
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
  String toString() =>
      '${objectRuntimeType(this, 'FixedColumnWidth')}(${debugFormatDouble(value)})';
}

/// Sizes the column to a fraction of the table's constraints' maxWidth.
///
/// This is a cheap way to size a column.
class FractionColumnWidth extends TableColumnWidth {
  /// Creates a column width based on a fraction of the table's constraints'
  /// maxWidth.
  const FractionColumnWidth(this.value);

  /// The fraction of the table's constraints' maxWidth that this column should
  /// occupy.
  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite) {
      return 0.0;
    }
    return value * containerWidth;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite) {
      return 0.0;
    }
    return value * containerWidth;
  }

  @override
  String toString() => '${objectRuntimeType(this, 'FractionColumnWidth')}($value)';
}

/// Sizes the column by taking a part of the remaining space once all
/// the other columns have been laid out.
///
/// For example, if two columns have a [FlexColumnWidth], then half the
/// space will go to one and half the space will go to the other.
///
/// This is a cheap way to size a column.
class FlexColumnWidth extends TableColumnWidth {
  /// Creates a column width based on a fraction of the remaining space once all
  /// the other columns have been laid out.
  const FlexColumnWidth([this.value = 1.0]);

  /// The fraction of the remaining space once all the other columns have
  /// been laid out that this column should occupy.
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
  String toString() => '${objectRuntimeType(this, 'FlexColumnWidth')}(${debugFormatDouble(value)})';
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
  /// Creates a column width that is the maximum of two other column widths.
  const MaxColumnWidth(this.a, this.b);

  /// A lower bound for the width of this column.
  final TableColumnWidth a;

  /// Another lower bound for the width of this column.
  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double? flex(Iterable<RenderBox> cells) {
    final double? aFlex = a.flex(cells);
    final double? bFlex = b.flex(cells);
    if (aFlex == null) {
      return bFlex;
    } else if (bFlex == null) {
      return aFlex;
    }
    return math.max(aFlex, bFlex);
  }

  @override
  String toString() => '${objectRuntimeType(this, 'MaxColumnWidth')}($a, $b)';
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
  /// Creates a column width that is the minimum of two other column widths.
  const MinColumnWidth(this.a, this.b);

  /// An upper bound for the width of this column.
  final TableColumnWidth a;

  /// Another upper bound for the width of this column.
  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double? flex(Iterable<RenderBox> cells) {
    final double? aFlex = a.flex(cells);
    final double? bFlex = b.flex(cells);
    if (aFlex == null) {
      return bFlex;
    } else if (bFlex == null) {
      return aFlex;
    }
    return math.min(aFlex, bFlex);
  }

  @override
  String toString() => '${objectRuntimeType(this, 'MinColumnWidth')}($a, $b)';
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
  /// used is specified by [RenderTable.textBaseline]. It is not valid to use
  /// the baseline value if [RenderTable.textBaseline] is not specified.
  ///
  /// This vertical alignment is relatively expensive because it causes the table
  /// to compute the baseline for each cell in the row.
  baseline,

  /// Cells with this alignment are sized to be as tall as the row, then made to fit the row.
  /// If all the cells have this alignment, then the row will have zero height.
  fill,

  /// Cells with this alignment are sized to be the same height as the tallest cell in the row.
  intrinsicHeight,
}

/// A table where the columns and rows are sized to fit the contents of the cells.
class RenderTable extends RenderBox {
  /// Creates a table render object.
  ///
  ///  * `columns` must either be null or non-negative. If `columns` is null,
  ///    the number of columns will be inferred from length of the first sublist
  ///    of `children`.
  ///  * `rows` must either be null or non-negative. If `rows` is null, the
  ///    number of rows will be inferred from the `children`. If `rows` is not
  ///    null, then `children` must be null.
  ///  * `children` must either be null or contain lists of all the same length.
  ///    if `children` is not null, then `rows` must be null.
  ///  * [columnWidths] may be null, in which case it defaults to an empty map.
  RenderTable({
    int? columns,
    int? rows,
    Map<int, TableColumnWidth>? columnWidths,
    this._defaultColumnWidth = const FlexColumnWidth(),
    required this._textDirection,
    this._border,
    List<Decoration?>? rowDecorations,
    this._configuration = ImageConfiguration.empty,
    this._defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this._textBaseline,
    List<List<RenderBox>>? children,
  }) : assert(columns == null || columns >= 0),
       assert(rows == null || rows >= 0),
       assert(rows == null || children == null),
       _columns = columns ?? (children != null && children.isNotEmpty ? children.first.length : 0),
       _rows = rows ?? 0,
       _columnWidths = columnWidths ?? HashMap<int, TableColumnWidth>() {
    _children = <RenderBox?>[]..length = _columns * _rows;
    this.rowDecorations = rowDecorations; // must use setter to initialize box painters array
    children?.forEach(addRow);
  }

  // Children are stored in row-major order.
  // _children.length must be rows * columns
  List<RenderBox?> _children = const <RenderBox?>[];

  /// The number of vertical alignment lines in this table.
  ///
  /// Changing the number of columns will remove any children that no longer fit
  /// in the table.
  ///
  /// Changing the number of columns is an expensive operation because the table
  /// needs to rearrange its internal representation.
  int get columns => _columns;
  int _columns;
  set columns(int value) {
    assert(value >= 0);
    if (value == columns) {
      return;
    }
    final int oldColumns = columns;
    final List<RenderBox?> oldChildren = _children;
    _columns = value;
    _children = List<RenderBox?>.filled(columns * rows, null);
    final int columnsToCopy = math.min(columns, oldColumns);
    for (var y = 0; y < rows; y += 1) {
      for (var x = 0; x < columnsToCopy; x += 1) {
        _children[x + y * columns] = oldChildren[x + y * oldColumns];
      }
    }
    if (oldColumns > columns) {
      for (var y = 0; y < rows; y += 1) {
        for (int x = columns; x < oldColumns; x += 1) {
          final int xy = x + y * oldColumns;
          if (oldChildren[xy] != null) {
            dropChild(oldChildren[xy]!);
          }
        }
      }
    }
    markNeedsLayout();
  }

  /// The number of horizontal alignment lines in this table.
  ///
  /// Changing the number of rows will remove any children that no longer fit
  /// in the table.
  int get rows => _rows;
  int _rows;
  set rows(int value) {
    assert(value >= 0);
    if (value == rows) {
      return;
    }
    if (_rows > value) {
      for (int xy = columns * value; xy < _children.length; xy += 1) {
        if (_children[xy] != null) {
          dropChild(_children[xy]!);
        }
      }
    }
    _rows = value;
    _children.length = columns * rows;
    markNeedsLayout();
  }

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// This property can never return null. If it is set to null, and the existing
  /// map is not empty, then the value is replaced by an empty map. (If it is set
  /// to null while the current value is an empty map, the value is not changed.)
  Map<int, TableColumnWidth>? get columnWidths =>
      Map<int, TableColumnWidth>.unmodifiable(_columnWidths);
  Map<int, TableColumnWidth> _columnWidths;
  set columnWidths(Map<int, TableColumnWidth>? value) {
    if (_columnWidths == value) {
      return;
    }
    if (_columnWidths.isEmpty && value == null) {
      return;
    }
    _columnWidths = value ?? HashMap<int, TableColumnWidth>();
    markNeedsLayout();
  }

  /// Determines how the width of column with the given index is determined.
  void setColumnWidth(int column, TableColumnWidth value) {
    if (_columnWidths[column] == value) {
      return;
    }
    _columnWidths[column] = value;
    markNeedsLayout();
  }

  /// How to determine with widths of columns that don't have an explicit sizing algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null.
  TableColumnWidth get defaultColumnWidth => _defaultColumnWidth;
  TableColumnWidth _defaultColumnWidth;
  set defaultColumnWidth(TableColumnWidth value) {
    if (defaultColumnWidth == value) {
      return;
    }
    _defaultColumnWidth = value;
    markNeedsLayout();
  }

  /// The direction in which the columns are ordered.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  /// The style to use when painting the boundary and interior divisions of the table.
  ///
  /// {@template flutter.rendering.RenderTable.border.spans}
  /// The inner borders are not painted inside cells that span several columns
  /// or rows. The border is painted as if the table had no spans, with the
  /// inside of every spanning cell clipped out. The clip stops where the
  /// borders around the cell begin: half the width of [TableBorder.verticalInside]
  /// or [TableBorder.horizontalInside] away from a neighboring cell, and the
  /// full width of the outer side at the edge of the table.
  ///
  /// A subclass of [TableBorder] that overrides [TableBorder.paint] is clipped
  /// the same way. Anything it paints further inside a spanning cell, such as
  /// a border that is wider or more blurred than its [BorderSide.width], is cut
  /// off at that edge.
  /// {@endtemplate}
  TableBorder? get border => _border;
  TableBorder? _border;
  set border(TableBorder? value) {
    if (border == value) {
      return;
    }
    _border = value;
    markNeedsPaint();
  }

  /// The decorations to use for each row of the table.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  List<Decoration?> get rowDecorations =>
      List<Decoration?>.unmodifiable(_rowDecorations ?? const <Decoration>[]);
  // _rowDecorations and _rowDecorationPainters need to be in sync. They have to
  // either both be null or have same length.
  List<Decoration?>? _rowDecorations;
  List<BoxPainter?>? _rowDecorationPainters;
  set rowDecorations(List<Decoration?>? value) {
    if (_rowDecorations == value) {
      return;
    }
    _rowDecorations = value;
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) {
        painter?.dispose();
      }
    }
    _rowDecorationPainters = _rowDecorations != null
        ? List<BoxPainter?>.filled(_rowDecorations!.length, null)
        : null;
  }

  /// The settings to pass to the [rowDecorations] when painting, so that they
  /// can resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == _configuration) {
      return;
    }
    _configuration = value;
    markNeedsPaint();
  }

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  TableCellVerticalAlignment get defaultVerticalAlignment => _defaultVerticalAlignment;
  TableCellVerticalAlignment _defaultVerticalAlignment;
  set defaultVerticalAlignment(TableCellVerticalAlignment value) {
    if (_defaultVerticalAlignment == value) {
      return;
    }
    _defaultVerticalAlignment = value;
    markNeedsLayout();
  }

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;
  set textBaseline(TextBaseline? value) {
    if (_textBaseline == value) {
      return;
    }
    _textBaseline = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableCellParentData) {
      child.parentData = TableCellParentData();
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.role = SemanticsRole.table;
    config.isSemanticBoundary = true;
    config.explicitChildNodes = true;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final RenderBox? child in _children) {
      if (child != null && _isLaidOutCell(child)) {
        visitor(child);
      }
    }
  }

  // Whether `child` took part in the last layout, and so is painted, hit tested
  // and included in the semantics tree.
  //
  // Layout skips placeholders (TableCell.none) and, in release builds where the
  // placeholder assertion does not run, any other widget in a slot that a span
  // covers. hasSize alone does not exclude them, because a cell that ends up in
  // such a slot keeps the size and offset from its last layout: its element,
  // and with it its render object, is reused.
  bool _isLaidOutCell(RenderBox child) {
    final childParentData = child.parentData! as TableCellParentData;
    return child.hasSize &&
        childParentData._isVisible &&
        !(_cachedSpannedCells?.isCovered(childParentData.x!, childParentData.y!) ?? false);
  }

  // The offset that assembleSemanticsNode last added to the transform of each
  // child, to move it into its row or cell wrapper, and the transform that the
  // child was left with.
  final Map<int, ({Matrix4? transform, Offset shift})> _idToSemanticsShift =
      <int, ({Matrix4? transform, Offset shift})>{};
  final Map<int, SemanticsNode> _cachedRows = <int, SemanticsNode>{};
  final Map<_Index, SemanticsNode> _cachedCells = <_Index, SemanticsNode>{};

  @override
  void clearSemantics() {
    super.clearSemantics();
    _idToSemanticsShift.clear();
    _cachedRows.clear();
    _cachedCells.clear();
  }

  /// Provides custom semantics for tables by generating nodes for rows and maybe cells.
  ///
  /// Table rows are not RenderObjects, so their semantics nodes must be created separately.
  /// And if a cell has multiple semantics node or has a different semantic role, we create
  /// a new semantics node to wrap it.
  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final rows = <SemanticsNode>[];

    final rawCells = List<List<List<SemanticsNode>>>.generate(
      _rows,
      (int rowIndex) =>
          List<List<SemanticsNode>>.generate(_columns, (int columnIndex) => <SemanticsNode>[]),
    );

    // The transform of `child` relative to the table.
    //
    // The children are moved into their rows and cell wrappers below by adding
    // an offset to their transforms. A child whose semantics have not been
    // rebuilt since then still has that transform, so the offset is taken off
    // again.
    Matrix4? tableTransform(SemanticsNode child) {
      final ({Matrix4? transform, Offset shift})? previous = _idToSemanticsShift[child.id];
      if (previous == null || !identical(child.transform, previous.transform)) {
        return child.transform;
      }
      return Matrix4.translationValues(-previous.shift.dx, -previous.shift.dy, 0)
        ..multiply(child.transform ?? Matrix4.identity());
    }

    Rect rectInTable(SemanticsNode child) {
      final Matrix4? transform = tableTransform(child);
      return transform == null ? child.rect : MatrixUtils.transformRect(transform, child.rect);
    }

    int findRowIndex(double top) {
      // Iterate over _rows rather than _rowTops.length because _rowTops has one
      // additional entry that marks the bottom boundary of the last row.
      for (int i = _rows - 1; i >= 0; i--) {
        if (_rowTops[i] <= top) {
          return i;
        }
      }
      return -1;
    }

    int findColumnIndex(double left) {
      if (_columnLefts == null) {
        return -1;
      }
      for (int i = _columnLefts!.length - 1; i >= 0; i--) {
        if (_columnLefts!.elementAt(i) <= left) {
          return i;
        }
      }
      return -1;
    }

    final List<_Span> spans = _cachedSpannedCells?.spans ?? const <_Span>[];

    // Every child is looked up in the table by where it is, so a child that
    // moved to another cell is found there.
    for (final child in children) {
      final Rect rect = rectInTable(child);
      int y = findRowIndex(rect.top);
      int x = findColumnIndex(rect.left);
      // A child of a spanning cell can start below or to the right of where
      // the cell starts, for example when the cell is aligned to the bottom.
      // It still belongs to the row and column that the cell starts in.
      for (final span in spans) {
        final int leftColumn = _leftColumnOf(span);
        if (y >= span.y &&
            y < span.y + span.rowSpan &&
            x >= leftColumn &&
            x < leftColumn + span.colSpan) {
          y = span.y;
          x = leftColumn;
          break;
        }
      }
      if (y != -1 && x != -1) {
        rawCells[y][x].add(child);
      }
    }

    // Forget the children that are not part of the table anymore.
    final childIds = <int>{for (final child in children) child.id};
    _idToSemanticsShift.removeWhere(
      (int id, ({Matrix4? transform, Offset shift}) _) => !childIds.contains(id),
    );

    for (var y = 0; y < _rows; y++) {
      Rect rowBox = getRowBox(y);
      // A row has no height of its own when all of its cells that are not
      // empty span several rows, because they add their height to the last row
      // that they cover. The row still holds these cells, so it reaches down
      // to the bottom of the tallest of them.
      if (rowBox.height == 0) {
        for (final span in spans) {
          if (span.y == y) {
            rowBox = Rect.fromLTRB(
              rowBox.left,
              rowBox.top,
              rowBox.right,
              math.max(rowBox.bottom, _rowTops[span.y + span.rowSpan]),
            );
          }
        }
      }
      // Skip row if it's empty
      if (rowBox.height == 0) {
        continue;
      }

      final SemanticsNode newRow =
          _cachedRows[y] ??
          (_cachedRows[y] = SemanticsNode(
            showOnScreen: () {
              showOnScreen(descendant: this, rect: rowBox);
            },
          ));

      // The list of cells of this Row.
      final cells = <SemanticsNode>[];

      for (var x = 0; x < columns; x++) {
        final List<SemanticsNode> rawChildrens = rawCells[y][x];
        if (rawChildrens.isEmpty) {
          continue;
        }

        // If the cell has multiple children or the only child is not a cell or columnHeader,
        // create a new semantic node with role cell to wrap it.
        // This can happen when the cell has a different semantic role, or the cell doesn't have a semantic
        // role because user is not using the `TableCell` widget.
        final bool addCellWrapper =
            rawChildrens.length > 1 ||
            (rawChildrens.single.role != SemanticsRole.cell &&
                rawChildrens.single.role != SemanticsRole.columnHeader);

        late final SemanticsNode cell;
        if (!addCellWrapper) {
          cell = rawChildrens.single;
        } else {
          final index = _Index(y, x);
          cell = _cachedCells.putIfAbsent(index, () => SemanticsNode())
            ..updateWith(
              config: SemanticsConfiguration()..role = SemanticsRole.cell,
              childrenInInversePaintOrder: rawChildrens,
            );
        }

        final double cellWidth = x == _columns - 1
            ? rowBox.width - _columnLefts!.elementAt(x)
            : _columnLefts!.elementAt(x + 1) - _columnLefts!.elementAt(x);

        // Skip cell if it's invisible
        if (cellWidth <= 0.0) {
          continue;
        }
        // Add wrapper transform
        if (addCellWrapper) {
          // TODO(hm21): These wrapper bounds use a single column width and a
          // single row height, so a cell spanning multiple columns or rows is
          // clipped to one cell in the semantics tree. Make them span-aware,
          // see https://github.com/flutter/flutter/issues/192849. The RTL
          // handling in findColumnIndex is tracked separately in
          // https://github.com/flutter/flutter/issues/192848.
          cell
            ..transform = Matrix4.translationValues(_columnLefts!.elementAt(x), 0, 0)
            ..rect = Rect.fromLTWH(0, 0, cellWidth, rowBox.height);
        }
        for (final child in rawChildrens) {
          // Move the child from the coordinates of the table into those of the
          // row, or of the cell wrapper if there is one.
          final shift = Offset(addCellWrapper ? -_columnLefts!.elementAt(x) : 0.0, -rowBox.top);
          child.transform = Matrix4.translationValues(shift.dx, shift.dy, 0)
            ..multiply(tableTransform(child) ?? Matrix4.identity());
          // Read the transform back, because the setter keeps the previous
          // transform if it is equal and turns an identity matrix into null.
          _idToSemanticsShift[child.id] = (transform: child.transform, shift: shift);
        }

        cell.indexInParent = x;
        cells.add(cell);
      }

      newRow
        ..updateWith(
          config: SemanticsConfiguration()
            ..indexInParent = y
            ..role = SemanticsRole.row,
          childrenInInversePaintOrder: cells,
        )
        ..transform = Matrix4.translationValues(rowBox.left, rowBox.top, 0)
        ..rect = Rect.fromLTWH(0, 0, rowBox.width, rowBox.height);

      rows.add(newRow);
    }

    node.updateWith(config: config, childrenInInversePaintOrder: rows);
  }

  /// Replaces the children of this table with the given cells.
  ///
  /// The cells are divided into the specified number of columns before
  /// replacing the existing children.
  ///
  /// If the new cells contain any existing children of the table, those
  /// children are moved to their new location in the table rather than
  /// removed from the table and re-added.
  void setFlatChildren(int columns, List<RenderBox?> cells) {
    if (cells == _children && columns == _columns) {
      return;
    }
    assert(columns >= 0);
    // consider the case of a newly empty table
    if (columns == 0 || cells.isEmpty) {
      assert(cells.isEmpty);
      _columns = columns;
      if (_children.isEmpty) {
        assert(_rows == 0);
        return;
      }
      for (final RenderBox? oldChild in _children) {
        if (oldChild != null) {
          dropChild(oldChild);
        }
      }
      _rows = 0;
      _children.clear();
      markNeedsLayout();
      return;
    }
    assert(cells.length % columns == 0);
    // fill a set with the cells that are moving (it's important not
    // to dropChild a child that's remaining with us, because that
    // would clear their parentData field)
    final Set<RenderBox> lostChildren = HashSet<RenderBox>();
    for (var y = 0; y < _rows; y += 1) {
      for (var x = 0; x < _columns; x += 1) {
        final int xyOld = x + y * _columns;
        final int xyNew = x + y * columns;
        if (_children[xyOld] != null &&
            (x >= columns || xyNew >= cells.length || _children[xyOld] != cells[xyNew])) {
          lostChildren.add(_children[xyOld]!);
        }
      }
    }
    // adopt cells that are arriving, and cross cells that are just moving off our list of lostChildren
    var y = 0;
    while (y * columns < cells.length) {
      for (var x = 0; x < columns; x += 1) {
        final int xyNew = x + y * columns;
        final int xyOld = x + y * _columns;
        if (cells[xyNew] != null &&
            (x >= _columns || y >= _rows || _children[xyOld] != cells[xyNew])) {
          if (!lostChildren.remove(cells[xyNew])) {
            adoptChild(cells[xyNew]!);
          }
        }
      }
      y += 1;
    }
    // drop all the lost children
    lostChildren.forEach(dropChild);
    // update our internal values
    _columns = columns;
    _rows = cells.length ~/ columns;
    _children = List<RenderBox?>.of(cells);
    assert(_children.length == rows * columns);
    markNeedsLayout();
  }

  /// Replaces the children of this table with the given cells.
  void setChildren(List<List<RenderBox>>? cells) {
    // TODO(ianh): Make this smarter, like setFlatChildren
    if (cells == null) {
      setFlatChildren(0, const <RenderBox?>[]);
      return;
    }
    for (final RenderBox? oldChild in _children) {
      if (oldChild != null) {
        dropChild(oldChild);
      }
    }
    _children.clear();
    _columns = cells.isNotEmpty ? cells.first.length : 0;
    _rows = 0;
    cells.forEach(addRow);
    assert(_children.length == rows * columns);
  }

  /// Adds a row to the end of the table.
  ///
  /// The newly added children must not already have parents.
  void addRow(List<RenderBox?> cells) {
    assert(cells.length == columns);
    assert(_children.length == rows * columns);
    _rows += 1;
    _children.addAll(cells);
    for (final cell in cells) {
      if (cell != null) {
        adoptChild(cell);
      }
    }
    markNeedsLayout();
  }

  /// Replaces the child at the given position with the given child.
  ///
  /// If the given child is already located at the given position, this function
  /// does not modify the table. Otherwise, the given child must not already
  /// have a parent.
  void setChild(int x, int y, RenderBox? value) {
    assert(x >= 0 && x < columns && y >= 0 && y < rows);
    assert(_children.length == rows * columns);
    final int xy = x + y * columns;
    final RenderBox? oldChild = _children[xy];
    if (oldChild == value) {
      return;
    }
    if (oldChild != null) {
      dropChild(oldChild);
    }
    _children[xy] = value;
    if (value != null) {
      adoptChild(value);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox? child in _children) {
      child?.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) {
        painter?.dispose();
      }
      _rowDecorationPainters = List<BoxPainter?>.filled(_rowDecorations!.length, null);
    }
    for (final RenderBox? child in _children) {
      child?.detach();
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    assert(_children.length == rows * columns);
    for (final RenderBox? child in _children) {
      if (child != null) {
        visitor(child);
      }
    }
  }

  @protected
  @override
  void redepthChildren() {
    visitChildren(redepthChild);
  }

  // Cells that span several columns are measured as part of the column they
  // start in, because [TableColumnWidth] is handed the cells of a single column
  // at a time. A spanning cell can therefore make that one column as wide as
  // the whole span instead of having its width shared between the columns it
  // covers.
  //
  // Sharing it would mean growing only the columns whose width actually depends
  // on their cells - a [FixedColumnWidth] column has to keep the width it asked
  // for - and [TableColumnWidth] does not expose whether that is the case.
  // TODO(hm21): Share the width of a column-spanning cell between the columns
  // it covers, once TableColumnWidth can report whether it is cell-driven.
  // See https://github.com/flutter/flutter/issues/192847.
  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      return 0.0;
    }
    var totalMinWidth = 0.0;
    for (var x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMinWidth += columnWidth.minIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMinWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      return 0.0;
    }
    var totalMaxWidth = 0.0;
    for (var x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMaxWidth += columnWidth.maxIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMaxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // winner of the 2016 world's most expensive intrinsic dimension function award
    // honorable mention, most likely to improve if taught about memoization award
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      return 0.0;
    }
    final List<double> widths = _computeColumnWidths(BoxConstraints.tightForFinite(width: width));
    // A cell that spans several rows does not add its height to the row it
    // starts in. It records how far down from the top of the table it reaches
    // on the last row it covers, and that row grows to reach at least that far,
    // so the span only adds the height its rows do not already provide. This
    // mirrors the accounting in [computeDryLayout] and [performLayout], which
    // keeps the intrinsic height in agreement with the height the table
    // actually lays out to.
    final requiredRowBottoms = Float64List(rows);
    var rowTop = 0.0;
    for (var y = 0; y < rows; y += 1) {
      var rowHeight = 0.0;
      for (var x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child == null) {
          continue;
        }
        final childParentData = child.parentData! as TableCellParentData;
        // Placeholder cells (TableCell.none) are covered by a spanning cell and
        // contribute no size of their own, so there is nothing to measure.
        if (!childParentData._isVisible) {
          continue;
        }
        final int colSpan = childParentData.colSpan;
        final int rowSpan = childParentData.rowSpan;

        // Compute the total width covered by this cell's column span.
        var spanWidth = 0.0;
        for (var i = 0; i < colSpan && (x + i) < columns; i++) {
          spanWidth += widths[x + i];
        }

        final double childHeight = child.getMaxIntrinsicHeight(spanWidth);
        if (rowSpan == 1) {
          rowHeight = math.max(rowHeight, childHeight);
        } else {
          final int targetY = y + rowSpan - 1;
          if (targetY < rows) {
            requiredRowBottoms[targetY] = math.max(
              requiredRowBottoms[targetY],
              rowTop + childHeight,
            );
          }
        }
      }

      rowHeight = math.max(rowHeight, requiredRowBottoms[y] - rowTop);
      rowTop += rowHeight;
    }
    return rowTop;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return getMinIntrinsicHeight(width);
  }

  double? _baselineDistance;
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // returns the baseline offset of the cell in the first row with
    // the lowest baseline, and uses `TableCellVerticalAlignment.baseline`.
    assert(!debugNeedsLayout);
    return _baselineDistance;
  }

  /// Returns the list of [RenderBox] objects that are in the given
  /// column, in row order, starting from the first row.
  ///
  /// This is a lazily-evaluated iterable.
  // The following uses sync* because it is public API documented to return a
  // lazy iterable.
  Iterable<RenderBox> column(int x) sync* {
    for (var y = 0; y < rows; y += 1) {
      final int xy = x + y * columns;
      final RenderBox? child = _children[xy];
      if (child != null) {
        yield child;
      }
    }
  }

  /// Returns the list of [RenderBox] objects that are on the given
  /// row, in column order, starting with the first column.
  ///
  /// This is a lazily-evaluated iterable.
  // The following uses sync* because it is public API documented to return a
  // lazy iterable.
  Iterable<RenderBox> row(int y) sync* {
    final int start = y * columns;
    final int end = (y + 1) * columns;
    for (var xy = start; xy < end; xy += 1) {
      final RenderBox? child = _children[xy];
      if (child != null) {
        yield child;
      }
    }
  }

  List<double> _computeColumnWidths(BoxConstraints constraints) {
    assert(_children.length == rows * columns);
    // We apply the constraints to the column widths in the order of
    // least important to most important:
    // 1. apply the ideal widths (maxIntrinsicWidth)
    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go

    // 1. apply ideal widths, and collect information we'll need later
    final widths = List<double>.filled(columns, 0.0);
    final minWidths = List<double>.filled(columns, 0.0);
    final flexes = List<double?>.filled(columns, null);
    var tableWidth = 0.0; // running tally of the sum of widths[x] for all x
    var unflexedTableWidth = 0.0; // sum of the maxIntrinsicWidths of any column that has null flex
    var totalFlex = 0.0;
    for (var x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      // apply ideal width (maxIntrinsicWidth)
      final double maxIntrinsicWidth = columnWidth.maxIntrinsicWidth(
        columnCells,
        constraints.maxWidth,
      );
      assert(maxIntrinsicWidth.isFinite);
      assert(maxIntrinsicWidth >= 0.0);
      widths[x] = maxIntrinsicWidth;
      tableWidth += maxIntrinsicWidth;
      // collect min width information while we're at it
      final double minIntrinsicWidth = columnWidth.minIntrinsicWidth(
        columnCells,
        constraints.maxWidth,
      );
      assert(minIntrinsicWidth.isFinite);
      assert(minIntrinsicWidth >= 0.0);
      minWidths[x] = minIntrinsicWidth;
      assert(maxIntrinsicWidth >= minIntrinsicWidth);
      // collect flex information while we're at it
      final double? flex = columnWidth.flex(columnCells);
      if (flex != null) {
        assert(flex.isFinite);
        assert(flex > 0.0);
        flexes[x] = flex;
        totalFlex += flex;
      } else {
        unflexedTableWidth = unflexedTableWidth + maxIntrinsicWidth;
      }
    }
    final double maxWidthConstraint = constraints.maxWidth;
    final double minWidthConstraint = constraints.minWidth;

    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    if (totalFlex > 0.0) {
      // this can only grow the table, but it _will_ grow the table at
      // least as big as the target width.
      final double targetWidth;
      if (maxWidthConstraint.isFinite) {
        targetWidth = maxWidthConstraint;
      } else {
        targetWidth = minWidthConstraint;
      }
      if (tableWidth < targetWidth) {
        final double remainingWidth = targetWidth - unflexedTableWidth;
        assert(remainingWidth.isFinite);
        assert(remainingWidth >= 0.0);
        for (var x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double flexedWidth = remainingWidth * flexes[x]! / totalFlex;
            assert(flexedWidth.isFinite);
            assert(flexedWidth >= 0.0);
            if (widths[x] < flexedWidth) {
              final double delta = flexedWidth - widths[x];
              tableWidth += delta;
              widths[x] = flexedWidth;
            }
          }
        }
        assert(tableWidth + precisionErrorTolerance >= targetWidth);
      }
    } // step 2 and 3 are mutually exclusive
    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    else if (tableWidth < minWidthConstraint) {
      final double delta = (minWidthConstraint - tableWidth) / columns;
      for (var x = 0; x < columns; x += 1) {
        widths[x] = widths[x] + delta;
      }
      tableWidth = minWidthConstraint;
    }

    // beyond this point, unflexedTableWidth is no longer valid

    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go
    if (tableWidth > maxWidthConstraint) {
      double deficit = tableWidth - maxWidthConstraint;
      // Some columns may have low flex but have all the free space.
      // (Consider a case with a 1px wide column of flex 1000.0 and
      // a 1000px wide column of flex 1.0; the sizes coming from the
      // maxIntrinsicWidths. If the maximum table width is 2px, then
      // just applying the flexes to the deficit would result in a
      // table with one column at -998px and one column at 990px,
      // which is wildly unhelpful.)
      // Similarly, some columns may be flexible, but not actually
      // be shrinkable due to a large minimum width. (Consider a
      // case with two columns, one is flex and one isn't, both have
      // 1000px maxIntrinsicWidths, but the flex one has 1000px
      // minIntrinsicWidth also. The whole deficit will have to come
      // from the non-flex column.)
      // So what we do is we repeatedly iterate through the flexible
      // columns shrinking them proportionally until we have no
      // available columns, then do the same to the non-flexible ones.
      int availableColumns = columns;
      while (deficit > precisionErrorTolerance && totalFlex > precisionErrorTolerance) {
        var newTotalFlex = 0.0;
        for (var x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double newWidth = widths[x] - deficit * flexes[x]! / totalFlex;
            assert(newWidth.isFinite);
            if (newWidth <= minWidths[x]) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
              flexes[x] = null;
              availableColumns -= 1;
            } else {
              deficit -= widths[x] - newWidth;
              widths[x] = newWidth;
              newTotalFlex += flexes[x]!;
            }
            assert(widths[x] >= 0.0);
          }
        }
        totalFlex = newTotalFlex;
      }
      while (deficit > precisionErrorTolerance && availableColumns > 0) {
        // Now we have to take out the remaining space from the
        // columns that aren't minimum sized.
        // To make this fair, we repeatedly remove equal amounts from
        // each column, clamped to the minimum width, until we run out
        // of columns that aren't at their minWidth.
        final double delta = deficit / availableColumns;
        assert(delta != 0);
        var newAvailableColumns = 0;
        for (var x = 0; x < columns; x += 1) {
          final double availableDelta = widths[x] - minWidths[x];
          if (availableDelta > 0.0) {
            if (availableDelta <= delta) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
            } else {
              deficit -= delta;
              widths[x] = widths[x] - delta;
              newAvailableColumns += 1;
            }
          }
        }
        availableColumns = newAvailableColumns;
      }
    }
    return widths;
  }

  // cache the table geometry for painting purposes
  final List<double> _rowTops = <double>[];
  Iterable<double>? _columnLefts;
  late double _tableWidth;

  // Records the spanning cells and the cells they cover, used to skip the
  // covered cells while painting and hit testing, and to clip the inner borders
  // out of the spans. Set at the end of every layout and null when the table
  // has no spanning cells. See [_SpannedCells].
  //
  // Row heights are not cached; they are computed on-the-fly as
  // _rowTops[i + 1] - _rowTops[i], which is O(1) per row.
  _SpannedCells? _cachedSpannedCells;

  // The column, counted from the left, that is the leftmost one that `span`
  // covers.
  int _leftColumnOf(_Span span) {
    return switch (textDirection) {
      TextDirection.ltr => span.x,
      TextDirection.rtl => columns - span.x - span.colSpan,
    };
  }

  /// Computes the visual x-position for a cell, adjusting for text direction
  /// and column span.
  double _computeCellX({
    required Float64List positions,
    required int columnIndex,
    required int colSpan,
  }) {
    return switch (textDirection) {
      TextDirection.ltr => positions[columnIndex],
      TextDirection.rtl => positions[columnIndex + colSpan - 1],
    };
  }

  /// Returns the position and dimensions of the box that the given
  /// row covers, in this render object's coordinate space (so the
  /// left coordinate is always 0.0).
  ///
  /// The row being queried must exist.
  ///
  /// This is only valid after layout.
  Rect getRowBox(int row) {
    assert(row >= 0);
    assert(row < rows);
    assert(!debugNeedsLayout);
    return Rect.fromLTRB(0.0, _rowTops[row], size.width, _rowTops[row + 1]);
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    if (rows * columns == 0) {
      return null;
    }
    final List<double> widths = _computeColumnWidths(constraints);
    double? baselineOffset;
    // Like in [performLayout], a cell that spans several columns is laid out at
    // the combined width of these columns, and the slots that it covers are
    // skipped.
    var coveredUntilColumn = 0;
    for (var col = 0; col < columns; col += 1) {
      final RenderBox? child = _children[col];
      if (child == null) {
        continue;
      }
      final childParentData = child.parentData! as TableCellParentData;
      if (col < coveredUntilColumn || !childParentData._isVisible) {
        continue;
      }
      final int colSpan = childParentData.colSpan;
      coveredUntilColumn = col + colSpan;
      var spanWidth = 0.0;
      for (var i = 0; i < colSpan && (col + i) < columns; i++) {
        spanWidth += widths[col + i];
      }
      final childConstraints = BoxConstraints.tightFor(width: spanWidth);
      final double? childBaseline = switch (childParentData.verticalAlignment ??
          defaultVerticalAlignment) {
        TableCellVerticalAlignment.baseline => child.getDryBaseline(childConstraints, baseline),
        TableCellVerticalAlignment.top ||
        TableCellVerticalAlignment.middle ||
        TableCellVerticalAlignment.bottom ||
        TableCellVerticalAlignment.fill ||
        TableCellVerticalAlignment.intrinsicHeight => null,
      };
      if (childBaseline != null && (baselineOffset == null || baselineOffset < childBaseline)) {
        baselineOffset = childBaseline;
      }
    }
    return baselineOffset;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (rows * columns == 0) {
      return constraints.constrain(Size.zero);
    }
    final List<double> widths = _computeColumnWidths(constraints);
    // For every row, how far down from the top of the table it has to reach so
    // that the rowSpan cells ending in it fit. See [computeMinIntrinsicHeight].
    final requiredRowBottoms = Float64List(rows);
    final double tableWidth = widths.fold(0.0, (double a, double b) => a + b);
    var rowTop = 0.0;
    for (var y = 0; y < rows; y += 1) {
      var rowHeight = 0.0;
      for (var x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final childParentData = child.parentData! as TableCellParentData;
          // Placeholder cells (TableCell.none) are covered by a spanning cell
          // and contribute no size of their own, so there is nothing to measure.
          if (!childParentData._isVisible) {
            continue;
          }
          final int colSpan = childParentData.colSpan;
          final int rowSpan = childParentData.rowSpan;

          // Compute the total width covered by this cell's column span.
          var spanWidth = 0.0;
          for (var i = 0; i < colSpan && (x + i) < columns; i++) {
            spanWidth += widths[x + i];
          }

          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(
                debugCannotComputeDryLayout(
                  reason: 'TableCellVerticalAlignment.baseline requires a full layout for baseline metrics to be available.',
                ),
              );
              return Size.zero;
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
            case TableCellVerticalAlignment.intrinsicHeight:
              final Size childSize = child.getDryLayout(BoxConstraints.tightFor(width: spanWidth));
              if (rowSpan == 1) {
                rowHeight = math.max(rowHeight, childSize.height);
              } else if (rowSpan > 1) {
                final int targetY = y + rowSpan - 1;
                if (targetY < rows) {
                  requiredRowBottoms[targetY] = math.max(
                    requiredRowBottoms[targetY],
                    rowTop + childSize.height,
                  );
                }
              }
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }

      rowHeight = math.max(rowHeight, requiredRowBottoms[y] - rowTop);
      rowTop += rowHeight;
    }
    return constraints.constrain(Size(tableWidth, rowTop));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final int rows = this.rows;
    final int columns = this.columns;
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      // TODO(ianh): if columns is zero, this should be zero width
      // TODO(ianh): if columns is not zero, this should be based on the column width specifications
      _tableWidth = 0.0;
      _cachedSpannedCells = null;
      size = constraints.constrain(Size.zero);
      return;
    }
    final List<double> widths = _computeColumnWidths(constraints);
    // Tracks the spanning cells and the cells they cover, so that the covered
    // cells are skipped and the inner borders are clipped out of the spans
    // while painting. See [_SpannedCells].
    final spannedCells = _SpannedCells(rows: rows, columns: columns);
    // Use typed lists for predictable memory layout and faster indexed access.
    final columnStartPositions = Float64List(columns);
    // For every row, how far down from the top of the table it has to reach so
    // that the rowSpan cells ending in it fit. See the end of the first pass.
    final requiredRowBottoms = Float64List(rows);
    final rowHeights = Float64List(rows);
    final beforeBaselineDistances = Float64List(rows);
    // Flat arrays in row-major order (index: y * columns + x) instead of
    // nested lists for better cache locality.
    final spanWidthsInRowMajor = Float64List(rows * columns);
    final baselinesInRowMajor = Float64List(rows * columns);
    // Sentinel stored in [baselinesInRowMajor] for baseline-aligned cells whose
    // child has no real baseline. Such cells are top-aligned, so they must not
    // be offset by the row's baseline distance in the second pass. Real baseline
    // distances are always >= 0, so a negative value is unambiguous.
    const kNoBaseline = -1.0;

    switch (textDirection) {
      case TextDirection.rtl:
        columnStartPositions[columns - 1] = 0.0;
        for (int x = columns - 2; x >= 0; x -= 1) {
          columnStartPositions[x] = columnStartPositions[x + 1] + widths[x + 1];
        }
        _columnLefts = columnStartPositions.reversed;
        _tableWidth = columnStartPositions.first + widths.first;
      case TextDirection.ltr:
        columnStartPositions[0] = 0.0;
        for (var x = 1; x < columns; x += 1) {
          columnStartPositions[x] = columnStartPositions[x - 1] + widths[x - 1];
        }
        _columnLefts = columnStartPositions;
        _tableWidth = columnStartPositions.last + widths.last;
    }
    _rowTops.clear();
    _baselineDistance = null;

    // First layout pass: measure children and collect span information.
    var rowTop = 0.0;
    for (var y = 0; y < rows; y += 1) {
      var rowHeight = 0.0;
      var haveBaseline = false;
      var beforeBaselineDistance = 0.0;
      var afterBaselineDistance = 0.0;

      for (var x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child == null) {
          continue;
        }
        final childParentData = child.parentData! as TableCellParentData;
        childParentData.x = x;
        childParentData.y = y;

        final int colSpan = childParentData.colSpan;
        final int rowSpan = childParentData.rowSpan;
        assert(
          (colSpan == 0) == (rowSpan == 0),
          'Cell at ($x, $y): colSpan and rowSpan must either both be 0, for a '
          'TableCell.none placeholder, or both be at least 1, got a colSpan of '
          '$colSpan and a rowSpan of $rowSpan.',
        );

        final bool isHiddenCell = spannedCells.isCovered(x, y);
        assert(
          isHiddenCell == !childParentData._isVisible,
          'Cell at ($x, $y): a cell is covered by a span if and only if it is a '
          'TableCell.none placeholder. A cell covered by a colSpan or rowSpan must '
          'be declared as TableCell.none, and a TableCell.none must only appear '
          'where it is covered by a span.',
        );
        if (isHiddenCell || !childParentData._isVisible) {
          continue;
        }

        // Compute the total width covered by this cell's column span.
        var spanWidth = 0.0;
        for (var i = 0; i < colSpan && (x + i) < columns; i++) {
          spanWidth += widths[x + i];
        }
        spanWidthsInRowMajor[y * columns + x] = spanWidth;

        // Update span caches for hidden-cell detection and border painting.
        if (childParentData._hasSpan) {
          assert(() {
            if (x + colSpan > columns) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Invalid TableCell.colSpan'),
                ErrorDescription(
                  'In row $y, the cell at column $x has a colSpan of $colSpan, '
                  'which extends beyond the total number of columns ($columns).',
                ),
                ErrorHint(
                  'Ensure that colSpan does not exceed the remaining columns in the row.\n'
                  'For example, if a table has $columns columns, '
                  'and you are at column index $x, the maximum valid colSpan is '
                  '${columns - x}.',
                ),
              ]);
            }
            if (y + rowSpan > rows) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Invalid TableCell.rowSpan'),
                ErrorDescription(
                  'In row $y, the cell at column $x has a rowSpan of $rowSpan, '
                  'which extends beyond the total number of rows ($rows).',
                ),
                ErrorHint(
                  'Ensure that rowSpan does not exceed the remaining rows in the table.\n'
                  'For example, if a table has $rows rows, '
                  'and you are at row index $y, the maximum valid rowSpan is '
                  '${rows - y}.',
                ),
              ]);
            }
            return true;
          }());
          spannedCells.add(
            x: x,
            y: y,
            colSpan: math.min(colSpan, columns - x),
            rowSpan: math.min(rowSpan, rows - y),
          );
        }

        // Layout the child according to its vertical alignment.
        switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
          case TableCellVerticalAlignment.baseline:
            // TODO(hm21): Take rowSpan into account for baseline-aligned cells,
            // which currently add their whole height to the row they start in.
            // See https://github.com/flutter/flutter/issues/193626.
            assert(
              textBaseline != null,
              'An explicit textBaseline is required when using baseline alignment.',
            );
            child.layout(BoxConstraints.tightFor(width: spanWidth), parentUsesSize: true);

            final double? childBaseline = child.getDistanceToBaseline(
              textBaseline!,
              onlyReal: true,
            );

            if (childBaseline != null) {
              beforeBaselineDistance = math.max(beforeBaselineDistance, childBaseline);
              afterBaselineDistance = math.max(
                afterBaselineDistance,
                child.size.height - childBaseline,
              );
              baselinesInRowMajor[y * columns + x] = childBaseline;
              haveBaseline = true;
            } else {
              // The child has no real baseline, so it is top-aligned within the
              // row. Record the sentinel so the second pass places it the same
              // way instead of offsetting it by the row's baseline distance.
              rowHeight = math.max(rowHeight, child.size.height);
              baselinesInRowMajor[y * columns + x] = kNoBaseline;
            }
          case TableCellVerticalAlignment.top:
          case TableCellVerticalAlignment.middle:
          case TableCellVerticalAlignment.bottom:
          case TableCellVerticalAlignment.intrinsicHeight:
            child.layout(BoxConstraints.tightFor(width: spanWidth), parentUsesSize: true);
            final double childHeight = child.size.height;

            if (rowSpan == 1) {
              rowHeight = math.max(rowHeight, childHeight);
            } else if (rowSpan > 1) {
              final int targetY = y + rowSpan - 1;
              if (targetY < rows) {
                requiredRowBottoms[targetY] = math.max(
                  requiredRowBottoms[targetY],
                  rowTop + childHeight,
                );
              }
            }

          case TableCellVerticalAlignment.fill:
            break;
        }
      }

      if (haveBaseline) {
        if (y == 0) {
          _baselineDistance = beforeBaselineDistance;
        }
        rowHeight = math.max(rowHeight, beforeBaselineDistance + afterBaselineDistance);
      }

      // A row that rowSpan cells end in has to reach down to the bottom of the
      // tallest of them. rowTop is final here: every row above already has its
      // final height, including the height its baseline-aligned cells give it.
      rowHeight = math.max(rowHeight, requiredRowBottoms[y] - rowTop);
      rowHeights[y] = rowHeight;
      beforeBaselineDistances[y] = beforeBaselineDistance;
      rowTop += rowHeight;
    }

    // Second layout pass: position children using final row heights.
    rowTop = 0.0;
    for (var y = 0; y < rows; y += 1) {
      _rowTops.add(rowTop);
      final double beforeBaselineDistance = beforeBaselineDistances[y];
      final double rowHeight = rowHeights[y];

      for (var x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child == null) {
          continue;
        }

        final childParentData = child.parentData! as TableCellParentData;
        final int rowSpan = childParentData.rowSpan;
        final bool isHiddenCell = spannedCells.isCovered(x, y);
        assert(
          isHiddenCell == !childParentData._isVisible,
          'Cell at ($x, $y): a cell is covered by a span if and only if it is a '
          'TableCell.none placeholder. A cell covered by a colSpan or rowSpan must '
          'be declared as TableCell.none, and a TableCell.none must only appear '
          'where it is covered by a span.',
        );
        if (isHiddenCell || !childParentData._isVisible) {
          continue;
        }

        // Compute the total height covered by this cell's row span.
        var spanHeight = rowHeight;
        if (rowSpan > 1) {
          spanHeight = 0.0;
          for (var dy = 0; dy < rowSpan && (y + dy) < rows; dy++) {
            spanHeight += rowHeights[y + dy];
          }
        }

        final int colSpan = childParentData.colSpan;
        final double cellX = _computeCellX(
          positions: columnStartPositions,
          columnIndex: x,
          colSpan: colSpan,
        );

        // Set the child's final offset based on vertical alignment.
        switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
          case TableCellVerticalAlignment.baseline:
            final double childBaseline = baselinesInRowMajor[y * columns + x];
            // A child with no real baseline was top-aligned in the first pass;
            // keep it top-aligned here rather than offsetting it by the row's
            // baseline distance.
            childParentData.offset = childBaseline == kNoBaseline
                ? Offset(cellX, rowTop)
                : Offset(cellX, rowTop + beforeBaselineDistance - childBaseline);
          case TableCellVerticalAlignment.top:
            childParentData.offset = Offset(cellX, rowTop);
          case TableCellVerticalAlignment.middle:
            childParentData.offset = Offset(cellX, rowTop + (spanHeight - child.size.height) / 2.0);
          case TableCellVerticalAlignment.bottom:
            childParentData.offset = Offset(cellX, rowTop + spanHeight - child.size.height);
          case TableCellVerticalAlignment.fill:
          case TableCellVerticalAlignment.intrinsicHeight:
            final double spanWidth = spanWidthsInRowMajor[y * columns + x];

            child.layout(BoxConstraints.tightFor(width: spanWidth, height: spanHeight));
            childParentData.offset = Offset(cellX, rowTop);
        }
      }

      rowTop += rowHeight;
    }
    _rowTops.add(rowTop);
    size = constraints.constrain(Size(_tableWidth, rowTop));
    assert(_rowTops.length == rows + 1);

    // Publish the spanning cells for use during painting and hit testing, or
    // clear them when the table has no spanning cells.
    _cachedSpannedCells = spannedCells.spans.isEmpty ? null : spannedCells;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    assert(_children.length == rows * columns);
    for (int index = _children.length - 1; index >= 0; index -= 1) {
      final RenderBox? child = _children[index];
      if (child != null && _isLaidOutCell(child)) {
        final childParentData = child.parentData! as BoxParentData;
        final bool isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - childParentData.offset);
            return child.hitTest(result, position: transformed);
          },
        );
        if (isHit) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      if (border != null) {
        final borderRect = Rect.fromLTWH(offset.dx, offset.dy, _tableWidth, 0.0);
        border!.paint(
          context.canvas,
          borderRect,
          rows: const <double>[],
          columns: const <double>[],
        );
      }
      return;
    }
    assert(_rowTops.length == rows + 1);
    if (_rowDecorations != null) {
      assert(_rowDecorations!.length == _rowDecorationPainters!.length);
      final Canvas canvas = context.canvas;
      for (var y = 0; y < rows; y += 1) {
        if (_rowDecorations!.length <= y) {
          break;
        }
        if (_rowDecorations![y] != null) {
          _rowDecorationPainters![y] ??= _rowDecorations![y]!.createBoxPainter(markNeedsPaint);
          _rowDecorationPainters![y]!.paint(
            canvas,
            Offset(offset.dx, offset.dy + _rowTops[y]),
            configuration.copyWith(size: Size(size.width, _rowTops[y + 1] - _rowTops[y])),
          );
        }
      }
    }
    for (var index = 0; index < _children.length; index += 1) {
      final RenderBox? child = _children[index];
      if (child != null && _isLaidOutCell(child)) {
        final childParentData = child.parentData! as BoxParentData;
        context.paintChild(child, childParentData.offset + offset);
      }
    }
    assert(_rows == _rowTops.length - 1);
    assert(_columns == _columnLefts!.length);
    if (border != null) {
      // The border rect might not fill the entire height of this render object
      // if the rows underflow. We always force the columns to fill the width of
      // the render object, which means the columns cannot underflow.
      final borderRect = Rect.fromLTWH(offset.dx, offset.dy, _tableWidth, _rowTops.last);
      final Iterable<double> rows = _rowTops.getRange(1, _rowTops.length - 1);
      final Iterable<double> columns = _columnLefts!.skip(1);
      final _SpannedCells? spannedCells = _cachedSpannedCells;
      if (spannedCells == null) {
        border!.paint(context.canvas, borderRect, rows: rows, columns: columns);
      } else {
        // The border paints its inner borders across the whole table, so the
        // inside of every spanning cell is clipped out while it paints.
        context.canvas.save();
        _clipSpannedCells(context.canvas, borderRect, border!, spannedCells);
        border!.paint(context.canvas, borderRect, rows: rows, columns: columns);
        context.canvas.restore();
      }
    }
  }

  // Clips the inside of every spanning cell out of the canvas, so that the
  // inner borders that run through a span are not painted.
  //
  // The area that is clipped out stops where the borders around the span
  // begin. Next to another cell that is half the width of the inner border,
  // because inner borders are centered on the line between two cells. At the
  // edge of the table it is the full width of the outer border, because outer
  // borders are painted inside the table. Where a span reaches the edge of a
  // table with rounded corners, the clipped area also stays inside the rounded
  // outer border.
  //
  // The clips are not anti-aliased, so they keep or remove whole pixels. An
  // anti-aliased clip would also fade the pixels that a border around the span
  // only partly covers, which makes that border look lighter than the others.
  void _clipSpannedCells(Canvas canvas, Rect rect, TableBorder border, _SpannedCells spannedCells) {
    // The clipped area is shrunk by this fraction of a pixel, so that a pixel
    // whose center lies exactly on its edge is kept.
    const double kClipInset = 1.0 / 64.0;
    // The left edges of the columns from left to right, and the right edge of
    // the last column.
    final columnEdges = <double>[..._columnLefts!, _tableWidth];
    // TableBorder only rounds the corners of the outer border when all of its
    // painted sides have the same color, and paints square corners otherwise.
    final paintedOuterColors = <Color>{
      if (border.top.style != BorderStyle.none) border.top.color,
      if (border.right.style != BorderStyle.none) border.right.color,
      if (border.bottom.style != BorderStyle.none) border.bottom.color,
      if (border.left.style != BorderStyle.none) border.left.color,
    };
    final bool hasRoundedCorners =
        border.borderRadius != BorderRadius.zero && paintedOuterColors.length == 1;
    // With rounded corners and outer sides that differ, TableBorder paints each
    // outer side its BorderSide.strokeInset into the table. Otherwise it paints
    // the whole width of the side inside the table.
    bool matchesTop(BorderSide side) {
      return side.color == border.top.color &&
          side.width == border.top.width &&
          side.style == border.top.style;
    }

    final bool usesStrokeInset =
        hasRoundedCorners &&
        !(matchesTop(border.right) && matchesTop(border.bottom) && matchesTop(border.left));
    // A side that is not painted takes up no room, whatever its width. A
    // hairline, a side with a width of 0.0, is one physical pixel wide. That is
    // at most one logical pixel, so it is given one logical pixel.
    double widthOf(BorderSide side) {
      if (side.style == BorderStyle.none) {
        return 0.0;
      }
      return side.width == 0.0 ? 1.0 : side.width;
    }

    double outerWidthOf(BorderSide side) {
      final double width = widthOf(side);
      return usesStrokeInset ? side.copyWith(width: width).strokeInset : width;
    }

    final double leftWidth = outerWidthOf(border.left);
    final double topWidth = outerWidthOf(border.top);
    final double rightWidth = outerWidthOf(border.right);
    final double bottomWidth = outerWidthOf(border.bottom);
    final double verticalInset = widthOf(border.verticalInside) / 2.0;
    final double horizontalInset = widthOf(border.horizontalInside) / 2.0;
    final RRect? insideOuterBorder = !hasRoundedCorners
        ? null
        : EdgeInsets.fromLTRB(
            leftWidth + kClipInset,
            topWidth + kClipInset,
            rightWidth + kClipInset,
            bottomWidth + kClipInset,
          ).deflateRRect(border.borderRadius.toRRect(rect));
    for (final _Span span in spannedCells.spans) {
      // The span covers the columns from leftColumn up to, but not including,
      // rightColumn, counted from the left.
      final int leftColumn = _leftColumnOf(span);
      final int rightColumn = leftColumn + span.colSpan;
      final int bottomRow = span.y + span.rowSpan;
      final Rect interior = Rect.fromLTRB(
        rect.left + columnEdges[leftColumn] + (leftColumn == 0 ? leftWidth : verticalInset),
        rect.top + _rowTops[span.y] + (span.y == 0 ? topWidth : horizontalInset),
        rect.left +
            columnEdges[rightColumn] -
            (rightColumn == columns ? rightWidth : verticalInset),
        rect.top + _rowTops[bottomRow] - (bottomRow == rows ? bottomWidth : horizontalInset),
      ).deflate(kClipInset);
      if (interior.isEmpty) {
        continue;
      }
      final bool touchesTableEdge =
          leftColumn == 0 || rightColumn == columns || span.y == 0 || bottomRow == rows;
      if (insideOuterBorder != null && touchesTableEdge) {
        canvas.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Rect.largest)
            ..addPath(
              Path.combine(
                PathOperation.intersect,
                Path()..addRect(interior),
                Path()..addRRect(insideOuterBorder),
              ),
              Offset.zero,
            ),
          doAntiAlias: false,
        );
      } else {
        canvas.clipRect(interior, clipOp: ui.ClipOp.difference, doAntiAlias: false);
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TableBorder>('border', border, defaultValue: null));
    properties.add(
      DiagnosticsProperty<Map<int, TableColumnWidth>>(
        'specified column widths',
        _columnWidths,
        level: _columnWidths.isEmpty ? DiagnosticLevel.hidden : DiagnosticLevel.info,
      ),
    );
    properties.add(
      DiagnosticsProperty<TableColumnWidth>('default column width', defaultColumnWidth),
    );
    properties.add(MessageProperty('table size', '$columns\u00D7$rows'));
    properties.add(
      IterableProperty<String>(
        'column offsets',
        _columnLefts?.map(debugFormatDouble),
        ifNull: 'unknown',
      ),
    );
    properties.add(
      IterableProperty<String>('row offsets', _rowTops.map(debugFormatDouble), ifNull: 'unknown'),
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (_children.isEmpty) {
      return <DiagnosticsNode>[DiagnosticsNode.message('table is empty')];
    }

    return <DiagnosticsNode>[
      for (int y = 0; y < rows; y += 1)
        for (int x = 0; x < columns; x += 1)
          if (_children[x + y * columns] case final RenderBox child)
            child.toDiagnosticsNode(name: 'child ($x, $y)')
          else
            DiagnosticsProperty<Object>(
              'child ($x, $y)',
              null,
              ifNull: 'is null',
              showSeparator: false,
            ),
    ];
  }
}

/// Index for a cell.
@immutable
class _Index {
  const _Index(this.y, this.x);
  final int y;
  final int x;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! _Index) {
      return false;
    }
    return y == other.y && x == other.x;
  }

  @override
  int get hashCode => Object.hash(y, x);
}

// A cell that spans several columns or rows: the cell at column x of row y,
// which covers colSpan columns and rowSpan rows from there.
typedef _Span = ({int x, int y, int colSpan, int rowSpan});

// Records the cells of a table that span several columns or rows, and the
// cells that they cover.
//
// Only [RenderTable] fills this, during layout.
class _SpannedCells {
  _SpannedCells({required int rows, required int columns})
    : _columns = columns,
      // One bit for every cell: `+ 7` rounds the cell count up so a trailing
      // partial byte is still allocated, and `>> 3` converts the bit count to
      // a byte count (an integer divide by 8).
      _coveredCells = Uint8List((rows * columns + 7) >> 3);

  final int _columns;

  // Whether each cell is covered by a span, one bit per cell in row-major
  // order.
  final Uint8List _coveredCells;

  // The spanning cells, in the order in which they were added.
  final List<_Span> spans = <_Span>[];

  // Adds the cell at (x, y) that spans colSpan columns and rowSpan rows, and
  // marks every other cell that it covers.
  void add({required int x, required int y, required int colSpan, required int rowSpan}) {
    spans.add((x: x, y: y, colSpan: colSpan, rowSpan: rowSpan));
    for (var dy = 0; dy < rowSpan; dy++) {
      for (var dx = 0; dx < colSpan; dx++) {
        if (dx == 0 && dy == 0) {
          continue;
        }
        final int bit = (y + dy) * _columns + x + dx;
        // `bit >> 3` selects the byte holding the flag (bit ~/ 8) and `bit & 7`
        // is the position within that byte (bit % 8).
        _coveredCells[bit >> 3] |= 1 << (bit & 7);
      }
    }
  }

  // Whether the cell at (x, y) is covered by a span.
  bool isCovered(int x, int y) {
    final int bit = y * _columns + x;
    return _coveredCells[bit >> 3] & (1 << (bit & 7)) != 0;
  }
}
