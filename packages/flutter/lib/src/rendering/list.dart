// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

/// Parent data for use with [RenderList].
class ListParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class RenderList extends RenderVirtualViewport<ListParentData> {
  RenderList({
    List<RenderBox> children,
    double itemExtent,
    EdgeDims padding,
    int virtualChildCount,
    Offset paintOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical,
    Painter overlayPainter,
    LayoutCallback callback
  }) : _itemExtent = itemExtent,
       _padding = padding,
       super(
         virtualChildCount: virtualChildCount,
         paintOffset: paintOffset,
         scrollDirection: scrollDirection,
         overlayPainter: overlayPainter,
         callback: callback
       ) {
    addAll(children);
  }

  double get itemExtent => _itemExtent;
  double _itemExtent;
  void set itemExtent (double newValue) {
    assert(newValue != null);
    if (_itemExtent == newValue)
      return;
    _itemExtent = newValue;
    markNeedsLayout();
  }

  EdgeDims get padding => _padding;
  EdgeDims _padding;
  void set padding (EdgeDims newValue) {
    if (_padding == newValue)
      return;
    _padding = newValue;
    markNeedsLayout();
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! ListParentData)
      child.parentData = new ListParentData();
  }

  double get _scrollAxisPadding {
    switch (scrollDirection) {
      case Axis.vertical:
        return padding.vertical;
      case Axis.horizontal:
        return padding.horizontal;
    }
  }

  double get _preferredExtent {
    if (itemExtent == null)
      return double.INFINITY;
    int count = virtualChildCount;
    if (count == null)
      return double.INFINITY;
    double extent = itemExtent * count;
    if (padding != null)
      extent += _scrollAxisPadding;
    return extent;
  }

  double _getIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    switch (scrollDirection) {
      case Axis.vertical:
        return constraints.constrainWidth(0.0);
      case Axis.horizontal:
        return constraints.constrainWidth(_preferredExtent);
    }
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    switch (scrollDirection) {
      case Axis.vertical:
        return constraints.constrainHeight(_preferredExtent);
      case Axis.horizontal:
        return constraints.constrainHeight(0.0);
    }
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  void performLayout() {
    switch (scrollDirection) {
      case Axis.vertical:
        size = new Size(constraints.maxWidth,
                        constraints.constrainHeight(_preferredExtent));
        break;
      case Axis.horizontal:
        size = new Size(constraints.constrainWidth(_preferredExtent),
                        constraints.maxHeight);
        break;
    }

    if (callback != null)
      invokeLayoutCallback(callback);

    double itemWidth;
    double itemHeight;

    double x = 0.0;
    double dx = 0.0;

    double y = 0.0;
    double dy = 0.0;

    switch (scrollDirection) {
      case Axis.vertical:
        itemWidth = math.max(0, size.width - (padding == null ? 0.0 : padding.horizontal));
        itemHeight = itemExtent ?? size.height;
        y = padding != null ? padding.top : 0.0;
        dy = itemHeight;
        break;
      case Axis.horizontal:
        itemWidth = itemExtent ?? size.width;
        itemHeight = math.max(0.0, size.height - (padding == null ? 0.0 : padding.vertical));
        x = padding != null ? padding.left : 0.0;
        dx = itemWidth;
        break;
    }

    BoxConstraints innerConstraints =
        new BoxConstraints.tightFor(width: itemWidth, height: itemHeight);

    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints);

      final ListParentData childParentData = child.parentData;
      childParentData.offset = new Offset(x, y);
      x += dx;
      y += dy;

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }
}
