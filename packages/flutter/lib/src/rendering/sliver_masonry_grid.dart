// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

/// Controls the masonry layout of tiles.
///
/// Given the current constraints on the grid, a [SliverGridDelegate] computes
/// the masonry layout for the tiles in the grid. The tiles can be placed as masonry
/// layout with equally cross-axis sized and spaced. A contiguous sequence of children are
/// laid out after the shortest one of the previous row/column。
///
/// See also:
///
///  * [SliverMasonryGridDelegateWithFixedCrossAxisCount], which creates a masonry
///    layout with a fixed number of tiles in the cross axis.
///  * [SliverMasonryGridDelegateWithMaxCrossAxisExtent], which creates a masonry
///    layout that have a maximum cross-axis extent.
///  * [GridMasonryView], which uses this delegate to control the layout of its tiles.
///  * [SliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
///  * [RenderSliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
abstract class SliverMasonryGridDelegate {
  /// Creates a delegate that makes masonry layout with tiles in
  /// the cross axis.
  ///
  /// All of the arguments must not be null. The `mainAxisSpacing` and
  /// `crossAxisSpacing` arguments must not be negative.
  const SliverMasonryGridDelegate({
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  }) : assert(mainAxisSpacing != null && mainAxisSpacing >= 0),
       assert(crossAxisSpacing != null && crossAxisSpacing >= 0);

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// Return the offset of the child in the non-scrolling axis.
  double getCrossAxisOffset(SliverConstraints constraints, int crossAxisIndex) {
    final bool reverseCrossAxis = axisDirectionIsReversed(constraints.crossAxisDirection);
    final int crossAxisCount = getCrossAxisCount(constraints);
    final double childUsableCrossAxisExtent = getChildUsableCrossAxisExtent(constraints);
    final int actualCrossAxisIndex = (reverseCrossAxis && crossAxisCount > 1) ? crossAxisCount - 1 - crossAxisIndex : crossAxisIndex;

    return actualCrossAxisIndex % crossAxisCount * (childUsableCrossAxisExtent + crossAxisSpacing);
  }

  /// Return usable cross-axis extent of each child.
  ///
  /// It doesn't contain [crossAxisSpacing].
  double getChildUsableCrossAxisExtent(SliverConstraints constraints) {
    final int crossAxisCount = getCrossAxisCount(constraints);
    final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    return usableCrossAxisExtent / crossAxisCount;
  }

  /// Return [crossAxisCount] by [SliverMasonryGridDelegateWithFixedCrossAxisCount]
  /// and [SliverMasonryGridDelegateWithMaxCrossAxisExtent].
  int getCrossAxisCount(SliverConstraints constraints);

  /// Return true when the children need to be laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(SliverMasonryGridDelegate oldDelegate) {
    return oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing;
  }
}

