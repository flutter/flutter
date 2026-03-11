// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'sliver_list.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;

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
  RenderSliverFillViewport({required super.childManager, double viewportFraction = 1.0})
    : assert(viewportFraction > 0.0),
      _viewportFraction = viewportFraction;

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
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
    markNeedsLayout();
  }
}

/// A mixin for [RenderSliver] objects that can report their effective
/// cross-axis extent based on the current scroll position.
///
/// This is used by viewports that adapt their cross-axis size to their
/// content, such as when a [PageView] uses `wrapCrossAxis: true`.
mixin RenderSliverCrossAxisAdaptable on RenderSliver {
  /// The effective cross-axis extent at the current scroll position.
  ///
  /// This value is computed during layout and reflects the cross-axis size
  /// that the viewport should adopt, typically interpolated between visible
  /// children during page transitions.
  double get effectiveCrossAxisExtent;
}

/// A sliver that contains multiple box children that each fill the viewport
/// in the main axis, but use their natural size in the cross axis.
///
/// [RenderSliverFittedPage] places its children in a linear array along the
/// main axis. Each child is sized to fill the viewport in the main axis
/// (multiplied by [viewportFraction]), but is given loose constraints in the
/// cross axis, allowing it to determine its own cross-axis size.
///
/// After layout, this sliver reports an [effectiveCrossAxisExtent] that
/// interpolates smoothly between the cross-axis sizes of the currently
/// visible children. This is used by PageView's adaptive viewport to
/// dynamically size the viewport's cross axis.
///
/// See also:
///
///  * [RenderSliverFillViewport], which forces children to fill both axes.
class RenderSliverFittedPage extends RenderSliverFixedExtentBoxAdaptor
    with RenderSliverCrossAxisAdaptable {
  /// Creates a sliver that sizes children to fill the main axis but adapts
  /// to children's natural cross-axis sizes.
  RenderSliverFittedPage({required super.childManager, double viewportFraction = 1.0})
    : assert(viewportFraction > 0.0),
      _viewportFraction = viewportFraction;

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
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
    markNeedsLayout();
  }

  /// Cross-axis extents of laid-out children, keyed by child index.
  final Map<int, double> _childCrossAxisExtents = <int, double>{};

  @override
  double effectiveCrossAxisExtent = 0.0;

  /// Returns the cross-axis size of the given [child] after layout.
  double _childCrossAxisSize(RenderBox child) {
    return switch (constraints.axis) {
      Axis.horizontal => child.size.height,
      Axis.vertical => child.size.width,
    };
  }

  /// Records the cross-axis size of [child] at the given [index].
  void _trackChildCrossAxisExtent(RenderBox child, int index) {
    _childCrossAxisExtents[index] = _childCrossAxisSize(child);
  }

  /// Computes the interpolated cross-axis extent based on scroll position.
  ///
  /// During a page transition, this linearly interpolates between the
  /// cross-axis sizes of the two visible pages.
  double _computeEffectiveCrossAxisExtent(double scrollOffset) {
    if (_childCrossAxisExtents.isEmpty) {
      return constraints.crossAxisExtent;
    }

    final double pageExtent = itemExtent;
    if (pageExtent <= 0.0) {
      return _childCrossAxisExtents.values.fold(0.0, math.max);
    }

    final double page = scrollOffset / pageExtent;
    final int currentPage = page.floor();
    final double fraction = page - currentPage;

    final double? currentExtent = _childCrossAxisExtents[currentPage];
    if (currentExtent == null) {
      return _childCrossAxisExtents.values.fold(0.0, math.max);
    }

    if (fraction < precisionErrorTolerance) {
      return currentExtent;
    }

    final double? nextExtent = _childCrossAxisExtents[currentPage + 1];
    if (nextExtent == null) {
      return currentExtent;
    }

    return currentExtent + (nextExtent - currentExtent) * fraction;
  }

  /// Builds [BoxConstraints] for a child with tight main-axis extent and
  /// loose cross-axis constraints.
  BoxConstraints _buildChildConstraints() {
    final double mainExtent = itemExtent;
    return switch (constraints.axis) {
      Axis.horizontal => BoxConstraints(
        minWidth: mainExtent,
        maxWidth: mainExtent,
        maxHeight: constraints.crossAxisExtent,
      ),
      Axis.vertical => BoxConstraints(
        maxWidth: constraints.crossAxisExtent,
        minHeight: mainExtent,
        maxHeight: mainExtent,
      ),
    };
  }

  @override
  void performLayout() {
    assert(itemExtent.isFinite && itemExtent >= 0);

    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent)
        : null;

    _childCrossAxisExtents.clear();

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    final BoxConstraints childConstraints = _buildChildConstraints();

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
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
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (child == null) {
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
      _trackChildCrossAxisExtent(child, index);
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(childConstraints, parentUsesSize: true);
      final SliverMultiBoxAdaptorParentData childParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
      _trackChildCrossAxisExtent(firstChild!, firstIndex);
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (
      int index = indexOf(trailingChildWithLayout!) + 1;
      targetLastIndex == null || index <= targetLastIndex;
      ++index
    ) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          childConstraints,
          after: trailingChildWithLayout,
          parentUsesSize: true,
        );
        if (child == null) {
          estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
          break;
        }
      } else {
        child.layout(childConstraints, parentUsesSize: true);
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent,
        childParentData.index!,
      );
      _trackChildCrossAxisExtent(child, index);
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
      hasVisualOverflow:
          (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    effectiveCrossAxisExtent = _computeEffectiveCrossAxisExtent(constraints.scrollOffset);

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}

