// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

bool _debugIsMonotonic(List<double> offsets) {
  bool result = true;
  assert(() {
    double current = 0.0;
    for (double offset in offsets) {
      if (current > offset) {
        result = false;
        break;
      }
      current = offset;
    }
    return true;
  });
  return result;
}

List<double> _generateRegularOffsets(int count, double size) {
  final int length = count + 1;
  final List<double> result = new Float64List(length);
  for (int i = 0; i < length; ++i)
    result[i] = i * size;
  return result;
}

/// Specifies the geometry of tiles in a grid.
///
/// A grid specificiation divides a fixed width and height into a certain number
/// of rows and columns, each with a specific size.
///
/// See also:
///
///  * [CustomGrid]
///  * [GridDelegate]
///  * [RenderGrid]
class GridSpecification {
  /// Creates a grid specification from an explicit list of offsets.
  GridSpecification.fromOffsets({
    this.columnOffsets,
    this.rowOffsets,
    this.columnSpacing: 0.0,
    this.rowSpacing: 0.0,
    this.padding: EdgeInsets.zero
  }) {
    assert(_debugIsMonotonic(columnOffsets));
    assert(_debugIsMonotonic(rowOffsets));
    assert(columnSpacing != null && columnSpacing >= 0.0);
    assert(rowSpacing != null && rowSpacing >= 0.0);
    assert(padding != null && padding.isNonNegative);
  }

  /// Creates a grid specification containing a certain number of equally sized tiles.
  /// The tileWidth is the sum of the width of the child it will contain and
  /// columnSpacing (even if columnCount is 1). Similarly tileHeight is child's height
  /// plus rowSpacing. If the tiles are to completely fill the grid, then their size
  /// should be based on the grid's padded interior.
  GridSpecification.fromRegularTiles({
    double tileWidth,
    double tileHeight,
    int columnCount,
    int rowCount,
    this.rowSpacing: 0.0,
    this.columnSpacing: 0.0,
    this.padding: EdgeInsets.zero
  }) : columnOffsets = _generateRegularOffsets(columnCount, tileWidth),
       rowOffsets = _generateRegularOffsets(rowCount, tileHeight) {
    assert(_debugIsMonotonic(columnOffsets));
    assert(_debugIsMonotonic(rowOffsets));
    assert(columnSpacing != null && columnSpacing >= 0.0);
    assert(rowSpacing != null && rowSpacing >= 0.0);
    assert(padding != null && padding.isNonNegative);
  }

  /// The offsets of the column boundaries in the grid.
  ///
  /// The first offset is the offset of the left edge of the left-most column
  /// from the left edge of the interior of the grid's padding (0.0 if the padding
  /// is EdgeOffsets.zero). The last offset is the offset of the right edge of
  /// the right-most column from the left edge of the interior of the grid's padding.
  ///
  /// If there are n columns in the grid, there should be n + 1 entries in this
  /// list. The right edge of the last column is defined as columnOffsets(n), i.e.
  /// the left edge of an extra column.
  final List<double> columnOffsets;

  /// The offsets of the row boundaries in the grid.
  ///
  /// The first offset is the offset of the top edge of the top-most row from
  /// the top edge of the interior of the grid's padding (usually if the padding
  /// is EdgeOffsets.zero). The last offset is the offset of the bottom edge of
  /// the bottom-most column from the top edge of the interior of the grid's padding.
  ///
  /// If there are n rows in the grid, there should be n + 1 entries in this
  /// list. The bottom edge of the last row is defined as rowOffsets(n), i.e.
  /// the top edge of an extra row.
  final List<double> rowOffsets;

  /// The vertical distance between rows.
  final double rowSpacing;

  /// The horizontal distance between columns.
  final double columnSpacing;

  /// The interior padding of the grid.
  ///
  /// The grid's size encloses the spaced rows and columns and is then inflated
  /// by the padding.
  final EdgeInsets padding;

