// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'framework.dart';
import 'sliver.dart';

/// Assists [_RenderSliverCustomExtentList] to preform layout, offering the
/// correlative calculation about scroll offset and child index.
abstract class SliverCustomExtentListAssistant {
  /// The layout offset for the child with the given index.
  double indexToLayoutOffset(int index);

  /// The child index that locates at the given scroll offset.
  ///
  /// The most frequent given scroll offsets are:
  /// the leading edge where the cache area starts,
  /// the earliest visible edge of this sliver,
  /// the latest visible edge of this sliver,
  /// the trailing edge where the cache area ends.
  /// So the assistant implemention should consider to return the index that
  /// locates at these frequent given scroll offsets in an efficient way.
  ///
  /// Should return a negative value if no child is available for the given
  /// scroll offset, this might be the case of over scrolling.
  int getChildIndexForScrollOffset(double scrollOffset);
}

/// A sliver that places its box children of diverse custom extent in a linear
/// array along the main axis.
///
/// [SliverCustomExtentList] arranges its children in a line along the main axis
/// starting at offset zero and without gaps. Each child is constrained to the
/// [SliverConstraints.crossAxisExtent] along the cross axis while may has
/// different extent along the main axis.
///
/// [SliverCustomExtentList] can be more efficient than [SliverList] because
/// [SliverCustomExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. Instead, it uses an assistant which is
/// implemented by the caller to calculate the children's position. It's a bit
/// more flexible than [SliverFixedExtentList] and [SliverPrototypeExtentList]
/// because there's no constraint on the item extent.
///
/// See also:
///
///  * [SliverPrototypeExtentList], whose itemExtent is defined by a prototype.
///  * [SliverFixedExtentList], whose itemExtent is a pixel value.
///  * [SliverList], which shows a list of variable-sized children in a
///    viewport.
class SliverCustomExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places its box children of diverse custom extent in
  /// a linear array along the main axis, with an assistant to calculate the
  /// children's position.
  const SliverCustomExtentList({
    Key? key,
    required SliverChildDelegate delegate,
    required this.extentAssistant,
  }) : assert(extentAssistant != null),
       super(key: key, delegate: delegate);

  /// Assist to determine the main axis extent of every children of this sliver.
  ///
  /// The [extentAssistant] mainly helps to carculate the child index based on
  /// the scroll offset, facilitating the layout process by locating children
  /// derectly without adjacent items.
  final SliverCustomExtentListAssistant extentAssistant;

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverCustomExtentList(childManager: element, extentAssistant: extentAssistant);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSliverCustomExtentList).extentAssistant = extentAssistant;
  }
}

class _RenderSliverCustomExtentList extends RenderSliverMultiBoxAdaptor {
  _RenderSliverCustomExtentList({
    required SliverMultiBoxAdaptorElement childManager,
    required SliverCustomExtentListAssistant extentAssistant,
  }) : _extentAssistant = extentAssistant,
       super(childManager: childManager);

  SliverCustomExtentListAssistant _extentAssistant;
  SliverCustomExtentListAssistant get extentAssistant => _extentAssistant;
  set extentAssistant(SliverCustomExtentListAssistant value) {
    assert(value != null);
    if (_extentAssistant == value)
      return;
    _extentAssistant = value;
    markNeedsLayout();
  }

  double _indexToLayoutOffset(int index) {
    if (!kReleaseMode && debugProfileSliverCustomExtentListAssistantEnabled) {
      return Timeline.timeSync<double>(
          'SliverCustomExtentListAssistant.indexToLayoutOffset',
          () => _extentAssistant.indexToLayoutOffset(index));
    }

    return _extentAssistant.indexToLayoutOffset(index);
  }

  int _getChildIndexForScrollOffset(double scrollOffset) {
    if (!kReleaseMode && debugProfileSliverCustomExtentListAssistantEnabled) {
      return Timeline.timeSync<int>(
          'SliverCustomExtentListAssistant.getChildIndexForScrollOffset',
          () => _extentAssistant.getChildIndexForScrollOffset(scrollOffset));
    }

    return _extentAssistant.getChildIndexForScrollOffset(scrollOffset);
  }

  int _calculateLeadingGarbage(int firstIndex) {
    RenderBox? walker = firstChild;
    int leadingGarbage = 0;
    while (walker != null && indexOf(walker) < firstIndex) {
      leadingGarbage += 1;
      walker = childAfter(walker);
    }
    return leadingGarbage;
  }