/// Creates masonry layouts with a fixed number of tiles in the cross axis.
///
/// For example, if the grid is vertical, this delegate will create a layout
/// with a fixed number of columns. If the grid is horizontal, this delegate
/// will create a layout with a fixed number of rows.
///
/// This delegate creates grids with equally cross-axis sized and spaced tiles.
///
/// See also:
///
///  * [SliverMasonryGridDelegateWithMaxCrossAxisExtent], which creates a masonry
///    layout that have a maximum cross-axis extent.
///  * [MasonryGridView], which uses this delegate to control the layout of its tiles.
///  * [SliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
///  * [RenderSliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
class SliverMasonryGridDelegateWithFixedCrossAxisCount extends SliverMasonryGridDelegate {
  /// Creates a delegate that makes masonry layouts with a fixed number of tiles in
  /// the cross axis.
  ///
  /// All of the arguments must not be null. The `mainAxisSpacing` and
  /// `crossAxisSpacing` arguments must not be negative.The `crossAxisCount`
  /// must be greater than zero.
  const SliverMasonryGridDelegateWithFixedCrossAxisCount({
    @required this.crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) : assert(crossAxisCount != null && crossAxisCount > 0),
       super(mainAxisSpacing: mainAxisSpacing, crossAxisSpacing: crossAxisSpacing);

  /// The number of children in the cross axis.
  final int crossAxisCount;

  @override
  int getCrossAxisCount(SliverConstraints constraints) {
    return crossAxisCount;
  }

  @override
  bool shouldRelayout(SliverMasonryGridDelegate oldDelegate) {
    if(oldDelegate.runtimeType != runtimeType) {
      return true;
    }

    return oldDelegate is SliverMasonryGridDelegateWithFixedCrossAxisCount
       && (oldDelegate.crossAxisCount != crossAxisCount
       || super.shouldRelayout(oldDelegate));
  }
}

/// Creates masonry layouts with tiles that each have a maximum cross-axis extent.
///
/// This delegate will select a cross-axis extent for the tiles that is as
/// large as possible subject to the following conditions:
///
///  - The extent evenly divides the cross-axis extent of the grid.
///  - The extent is at most [maxCrossAxisExtent].
///
/// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
/// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
/// columns that are 125.0 pixels wide.
///
/// This delegate creates grids with equally cross-axis sized and spaced tiles.
///
/// See also:
///
///  * [SliverMasonryGridDelegateWithFixedCrossAxisCount], which creates a masonry
///    layout with a fixed number of tiles in the cross axis.
///  * [MasonryGridView], which uses this delegate to control the layout of its tiles.
///  * [SliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
///  * [RenderSliverMasonryGrid], which uses this delegate to control the layout of its
///    tiles.
class SliverMasonryGridDelegateWithMaxCrossAxisExtent extends SliverMasonryGridDelegate {
  /// Creates a delegate that makes masonry layouts with tiles that have a maximum
  /// cross-axis extent.
  ///
  /// All of the arguments must not be null. The [maxCrossAxisExtent],
  /// [mainAxisSpacing], and [crossAxisSpacing] arguments must not be negative.
  const SliverMasonryGridDelegateWithMaxCrossAxisExtent({
    @required this.maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) : assert(maxCrossAxisExtent != null && maxCrossAxisExtent >= 0),
       super(mainAxisSpacing: mainAxisSpacing, crossAxisSpacing: crossAxisSpacing);

  /// The maximum extent of tiles in the cross axis.
  ///
  /// This delegate will select a cross-axis extent for the tiles that is as
  /// large as possible subject to the following conditions:
  ///
  ///  - The extent evenly divides the cross-axis extent of the grid.
  ///  - The extent is at most [maxCrossAxisExtent].
  ///
  /// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
  /// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
  /// columns that are 125.0 pixels wide.
  final double maxCrossAxisExtent;

  @override
  int getCrossAxisCount(SliverConstraints constraints) {
    return (constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
  }

  @override
  bool shouldRelayout(SliverMasonryGridDelegate oldDelegate) {
    if(oldDelegate.runtimeType != runtimeType) {
      return true;
    }

    return oldDelegate is SliverMasonryGridDelegateWithMaxCrossAxisExtent
       && (oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent
       || super.shouldRelayout(oldDelegate));
  }
}

/// Parent data structure used by [RenderSliverMasonryGrid].
class SliverMasonryGridParentData extends SliverMultiBoxAdaptorParentData {
  /// The trailing position of the child relative to the zero scroll offset.
  ///
  /// The number of pixels from from the zero scroll offset of the parent sliver
  /// (the line at which its [SliverConstraints.scrollOffset] is zero) to the
  /// side of the child closest to that offset.
  ///
  /// In a typical list, this does not change as the parent is scrolled.
  double trailingLayoutOffset;

  /// The index of crossAxis.
  int crossAxisIndex;

  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  double crossAxisOffset;

  /// The indexes of the children in the same index of crossAxis.
  List<int> indexes = <int>[];

  @override
  String toString() =>
      'crossAxisIndex=$crossAxisIndex;crossAxisOffset=$crossAxisOffset;trailingLayoutOffset=$trailingLayoutOffset;indexes$indexes; ${super.toString()}';
}

/// A sliver that places multiple box children with masonry layouts.
///
/// [RenderSliverMasonryGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the cross-axis size specified by the
/// [gridDelegate].
///
/// See also:
///
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [RenderSliverGrid], which places its children in arbitrary positions.
class RenderSliverMasonryGrid extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose cross-axis size
  /// is determined by a delegate and position is determined by masonry rule.
  ///
  /// The [childManager] and [gridDelegate] arguments must not be null.
  RenderSliverMasonryGrid({
    @required RenderSliverBoxChildManager childManager,
    @required SliverMasonryGridDelegate gridDelegate,
  }) : assert(gridDelegate != null),
       _gridDelegate = gridDelegate,
       super(childManager: childManager);

  /// It stores parent data of the leading and trailing.
  _CrossAxisChildrenData _previousCrossAxisChildrenData;

  /// The delegate that controls the size and position of the children.
  SliverMasonryGridDelegate get gridDelegate => _gridDelegate;
  SliverMasonryGridDelegate _gridDelegate;
  set gridDelegate(SliverMasonryGridDelegate value) {
    assert(value != null);
    if (_gridDelegate == value) {
      return;
    }
    if (value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMasonryGridParentData) {
      child.parentData = SliverMasonryGridParentData();
    }
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverMasonryGridParentData childParentData = child.parentData as SliverMasonryGridParentData;
    return childParentData.crossAxisOffset;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    _clearIfNeed();

    final _CrossAxisChildrenData crossAxisChildrenData = _CrossAxisChildrenData(
      gridDelegate: _gridDelegate,
      constraints: constraints,
      leadingChildren: _previousCrossAxisChildrenData?.leadingChildren,
    );

    final BoxConstraints childConstraints = constraints.asBoxConstraints(
      crossAxisExtent: _gridDelegate.getChildUsableCrossAxisExtent(constraints));

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // This algorithm in principle is straight-forward: find the leading children
    // that overlaps the given scrollOffset base on [_previousCrossAxisChildrenData],
    // creating more children after the shortest one of the previous row/column,
    // then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox leadingChildWithLayout, trailingChildWithLayout;

    // Find the last child that is at or before the scrollOffset.
    RenderBox earliestUsefulChild = firstChild;

    // A firstChild with null layout offset is likely a result of children
    // reordering.
    //
    // We rely on firstChild to have accurate layout offset. In the case of null
    // layout offset, we have to find the first child that has valid layout
    // offset.
    if (childScrollOffset(firstChild) == null) {
      int leadingChildrenWithoutLayoutOffset = 0;
      while (childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(firstChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      // We should be able to destroy children with null layout offset safely,
      // because they are likely outside of viewport.
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      assert(firstChild != null);
    }

    // Find the last child that is at or before the scrollOffset.
    earliestUsefulChild = firstChild;

    if (crossAxisChildrenData.maxLeadingLayoutOffset > scrollOffset) {
      RenderBox child = firstChild;
      // Add children from min index to max index of leading to
      // make sure indexes are continuous.
      final int maxLeadingIndex = crossAxisChildrenData.maxLeadingIndex;
      while (child != null && maxLeadingIndex > indexOf(child)) {
        child = childAfter(child);
      }
      final int minLeadingIndex = crossAxisChildrenData.minLeadingIndex;
      while (child != null && minLeadingIndex < indexOf(child)) {
        crossAxisChildrenData.insertLeading(child: child, paintExtentOf: paintExtentOf);
        child = childBefore(child);
      }

      while (crossAxisChildrenData.maxLeadingLayoutOffset > scrollOffset) {
        // We have to add children before the earliestUsefulChild.
        earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);

        if (earliestUsefulChild == null) {
          if (scrollOffset == 0.0) {
            // insertAndLayoutLeadingChild only lays out the children before
            // firstChild. In this case, nothing has been laid out. We have
            // to lay out firstChild manually.
            firstChild.layout(childConstraints, parentUsesSize: true);
            earliestUsefulChild = firstChild;
            leadingChildWithLayout = earliestUsefulChild;
            trailingChildWithLayout ??= earliestUsefulChild;
            crossAxisChildrenData.clear();
            crossAxisChildrenData.insert(
              child: earliestUsefulChild,
              childTrailingLayoutOffset: childTrailingLayoutOffset,
            );
            break;
          } else {
            // We ran out of children before reaching the scroll offset.
            // We must inform our parent that this sliver cannot fulfill
            // its contract and that we need a scroll offset correction.
            geometry = SliverGeometry(
              scrollOffsetCorrection: -scrollOffset,
            );
            return;
          }
        }

        crossAxisChildrenData.insertLeading(child: earliestUsefulChild, paintExtentOf: paintExtentOf);

        final SliverMasonryGridParentData data = earliestUsefulChild.parentData as SliverMasonryGridParentData;

        // firstChildScrollOffset may contain double precision error
        if (data.layoutOffset < -precisionErrorTolerance) {
          // The first child doesn't fit within the viewport (underflow) and
          // there may be additional children above it. Find the real first child
          // and then correct the scroll position so that there's room for all and
          // so that the trailing edge of the original firstChild appears where it
          // was before the scroll offset correction.
          // do this work incrementally, instead of all at once,
          // i.e. find a way to avoid visiting ALL of the children whose offset
          // is < 0 before returning for the scroll correction.
          double correction = 0.0;
          while (earliestUsefulChild != null) {
            assert(firstChild == earliestUsefulChild);
            correction += paintExtentOf(firstChild);
            earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
            crossAxisChildrenData.insertLeading(child: earliestUsefulChild, paintExtentOf: paintExtentOf);
          }
          geometry = SliverGeometry(
            scrollOffsetCorrection: correction - data.layoutOffset,
          );
          return;
        }

        assert(earliestUsefulChild == firstChild);
        leadingChildWithLayout = earliestUsefulChild;
        trailingChildWithLayout ??= earliestUsefulChild;
      }
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.
    assert(earliestUsefulChild == firstChild);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;
    RenderBox child = earliestUsefulChild;
    int index = indexOf(child);
    crossAxisChildrenData.insert(
      child: child,
      childTrailingLayoutOffset: childTrailingLayoutOffset,
    );

    bool advance() {
      // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout) {
        inLayoutRange = false;
      }
      child = childAfter(child);
      if (child == null) {
        inLayoutRange = false;
      }
      index += 1;

      if (!inLayoutRange) {
        if (child == null || indexOf(child) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(
            childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          child.layout(childConstraints, parentUsesSize: true);
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);

      final SliverMasonryGridParentData childParentData = child.parentData as SliverMasonryGridParentData;

      crossAxisChildrenData.insert(
        child: child,
        childTrailingLayoutOffset: childTrailingLayoutOffset,
      );

      assert(childParentData.index == index);
      return true;
    }

    final List<int> leadingGarbages = <int>[];

    // Find the first child that ends after the scroll offset.
    while (childTrailingLayoutOffset(child) < scrollOffset) {
      leadingGarbage += 1;
      leadingGarbages.add(index);
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // We ran out of children before reaching the scroll offset.
        // We must inform our parent that this sliver cannot fulfill
        // its contract and that we need a max scroll offset correction.
        final double extent = crossAxisChildrenData.maxChildTrailingLayoutOffset;
        collectGarbage(childCount,0);
        geometry = SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        _previousCrossAxisChildrenData = null;
        return;
      }
    }

    if (leadingGarbage > 0) {
      // Make sure the leadings are after the scroll offset
      while (crossAxisChildrenData.minChildTrailingLayoutOffset < scrollOffset) {
        if (!advance()) {
          final int minTrailingIndex = crossAxisChildrenData.minTrailingIndex;
          // The indexes are continuous, make sure they are less than minTrailingIndex.
          for (final int index in leadingGarbages) {
            if (index >= minTrailingIndex) {
              leadingGarbage--;
            }
          }
          leadingGarbage = math.max(0, leadingGarbage);
          break;
        }
      }
      crossAxisChildrenData.setLeading();
    }

    if (child != null) {
      final int crossAxisCount = _gridDelegate.getCrossAxisCount(constraints);
      while (
          // Now find the first child that ends after our end.
          crossAxisChildrenData.minChildTrailingLayoutOffset < targetEndScrollOffset
          // Make sure leading children are all laid out.
       || crossAxisChildrenData.leadingChildren.length < crossAxisCount
       || crossAxisChildrenData.leadingChildren.length > childCount
       || (child.parentData as SliverMasonryGridParentData).index < crossAxisCount - 1) {
        if (!advance()) {
          reachedEnd = true;
          break;
        }
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.
    collectGarbage(leadingGarbage, trailingGarbage);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    double estimatedMaxScrollOffset;

    final double endScrollOffset = crossAxisChildrenData.maxChildTrailingLayoutOffset;

    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild),
        lastIndex: indexOf(lastChild),
        leadingScrollOffset: childScrollOffset(firstChild),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >= endScrollOffset - childScrollOffset(firstChild));
    }

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();

    // Save, for next layout.
    _previousCrossAxisChildrenData = crossAxisChildrenData;
  }

  /// Masonry layout maybe have changed. We need to recalculate from the zero index so that
  /// layouts will not change suddenly when scroll.
  void _clearIfNeed() {
    if (_previousCrossAxisChildrenData != null) {
      if (_previousCrossAxisChildrenData.crossAxisCount != gridDelegate.getCrossAxisCount(constraints)
       || _previousCrossAxisChildrenData.gridDelegate.mainAxisSpacing != gridDelegate.mainAxisSpacing
       || _previousCrossAxisChildrenData.constraints.crossAxisExtent != constraints.crossAxisExtent) {
        _previousCrossAxisChildrenData = null;
        collectGarbage(childCount, 0);
      }
    }
  }

  /// Return the trailing position of the child.
  double childTrailingLayoutOffset(RenderBox child) {
    return childScrollOffset(child) + paintExtentOf(child);
  }
}

/// Data structure used to calculate masonry layout by [RenderSliverMasonryGrid]
class _CrossAxisChildrenData {
  _CrossAxisChildrenData({
    @required this.gridDelegate,
    @required this.constraints,
    List<SliverMasonryGridParentData> leadingChildren,
  }) : leadingChildren = leadingChildren?.toList() ?? <SliverMasonryGridParentData>[],
       trailingChildren = leadingChildren?.toList() ?? <SliverMasonryGridParentData>[];

  /// The parent data of leading children.
  final List<SliverMasonryGridParentData> leadingChildren;

  /// The parent data of trailing children.
  final List<SliverMasonryGridParentData> trailingChildren;

  /// A delegate that controls the masonry layout of the children within the [MasonryGridView].
  final SliverMasonryGridDelegate gridDelegate;

  /// Immutable layout constraints for [RenderSliverMasonryGrid] layout.
  final SliverConstraints constraints;

  /// The number of children in the cross axis.
  int get crossAxisCount => gridDelegate.getCrossAxisCount(constraints);

  /// Fill the leading at the beginning then the children are
  /// laid out after the shortest one.
  void insert({
    @required RenderBox child,
    @required double Function(RenderBox child) childTrailingLayoutOffset,
  }) {
    final SliverMasonryGridParentData data = child.parentData as SliverMasonryGridParentData;

    if (!leadingChildren.contains(data)) {
      if (leadingChildren.length != crossAxisCount) {
        data.crossAxisIndex ??= leadingChildren.length;

        data.crossAxisOffset = gridDelegate.getCrossAxisOffset(constraints, data.crossAxisIndex);

        data.layoutOffset = 0.0;
        data.indexes.clear();
        trailingChildren.add(data);
        leadingChildren.add(data);
      }
      // The child after the leading should be put into the trailing.
      else {
        if (data.crossAxisIndex != null) {
          final SliverMasonryGridParentData item = trailingChildren.firstWhere(
            (SliverMasonryGridParentData x) => x.index > data.index && x.crossAxisIndex == data.crossAxisIndex,
            orElse: () => null,
          );

          // It is out of the viewport.
          // It happens when one child has large size in the main axis,
          if (item != null) {
            data.trailingLayoutOffset = childTrailingLayoutOffset(child);
            return;
          }
        }
        // Find the shortest one and laid out after it.
        final SliverMasonryGridParentData min = trailingChildren.reduce(
          (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
          current.trailingLayoutOffset < next.trailingLayoutOffset ||
          (current.trailingLayoutOffset == next.trailingLayoutOffset && current.crossAxisIndex < next.crossAxisIndex)
          ? current : next,
        );

        data.layoutOffset = min.trailingLayoutOffset + gridDelegate.mainAxisSpacing;
        data.crossAxisIndex = min.crossAxisIndex;
        data.crossAxisOffset = gridDelegate.getCrossAxisOffset(constraints, data.crossAxisIndex);

        for (final SliverMasonryGridParentData parentData in trailingChildren) {
          parentData.indexes.remove(min.index);
        }

        min.indexes.add(min.index);
        data.indexes = min.indexes;

        trailingChildren.remove(min);
        trailingChildren.add(data);
      }
    }

    data.crossAxisOffset = gridDelegate.getCrossAxisOffset(constraints, data.crossAxisIndex);
    data.trailingLayoutOffset = childTrailingLayoutOffset(child);
  }

  /// When maxLeadingLayoutOffset is less than scrollOffset,
  /// we have to insert child before the scrollOffset base on the leadings.
  void insertLeading({
    @required RenderBox child,
    @required double Function(RenderBox child) paintExtentOf,
  }) {
    final SliverMasonryGridParentData data = child.parentData as SliverMasonryGridParentData;
    if (!leadingChildren.contains(data)) {

      final SliverMasonryGridParentData leading = leadingChildren.firstWhere(
        (SliverMasonryGridParentData x) => x.indexes.contains(data.index),
        orElse: () => null,
      );

      // This child is after the leadings.
      if (leading == null || data.index > leading.index) {
        return;
      }

      // Laid out the child before the leading.
      data.trailingLayoutOffset = leading.layoutOffset - gridDelegate.mainAxisSpacing;
      data.layoutOffset = data.trailingLayoutOffset - paintExtentOf(child);
      data.crossAxisIndex = leading.crossAxisIndex;
      data.crossAxisOffset = gridDelegate.getCrossAxisOffset(constraints, data.crossAxisIndex);
      data.indexes = leading.indexes;

      leadingChildren.remove(leading);
      trailingChildren.remove(leading);
      leadingChildren.add(data);
      trailingChildren.add(data);
    }
  }

  double get maxLeadingLayoutOffset {
    if(leadingChildren.isEmpty) {
      return 0.0;
    }

    return leadingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.layoutOffset >= next.layoutOffset ? current : next
    ).layoutOffset;
  }

  double get minChildTrailingLayoutOffset {
    if(trailingChildren.isEmpty) {
      return 0.0;
    }

    return trailingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.trailingLayoutOffset <= next.trailingLayoutOffset ? current : next
    ).trailingLayoutOffset;
  }

  double get maxChildTrailingLayoutOffset {
    if(trailingChildren.isEmpty) {
      return 0.0;
    }

    return trailingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.trailingLayoutOffset >= next.trailingLayoutOffset ? current : next
    ).trailingLayoutOffset;
  }

  int get minLeadingIndex {
    if(leadingChildren.isEmpty) {
      return -1;
    }

    return leadingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.index < next.index ? current : next
    ).index;
  }

  int get maxLeadingIndex {
    if(leadingChildren.isEmpty) {
      return -1;
    }

    return leadingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.index > next.index ? current : next
    ).index;
  }

  int get minTrailingIndex {
    if(trailingChildren.isEmpty) {
      return -1;
    }

    return trailingChildren.reduce(
      (SliverMasonryGridParentData current, SliverMasonryGridParentData next) =>
      current.index < next.index ? current : next
    ).index;
  }

  void clear() {
    leadingChildren.clear();
    trailingChildren.clear();
  }

  /// Called after all of the leading are after the scroll offset
  /// That is the final leading.
  void setLeading() {
    leadingChildren.clear();
    leadingChildren.addAll(trailingChildren);
  }
}