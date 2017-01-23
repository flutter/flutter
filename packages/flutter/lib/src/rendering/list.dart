// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

/// Parent data for use with [RenderList].
class ListParentData extends ContainerBoxParentDataMixin<RenderBox> { }

/// A linear layout of children intended for use as a virtual viewport.
///
/// Children are layout out in order along the main axis. If [itemExtent] is
/// non-null, each child is required to have exactly [itemExtent] extent in the
/// main axis. If [itemExtent] is null, each child is required to have the same
/// extent in the main axis as the list itself.
///
/// In the cross axis, the render list expands to fill the available space and
/// each child is required to have the same extent in the cross axis as the list
/// itself.
class RenderList extends RenderVirtualViewport<ListParentData> {
  /// Creates a render list.
  ///
  /// By default, the list is oriented vertically and anchored at the start.
  RenderList({
    List<RenderBox> children,
    double itemExtent,
    EdgeInsets padding,
    int virtualChildCount,
    Offset paintOffset: Offset.zero,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    LayoutCallback<BoxConstraints> callback
  }) : _itemExtent = itemExtent,
       _padding = padding,
       super(
         virtualChildCount: virtualChildCount,
         paintOffset: paintOffset,
         mainAxis: mainAxis,
         anchor: anchor,
         callback: callback
       ) {
    addAll(children);
  }

  /// The main-axis extent of each item in the list.
  ///
  /// If [itemExtent] is null, the items are required to match the main-axis
  /// extent of the list itself.
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent (double newValue) {
    if (_itemExtent == newValue)
      return;
    _itemExtent = newValue;
    markNeedsLayout();
  }

  /// The amount of space by which to inset the children inside the list.
  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding (EdgeInsets newValue) {
    if (_padding == newValue)
      return;
    _padding = newValue;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ListParentData)
      child.parentData = new ListParentData();
  }

  double get _preferredExtent {
    if (itemExtent == null)
      return double.INFINITY;
    final int count = virtualChildCount;
    if (count == null)
      return double.INFINITY;
    double extent = itemExtent * count;
    if (padding != null)
      extent += padding.along(mainAxis);
    return extent;
  }

  double _computeIntrinsicWidth() {
    switch (mainAxis) {
      case Axis.vertical:
        assert(debugThrowIfNotCheckingIntrinsics());
        return 0.0;
      case Axis.horizontal:
        final double width = _preferredExtent;
        if (width.isFinite)
          return width;
        assert(debugThrowIfNotCheckingIntrinsics());
        return 0.0;
    }
    assert(mainAxis != null);
    return null;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicWidth();
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicWidth();
  }

  double _computeIntrinsicHeight() {
    switch (mainAxis) {
      case Axis.vertical:
        final double height = _preferredExtent;
        if (height.isFinite)
          return height;
        assert(debugThrowIfNotCheckingIntrinsics());
        return 0.0;
      case Axis.horizontal:
        assert(debugThrowIfNotCheckingIntrinsics());
        return 0.0;
    }
    assert(mainAxis != null);
    return null;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight();
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight();
  }

  @override
  void performLayout() {
    switch (mainAxis) {
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
      invokeLayoutCallback<BoxConstraints>(callback);

    double itemWidth;
    double itemHeight;

    double x = 0.0;
    double dx = 0.0;

    double y = 0.0;
    double dy = 0.0;

    switch (mainAxis) {
      case Axis.vertical:
        itemWidth = math.max(0.0, size.width - (padding == null ? 0.0 : padding.horizontal));
        itemHeight = itemExtent ?? size.height;
        x = padding != null ? padding.left : 0.0;
        dy = itemHeight;
        break;
      case Axis.horizontal:
        itemWidth = itemExtent ?? size.width;
        itemHeight = math.max(0.0, size.height - (padding == null ? 0.0 : padding.vertical));
        y = padding != null ? padding.top : 0.0;
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
