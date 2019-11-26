// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_fixed_extent_list.dart';
import 'sliver_multi_box_adaptor.dart';

/// A sliver that contains multiple box children that each fill the viewport.
///
/// [RenderSliverFillViewport] places its children in a linear array along the
/// main axis. Each child is sized to fill the viewport, both in the main and
/// cross axis. A [viewportFraction] factor can be provided to size the children
/// to a multiple of the viewport's main axis dimension (typically a fraction
/// less than 1.0).
///
/// See also:
///
///  * [RenderSliverFillRemaining], which sizes the children based on the
///    remaining space rather than the viewport itself.
///  * [RenderSliverFixedExtentList], which has a configurable [itemExtent].
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
class RenderSliverFillViewport extends RenderSliverFixedExtentBoxAdaptor {
  /// Creates a sliver that contains multiple box children that each fill the
  /// viewport.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverFillViewport({
    @required RenderSliverBoxChildManager childManager,
    double viewportFraction = 1.0,
  }) : assert(viewportFraction != null),
       assert(viewportFraction > 0.0),
       _viewportFraction = viewportFraction,
       super(childManager: childManager);

  @override
  double get itemExtent => constraints.viewportMainAxisExtent * viewportFraction;

  /// The fraction of the viewport that each child should fill in the main axis.
  ///
  /// If this fraction is less than 1.0, more than one child will be visible at
  /// once. If this fraction is greater than 1.0, each child will be larger than
  /// the viewport in the main axis.
  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double value) {
    assert(value != null);
    if (_viewportFraction == value)
      return;
    _viewportFraction = value;
    markNeedsLayout();
  }

  double get _padding => (1.0 - viewportFraction) * constraints.viewportMainAxisExtent * 0.5;

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    return _padding + super.indexToLayoutOffset(itemExtent, index);
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return super.getMinChildIndexForScrollOffset(math.max(scrollOffset - _padding, 0.0), itemExtent);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return super.getMaxChildIndexForScrollOffset(math.max(scrollOffset - _padding, 0.0), itemExtent);
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    final double padding = _padding;
    return childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset - padding,
      trailingScrollOffset: trailingScrollOffset - padding,
    ) + padding + padding;
  }
}

/// A sliver that contains a single box child that fills the remaining space in
/// the viewport.
///
/// [RenderSliverFillRemaining] sizes its child to fill the viewport in the
/// cross axis and to fill the remaining space in the viewport in the main axis.
///
/// Typically this will be the last sliver in a viewport, since (by definition)
/// there is never any room for anything beyond this sliver.
///
/// See also:
///
///  * [RenderSliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [RenderSliverList], which shows a list of variable-sized children in a
///    viewport.
class RenderSliverFillRemaining extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox] which is sized to fit
  /// the remaining space in the viewport.
  RenderSliverFillRemaining({
    RenderBox child,
    this.hasScrollBody = true,
    this.fillOverscroll = false,
  }) : assert(hasScrollBody != null),
       super(child: child);

  /// Indicates whether the child has a scrollable body, this value cannot be
  /// null.
  ///
  /// Defaults to true such that the child will extend beyond the viewport and
  /// scroll, as seen in [NestedScrollView].
  ///
  /// Setting this value to false will allow the child to fill the remainder of
  /// the viewport and not extend further. However, if the
  /// [precedingScrollExtent] exceeds the size of the viewport, the sliver will
  /// defer to the child's size rather than overriding it.
  bool hasScrollBody;

  /// Indicates whether the child should stretch to fill the overscroll area
  /// created by certain scroll physics, such as iOS' default scroll physics.
  /// This value cannot be null. This flag is only relevant when the
  /// [hasScrollBody] value is false.
  ///
  /// Defaults to false, meaning the default behavior is for the child to
  /// maintain its size and not extend into the overscroll area.
  bool fillOverscroll;

  @override
  void performLayout() {
    double childExtent;
    double extent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
    double maxExtent = constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);

    if (hasScrollBody) {
      extent = maxExtent;
      if (child != null)
        child.layout(
          constraints.asBoxConstraints(
            minExtent: extent,
            maxExtent: extent,
          ),
          parentUsesSize: true,
        );
    } else if (child != null) {
      switch (constraints.axis) {
        case Axis.horizontal:
          childExtent = child.getMaxIntrinsicWidth(constraints.crossAxisExtent);
          break;
        case Axis.vertical:
          childExtent = child.getMaxIntrinsicHeight(constraints.crossAxisExtent);
          break;
      }

      if (constraints.precedingScrollExtent > constraints.viewportMainAxisExtent || childExtent > extent)
        extent = childExtent;
      if (maxExtent < extent)
        maxExtent = extent;
      if ((fillOverscroll ? maxExtent : extent) > childExtent) {
        child.layout(
          constraints.asBoxConstraints(
            minExtent: extent,
            maxExtent: fillOverscroll ? maxExtent : extent,
          ),
          parentUsesSize: true,
        );
      } else {
        child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
      }
    }

    assert(extent.isFinite,
      'The calculated extent for the child of SliverFillRemaining is not finite.'
        'This can happen if the child is a scrollable, in which case, the'
        'hasScrollBody property of SliverFillRemaining should not be set to'
        'false.',
    );
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: hasScrollBody ? constraints.viewportMainAxisExtent : extent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}
