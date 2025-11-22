// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'sliver_fill.dart';
/// @docImport 'sliver_list.dart';
library;

import 'dart:collection';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/indexed_scroll_controller.dart';
import 'package:flutter/src/widgets/scroll_position.dart';

/// A sliver that contains multiple box children that have the explicit extent in
/// the main axis.
///
/// [RenderSliverFixedExtentBoxAdaptor] places its children in a linear array
/// along the main axis. Each child is forced to have the returned value of [itemExtentBuilder]
/// when the [itemExtentBuilder] is non-null or the [itemExtent] when [itemExtentBuilder]
/// is null in the main axis and the [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// Subclasses should override [itemExtent] or [itemExtentBuilder] to control
/// the size of the children in the main axis. For a concrete subclass with a
/// configurable [itemExtent], see [RenderSliverFixedExtentList] or [RenderSliverVariedExtentList].
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
  RenderSliverFixedExtentBoxAdaptor({required super.childManager});

  /// The main-axis extent of each item.
  ///
  /// If this is non-null, the [itemExtentBuilder] must be null.
  /// If this is null, the [itemExtentBuilder] must be non-null.
  double? get itemExtent;

  /// The main-axis extent builder of each item.
  ///
  /// If this is non-null, the [itemExtent] must be null.
  /// If this is null, the [itemExtent] must be non-null.
  ItemExtentBuilder? get itemExtentBuilder => null;

  /// The layout offset for the child with the given index.
  ///
  /// This function uses the returned value of [itemExtentBuilder] or the
  /// [itemExtent] to avoid recomputing item size repeatedly during layout.
  ///
  /// By default, places the children in order, without gaps, starting from
  /// layout offset zero.
  @visibleForTesting
  @protected
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.',
    )
    double itemExtent,
    int index,
  ) {
    if (itemExtentBuilder == null) {
      itemExtent = this.itemExtent!;
      return itemExtent * index;
    } else {
      double offset = 0.0;
      double? itemExtent;
      for (int i = 0; i < index; i++) {
        final int? childCount = childManager.estimatedChildCount;
        if (childCount != null && i > childCount - 1) {
          break;
        }
        itemExtent = itemExtentBuilder!(i, _currentLayoutDimensions);
        if (itemExtent == null) {
          break;
        }
        offset += itemExtent;
      }
      return offset;
    }
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
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.',
    )
    double itemExtent,
  ) {
    if (itemExtentBuilder == null) {
      itemExtent = this.itemExtent!;
      if (itemExtent > 0.0) {
        final double actual = scrollOffset / itemExtent;
        final int round = actual.round();
        if ((actual * itemExtent - round * itemExtent).abs() < precisionErrorTolerance) {
          return round;
        }
        return actual.floor();
      }
      return 0;
    } else {
      return _getChildIndexForScrollOffset(scrollOffset, itemExtentBuilder!);
    }
  }

  /// The maximum child index that is visible at the given scroll offset.
  ///
  /// This function uses the returned value of [itemExtentBuilder] or the
  /// [itemExtent] to avoid recomputing item size repeatedly during layout.
  ///
  /// By default, returns a value consistent with the children being placed in
  /// order, without gaps, starting from layout offset zero.
  @visibleForTesting
  @protected
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.',
    )
    double itemExtent,
  ) {
    if (itemExtentBuilder == null) {
      itemExtent = this.itemExtent!;
      if (itemExtent > 0.0) {
        final double actual = scrollOffset / itemExtent - 1;
        final int round = actual.round();
        if ((actual * itemExtent - round * itemExtent).abs() < precisionErrorTolerance) {
          return math.max(0, round);
        }
        return math.max(0, actual.ceil());
      }
      return 0;
    } else {
      return _getChildIndexForScrollOffset(scrollOffset, itemExtentBuilder!);
    }
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
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
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
  /// If [itemExtentBuilder] is null, multiplies the [itemExtent] by the number
  /// of children reported by [RenderSliverBoxChildManager.childCount].
  /// If [itemExtentBuilder] is non-null, sum the extents of the first
  /// [RenderSliverBoxChildManager.childCount] children.
  ///
  /// See also:
  ///
  ///  * [estimateMaxScrollOffset], which is similar but may provide inaccurate
  ///    values.
  @visibleForTesting
  @protected
  double computeMaxScrollOffset(
    SliverConstraints constraints,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.',
    )
    double itemExtent,
  ) {
    if (itemExtentBuilder == null) {
      itemExtent = this.itemExtent!;
      return childManager.childCount * itemExtent;
    } else {
      double offset = 0.0;
      double? itemExtent;
      for (int i = 0; i < childManager.childCount; i++) {
        itemExtent = itemExtentBuilder!(i, _currentLayoutDimensions);
        if (itemExtent == null) {
          break;
        }
        offset += itemExtent;
      }
      return offset;
    }
  }

  int _getChildIndexForScrollOffset(double scrollOffset, ItemExtentBuilder callback) {
    if (scrollOffset == 0.0) {
      return 0;
    }
    double position = 0.0;
    int index = 0;
    double? itemExtent;
    while (position < scrollOffset) {
      final int? childCount = childManager.estimatedChildCount;
      if (childCount != null && index > childCount - 1) {
        break;
      }
      itemExtent = callback(index, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      position += itemExtent;
      ++index;
    }
    return index - 1;
  }

  BoxConstraints _getChildConstraints(int index) {
    double extent;
    if (itemExtentBuilder == null) {
      extent = itemExtent!;
    } else {
      extent = itemExtentBuilder!(index, _currentLayoutDimensions)!;
    }
    return constraints.asBoxConstraints(minExtent: extent, maxExtent: extent);
  }

  late SliverLayoutDimensions _currentLayoutDimensions;

  @override
  void performLayout() {
    assert(
      (itemExtent != null && itemExtentBuilder == null) ||
          (itemExtent == null && itemExtentBuilder != null),
    );
    assert(itemExtentBuilder != null || (itemExtent!.isFinite && itemExtent! >= 0));

    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    _currentLayoutDimensions = SliverLayoutDimensions(
      scrollOffset: constraints.scrollOffset,
      precedingScrollExtent: constraints.precedingScrollExtent,
      viewportMainAxisExtent: constraints.viewportMainAxisExtent,
      crossAxisExtent: constraints.crossAxisExtent,
    );
    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent)
        : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
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
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
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
        geometry = SliverGeometry(
          scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index),
        );
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (
      int index = indexOf(trailingChildWithLayout!) + 1;
      targetLastIndex == null || index <= targetLastIndex;
      ++index
    ) {
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
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent,
        childParentData.index!,
      );
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(
      deprecatedExtraItemExtent,
      lastIndex + 1,
    );

    assert(
      firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance,
    );
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

    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent)
        : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow:
          (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
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
  RenderSliverFixedExtentList({required super.childManager, required double itemExtent})
    : _itemExtent = itemExtent;

  @override
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    if (_itemExtent == value) {
      return;
    }
    _itemExtent = value;
    markNeedsLayout();
  }
}

