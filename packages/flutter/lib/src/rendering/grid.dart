// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  int length = count + 1;
  List<double> result = new Float64List(length);
  for (int i = 0; i < length; ++i)
    result[i] = i * size;
  return result;
}

class GridSpecification {
  /// Creates a grid specification from an explicit list of offsets.
  GridSpecification.fromOffsets({
    this.columnOffsets,
    this.rowOffsets,
    this.padding: EdgeDims.zero
  }) {
    assert(_debugIsMonotonic(columnOffsets));
    assert(_debugIsMonotonic(rowOffsets));
    assert(padding != null);
  }

  /// Creates a grid specification containing a certain number of equally sized tiles.
  GridSpecification.fromRegularTiles({
    double tileWidth,
    double tileHeight,
    int columnCount,
    int rowCount,
    this.padding: EdgeDims.zero
  }) : columnOffsets = _generateRegularOffsets(columnCount, tileWidth),
       rowOffsets = _generateRegularOffsets(rowCount, tileHeight) {
    assert(_debugIsMonotonic(columnOffsets));
    assert(_debugIsMonotonic(rowOffsets));
    assert(padding != null);
  }

  /// The offsets of the column boundaries in the grid.
  ///
  /// The first offset is the offset of the left edge of the left-most column
  /// from the left edge of the interior of the grid's padding (usually 0.0).
  /// The last offset is the offset of the right edge of the right-most column
  /// from the left edge of the interior of the grid's padding.
  ///
  /// If there are n columns in the grid, there should be n + 1 entries in this
  /// list (because there's an entry before the first column and after the last
  /// column).
  final List<double> columnOffsets;

  /// The offsets of the row boundaries in the grid.
  ///
  /// The first offset is the offset of the top edge of the top-most row from
  /// the top edge of the interior of the grid's padding (usually 0.0). The
  /// last offset is the offset of the bottom edge of the bottom-most column
  /// from the top edge of the interior of the grid's padding.
  ///
  /// If there are n rows in the grid, there should be n + 1 entries in this
  /// list (because there's an entry before the first row and after the last
  /// row).
  final List<double> rowOffsets;

  /// The interior padding of the grid.
  ///
  /// The grid's size encloses the rows and columns and is then inflated by the
  /// padding.
  final EdgeDims padding;

  /// The size of the grid.
  Size get gridSize => new Size(columnOffsets.last + padding.horizontal, rowOffsets.last + padding.vertical);

  /// The number of columns in this grid.
  int get columnCount => columnOffsets.length - 1;

  /// The number of rows in this grid.
  int get rowCount => rowOffsets.length - 1;
}

/// Where to place a child within a grid.
class GridChildPlacement {
  GridChildPlacement({
    this.column,
    this.row,
    this.columnSpan: 1,
    this.rowSpan: 1,
    this.padding: EdgeDims.zero
  }) {
    assert(column != null);
    assert(row != null);
    assert(columnSpan != null);
    assert(rowSpan != null);
    assert(padding != null);
  }

  /// The column in which to place the child.
  final int column;

  /// The row in which to place the child.
  final int row;

  /// How many columns the child should span.
  final int columnSpan;

  /// How many rows the child should span.
  final int rowSpan;

  /// How much the child should be inset from the column and row boundaries.
  final EdgeDims padding;
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

  /// Returns the minimum width that this grid could be without failing to paint
  /// its contents within itself.
  double getMinIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(_getGridSize(constraints, childCount).width);
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the height.
  double getMaxIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(_getGridSize(constraints, childCount).width);
  }

  /// Return the minimum height that this grid could be without failing to paint
  /// its contents within itself.
  double getMinIntrinsicHeight(BoxConstraints constraints, int childCount) {
    return constraints.constrainHeight(_getGridSize(constraints, childCount).height);
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the width.
  double getMaxIntrinsicHeight(BoxConstraints constraints, int childCount) {
    return constraints.constrainHeight(_getGridSize(constraints, childCount).height);
  }
}

/// A [GridDelegate] the places its children in order throughout the grid.
abstract class GridDelegateWithInOrderChildPlacement extends GridDelegate {
  GridDelegateWithInOrderChildPlacement({ this.padding: EdgeDims.zero });

  /// The amount of padding to apply to each child.
  final EdgeDims padding;

  GridChildPlacement getChildPlacement(GridSpecification specification, int index, Object placementData) {
    int columnCount = specification.columnOffsets.length - 1;
    return new GridChildPlacement(
      column: index % columnCount,
      row: index ~/ columnCount,
      padding: padding
    );
  }

  bool shouldRelayout(GridDelegateWithInOrderChildPlacement oldDelegate) {
    return padding != oldDelegate.padding;
  }
}

/// A [GridDelegate] that divides the grid's width evenly amount a fixed number of columns.
class FixedColumnCountGridDelegate extends GridDelegateWithInOrderChildPlacement {
  FixedColumnCountGridDelegate({
    this.columnCount,
    this.tileAspectRatio: 1.0,
    EdgeDims padding: EdgeDims.zero
  }) : super(padding: padding);

