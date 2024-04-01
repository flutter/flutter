// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'sliver.dart';

class SliverCarousel extends SliverMultiBoxAdaptorWidget {
  const SliverCarousel({
    super.key,
    required super.delegate,
    required this.clipExtent,
    required this.childExtentList,
  });

  final double clipExtent;
  final List<int> childExtentList;

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverCarousel(
      childManager: element,
      clipExtent: clipExtent,
      childExtentList: childExtentList,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverCarousel renderObject) {
    renderObject.clipExtent = clipExtent;
    renderObject.childExtentList = childExtentList;
  }
}

class RenderSliverCarousel extends RenderSliverMultiBoxAdaptor {
  RenderSliverCarousel({
    required super.childManager,
    required double clipExtent,
    required List<int> childExtentList,
  }) : _clipExtent = clipExtent,
       _childExtentList = childExtentList;

  double get clipExtent => _clipExtent;
  double _clipExtent;
  set clipExtent(double value) {
    if (_clipExtent == value) {
      return;
    }
    _clipExtent = value;
    markNeedsLayout();
  }

  List<int> get childExtentList => _childExtentList;
  List<int> _childExtentList;
  set childExtentList(List<int> value) {
    if (_childExtentList == value) {
      return;
    }
    _childExtentList = value;
    markNeedsLayout();
  }

  // TODO: need to handle the first and last item resizing case
  double _getChildExtent(int index) {
    double extent;
    if (_firstVisibleItemIndex == index) {
      extent = math.max(_firstVisibleItemExtent, clipExtent);
    } else if (index > _firstVisibleItemIndex
      // In this if statement, children are visible items except the first one.
      && index - _firstVisibleItemIndex + 1 <= childExtentList.length
    ) {
      assert(index - _firstVisibleItemIndex < childExtentList.length);

      extent = extentPerWeightUnit * childExtentList.elementAt(index - _firstVisibleItemIndex); // initial extent
      final int currWeight = childExtentList.elementAt(index - _firstVisibleItemIndex);
      double progress = _gapBetweenCurrentAndPrev / firstChildExtent;

      assert(index - _firstVisibleItemIndex - 1 < childExtentList.length, '$index');
      final int prevWeight = childExtentList.elementAt(index - _firstVisibleItemIndex - 1);
      final double finalIncrease = (prevWeight - currWeight) / childExtentList.max;
      extent = extent + finalIncrease * progress * maxChildExtent;
      //else {
      //   assert(index - _firstVisibleItemIndex - 1 < childExtentList.length, '$index');
      //   final int prevWeight = childExtentList.elementAt(index - _firstVisibleItemIndex - 1);
      //   final double finalIncrease = (prevWeight - currWeight) / childExtentList.max;

      //   extent = extent + finalIncrease * progress * maxChildExtent;
      // }
    } else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > childExtentList.length)
    {
      double visibleItemsTotalExtent = _firstVisibleItemExtent;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _getChildExtent(i);
      }
      extent = math.max(constraints.remainingPaintExtent - visibleItemsTotalExtent, clipExtent);
    }
    else {
      extent = math.max(minChildExtent, clipExtent);
    }

    return extent;
  }

  BoxConstraints _getChildConstraints(int index) {
    final double extent = _getChildExtent(index);
    return constraints.asBoxConstraints(
      minExtent: extent,
      maxExtent: extent,
      crossAxisExtent: 200,
    );
  }

  double get extentPerWeightUnit => constraints.remainingPaintExtent / (childExtentList.reduce((int total, int extent) => total + extent));

  double get firstChildExtent => childExtentList.first * extentPerWeightUnit;
  double get maxChildExtent => childExtentList.max * extentPerWeightUnit;
  double get mediumChildExtent {
    final List<int> sortedList = List<int>.from(childExtentList);
    sortedList.sort();
    return sortedList.elementAt(1) * extentPerWeightUnit;
  }
  double get minChildExtent => childExtentList.min * extentPerWeightUnit;

  int get _firstVisibleItemIndex => (constraints.scrollOffset / firstChildExtent).floor();
  double get _gapBetweenCurrentAndPrev => constraints.scrollOffset % firstChildExtent;
  double get _firstVisibleItemExtent => firstChildExtent - _gapBetweenCurrentAndPrev;

  /// The layout offset for the child with the given index.
  double indexToLayoutOffset(int index) {
    if (_firstVisibleItemIndex == index && firstChildExtent - _gapBetweenCurrentAndPrev > clipExtent) { // pinned
      return constraints.scrollOffset;
    } else if (_firstVisibleItemIndex == index) { // do not pin
      return firstChildExtent * index + (firstChildExtent - clipExtent);
    } else if (index > _firstVisibleItemIndex) {
      double visibleItemsTotalExtent = _firstVisibleItemExtent;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _getChildExtent(i);
      }
      return constraints.scrollOffset + visibleItemsTotalExtent;
    }

    return firstChildExtent * index;
  }

  /// The minimum child index that is visible at the given scroll offset.
  int getMinChildIndexForScrollOffset() {
    return _firstVisibleItemIndex;
  }

  /// The maximum child index that is visible at the given scroll offset.
  int getMaxChildIndexForScrollOffset() {
    final int? childCount = childManager.estimatedChildCount;
    if (childCount != null) {
      double visibleItemsTotalExtent = _firstVisibleItemExtent;
      for (int i = _firstVisibleItemIndex + 1; i < childCount; i++) {
        visibleItemsTotalExtent += _getChildExtent(i);
        if (visibleItemsTotalExtent >= constraints.remainingPaintExtent) {
          return i;
        }
      }
    }
    return childCount ?? 0;
  }


  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final int firstIndex = getMinChildIndexForScrollOffset();
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
        getMaxChildIndexForScrollOffset() : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null ? calculateTrailingGarbage(lastIndex: targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset();
        }
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(_getChildConstraints(index));
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: indexToLayoutOffset(index));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(_getChildConstraints(index), after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = indexToLayoutOffset(index);
          break;
        }
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(childParentData.index!);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(lastIndex + 1);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
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
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite ?
        getMaxChildIndexForScrollOffset() : null;

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
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  ///
  double computeMaxScrollOffset() {
    return childManager.childCount * maxChildExtent;
  }
}

enum CarouselLayout {
  /// Show carousel items with 3 sizes. Leading items have maximum size, the
  /// second to last item has medium size and the last item has minimum size.
  multiBrowse,

  /// Carousel items have same size.
  uncontained,

  /// The hero layout shows at least one large item and one small item.
  hero,

  /// The center-aligned hero layout shows at least one large item and two small items.
  centeredHero,
}