/// A sliver that places multiple box children with the corresponding main axis extent in
/// a linear array.
class RenderSliverVariedExtentList extends RenderSliverFixedExtentBoxAdaptor {
  /// Creates a sliver that contains multiple box children that have a explicit
  /// extent in the main axis.
  RenderSliverVariedExtentList({
    required super.childManager,
    required ItemExtentBuilder itemExtentBuilder,
  }) : _itemExtentBuilder = itemExtentBuilder;

  @override
  ItemExtentBuilder get itemExtentBuilder => _itemExtentBuilder;
  ItemExtentBuilder _itemExtentBuilder;
  set itemExtentBuilder(ItemExtentBuilder value) {
    if (_itemExtentBuilder == value) {
      return;
    }
    _itemExtentBuilder = value;
    markNeedsLayout();
  }

  @override
  double? get itemExtent => null;
}

class RenderSliverIndexedVariedExtentList extends RenderSliverMultiBoxAdaptor {
  RenderSliverIndexedVariedExtentList({
    required super.childManager,
    required ItemExtentBuilder itemExtentBuilder,
    required ItemPositionsListener itemPositionsListener,
    required SliverIndexAnchor anchor,
    required IndexedScrollAPI api,
  }) : _itemExtentBuilder = itemExtentBuilder,
       _itemPositionsListener = itemPositionsListener,
       _anchor = anchor,
       _api = api;