/// A sliver that contains a single box child that contains a scrollable and
/// fills the viewport.
///
/// [RenderSliverFillRemainingWithScrollable] sizes its child to fill the
/// viewport in the cross axis and to fill the remaining space in the viewport
/// in the main axis.
///
/// Typically this will be the last sliver in a viewport, since (by definition)
/// there is never any room for anything beyond this sliver.
///
/// See also:
///
///  * [NestedScrollView], which uses this sliver for the inner scrollable.
///  * [RenderSliverFillRemaining], which lays out its
///    non-scrollable child slightly different than this widget.
///  * [RenderSliverFillRemainingAndOverscroll], which incorporates the
///    overscroll into the remaining space to fill.
///  * [RenderSliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [RenderSliverList], which shows a list of variable-sized children in a
///    viewport.
class RenderSliverFillRemainingWithScrollable extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a scrollable [RenderBox] which is
  /// sized to fit the remaining space in the viewport.
  RenderSliverFillRemainingWithScrollable({super.child});

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    final double extent = constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: constraints.viewportMainAxisExtent,
    );
    if (child != null) {
      var maxExtent = extent;

      // If sliver has no extent, but is within viewport's cacheExtent, use the
      // sliver's cacheExtent as the maxExtent so that it does not get dropped
      // from the semantic tree.
      if (extent == 0 && cacheExtent > 0) {
        maxExtent = cacheExtent;
      }
      child!.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: maxExtent));
    }

    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    geometry = SliverGeometry(
      scrollExtent: constraints.viewportMainAxisExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow:
          extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
      cacheExtent: cacheExtent,
    );
    if (child != null) {
      setChildParentData(child!, constraints, geometry!);
    }
  }
}