  /// The number of columns in the grid.
  final int columnCount;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    assert(constraints.maxWidth < double.INFINITY);
    int rowCount = (childCount / columnCount).ceil();
    double tileWidth = constraints.maxWidth / columnCount;
    double tileHeight = tileWidth / tileAspectRatio;
    return new GridSpecification.fromRegularTiles(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      rowCount: rowCount,
      padding: padding.flipped
    );
  }

  bool shouldRelayout(FixedColumnCountGridDelegate oldDelegate) {
    return columnCount != oldDelegate.columnCount
        || tileAspectRatio != oldDelegate.tileAspectRatio
        || super.shouldRelayout(oldDelegate);
  }

  double getMinIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(0.0);
  }
}

/// A [GridDelegate] that fills the width with a variable number of tiles.
///
/// This delegate will select a tile width that is as large as possible subject
/// to the following conditions:
///
///  - The tile width evenly divides the width of the grid.
///  - The tile width is at most [maxTileWidth].
///
class MaxTileWidthGridDelegate extends GridDelegateWithInOrderChildPlacement {
  MaxTileWidthGridDelegate({
    this.maxTileWidth,
    this.tileAspectRatio: 1.0,
    EdgeDims padding: EdgeDims.zero
  }) : super(padding: padding);

  /// The maximum width of a tile in the grid.
  final double maxTileWidth;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    assert(constraints.maxWidth < double.INFINITY);
    double gridWidth = constraints.maxWidth;
    int columnCount = (gridWidth / maxTileWidth).ceil();
    int rowCount = (childCount / columnCount).ceil();
    double tileWidth = gridWidth / columnCount;
    double tileHeight = tileWidth / tileAspectRatio;
    return new GridSpecification.fromRegularTiles(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      rowCount: rowCount,
      padding: padding.flipped
    );
  }

  bool shouldRelayout(MaxTileWidthGridDelegate oldDelegate) {
    return maxTileWidth != oldDelegate.maxTileWidth
        || tileAspectRatio != oldDelegate.tileAspectRatio
        || super.shouldRelayout(oldDelegate);
  }

  double getMinIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints, int childCount) {
    return constraints.constrainWidth(maxTileWidth * childCount);
  }
}

/// Parent data for use with [RenderGrid]
class GridParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// Opaque data passed to the getChildPlacement method of the grid's [GridDelegate].
  Object placementData;

  void merge(GridParentData other) {
    if (other.placementData != null)
      placementData = other.placementData;
    super.merge(other);
  }

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
  GridDelegate get delegate => _delegate;
  GridDelegate _delegate;
  void set delegate (GridDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    if (newDelegate.runtimeType != _delegate.runtimeType || newDelegate.shouldRelayout(_delegate)) {
      _specification = null;
      markNeedsLayout();
    }
    _delegate = newDelegate;
  }

  /// The virtual index of the first child.
  ///
  /// When asking the delegate for the position of each child, the grid will add
  /// the virtual child i to the indices of its children.
  int get virtualChildBase => _virtualChildBase;
  int _virtualChildBase;
  void set virtualChildBase(int value) {
    assert(value != null);
    if (_virtualChildBase == value)
      return;
    _virtualChildBase = value;
    markNeedsLayout();
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! GridParentData)
      child.parentData = new GridParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _delegate.getMinIntrinsicWidth(constraints, virtualChildCount);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _delegate.getMaxIntrinsicWidth(constraints, virtualChildCount);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _delegate.getMinIntrinsicHeight(constraints, virtualChildCount);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _delegate.getMaxIntrinsicHeight(constraints, virtualChildCount);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

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

  void performLayout() {
    _updateGridSpecification();
    Size gridSize = _specification.gridSize;
    size = constraints.constrain(gridSize);

    if (callback != null)
      invokeLayoutCallback(callback);

    double gridTopPadding = _specification.padding.top;
    double gridLeftPadding = _specification.padding.left;
    int childIndex = virtualChildBase;
    RenderBox child = firstChild;
    while (child != null) {
      final GridParentData childParentData = child.parentData;

      GridChildPlacement placement = delegate.getChildPlacement(_specification, childIndex, childParentData.placementData);
      assert(placement.column >= 0);
      assert(placement.row >= 0);
      assert(placement.column + placement.columnSpan < _specification.columnOffsets.length);
      assert(placement.row + placement.rowSpan < _specification.rowOffsets.length);

      double tileLeft = _specification.columnOffsets[placement.column] + gridLeftPadding;
      double tileRight = _specification.columnOffsets[placement.column + placement.columnSpan] + gridLeftPadding;
      double tileTop = _specification.rowOffsets[placement.row] + gridTopPadding;
      double tileBottom = _specification.rowOffsets[placement.row + placement.rowSpan] + gridTopPadding;

      double childWidth = tileRight - tileLeft - placement.padding.horizontal;
      double childHeight = tileBottom - tileTop - placement.padding.vertical;

      child.layout(new BoxConstraints(
        minWidth: childWidth,
        maxWidth: childWidth,
        minHeight: childHeight,
        maxHeight: childHeight
      ));

      childParentData.offset = new Offset(
        tileLeft + placement.padding.left,
        tileTop + placement.padding.top
      );

      childIndex += 1;

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }
}