  IndexedScrollAPI _api;

  final Map<int, double> _offsetCache = HashMap();
  final Map<int, double> _extentCache = HashMap();
  double _lastCumulativeOffset = 0.0;
  int _lastCachedIndex = -1;
  bool _needsCorrection = false;
  double _precedingScrollExtent = 0.0;

  SliverIndexAnchor _anchor;
  SliverIndexAnchor get anchor => _anchor;
  set anchor(SliverIndexAnchor value) {
    if (_anchor == value) return;
    _anchor = value;
  }

  set api(IndexedScrollAPI api) {
    _api = api;
  }

  ItemPositionsListener _itemPositionsListener;
  ItemPositionsListener get itemPositionsListener => _itemPositionsListener;
  set itemPositionsListener(ItemPositionsListener value) {
    if (_itemPositionsListener == value) return;
    _itemPositionsListener = value;
  }

  ItemExtentBuilder get itemExtentBuilder => _itemExtentBuilder;
  ItemExtentBuilder _itemExtentBuilder;
  set itemExtentBuilder(ItemExtentBuilder value) {
    if (_itemExtentBuilder == value) return;
    _itemExtentBuilder = value;
    _needsCorrection = true;
    markNeedsLayout();
  }

  double get precedingScrollExtent => _precedingScrollExtent;
  void _clearExtentsCache() {
    _offsetCache.clear();
    _extentCache.clear();
    _lastCachedIndex = -1;
    _lastCumulativeOffset = 0.0;
  }

  double? getExtentForIndex(int index) => _getExtentForIndex(index);
  double? getOffsetForIndex(int index) => _getOffsetForIndex(index);
  double? _getExtentForIndex(int index) {
    if (_extentCache.containsKey(index)) return _extentCache[index];
    final SliverLayoutDimensions layoutDimensions = _currentLayoutDimensions ?? _layoutDimensions;
    final double? extent = itemExtentBuilder(index, layoutDimensions);
    if (extent != null) _extentCache[index] = extent;
    return extent;
  }

  double? _getOffsetForIndex(int index) {
    if (index < 0) return 0.0;
    if (_offsetCache.containsKey(index)) return _offsetCache[index];
    if (index < _lastCachedIndex) _clearExtentsCache();
    if (_lastCachedIndex == -1) {
      _offsetCache[0] = 0.0;
      _lastCachedIndex = 0;
    }
    for (int i = _lastCachedIndex; i < index; i++) {
      final double? extent = _getExtentForIndex(i);
      if (extent == null) return null;
      _lastCumulativeOffset += extent;
      _offsetCache[i + 1] = _lastCumulativeOffset;
    }
    _lastCachedIndex = math.max(_lastCachedIndex, index);
    return _offsetCache[index];
  }

  SliverLayoutDimensions? _currentLayoutDimensions;
  SliverLayoutDimensions get _layoutDimensions => SliverLayoutDimensions(
    scrollOffset: constraints.scrollOffset,
    precedingScrollExtent: constraints.precedingScrollExtent,
    viewportMainAxisExtent: constraints.viewportMainAxisExtent,
    crossAxisExtent: constraints.crossAxisExtent,
  );
  double indexToLayoutOffset(int index) => _getOffsetForIndex(index) ?? 0.0;

