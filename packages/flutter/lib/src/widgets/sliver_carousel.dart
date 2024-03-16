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
    // required this.maxChildExtent,
    required this.clipExtent,
    required this.childExtentList,
  });

  // final double maxChildExtent;
  final double clipExtent;
  final List<int> childExtentList; // 比例

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverCarousel(
      childManager: element,
      // maxChildExtent: maxChildExtent,
      clipExtent: clipExtent,
      childExtentList: childExtentList,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverCarousel renderObject) {
    // renderObject.maxChildExtent = maxChildExtent;
  }
}

class RenderSliverCarousel extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverCarousel({
    required super.childManager,
    // required double maxChildExtent,
    required double clipExtent,
    required List<int> childExtentList,
  }) : _clipExtent = clipExtent,
      //  _maxChildExtent = maxChildExtent,
       _childExtentList = childExtentList;

  // double get maxChildExtent => _maxChildExtent;
  // double _maxChildExtent;
  // set maxChildExtent(double value) {
  //   if (_maxChildExtent == value) {
  //     return;
  //   }
  //   _maxChildExtent = value;
  //   markNeedsLayout();
  // }

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

  BoxConstraints _getChildConstraints(int index) {
    double extent;
    if (_firstVisibleItemIndex == index) {
      extent = _firstVisibleItemExtent;
    } else if (index > _firstVisibleItemIndex
      // Children in this if statement are visible items except the first one.
      && index - _firstVisibleItemIndex + 1 <= childExtentList.length
    ) {
      extent = eachSliceExtent * childExtentList.elementAt(index - _firstVisibleItemIndex);
      final int currentShare = childExtentList.elementAt(index - _firstVisibleItemIndex);
      final int prevShare = childExtentList.elementAt(index - _firstVisibleItemIndex - 1);
      final double finalIncrease = (currentShare - prevShare).abs() / childExtentList.max;
      final int denominator = childExtentList.max;
      final double progress = _gapBetweenCurrentAndPrev / maxChildExtent;
      // print('index: $index, finalIncrease: $finalIncrease, first item extent: $_firstVisibleItemExtent');
      // extent = math.min(extent + ((1 - numerator / denominator) * childExtentList.max) * progress, maxChildExtent);
      // print('Add delta: ${((1 - numerator / denominator) * childExtentList.max) * progress}');

      extent = extent + finalIncrease * progress * maxChildExtent;
    } else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > childExtentList.length)
    {
      double visibleItemsTotalExtent = 0;
      for (int i = _firstVisibleItemIndex; i < index; i++) {
        visibleItemsTotalExtent += _getChildConstraints(i).maxWidth;
      }
      // print('child count: $childCount visibleItemsTotalExtent: $visibleItemsTotalExtent');
      extent = constraints.remainingPaintExtent - visibleItemsTotalExtent;
    }
    else {
      extent = minChildExtent;
      // print('index: $index extent $extent');

    }
    return constraints.asBoxConstraints(
      minExtent: extent,
      maxExtent: extent,
      crossAxisExtent: 200,
    );
  }

  double get eachSliceExtent => constraints.remainingPaintExtent / (childExtentList.reduce((int total, int extent) => total + extent));
  double get maxChildExtent => childExtentList.first * eachSliceExtent;
  double get mediumChildExtent => childExtentList.elementAt(childExtentList.length - 2) * eachSliceExtent;
  double get minChildExtent => childExtentList.last * eachSliceExtent;
  int get _firstVisibleItemIndex => (constraints.scrollOffset / maxChildExtent).floor();
  double get _gapBetweenCurrentAndPrev => constraints.scrollOffset % maxChildExtent;
  double get _firstVisibleItemExtent => math.max(maxChildExtent - _gapBetweenCurrentAndPrev, clipExtent);

  int get _lastVisibleItenIndex => ((constraints.scrollOffset + constraints.viewportMainAxisExtent) / maxChildExtent).ceil() - 1;

  /// The layout offset for the child with the given index.
  ///
  /// This function uses the returned value of [itemExtentBuilder] or the
  /// [itemExtent] to avoid recomputing item size repeatedly during layout.
  ///
  /// By default, places the children in order, without gaps, starting from
  /// layout offset zero.
  @visibleForTesting
  @protected
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    assert(itemExtentBuilder == null);
      // print('first visible index: $_firstVisibleItemIndex');
  // print('getMinChildIndexForScrollOffset: ${getMinChildIndexForScrollOffset(constraints.scrollOffset + constraints.cacheOrigin, 0)}');
  // print('remaining paint extent: ${constraints.remainingPaintExtent}');
  // print('viewportMainAxisExtent: ${constraints.viewportMainAxisExtent}');
  // print('scrolloffset: ${constraints.scrollOffset}');
  // print('getMaxChildIndexForScrollOffset: ${getMaxChildIndexForScrollOffset(constraints.scrollOffset + constraints.remainingPaintExtent, 0)}');
  // print('last visible index $_lastVisibleItenIndex');
    if (_firstVisibleItemIndex == index && maxChildExtent - _gapBetweenCurrentAndPrev > clipExtent) { // pinned
      return constraints.scrollOffset;
    } else if (_firstVisibleItemIndex == index) { // do not pin
      return maxChildExtent * index + (maxChildExtent - clipExtent);
    } else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 <= childExtentList.length)
    {
      if (childExtentList.elementAt(index - _firstVisibleItemIndex) < childExtentList.max) {
        // print('========= layout info ========');
        // print('index: $index, layout offset: ${maxChildExtent * (index - 1) + _getChildConstraints(index - 1).maxWidth}, prev extent: ${_getChildConstraints(index - 1).maxWidth}');
        // print('==============================');
        return maxChildExtent * (index - 1) + _getChildConstraints(index - 1).maxWidth;
      }
    } else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > childExtentList.length)
    {
      double visibleItemsTotalExtent = 0;
      for (int i = _firstVisibleItemIndex; i < index; i++) {
        visibleItemsTotalExtent += _getChildConstraints(i).maxWidth;
      }
      // print('child count: $childCount visibleItemsTotalExtent: $visibleItemsTotalExtent');
      return constraints.scrollOffset + visibleItemsTotalExtent;
    }
    // print('in layout method - index: $index');
    return maxChildExtent * index;
  }

    /// The minimum child index that is visible at the given scroll offset.
  ///
  /// This function uses the returned value of [itemExtentBuilder] or the
  /// [itemExtent] to avoid recomputing item size repeatedly during layout.
  ///
  /// By default, returns a value consistent with the children being placed in
  /// order, without gaps, starting from layout offset zero.
  @visibleForTesting
  @protected
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    assert(itemExtentBuilder == null);
    final double childExtent = maxChildExtent;
    if (childExtent > 0.0) {
      final double actual = scrollOffset / childExtent;
      final int round = actual.round();
      if ((actual * childExtent - round * childExtent).abs() < precisionErrorTolerance) {
        return round;
      }
      return actual.floor();
    }
    return 0;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    // print('------------------------------ remainingPaintExtent: ${constraints.remainingPaintExtent} ------------------------------');

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent) : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null ? calculateTrailingGarbage(lastIndex: targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset(constraints, deprecatedExtraItemExtent);
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
        geometry = SliverGeometry(scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(_getChildConstraints(index), after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
          break;
        }
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, childParentData.index!);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex + 1);

    assert(firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
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
        getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent) : null;
print('\n------------------------------ '
'\nfirst visible index: $_firstVisibleItemIndex, '
'\nfirst visible extent: $_firstVisibleItemExtent,'
' \nmaxChildExtent: $maxChildExtent\n '
'mediumChildExtent: $mediumChildExtent\n'
'minChildExtent: $minChildExtent \n'
'last visible item: ${getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent)}\n------------------------------');
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

  @override
  double? get itemExtent => maxChildExtent;
}
