// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

class RenderSliverList extends RenderSliverMultiBoxAdaptor {
  RenderSliverList({
    @required RenderSliverBoxChildManager childManager,
    double itemExtent,
  }) : _itemExtent = itemExtent, super(childManager: childManager);

  /// The main-axis extent of each item in the list.
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent (double newValue) {
    assert(newValue != null);
    if (_itemExtent == newValue)
      return;
    _itemExtent = newValue;
    markNeedsLayout();
  }

  double _indexToScrollOffset(int index) => _itemExtent * index;

  @override
  void performLayout() {
    assert(debugAssertNotCurrentlyAllowingChildAdditions());
    final double scrollOffset = constraints.scrollOffset;
    assert(scrollOffset >= 0.0);
    final double remainingPaintExtent = constraints.remainingPaintExtent;
    assert(remainingPaintExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingPaintExtent;

    BoxConstraints childConstraints = constraints.asBoxConstraints(
      minExtent: itemExtent,
      maxExtent: itemExtent,
    );

    final int firstIndex = math.max(0, scrollOffset ~/ _itemExtent);
    final int targetLastIndex = math.max(0, (targetEndScrollOffset / itemExtent).ceil());

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount);
      final int trailingGarbage = (oldLastIndex - targetLastIndex).clamp(0, childCount);
      if (leadingGarbage + trailingGarbage > 0)
        collectGarbage(leadingGarbage, trailingGarbage);
    }

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, scrollOffset: _indexToScrollOffset(firstIndex))) {
        // There are no children.
        geometry = SliverGeometry.zero;
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final RenderBox child = insertAndLayoutLeadingChild(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.scrollOffset = _indexToScrollOffset(index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    assert(offsetOf(firstChild) <= scrollOffset);

    if (trailingChildWithLayout == null) {
      firstChild.layout(childConstraints);
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
      childParentData.scrollOffset = _indexToScrollOffset(childParentData.index);
    }

    final int lastIndex = indexOf(lastChild);
    final double leadingScrollOffset = _indexToScrollOffset(firstIndex);
    final double trailingScrollOffset = _indexToScrollOffset(lastIndex + 1);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = childManager.estimateScrollOffsetExtent(
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );

    final double paintedExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = new SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintedExtent,
      maxPaintExtent: estimatedTotalExtent,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: lastIndex >= targetLastIndex || constraints.scrollOffset > 0.0,
    );

    assert(debugAssertNotCurrentlyAllowingChildAdditions());
  }
}
