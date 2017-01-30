// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

/// Describes the placement of a child in a [RenderSliverGrid].
///
/// See also:
///
///  * [SliverGridDelegate.getGeometryForChildIndex], which returns this object
///    to describe the child's placement.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
class SliverGridGeometry {
  /// Creates an object that describes the placement of a child in a [RenderSliverGrid].
  const SliverGridGeometry({
    this.scrollOffset,
    this.crossAxisOffset,
    this.mainAxisExtent,
    this.crossAxisExtent,
  });

  /// The scroll offset of the leading edge of the child relative to the leading
  /// edge of the parent.
  final double scrollOffset;

  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  final double crossAxisOffset;

  /// The extent of the child in the scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's height. If the
  /// scroll axis is horizontal, this extent is the child's width.
  final double mainAxisExtent;

  /// The extent of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's width. If the
  /// scroll axis is horizontal, this extent is the child's height.
  final double crossAxisExtent;

  /// Returns a tight [BoxConstraints] that forces the child to have the
  /// required size.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent,
      maxExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
  }
}

class SliverGridParentData extends SliverMultiBoxAdaptorParentData {
  double crossAxisOffset;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

abstract class SliverGridDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverGridDelegate();

  int getMinChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset);

  int getMaxChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset);

  SliverGridGeometry getGeometryForChildIndex(SliverConstraints constraints, int index);

  double estimateMaxScrollOffset(SliverConstraints constraints, int childCount);

  bool shouldRelayout(@checked SliverGridDelegate oldDelegate);
}

class SliverGridDelegateWithFixedCrossAxisCount extends SliverGridDelegate {
  const SliverGridDelegateWithFixedCrossAxisCount({
    @required this.crossAxisCount,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.childAspectRatio: 1.0,
  });

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(childAspectRatio > 0.0);
    return true;
  }

  double _getMainAxisStride(double crossAxisExtent) {
    final double usableCrossAxisExtent = crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return childMainAxisExtent + mainAxisSpacing;
  }

  @override
  int getMinChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset) {
    assert(_debugAssertIsValid());
    return crossAxisCount * (scrollOffset ~/ _getMainAxisStride(constraints.crossAxisExtent));
  }

  @override
  int getMaxChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset) {
    assert(_debugAssertIsValid());
    final int mainAxisCount = (scrollOffset / _getMainAxisStride(constraints.crossAxisExtent)).ceil();
    return math.max(0, crossAxisCount * mainAxisCount - 1);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(SliverConstraints constraints, int index) {
    final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    final double mainAxisStride = childMainAxisExtent + mainAxisSpacing;
    final double crossAxisStrid = childCrossAxisExtent + crossAxisSpacing;
    assert(mainAxisStride == _getMainAxisStride(constraints.crossAxisExtent));

    return new SliverGridGeometry(
      scrollOffset: (index ~/ crossAxisCount) * mainAxisStride,
      crossAxisOffset: (index % crossAxisCount) * crossAxisStrid,
      mainAxisExtent: childMainAxisExtent,
      crossAxisExtent: childCrossAxisExtent,
    );
  }

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, int childCount) {
    if (childCount == null)
      return null;
    final int mainAxisCount = ((childCount - 1) / crossAxisCount).floor() + 1;
    return _getMainAxisStride(constraints.crossAxisExtent) * mainAxisCount - mainAxisSpacing;
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithFixedCrossAxisCount oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount
        || oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing
        || oldDelegate.childAspectRatio != childAspectRatio;
  }
}

/// A [GridDelegate] that fills the width with a variable number of tiles.
///
/// This delegate will select a tile width that is as large as possible subject
/// to the following conditions:
///
///  - The tile width evenly divides the width of the grid.
///  - The tile width is at most [maxTileWidth].
class SliverGridDelegateWithMaxCrossAxisExtent extends SliverGridDelegate {
  /// Creates a grid delegate that uses a max tile width.
  ///
  /// The [maxTileWidth] argument must not be null.
  const SliverGridDelegateWithMaxCrossAxisExtent({
    @required this.maxCrossAxisExtent,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.childAspectRatio: 1.0,
  });