/// A sliver that contains a single box child that is non-scrollable and fills
/// the remaining space in the viewport.
///
/// [RenderSliverFillRemaining] sizes its child to fill the
/// viewport in the cross axis and to fill the remaining space in the viewport
/// in the main axis.
///
/// Typically this will be the last sliver in a viewport, since (by definition)
/// there is never any room for anything beyond this sliver.
///
/// See also:
///
///  * [RenderSliverFillRemainingWithScrollable], which lays out its scrollable
///    child slightly different than this widget.
///  * [RenderSliverFillRemainingAndOverscroll], which incorporates the
///    overscroll into the remaining space to fill.
///  * [RenderSliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [RenderSliverList], which shows a list of variable-sized children in a
///    viewport.
class RenderSliverFillRemaining extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a non-scrollable [RenderBox] which is
  /// sized to fit the remaining space in the viewport.
  RenderSliverFillRemaining({super.child});

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    // The remaining space in the viewportMainAxisExtent. Can be <= 0 if we have
    // scrolled beyond the extent of the screen.
    double extent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;

    if (child != null) {
      final double childExtent = switch (constraints.axis) {
        Axis.horizontal => child!.getMaxIntrinsicWidth(constraints.crossAxisExtent),
        Axis.vertical => child!.getMaxIntrinsicHeight(constraints.crossAxisExtent),
      };

      // If the childExtent is greater than the computed extent, we want to use
      // that instead of potentially cutting off the child. This allows us to
      // safely specify a maxExtent.
      extent = math.max(extent, childExtent);
      child!.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent));
    }

    assert(
      extent.isFinite,
      'The calculated extent for the child of SliverFillRemaining is not finite. '
      'This can happen if the child is a scrollable, in which case, the '
      'hasScrollBody property of SliverFillRemaining should not be set to '
      'false.',
    );
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    final double cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: extent);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow:
          extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
      cacheExtent: cacheExtent,
    );
    if (child != null) {
      setChildParentData(child!, constraints, geometry!);
    }
  }
}

/// A sliver that contains a single box child that is non-scrollable and fills
/// the remaining space in the viewport including any overscrolled area.
///
/// [RenderSliverFillRemainingAndOverscroll] sizes its child to fill the
/// viewport in the cross axis and to fill the remaining space in the viewport
/// in the main axis with the overscroll area included.
///
/// Typically this will be the last sliver in a viewport, since (by definition)
/// there is never any room for anything beyond this sliver.
///
/// See also:
///
///  * [RenderSliverFillRemainingWithScrollable], which lays out its scrollable
///    child without overscroll.
///  * [RenderSliverFillRemaining], which lays out its
///    non-scrollable child without overscroll.
///  * [RenderSliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [RenderSliverList], which shows a list of variable-sized children in a
///    viewport.
class RenderSliverFillRemainingAndOverscroll extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a non-scrollable [RenderBox] which is
  /// sized to fit the remaining space plus any overscroll in the viewport.
  RenderSliverFillRemainingAndOverscroll({super.child});

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    // The remaining space in the viewportMainAxisExtent. Can be <= 0 if we have
    // scrolled beyond the extent of the screen.
    double extent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
    // The maxExtent includes any overscrolled area. Can be < 0 if we have
    // overscroll in the opposite direction, away from the end of the list.
    double maxExtent = constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);

    if (child != null) {
      final double childExtent = switch (constraints.axis) {
        Axis.horizontal => child!.getMaxIntrinsicWidth(constraints.crossAxisExtent),
        Axis.vertical => child!.getMaxIntrinsicHeight(constraints.crossAxisExtent),
      };

      // If the childExtent is greater than the computed extent, we want to use
      // that instead of potentially cutting off the child. This allows us to
      // safely specify a maxExtent.
      extent = math.max(extent, childExtent);
      // The extent could be larger than the maxExtent due to a larger child
      // size or overscrolling at the top of the scrollable (rather than at the
      // end where this sliver is).
      maxExtent = math.max(extent, maxExtent);
      child!.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: maxExtent));
    }

    assert(
      extent.isFinite,
      'The calculated extent for the child of SliverFillRemaining is not finite. '
      'This can happen if the child is a scrollable, in which case, the '
      'hasScrollBody property of SliverFillRemaining should not be set to '
      'false.',
    );
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    final double cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: extent);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: math.min(maxExtent, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent,
      hasVisualOverflow:
          extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
      cacheExtent: cacheExtent,
    );
    if (child != null) {
      setChildParentData(child!, constraints, geometry!);
    }
  }
}