  int _calculateTrailingGarbage(int targetLastIndex) {
    RenderBox? walker = lastChild;
    int trailingGarbage = 0;
    while (walker != null && indexOf(walker) > targetLastIndex) {
      trailingGarbage += 1;
      walker = childBefore(walker);
    }
    return trailingGarbage;
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

    final BoxConstraints childConstraints = constraints.asBoxConstraints();

    final int firstIndex = _getChildIndexForScrollOffset(scrollOffset);
    final int firstVisibleIndex = constraints.cacheOrigin == 0.0 ? firstIndex :
        _getChildIndexForScrollOffset(constraints.scrollOffset);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
        _getChildIndexForScrollOffset(targetEndScrollOffset) : null;

    if (firstChild != null) {
      final int leadingGarbage = _calculateLeadingGarbage(firstIndex);
      final int trailingGarbage = targetLastIndex != null ? _calculateTrailingGarbage(targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double firstVisibleChildlayoutOffset = _indexToLayoutOffset(firstVisibleIndex);
      if (!addInitialChild(index: firstVisibleIndex, layoutOffset: firstVisibleChildlayoutOffset)) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    //      |---cache extent---|-----visible area-----|---cache extent---|
    //      |                  |                      |                  |
    // firstIndex      firstVisibleIndex       lastVisibleIndex      lastIndex
    // Here goes the layout strategy, for the purpose of rendering visible
    // children prior to those in cache extent:
    // 0. firstChild may locate at anywhere range from firstIndex to lastIndex,
    // or just at firstVisibleIndex in case all the items had been GC;
    // 1. insert and layout leading children previous to firstChild, back to
    // firstVisibleIndex, in a backward direction;
    // 2. insert and layout subsequent children forward until lastIndex;
    // 3. insert and layout leading children previous to firstVisibleIndex, back
    // to firstIndex, in a backward direction.

    double? layoutOffsetOfLeadingChildWithLayout;
    double? layoutOffsetOfTrailingChildWithLayout;
    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstVisibleIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: _indexToLayoutOffset(index + 1));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      // Resolved the child layout offset as long as we can by our own,
      // as that the extent assistant to calculate maybe cost time.
      childParentData.layoutOffset = layoutOffsetOfLeadingChildWithLayout == null ?
          _indexToLayoutOffset(index) : layoutOffsetOfLeadingChildWithLayout - paintExtentOf(firstChild!);
      assert((childParentData.layoutOffset! - _indexToLayoutOffset(index)).abs() < precisionErrorTolerance,
          'Layout offset of child $index resolved by _RenderSliverCustomExtentList(${childParentData.layoutOffset}) '
          'is not equal to assistant`s calculating result(${_indexToLayoutOffset(index)}).');
      assert(childParentData.index == index);
      layoutOffsetOfLeadingChildWithLayout = childParentData.layoutOffset;
      layoutOffsetOfTrailingChildWithLayout ??= childParentData.layoutOffset;
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(childConstraints, parentUsesSize: true);
      final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = _indexToLayoutOffset(indexOf(firstChild!));
      layoutOffsetOfLeadingChildWithLayout = childParentData.layoutOffset;
      layoutOffsetOfTrailingChildWithLayout = childParentData.layoutOffset;
      trailingChildWithLayout = firstChild;
    }

    assert(layoutOffsetOfLeadingChildWithLayout != null);
    assert(layoutOffsetOfTrailingChildWithLayout != null);
    assert(trailingChildWithLayout != null);

    double estimatedMaxScrollOffset = double.infinity;
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout, parentUsesSize: true);
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = layoutOffsetOfTrailingChildWithLayout! + paintExtentOf(lastChild!);
          break;
        }
      } else {
        child.layout(childConstraints, parentUsesSize: true);
      }
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = layoutOffsetOfTrailingChildWithLayout! + paintExtentOf(trailingChildWithLayout);
      assert((childParentData.layoutOffset! - _indexToLayoutOffset(index)).abs() < precisionErrorTolerance,
          'Layout offset of child $index resolved by _RenderSliverCustomExtentList(${childParentData.layoutOffset}) '
          'is not equal to assistant`s calculating result(${_indexToLayoutOffset(index)}).');
      layoutOffsetOfTrailingChildWithLayout = childParentData.layoutOffset;
      trailingChildWithLayout = child;
    }

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: _indexToLayoutOffset(index + 1));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = layoutOffsetOfLeadingChildWithLayout! - paintExtentOf(firstChild!);
      assert((childParentData.layoutOffset! - _indexToLayoutOffset(index)).abs() < precisionErrorTolerance,
          'Layout offset of child $index resolved by _RenderSliverCustomExtentList(${childParentData.layoutOffset}) '
          'is not equal to assistant`s calculating result(${_indexToLayoutOffset(index)}).');
      assert(childParentData.index == index);
      layoutOffsetOfLeadingChildWithLayout = childParentData.layoutOffset;
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = layoutOffsetOfLeadingChildWithLayout!;
    final double trailingScrollOffset = layoutOffsetOfTrailingChildWithLayout! + paintExtentOf(lastChild!);

    assert(firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance);
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
        _getChildIndexForScrollOffset(targetEndScrollOffsetForPaint) : null;
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
