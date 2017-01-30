// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

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

List<double> _generateRegularOffsets(int count, double extent) {
  final int length = count + 1;
  final List<double> result = new Float64List(length);
  for (int i = 0; i < length; ++i)
    result[i] = i * extent;
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
  ///
  /// The `tileWidth` and `tileHeight` is the horizontal and vertical
  /// (respectively) extent that each child will be allocated in the grid. The
  /// tiles will have [columnSpacing] space between them horizontally and
  /// [rowSpacing] space between them vertically.
  ///
  /// If the tiles are to completely fill the grid, then their size should be
  /// based on the grid's padded interior and the column and row spacing.
  GridSpecification.fromRegularTiles({
    double tileWidth,
    double tileHeight,
    int columnCount,
    int rowCount,
    double columnSpacing: 0.0,
    double rowSpacing: 0.0,
    this.padding: EdgeInsets.zero
  }) : columnOffsets = _generateRegularOffsets(columnCount, tileWidth + columnSpacing),
       rowOffsets = _generateRegularOffsets(rowCount, tileHeight + rowSpacing),
       columnSpacing = columnSpacing,
       rowSpacing = rowSpacing {
    assert(_debugIsMonotonic(columnOffsets));
    assert(_debugIsMonotonic(rowOffsets));
    assert(columnSpacing != null && columnSpacing >= 0.0);
    assert(rowSpacing != null && rowSpacing >= 0.0);
    assert(padding != null && padding.isNonNegative);
  }

  /// The offsets of the column boundaries in the grid.
  ///
  /// The first offset is the offset of the left edge of the left-most tile
  /// from the left edge of the interior of the grid's padding (0.0 if the padding
  /// is EdgeOffsets.zero). The difference between successive entries is the
  /// tile width plus the column spacing.
  ///
  /// The last offset is the offset of the right edge of the right-most tile
  /// from the left edge of the interior of the grid's padding (less the
  /// [columnSpacing]).
  ///
  /// If there are n columns in the grid, there should be n + 1 entries in this
  /// list. The right edge of the last column is defined as columnOffsets(n), i.e.
  /// the left edge of an extra column.
  final List<double> columnOffsets;

  /// The offsets of the row boundaries in the grid.
  ///
  /// The first offset is the offset of the top edge of the top-most tile from
  /// the top edge of the interior of the grid's padding (usually if the padding
  /// is EdgeOffsets.zero). The difference between successive entries is the
  /// tile height plus the row spacing
  ///
  /// The last offset is the offset of the bottom edge of the bottom-most tile
  /// from the top edge of the interior of the grid's padding. (less the
  /// [rowSpacing])
  ///
  /// If there are n rows in the grid, there should be n + 1 entries in this
  /// list. The bottom edge of the last row is defined as rowOffsets(n), i.e.
  /// the top edge of an extra row.
  final List<double> rowOffsets;

  /// The horizontal padding between columns.
  final double columnSpacing;

  /// The vertical padding between rows.
  final double rowSpacing;

  /// The interior padding of the grid.
  ///
  /// The grid's size encloses the spaced rows and columns and is then inflated
  /// by the padding.
  final EdgeInsets padding;

  /// The size of the grid.
  Size get gridSize {
    return new Size(
      columnOffsets.last + padding.horizontal - columnSpacing,
      rowOffsets.last + padding.vertical - rowSpacing
    );
  }

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
  /// Override this method to control size of the columns and rows.
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount);

  /// Override this method to control where children are placed in the grid.
  ///
  /// During layout, the grid calls this function for each child, passing the
  /// [placementData] associated with that child as context. The returned
  /// [GridChildPlacement] is then used to determine the size and position of
  /// that child within the grid.
  GridChildPlacement getChildPlacement(GridSpecification specification, int index, @checked Object placementData);

  /// Override this method to return true when the children need to be laid out.
  bool shouldRelayout(@checked GridDelegate oldDelegate) => true;

  Size _getGridSize(BoxConstraints constraints, int childCount) {
    return getGridSpecification(constraints, childCount).gridSize;
  }

  /// Insets for the entire grid.
  EdgeInsets get padding => EdgeInsets.zero;

  // TODO(ianh): It's a bit dubious to be using the getSize function from the delegate to
  // figure out the intrinsic dimensions. We really should either not support intrinsics,
  // or we should expose intrinsic delegate callbacks and throw if they're not implemented.

  /// Returns the minimum width that this grid could be without failing to paint
  /// its contents within itself.
  ///
  /// Override this to provide a more efficient or more correct solution. The
  /// default implementation actually instantiates a grid specification and
  /// measures the grid at the given height and child count.
  ///
  /// For more details on implementing this method, see
  /// [RenderBox.computeMinIntrinsicWidth].
  double getMinIntrinsicWidth(double height, int childCount) {
    final double width = _getGridSize(new BoxConstraints.tightForFinite(height: height), childCount).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the preferred height.
  ///
  /// Override this to provide a more efficient or more correct solution. The
  /// default implementation actually instantiates a grid specification and
  /// measures the grid at the given height and child count.
  ///
  /// For more details on implementing this method, see
  /// [RenderBox.computeMaxIntrinsicWidth].
  double getMaxIntrinsicWidth(double height, int childCount) {
    final double width = _getGridSize(new BoxConstraints.tightForFinite(height: height), childCount).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  /// Return the minimum height that this grid could be without failing to paint
  /// its contents within itself.
  ///
  /// Override this to provide a more efficient or more correct solution. The
  /// default implementation actually instantiates a grid specification and
  /// measures the grid at the given height and child count.
  ///
  /// For more details on implementing this method, see
  /// [RenderBox.computeMinIntrinsicHeight].
  double getMinIntrinsicHeight(double width, int childCount) {
    final double height = _getGridSize(new BoxConstraints.tightForFinite(width: width), childCount).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the preferred width.
  ///
  /// Override this to provide a more efficient or more correct solution. The
  /// default implementation actually instantiates a grid specification and
  /// measures the grid at the given height and child count.
  ///
  /// For more details on implementing this method, see
  /// [RenderBox.computeMaxIntrinsicHeight].
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

  /// The horizontal padding between columns.
  final double columnSpacing;

  /// The vertical padding between rows.
  final double rowSpacing;

  /// Insets for the entire grid.
  @override
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
///
/// Grids using this delegate cannot validly be placed inside an unconstrained
/// horizontal space, since they attempt to divide the incoming horizontal
/// maximum width constraint.
class FixedColumnCountGridDelegate extends GridDelegateWithInOrderChildPlacement {
  /// Creates a grid delegate that uses a fixed column count.
  ///
  /// The [columnCount] argument must not be null.
  FixedColumnCountGridDelegate({
    @required this.columnCount,
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
    final int rowCount = (childCount / columnCount).ceil();
    final double interiorWidth = constraints.maxWidth - padding.horizontal;
    final double columnWidth = interiorWidth / columnCount;
    final double tileWidth = math.max(0.0, columnWidth - columnSpacing);
    final double tileHeight = tileWidth / tileAspectRatio;
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

  @override
  double getMinIntrinsicHeight(double width, int childCount) {
    // TODO(ianh): Strictly, this should examine the children.
    return 0.0;
  }

  @override
  double getMaxIntrinsicHeight(double width, int childCount) {
    // TODO(ianh): Strictly, this should examine the children.
    return 0.0;
  }
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
    @required this.maxTileWidth,
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
    // We inflate the gridWidth by columnSpacing because the columnSpacing for
    // the rightmost tile in the grid doesn't actually consume space in the
    // grid because the rightmost tile is flush to the right interior edge of
    // the grid.
    final double totalColumnExtent = gridWidth + columnSpacing;
    final double maxColumnWidth = maxTileWidth + columnSpacing;
    final int columnCount = (totalColumnExtent / maxColumnWidth).ceil();
    final int rowCount = (childCount / columnCount).ceil();
    final double columnWidth = totalColumnExtent / columnCount;
    final double tileWidth = columnWidth - columnSpacing;
    final double tileHeight = tileWidth / tileAspectRatio;
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
  /// Opaque data passed to the [GridDelegate.getChildPlacement] method of the grid's [GridDelegate].
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
    LayoutCallback<BoxConstraints> callback
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
  /// For example, a [FixedColumnCountGridDelegate] for grids that have a fixed
  /// number of columns or a [MaxTileWidthGridDelegate] for grids that have a
  /// maximum tile width.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [GridDelegate.shouldRelayout] called; if the result is
  /// true, then the delegate will be called.
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
  double computeMinIntrinsicWidth(double height) {
    return _delegate.getMinIntrinsicWidth(height, virtualChildCount);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _delegate.getMaxIntrinsicWidth(height, virtualChildCount);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _delegate.getMinIntrinsicHeight(width, virtualChildCount);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
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
      invokeLayoutCallback<BoxConstraints>(callback);

    double gridTopPadding = 0.0;
    double gridLeftPadding = 0.0;

    switch (mainAxis) {
      case Axis.vertical:
        gridLeftPadding = _specification.padding.left;
        break;
      case Axis.horizontal:
        gridTopPadding = _specification.padding.top;
        break;
    }

    int childIndex = virtualChildBase;
    RenderBox child = firstChild;
    while (child != null) {
      final GridParentData childParentData = child.parentData;

      GridChildPlacement placement = delegate.getChildPlacement(_specification, childIndex, childParentData.placementData);
      assert(placement.column >= 0);
      assert(placement.row >= 0);
      assert(placement.column + placement.columnSpan < _specification.columnOffsets.length);
      assert(placement.row + placement.rowSpan < _specification.rowOffsets.length);

      final double tileLeft = gridLeftPadding + _specification.columnOffsets[placement.column];
      final double tileRight = gridLeftPadding + _specification.columnOffsets[placement.column + placement.columnSpan] - _specification.columnSpacing;
      final double tileTop = gridTopPadding + _specification.rowOffsets[placement.row];
      final double tileBottom =  gridTopPadding + _specification.rowOffsets[placement.row + placement.rowSpan] - _specification.rowSpacing;

      final double childWidth = math.max(0.0, tileRight - tileLeft);
      final double childHeight = math.max(0.0, tileBottom - tileTop);

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