  /// The number of children in the cross axis.
  final double maxCrossAxisExtent;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  bool _debugAssertIsValid() {
    assert(maxCrossAxisExtent > 0.0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(childAspectRatio > 0.0);
    return true;
  }

  int _getCrossAxisCount(double crossAxisExtent) {
    return (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
  }

  double _getMainAxisStride(double crossAxisExtent, int crossAxisCount) {
    final double usableCrossAxisExtent = crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return childMainAxisExtent + mainAxisSpacing;
  }

  @override
  int getMinChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset) {
    assert(_debugAssertIsValid());
    final double crossAxisExtent = constraints.crossAxisExtent;
    final int crossAxisCount = _getCrossAxisCount(crossAxisExtent);
    return crossAxisCount * (scrollOffset ~/ _getMainAxisStride(crossAxisExtent, crossAxisCount));
  }

  @override
  int getMaxChildIndexForScrollOffset(SliverConstraints constraints, double scrollOffset) {
    assert(_debugAssertIsValid());
    final double crossAxisExtent = constraints.crossAxisExtent;
    final int crossAxisCount = _getCrossAxisCount(crossAxisExtent);
    final int mainAxisCount = (scrollOffset / _getMainAxisStride(crossAxisExtent, crossAxisCount)).ceil();
    return math.max(0, crossAxisCount * mainAxisCount - 1);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(SliverConstraints constraints, int index) {
    final int crossAxisCount = _getCrossAxisCount(constraints.crossAxisExtent);
    final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    final double mainAxisStride = childMainAxisExtent + mainAxisSpacing;
    final double crossAxisStrid = childCrossAxisExtent + crossAxisSpacing;
    assert(mainAxisStride == _getMainAxisStride(constraints.crossAxisExtent, crossAxisCount));

    return new SliverGridGeometry(
      scrollOffset: (index ~/ crossAxisCount) * mainAxisStride,
      crossAxisOffset: (index % crossAxisCount) * crossAxisStrid,
      mainAxisExtent: childMainAxisExtent,
      crossAxisExtent: childCrossAxisExtent,
    );
  }

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, int childCount) {
    if (childCount == null)
      return null;
    final double crossAxisExtent = constraints.crossAxisExtent;
    final int crossAxisCount = _getCrossAxisCount(crossAxisExtent);
    final int mainAxisCount = ((childCount - 1) / crossAxisCount).floor() + 1;
    return _getMainAxisStride(crossAxisExtent, crossAxisCount) * mainAxisCount - mainAxisSpacing;
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithMaxCrossAxisExtent oldDelegate) {
    return oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent
        || oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing
        || oldDelegate.childAspectRatio != childAspectRatio;
  }
}

class RenderSliverGrid extends RenderSliverMultiBoxAdaptor {
  RenderSliverGrid({
    @required RenderSliverBoxChildManager childManager,
    @required SliverGridDelegate gridDelegate,
  }) : _gridDelegate = gridDelegate,
       super(childManager: childManager) {
    gridDelegate != null;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData)
      child.parentData = new SliverGridParentData();
  }

  SliverGridDelegate get gridDelegate => _gridDelegate;
  SliverGridDelegate _gridDelegate;

  set gridDelegate(SliverGridDelegate newDelegate) {
    assert(newDelegate != null);
    if (_gridDelegate == newDelegate)
      return;
    if (newDelegate.runtimeType != _gridDelegate.runtimeType ||
        newDelegate.shouldRelayout(_gridDelegate))
      markNeedsLayout();
    _gridDelegate = newDelegate;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverGridParentData childParentData = child.parentData;
    return childParentData.crossAxisOffset;
  }

  @override
  void performLayout() {
    assert(childManager.debugAssertChildListLocked());
    final double scrollOffset = constraints.scrollOffset;
    assert(scrollOffset >= 0.0);
    final double remainingPaintExtent = constraints.remainingPaintExtent;
    assert(remainingPaintExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingPaintExtent;

    final int firstIndex = _gridDelegate.getMinChildIndexForScrollOffset(constraints, scrollOffset);
    final int targetLastIndex = _gridDelegate.getMaxChildIndexForScrollOffset(constraints, targetEndScrollOffset);

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount);
      final int trailingGarbage = (oldLastIndex - targetLastIndex).clamp(0, childCount);
      if (leadingGarbage + trailingGarbage > 0)
        collectGarbage(leadingGarbage, trailingGarbage);
    }

    final SliverGridGeometry firstChildGridGeometry = _gridDelegate
        .getGeometryForChildIndex(constraints, firstIndex);
    double leadingScrollOffset = firstChildGridGeometry.scrollOffset;
    double trailingScrollOffset = firstChildGridGeometry.scrollOffset;

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex,
          scrollOffset: firstChildGridGeometry.scrollOffset)) {
        // There are no children.
        geometry = SliverGeometry.zero;
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final SliverGridGeometry gridGeometry = _gridDelegate
          .getGeometryForChildIndex(constraints, index);
      final RenderBox child = insertAndLayoutLeadingChild(
          gridGeometry.getBoxConstraints(constraints));
      final SliverGridParentData childParentData = child.parentData;
      childParentData.scrollOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
      if (gridGeometry.scrollOffset > trailingScrollOffset)
        trailingScrollOffset = gridGeometry.scrollOffset;
    }

    assert(offsetOf(firstChild) <= scrollOffset);

    if (trailingChildWithLayout == null) {
      firstChild.layout(firstChildGridGeometry.getBoxConstraints(constraints));
      final SliverGridParentData childParentData = firstChild.parentData;
      childParentData.crossAxisOffset = firstChildGridGeometry.crossAxisOffset;
      assert(childParentData.scrollOffset ==
          firstChildGridGeometry.scrollOffset);
      trailingChildWithLayout = firstChild;
    }

    for (int index = indexOf(trailingChildWithLayout) + 1; index <=
        targetLastIndex; ++index) {
      final SliverGridGeometry gridGeometry = _gridDelegate
          .getGeometryForChildIndex(constraints, index);
      final BoxConstraints childConstraints = gridGeometry.getBoxConstraints(
          constraints);
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
      final SliverGridParentData childParentData = child.parentData;
      childParentData.scrollOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      if (gridGeometry.scrollOffset > trailingScrollOffset)
        trailingScrollOffset = gridGeometry.scrollOffset;
    }

    final int lastIndex = indexOf(lastChild);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = childManager.estimateMaxScrollOffset(
      constraints,
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
      // Conservative to avoid complexity.
      hasVisualOverflow: true,
    );

    assert(childManager.debugAssertChildListLocked());
  }
}
