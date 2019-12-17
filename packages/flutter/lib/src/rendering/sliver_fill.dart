// Copyright 2014 The Flutter Authors. All rights reserved.
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
}

// TODO(Piinks): This class may not be needed anymore
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
abstract class RenderSliverFillRemaining extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox] which is sized to fit
  /// the remaining space in the viewport.
  RenderSliverFillRemaining({
    RenderBox child,
  }) : super(child: child);

  /// The dimension of the child in the main axis.
  @protected
  double get childExtent {
    if (child == null)
      return 0.0;
    assert(child.hasSize);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.vertical:
        return child.size.height;
      case Axis.horizontal:
        return child.size.width;
    }
    return null;
  }
}

/// Doc
class RenderSliverFillRemainingWithScrollable extends RenderSliverFillRemaining {
  /// Doc
  RenderSliverFillRemainingWithScrollable({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    // TODO(Piinks): This may fill too much space for NestedScrollView, https://github.com/flutter/flutter/issues/46028
    final double extent = constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);

    if (child != null)
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent));

    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: constraints.viewportMainAxisExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}

/// Doc
class RenderSliverFillRemainingWithoutScrollable extends RenderSliverFillRemaining {
  /// Doc
  RenderSliverFillRemainingWithoutScrollable({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    double childExtent;
    // The remaining space in the viewportMainAxisExtent. Can be <= 0 if we have
    // scrolled beyond the extent of the screen.
    double extent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;

    if (child != null) {
      switch (constraints.axis) {
        case Axis.horizontal:
          childExtent = child.getMaxIntrinsicWidth(constraints.crossAxisExtent);
          break;
        case Axis.vertical:
          childExtent = child.getMaxIntrinsicHeight(constraints.crossAxisExtent);
          break;
      }

      // If the childExtent is greater than the computed extent, we want to use
      // that instead of potentially cutting off the child.
      extent = math.max(extent, childExtent);
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent));
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
      scrollExtent: extent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}

/// Doc
class RenderSliverFillRemainingAndOverscroll extends RenderSliverFillRemaining {
  /// Doc
  RenderSliverFillRemainingAndOverscroll({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    double childExtent;
    double extent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
    double maxExtent = constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);

    if (child != null) {
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
      if (maxExtent > childExtent)
        child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: maxExtent));
      else
        child.layout(constraints.asBoxConstraints());
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
      scrollExtent: extent,
      paintExtent: math.min(maxExtent, constraints.remainingPaintExtent),
      maxPaintExtent: math.min(maxExtent, constraints.remainingPaintExtent),
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}