  int getChildIndexForScrollOffset(double scrollOffset) {
    if (scrollOffset <= 0.0) {
      return 0;
    }

    double position = 0.0;
    int index = 0;

    while (true) {
      final double? extent = _getExtentForIndex(index);
      // If we can't get an extent, we've reached the end of the list.
      if (extent == null) {
        final int? childCount = childManager.estimatedChildCount;
        if (childCount != null) {
          return (childCount - 1).clamp(0, childCount);
        }
        return index > 0 ? index - 1 : 0;
      }

      final double nextPosition = position + extent;
      // If the next item's starting edge is past our scroll offset,
      // then the current item is the one we are looking for.
      if (nextPosition > scrollOffset) {
        return index;
      }

      final int? childCount = childManager.estimatedChildCount;
      if (childCount != null && index + 1 >= childCount) {
        return index;
      }

      position = nextPosition;
      index++;
    }
  }

  int getMinChildIndexForScrollOffset(double scrollOffset) =>
      getChildIndexForScrollOffset(scrollOffset);
  int getMaxChildIndexForScrollOffset(double scrollOffset) =>
      getChildIndexForScrollOffset(scrollOffset);

  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) => childManager.estimateMaxScrollOffset(
    constraints,
    firstIndex: firstIndex,
    lastIndex: lastIndex,
    leadingScrollOffset: leadingScrollOffset,
    trailingScrollOffset: trailingScrollOffset,
  );
  double computeMaxScrollOffset(SliverConstraints constraints) =>
      _getOffsetForIndex(childManager.childCount) ?? 0.0;
  BoxConstraints _getChildConstraints(int index) {
    final double extent = _getExtentForIndex(index)!;
    return constraints.asBoxConstraints(minExtent: extent, maxExtent: extent);
  }

  @override
  void performLayout() {
    _precedingScrollExtent = this.constraints.precedingScrollExtent;

    if (_needsCorrection) {
      final double? oldOffset = getOffsetForIndex(anchor.index);
      final double? oldExtent = getExtentForIndex(anchor.index);
      final double? oldAnchorPointInSliver = (oldOffset != null && oldExtent != null)
          ? oldOffset + oldExtent * anchor.alignment
          : null;

      _clearExtentsCache();

      if (oldAnchorPointInSliver != null) {
        final double? newOffset = getOffsetForIndex(anchor.index);
        final double? newExtent = getExtentForIndex(anchor.index);
        final double? newAnchorPointInSliver = (newOffset != null && newExtent != null)
            ? newOffset + newExtent * anchor.alignment
            : null;

        if (newAnchorPointInSliver != null) {
          final double scrollOffsetCorrection = newAnchorPointInSliver - oldAnchorPointInSliver;
          if (scrollOffsetCorrection.abs() > precisionErrorTolerance) {
            geometry = SliverGeometry(scrollOffsetCorrection: scrollOffsetCorrection);
            _needsCorrection = false;
            return;
          }
        }
      }
    }

    _needsCorrection = false;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    final SliverConstraints constraints = this.constraints;
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    final double remainingExtent = constraints.remainingCacheExtent;
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    _currentLayoutDimensions = _layoutDimensions;
    final List<SliverIndexedItemPosition> visiblePositions = <SliverIndexedItemPosition>[];

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset);
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset)
        : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, layoutOffset: indexToLayoutOffset(firstIndex))) {
        final double max = (firstIndex <= 0) ? 0.0 : computeMaxScrollOffset(constraints);
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
        childManager.didFinishLayout();
        _itemPositionsListener.positionsNotifier.value = <SliverIndexedItemPosition>[];
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(_getChildConstraints(index));
      if (child == null) {
        geometry = SliverGeometry(scrollOffsetCorrection: indexToLayoutOffset(index));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(firstIndex);
      trailingChildWithLayout = firstChild;
    }

    for (
      int index = indexOf(trailingChildWithLayout!) + 1;
      targetLastIndex == null || index <= targetLastIndex;
      ++index
    ) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(_getChildConstraints(index), after: trailingChildWithLayout);
        if (child == null) break;
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(childParentData.index!);
    }

    // Get the obstruction from preceding slivers (e.g., a pinned app bar).
    double obstruction = 0.0;
    final RenderObject? parentViewport = parent;
    if (parentViewport is RenderViewportBase) {
      // ignore: invalid_use_of_protected_member
      obstruction = parentViewport.maxScrollObstructionExtentBefore(this);
    }

    final double effectivePaintExtent = math.max(
      0.0,
      constraints.remainingPaintExtent - obstruction,
    );

    RenderBox? currentChild = firstChild;
    while (currentChild != null) {
      final SliverMultiBoxAdaptorParentData childParentData =
          currentChild.parentData! as SliverMultiBoxAdaptorParentData;
      final double mainAxisExtent = _getExtentForIndex(childParentData.index!)!;

      final double itemOffsetFromScrollableArea =
          childParentData.layoutOffset! - constraints.scrollOffset;

      final double itemOffsetFromVisibleArea = itemOffsetFromScrollableArea - obstruction;

      if (effectivePaintExtent > 0) {
        final double itemLeadingEdge = itemOffsetFromVisibleArea / effectivePaintExtent;
        final double itemTrailingEdge =
            (itemOffsetFromVisibleArea + mainAxisExtent) / effectivePaintExtent;

        if (itemLeadingEdge < 1.0 && itemTrailingEdge > 0.0) {
          visiblePositions.add(
            SliverIndexedItemPosition(
              index: childParentData.index!,
              itemLeadingEdge: itemLeadingEdge,
              itemTrailingEdge: itemTrailingEdge,
            ),
          );
        }
      }

      currentChild = childAfter(currentChild);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(lastIndex + 1);

    final int? totalChildCount = childManager.estimatedChildCount;
    final double accurateMaxScrollOffset = (totalChildCount != null && totalChildCount > 0)
        ? (_getOffsetForIndex(totalChildCount) ?? trailingScrollOffset)
        : trailingScrollOffset;

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
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint)
        : null;

    geometry = SliverGeometry(
      scrollExtent: accurateMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: accurateMaxScrollOffset,
      hasVisualOverflow:
          (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    if (accurateMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }

    visiblePositions.sort(
      (SliverIndexedItemPosition a, SliverIndexedItemPosition b) => a.index.compareTo(b.index),
    );
    if (!const IterableEquality().equals(
      visiblePositions,
      _itemPositionsListener.positionsNotifier.value,
    )) {
      _itemPositionsListener.positionsNotifier.value = visiblePositions;
    }

    _currentLayoutDimensions = null;
    childManager.didFinishLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData) {
      child.parentData = SliverMultiBoxAdaptorParentData();
    }
  }

  double? _calculateTargetScrollOffset(int index, double alignment) {
    final double viewportDimension = constraints.viewportMainAxisExtent;
    final double sliverStartOffset = precedingScrollExtent;

    final double? itemOffsetInSliver = getOffsetForIndex(index);
    if (itemOffsetInSliver == null) return null;

    final double? itemExtent = getExtentForIndex(index);
    if (itemExtent == null) return null;

    final double alignmentOffset = (viewportDimension - itemExtent) * alignment;

    double targetScrollOffset = sliverStartOffset + itemOffsetInSliver - alignmentOffset;

    final RenderObject? parentViewport = parent;
    if (parentViewport is RenderViewportBase) {
      final double obstruction = parentViewport
          // ignore: invalid_use_of_protected_member
          .maxScrollObstructionExtentBefore(this);
      final double obstructionAdjustment = obstruction * (1.0 - alignment);
      targetScrollOffset -= obstructionAdjustment;
    }

    return targetScrollOffset;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _api.calculateTargetOffset = (int index, double alignment) {
      final double? offset = _calculateTargetScrollOffset(index, alignment);
      if (offset != null &&
          _api is IndexedScrollController &&
          (_api as IndexedScrollController).hasClients) {
        final ScrollPosition position = (_api as IndexedScrollController).position;
        return offset.clamp(position.minScrollExtent, position.maxScrollExtent);
      }
      return offset;
    };
  }

  @override
  void detach() {
    _api.calculateTargetOffset = (_, __) {
      debugPrint(
        'Warning: Tried to scroll to an index on a detached SliverIndexedVariedExtentList.',
      );
      return null;
    };
    super.detach();
  }
}