  /// The size of the grid.
  Size get gridSize => new Size(columnOffsets.last + padding.horizontal, rowOffsets.last + padding.vertical);

  /// The number of columns in this grid.
  int get columnCount => columnOffsets.length - 1;

  /// The number of rows in this grid.
  int get rowCount => rowOffsets.length - 1;
}

/// Where to place a child within a grid.
///
/// See also:
///
///  * [CustomGrid]
///  * [GridDelegate]
///  * [RenderGrid]
class GridChildPlacement {
  /// Creates a placement for a child in a grid.
  ///
  /// The [column] and [row] arguments must not be null. By default, the child
  /// spans a single column and row.
  GridChildPlacement({
    this.column,
    this.row,
    this.columnSpan: 1,
    this.rowSpan: 1
  }) {
    assert(column != null && column >= 0);
    assert(row != null && row >= 0);
    assert(columnSpan != null && columnSpan > 0);
    assert(rowSpan != null && rowSpan > 0);
  }

  /// The column in which to place the child.
  final int column;

  /// The row in which to place the child.
  final int row;

  /// How many columns the child should span.
  final int columnSpan;

  /// How many rows the child should span.
  final int rowSpan;
}

/// An abstract interface to control the layout of a [RenderGrid].
abstract class GridDelegate {
  /// Override this function to control size of the columns and rows.
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount);

  /// Override this function to control where children are placed in the grid.
  GridChildPlacement getChildPlacement(GridSpecification specification, int index, Object placementData);

  /// Override this method to return true when the children need to be laid out.
  bool shouldRelayout(GridDelegate oldDelegate) => true;

  Size _getGridSize(BoxConstraints constraints, int childCount) {
    return getGridSpecification(constraints, childCount).gridSize;
  }

  // TODO(ianh): It's a bit dubious to be using the getSize function from the delegate to
  // figure out the intrinsic dimensions. We really should either not support intrinsics,
  // or we should expose intrinsic delegate callbacks and throw if they're not implemented.

  /// Returns the minimum width that this grid could be without failing to paint
  /// its contents within itself.
  ///
  /// Override this to provide a more efficient solution. The default
  /// implementation actually instantiates a grid specification and measures the
  /// grid at the given height and child count.
  ///
  /// For more details, see [RenderBox.getMinIntrinsicWidth].
  double getMinIntrinsicWidth(double height, int childCount) {
    final double width = _getGridSize(new BoxConstraints.tightForFinite(height: height), childCount).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the preferred height.
  ///
  /// Override this to provide a more efficient solution. The default
  /// implementation actually instantiates a grid specification and measures the
  /// grid at the given height and child count.
  ///
  /// For more details, see [RenderBox.getMaxIntrinsicWidth].
  double getMaxIntrinsicWidth(double height, int childCount) {
    final double width = _getGridSize(new BoxConstraints.tightForFinite(height: height), childCount).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  /// Return the minimum height that this grid could be without failing to paint
  /// its contents within itself.
  ///
  /// Override this to provide a more efficient solution. The default
  /// implementation actually instantiates a grid specification and measures the
  /// grid at the given width and child count.
  ///
  /// For more details, see [RenderBox.getMinIntrinsicHeight].
  double getMinIntrinsicHeight(double width, int childCount) {
    final double height = _getGridSize(new BoxConstraints.tightForFinite(width: width), childCount).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the preferred width.
  ///
  /// Override this to provide a more efficient solution. The default
  /// implementation actually instantiates a grid specification and measures the
  /// grid at the given width and child count.
  ///
  /// For more details, see [RenderBox.getMaxIntrinsicHeight].
  double getMaxIntrinsicHeight(double width, int childCount) {
    final double height = _getGridSize(new BoxConstraints.tightForFinite(width: width), childCount).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }
}

/// A [GridDelegate] the places its children in order throughout the grid.
///
/// Subclasses must still provide a mechanism for sizing the grid by
/// implementing [getGridSpecification], and should also provide efficent
/// versions of the intrinsic sizing functions ([getMinIntrinsicWidth] and
/// company).
abstract class GridDelegateWithInOrderChildPlacement extends GridDelegate {
  /// Initializes [columnSpacing], [rowSpacing], and [padding] for subclasses.
  ///
  /// By default, the [columnSpacing], [rowSpacing], and [padding] are zero.
  GridDelegateWithInOrderChildPlacement({
    this.columnSpacing: 0.0,
    this.rowSpacing: 0.0,
    this.padding: EdgeInsets.zero
  }) {
    assert(columnSpacing != null && columnSpacing >= 0.0);
    assert(rowSpacing != null && rowSpacing >= 0.0);
    assert(padding != null && padding.isNonNegative);
  }

  /// The horizontal distance between columns.
  final double columnSpacing;

  /// The vertical distance between rows.
  final double rowSpacing;

  /// Insets for the entire grid.
  final EdgeInsets padding;

  @override
  GridChildPlacement getChildPlacement(GridSpecification specification, int index, Object placementData) {
    final int columnCount = specification.columnOffsets.length - 1;
    return new GridChildPlacement(
      column: index % columnCount,
      row: index ~/ columnCount
    );
  }

  @override
  bool shouldRelayout(GridDelegateWithInOrderChildPlacement oldDelegate) {
    return columnSpacing != oldDelegate.columnSpacing
        || rowSpacing != oldDelegate.rowSpacing
        || padding != oldDelegate.padding;
  }
}


/// A [GridDelegate] that divides the grid's width evenly for a fixed number of columns.
class FixedColumnCountGridDelegate extends GridDelegateWithInOrderChildPlacement {
  /// Creates a grid delegate that uses a fixed column count.
  ///
  /// The [columnCount] argument must not be null.
  FixedColumnCountGridDelegate({
    this.columnCount,
    double columnSpacing: 0.0,
    double rowSpacing: 0.0,
    EdgeInsets padding: EdgeInsets.zero,
    this.tileAspectRatio: 1.0
  }) : super(columnSpacing: columnSpacing, rowSpacing: rowSpacing, padding: padding) {
    assert(columnCount != null && columnCount >= 0);
    assert(tileAspectRatio != null && tileAspectRatio > 0.0);
  }

  /// The number of columns in the grid.
  final int columnCount;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  @override
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    assert(constraints.maxWidth < double.INFINITY);
    int rowCount = (childCount / columnCount).ceil();
    double tileWidth = math.max(0.0, constraints.maxWidth - padding.horizontal + columnSpacing) / columnCount;
    double tileHeight = tileWidth / tileAspectRatio;
    return new GridSpecification.fromRegularTiles(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      rowCount: rowCount,
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      padding: padding
    );
  }

  @override
  bool shouldRelayout(FixedColumnCountGridDelegate oldDelegate) {
    return columnCount != oldDelegate.columnCount
        || tileAspectRatio != oldDelegate.tileAspectRatio
        || super.shouldRelayout(oldDelegate);
  }

  @override
  double getMinIntrinsicWidth(double height, int childCount) {
    // TODO(ianh): Strictly, this should examine the children.
    return 0.0;
  }

  @override
  double getMaxIntrinsicWidth(double height, int childCount) {
    // TODO(ianh): Strictly, this should examine the children.
    return 0.0;
  }

  // TODO(ianh): Provide efficient intrinsic height functions.
}

/// A [GridDelegate] that fills the width with a variable number of tiles.
///
/// This delegate will select a tile width that is as large as possible subject
/// to the following conditions:
///
///  - The tile width evenly divides the width of the grid.
///  - The tile width is at most [maxTileWidth].
class MaxTileWidthGridDelegate extends GridDelegateWithInOrderChildPlacement {
  /// Creates a grid delegate that uses a max tile width.
  ///
  /// The [maxTileWidth] argument must not be null.
  MaxTileWidthGridDelegate({
    this.maxTileWidth,
    this.tileAspectRatio: 1.0,
    double columnSpacing: 0.0,
    double rowSpacing: 0.0,
    EdgeInsets padding: EdgeInsets.zero
  }) : super(columnSpacing: columnSpacing, rowSpacing: rowSpacing, padding: padding) {
    assert(maxTileWidth != null && maxTileWidth >= 0.0);
    assert(tileAspectRatio != null && tileAspectRatio > 0.0);
  }

  /// The maximum width of a tile in the grid.
  final double maxTileWidth;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  @override
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    if (!constraints.maxWidth.isFinite) {
      // if we're unbounded, just shrink-wrap around a single line of tiles
      return new GridSpecification.fromRegularTiles(
        tileWidth: maxTileWidth,
        tileHeight: maxTileWidth / tileAspectRatio,
        columnCount: childCount,
        rowCount: 1,
        columnSpacing: columnSpacing,
        rowSpacing: rowSpacing,
        padding: padding
      );
    }
    final double gridWidth = math.max(0.0, constraints.maxWidth - padding.horizontal);
    int columnCount = (gridWidth / maxTileWidth).ceil();
    int rowCount = (childCount / columnCount).ceil();
    double tileWidth = gridWidth / columnCount;
    double tileHeight = tileWidth / tileAspectRatio;
    return new GridSpecification.fromRegularTiles(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      rowCount: rowCount,
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      padding: padding
    );
  }

  @override
  bool shouldRelayout(MaxTileWidthGridDelegate oldDelegate) {
    return maxTileWidth != oldDelegate.maxTileWidth
        || tileAspectRatio != oldDelegate.tileAspectRatio
        || super.shouldRelayout(oldDelegate);
  }

  @override
  double getMinIntrinsicWidth(double height, int childCount) {
    // TODO(ianh): Strictly, this should examine the children.
    return 0.0;
  }

  @override
  double getMaxIntrinsicWidth(double height, int childCount) {
    return maxTileWidth * childCount;
  }

  // TODO(ianh): Provide efficient intrinsic height functions.
}

