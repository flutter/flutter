// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

class GridParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> {}

class GridMetrics {
  // Grid is width-in, height-out.  We fill the max width and adjust height
  // accordingly.
  factory GridMetrics({ double width, int childCount, double childExtent }) {
    assert(width != null);
    assert(childCount != null);
    assert(childExtent != null);
    int childrenPerRow = (width / childExtent).floor() + 1;
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
    return new GridMetrics._(size, childSize, childrenPerRow, childPadding, rowCount);
  }

  const GridMetrics._(this.size, this.childSize, this.childrenPerRow, this.childPadding, this.rowCount);

  final Size size;
  final Size childSize;
  final int childrenPerRow; // aka columnCount
  final double childPadding;
  final int rowCount;
}

class RenderGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, GridParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, GridParentData> {
  RenderGrid({ List<RenderBox> children, double maxChildExtent }) {
    addAll(children);
    _maxChildExtent = maxChildExtent;
  }

  double _maxChildExtent;
  bool _hasVisualOverflow = false;

  void setupParentData(RenderBox child) {
    if (child.parentData is! GridParentData)
      child.parentData = new GridParentData();
  }

  // getMinIntrinsicWidth() should return the minimum width that this box could
  // be without failing to render its contents within itself.
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    // We can render at any width.
    return constraints.constrainWidth(0.0);
  }

  // getMaxIntrinsicWidth() should return the smallest width beyond which
  // increasing the width never decreases the height.
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    double maxWidth = childCount * _maxChildExtent;
    return constraints.constrainWidth(maxWidth);
  }

  // getMinIntrinsicHeight() should return the minimum height that this box could
  // be without failing to render its contents within itself.
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    double desiredHeight = _computeMetrics().size.height;
    return constraints.constrainHeight(desiredHeight);
  }

  // getMaxIntrinsicHeight should return the smallest height beyond which
  // increasing the height never decreases the width.
  // If the layout algorithm used is width-in-height-out, i.e. the height
  // depends on the width and not vice versa, then this will return the same
  // as getMinIntrinsicHeight().
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return getMinIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  GridMetrics _computeMetrics() {
    return new GridMetrics(
      width: constraints.maxWidth,
      childCount: childCount,
      childExtent: _maxChildExtent
    );
  }

  void performLayout() {
    // We could shrink-wrap our contents when infinite, but for now we don't.
    assert(constraints.maxWidth < double.INFINITY);
    GridMetrics metrics = _computeMetrics();
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
      child.parentData.position = new Point(x, y);

      column += 1;
      if (column >= metrics.childrenPerRow) {
        row += 1;
        column = 0;
      }
      child = child.parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow) {
      context.canvas.save();
      context.canvas.clipRect(offset & size);
      defaultPaint(context, offset);
      context.canvas.restore();
    } else {
      defaultPaint(context, offset);
    }
  }
}
