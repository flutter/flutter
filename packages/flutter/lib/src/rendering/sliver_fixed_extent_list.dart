// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

/// A sliver that contains multiple box children that have the same extent in
/// the main axis.
///
/// [RenderSliverFixedExtentBoxAdaptor] places its children in a linear array
/// along the main axis. Each child is forced to have the [itemExtent] in the
/// main axis and the [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// Subclasses should override [itemExtent] to control the size of the children
/// in the main axis. For a concrete subclass with a configurable [itemExtent],
/// see [RenderSliverFixedExtentList].
///
/// [RenderSliverFixedExtentBoxAdaptor] is more efficient than
/// [RenderSliverList] because [RenderSliverFixedExtentBoxAdaptor] does not need
/// to perform layout on its children to obtain their extent in the main axis.
///
/// See also:
///
///  * [RenderSliverFixedExtentList], which has a configurable [itemExtent].
///  * [RenderSliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [RenderSliverFillRemaining], which determines the [itemExtent] based on
///    [SliverConstraints.remainingPaintExtent].
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
abstract class RenderSliverFixedExtentBoxAdaptor extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that contains multiple box children that have the same
  /// extent in the main axis.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverFixedExtentBoxAdaptor({
    @required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  /// The main-axis extent of each item.
  double get itemExtent;

  /// The layout offset for the child with the given index.
  ///
  /// This function is given the [itemExtent] as an argument to avoid
  /// recomputing [itemExtent] repeatedly during layout.
  ///
  /// By default, places the children in order, without gaps, starting from
  /// layout offset zero.
  @protected
  double indexToLayoutOffset(double itemExtent, int index) => itemExtent * index;

  /// The minimum child index that is visible at the given scroll offset.
  ///
  /// This function is given the [itemExtent] as an argument to avoid
  /// recomputing [itemExtent] repeatedly during layout.
  ///
  /// By default, returns a value consistent with the children being placed in
  /// order, without gaps, starting from layout offset zero.
  @protected
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0 ? math.max(0, scrollOffset ~/ itemExtent) : 0;
  }

  /// The maximum child index that is visible at the given scroll offset.
  ///
  /// This function is given the [itemExtent] as an argument to avoid
  /// recomputing [itemExtent] repeatedly during layout.
  ///
  /// By default, returns a value consistent with the children being placed in
  /// order, without gaps, starting from layout offset zero.
  @protected
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0 ? math.max(0, (scrollOffset / itemExtent).ceil() - 1) : 0;
  }

  /// Called to estimate the total scrollable extents of this object.
  ///
  /// Must return the total distance from the start of the child with the
  /// earliest possible index to the end of the child with the last possible
  /// index.
  ///
  /// By default, defers to [RenderSliverBoxChildManager.estimateMaxScrollOffset].
  ///
  /// See also:
  ///
  ///  * [computeMaxScrollOffset], which is similar but must provide a precise
  ///    value.
  @protected
  double estimateMaxScrollOffset(SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    return childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );
  }

  /// Called to obtain a precise measure of the total scrollable extents of this
  /// object.
  ///
  /// Must return the precise total distance from the start of the child with
  /// the earliest possible index to the end of the child with the last possible
  /// index.
  ///
  /// This is used when no child is available for the index corresponding to the
  /// current scroll offset, to determine the precise dimensions of the sliver.
  /// It must return a precise value. It will not be called if the
  /// [childManager] returns an infinite number of children for positive
  /// indices.
  ///
  /// By default, multiplies the [itemExtent] by the number of children reported
  /// by [RenderSliverBoxChildManager.childCount].
  ///
  /// See also:
  ///
  ///  * [estimateMaxScrollOffset], which is similar but may provide inaccurate
  ///    values.
  @protected
  double computeMaxScrollOffset(SliverConstraints constraints, double itemExtent) {
    return childManager.childCount * itemExtent;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double itemExtent = this.itemExtent;

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final BoxConstraints childConstraints = constraints.asBoxConstraints(
      minExtent: itemExtent,
      maxExtent: itemExtent,
    );

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, itemExtent);
    final int targetLastIndex = targetEndScrollOffset.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffset, itemExtent) : null;

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount);
      final int trailingGarbage = targetLastIndex == null ? 0 : (oldLastIndex - targetLastIndex).clamp(0, childCount);
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, layoutOffset: indexToLayoutOffset(itemExtent, firstIndex))) {
        // There are either no children, or we are past the end of all our children.
        final double max = computeMaxScrollOffset(constraints, itemExtent);
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final RenderBox child = insertAndLayoutLeadingChild(childConstraints);
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: index * itemExtent);
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = indexToLayoutOffset(itemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild.layout(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData = firstChild.parentData;
      childParentData.layoutOffset = indexToLayoutOffset(itemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    while (targetLastIndex == null || indexOf(trailingChildWithLayout) < targetLastIndex) {
      RenderBox child = childAfter(trailingChildWithLayout);
      if (child == null) {
        child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = indexToLayoutOffset(itemExtent, childParentData.index);
    }

    final int lastIndex = indexOf(lastChild);
    final double leadingScrollOffset = indexToLayoutOffset(itemExtent, firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(itemExtent, lastIndex + 1);

    assert(firstIndex == 0 || childScrollOffset(firstChild) <= scrollOffset);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedMaxScrollOffset = estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;
    final int targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, itemExtent) : null;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint)
        || constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == trailingScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}

/// A sliver that places multiple box children with the same main axis extent in
/// a linear array.
///
/// [RenderSliverFixedExtentList] places its children in a linear array along
/// the main axis starting at offset zero and without gaps. Each child is forced
/// to have the [itemExtent] in the main axis and the
/// [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// [RenderSliverFixedExtentList] is more efficient than [RenderSliverList]
/// because [RenderSliverFixedExtentList] does not need to perform layout on its
/// children to obtain their extent in the main axis.
///
/// See also:
///
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [RenderSliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [RenderSliverFillRemaining], which determines the [itemExtent] based on
///    [SliverConstraints.remainingPaintExtent].
class RenderSliverFixedExtentList extends RenderSliverFixedExtentBoxAdaptor {
  /// Creates a sliver that contains multiple box children that have a given
  /// extent in the main axis.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverFixedExtentList({
    @required RenderSliverBoxChildManager childManager,
    double itemExtent,
  }) : _itemExtent = itemExtent, super(childManager: childManager);

  @override
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    if (_itemExtent == value)
      return;
    _itemExtent = value;
    markNeedsLayout();
  }
}