/// Parent data for use with [RenderGrid]
class GridParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// Opaque data passed to the getChildPlacement method of the grid's [GridDelegate].
  Object placementData;

  @override
  String toString() => '${super.toString()}; placementData=$placementData';
}

/// Implements the grid layout algorithm
///
/// In grid layout, children are arranged into rows and columns in on a two
/// dimensional grid. The [GridDelegate] determines how to arrange the
/// children on the grid.
///
/// The arrangment of rows and columns in the grid cannot depend on the contents
/// of the tiles in the grid, which makes grid layout most useful for images and
/// card-like layouts rather than for document-like layouts that adjust to the
/// amount of text contained in the tiles.
///
/// Additionally, grid layout materializes all of its children, which makes it
/// most useful for grids containing a moderate number of tiles.
class RenderGrid extends RenderVirtualViewport<GridParentData> {
  /// Creates a grid render object.
  ///
  /// The [delegate] argument must not be null.
  RenderGrid({
    List<RenderBox> children,
    GridDelegate delegate,
    int virtualChildBase: 0,
    int virtualChildCount,
    Offset paintOffset: Offset.zero,
    LayoutCallback callback
  }) : _delegate = delegate, _virtualChildBase = virtualChildBase, super(
    virtualChildCount: virtualChildCount,
    paintOffset: paintOffset,
    callback: callback
  ) {
    assert(delegate != null);
    addAll(children);
  }

