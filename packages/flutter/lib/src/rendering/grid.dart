// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

class _GridMetrics {
  // Grid is width-in, height-out.  We fill the max width and adjust height
  // accordingly.
  factory _GridMetrics({ double width, int childCount, double maxChildExtent }) {
    assert(width != null);
    assert(childCount != null);
    assert(maxChildExtent != null);
    double childExtent = maxChildExtent;
    int childrenPerRow = (width / childExtent).floor();
    // If the child extent divides evenly into the width use that, otherwise + 1
    if (width / childExtent != childrenPerRow.toDouble()) childrenPerRow += 1;
    double totalPadding = 0.0;
    if (childrenPerRow * childExtent > width) {
      // TODO(eseidel): We should snap to pixel bounderies.
      childExtent = width / childrenPerRow;
    } else {
      totalPadding = width - (childrenPerRow * childExtent);
    }
    double childPadding = totalPadding / (childrenPerRow + 1.0);
    int rowCount = (childCount / childrenPerRow).ceil();

    double height = childPadding * (rowCount + 1) + (childExtent * rowCount);
    Size childSize = new Size(childExtent, childExtent);
    Size size = new Size(width, height);
    return new _GridMetrics._(size, childSize, childrenPerRow, childPadding, rowCount);
  }

  const _GridMetrics._(this.size, this.childSize, this.childrenPerRow, this.childPadding, this.rowCount);

  final Size size;
  final Size childSize;
  final int childrenPerRow; // aka columnCount
  final double childPadding;
  final int rowCount;
}

/// Parent data for use with [RenderGrid]
class GridParentData extends ContainerBoxParentDataMixin<RenderBox> {}

/// Implements the grid layout algorithm
///
/// In grid layout, children are arranged into rows and collumns in on a two
/// dimensional grid. The grid determines how many children will be placed in
/// each row by making the children as wide as possible while still respecting
/// the given [maxChildExtent].
class RenderGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, GridParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, GridParentData> {
  RenderGrid({ List<RenderBox> children, double maxChildExtent }) {
    addAll(children);
    _maxChildExtent = maxChildExtent;
  }

  double _maxChildExtent;
  bool _hasVisualOverflow = false;

  double get maxChildExtent => _maxChildExtent;
  void set maxChildExtent (double value) {
    if (_maxChildExtent != value) {
      _maxChildExtent = value;
      markNeedsLayout();
    }
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! GridParentData)
      child.parentData = new GridParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    // We can render at any width.
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    double maxWidth = childCount * _maxChildExtent;
    return constraints.constrainWidth(maxWidth);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    double desiredHeight = _computeMetrics().size.height;
    return constraints.constrainHeight(desiredHeight);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return getMinIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  _GridMetrics _computeMetrics() {
    return new _GridMetrics(
      width: constraints.maxWidth,
      childCount: childCount,
      maxChildExtent: _maxChildExtent
    );
  }

  void performLayout() {
    // We could shrink-wrap our contents when infinite, but for now we don't.
    assert(constraints.maxWidth < double.INFINITY);
    _GridMetrics metrics = _computeMetrics();
    size = constraints.constrain(metrics.size);
    if (constraints.maxHeight < size.height)
      _hasVisualOverflow = true;

    int row = 0;
    int column = 0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(new BoxConstraints.tight(metrics.childSize));

      double x = (column + 1) * metrics.childPadding + (column * metrics.childSize.width);
      double y = (row + 1) * metrics.childPadding + (row * metrics.childSize.height);
      final GridParentData childParentData = child.parentData;
      childParentData.position = new Point(x, y);

      column += 1;
      if (column >= metrics.childrenPerRow) {
        row += 1;
        column = 0;
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Point.origin & size, defaultPaint);
    else
      defaultPaint(context, offset);
  }
}
