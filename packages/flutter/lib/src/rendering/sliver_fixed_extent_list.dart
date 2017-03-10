// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

abstract class RenderSliverFixedExtentBoxAdaptor extends RenderSliverMultiBoxAdaptor {
  RenderSliverFixedExtentBoxAdaptor({
    @required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  /// The main-axis extent of each item.
  double get itemExtent;

  @protected
  double indexToScrollOffset(double itemExtent, int index) => itemExtent * index;

  @protected
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0 ? math.max(0, scrollOffset ~/ itemExtent) : 0;
  }

  @protected
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0 ? math.max(0, (scrollOffset / itemExtent).ceil() - 1) : 0;
  }

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

  @override
  void performLayout() {
    assert(childManager.debugAssertChildListLocked());
    childManager.setDidUnderflow(false);

    final double itemExtent = this.itemExtent;

    final double scrollOffset = constraints.scrollOffset;
    assert(scrollOffset >= 0.0);
    final double remainingPaintExtent = constraints.remainingPaintExtent;
    assert(remainingPaintExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingPaintExtent;

    final BoxConstraints childConstraints = constraints.asBoxConstraints(
      minExtent: itemExtent,
      maxExtent: itemExtent,
    );

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, itemExtent);
    final int targetLastIndex = getMaxChildIndexForScrollOffset(targetEndScrollOffset, itemExtent);

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount);
      final int trailingGarbage = (oldLastIndex - targetLastIndex).clamp(0, childCount);
      if (leadingGarbage + trailingGarbage > 0)
        collectGarbage(leadingGarbage, trailingGarbage);
    }

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, scrollOffset: indexToScrollOffset(itemExtent, firstIndex))) {
        // There are no children.
        geometry = SliverGeometry.zero;
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final RenderBox child = insertAndLayoutLeadingChild(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = indexToScrollOffset(itemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild.layout(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData = firstChild.parentData;
      childParentData.layoutOffset = indexToScrollOffset(itemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    while (indexOf(trailingChildWithLayout) < targetLastIndex) {
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
      childParentData.layoutOffset = indexToScrollOffset(itemExtent, childParentData.index);
    }

    final int lastIndex = indexOf(lastChild);
    final double leadingScrollOffset = indexToScrollOffset(itemExtent, firstIndex);
    final double trailingScrollOffset = indexToScrollOffset(itemExtent, lastIndex + 1);

    assert(firstIndex == 0 || childScrollOffset(firstChild) <= scrollOffset);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(lastIndex <= targetLastIndex);

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

    geometry = new SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: lastIndex >= targetLastIndex || constraints.scrollOffset > 0.0,
    );

    assert(childManager.debugAssertChildListLocked());
  }
}

class RenderSliverFixedExtentList extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverFixedExtentList({
    @required RenderSliverBoxChildManager childManager,
    double itemExtent,
  }) : _itemExtent = itemExtent, super(childManager: childManager);

  @override
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent (double value) {
    assert(value != null);
    if (_itemExtent == value)
      return;
    _itemExtent = value;
    markNeedsLayout();
  }
}

class RenderSliverFill extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverFill({
    @required RenderSliverBoxChildManager childManager,
    double viewportFraction: 1.0,
  }) : _viewportFraction = viewportFraction, super(childManager: childManager) {
    assert(viewportFraction != null);
    assert(viewportFraction > 0.0);
  }

  @override
  double get itemExtent => constraints.viewportMainAxisExtent * viewportFraction;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction (double value) {
    assert(value != null);
    if (_viewportFraction == value)
      return;
    _viewportFraction = value;
    markNeedsLayout();
  }

  double get _padding => (1.0 - viewportFraction) * constraints.viewportMainAxisExtent * 0.5;

  @override
  double indexToScrollOffset(double itemExtent, int index) {
    return _padding + super.indexToScrollOffset(itemExtent, index);
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
  double estimateMaxScrollOffset(SliverConstraints constraints, {
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