  /// The delegate that controls the layout of the children.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [GridDelegate.shouldRelayout] called; if the result is
  /// `true`, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// The delegate must not be null.
  GridDelegate get delegate => _delegate;
  GridDelegate _delegate;
  set delegate (GridDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    if (newDelegate.runtimeType != _delegate.runtimeType || newDelegate.shouldRelayout(_delegate)) {
      _specification = null;
      markNeedsLayout();
    }
    _delegate = newDelegate;
  }

  @override
  set mainAxis(Axis value) {
    assert(() {
      if (value != Axis.vertical)
        throw new FlutterError('RenderGrid doesn\'t yet support horizontal scrolling.');
      return true;
    });
    super.mainAxis = value;
  }

  @override
  int get virtualChildCount => super.virtualChildCount ?? childCount;

  /// The virtual index of the first child.
  ///
  /// When asking the delegate for the position of each child, the grid will add
  /// the virtual child i to the indices of its children.
  int get virtualChildBase => _virtualChildBase;
  int _virtualChildBase;
  set virtualChildBase(int value) {
    assert(value != null);
    if (_virtualChildBase == value)
      return;
    _virtualChildBase = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GridParentData)
      child.parentData = new GridParentData();
  }

  @override
  double getMinIntrinsicWidth(double height) {
    return _delegate.getMinIntrinsicWidth(height, virtualChildCount);
  }

  @override
  double getMaxIntrinsicWidth(double height) {
    return _delegate.getMaxIntrinsicWidth(height, virtualChildCount);
  }

  @override
  double getMinIntrinsicHeight(double width) {
    return _delegate.getMinIntrinsicHeight(width, virtualChildCount);
  }

  @override
  double getMaxIntrinsicHeight(double width) {
    return _delegate.getMaxIntrinsicHeight(width, virtualChildCount);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  /// The specification of this grid.
  ///
  /// The grid specification cannot be set directly. Instead, set a [delegate]
  /// to control the specification.
  GridSpecification get specification => _specification;
  GridSpecification _specification;
  int _specificationChildCount;
  BoxConstraints _specificationConstraints;

  void _updateGridSpecification() {
    if (_specification == null
        || _specificationChildCount != virtualChildCount
        || _specificationConstraints != constraints) {
      _specification = delegate.getGridSpecification(constraints, virtualChildCount);
      _specificationChildCount = virtualChildCount;
      _specificationConstraints = constraints;
    }
  }

  @override
  void performLayout() {
    _updateGridSpecification();
    final Size gridSize = _specification.gridSize;
    size = constraints.constrain(gridSize);

    if (callback != null)
      invokeLayoutCallback(callback);

    final double gridTopPadding = _specification.padding.top;
    final double gridLeftPadding = _specification.padding.left;
    int childIndex = virtualChildBase;
    RenderBox child = firstChild;
    while (child != null) {
      final GridParentData childParentData = child.parentData;

      GridChildPlacement placement = delegate.getChildPlacement(_specification, childIndex, childParentData.placementData);
      assert(placement.column >= 0);
      assert(placement.row >= 0);
      assert(placement.column + placement.columnSpan < _specification.columnOffsets.length);
      assert(placement.row + placement.rowSpan < _specification.rowOffsets.length);

      double tileLeft = gridLeftPadding + _specification.columnOffsets[placement.column];
      double tileRight = gridLeftPadding + _specification.columnOffsets[placement.column + placement.columnSpan];
      double tileTop = gridTopPadding + _specification.rowOffsets[placement.row];
      double tileBottom =  gridTopPadding + _specification.rowOffsets[placement.row + placement.rowSpan];

      double childWidth = math.max(0.0, tileRight - tileLeft - _specification.columnSpacing);
      double childHeight = math.max(0.0, tileBottom - tileTop - _specification.rowSpacing);

      child.layout(new BoxConstraints(
        minWidth: childWidth,
        maxWidth: childWidth,
        minHeight: childHeight,
        maxHeight: childHeight
      ));

      childParentData.offset = new Offset(tileLeft, tileTop);
      childIndex += 1;

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }
}
