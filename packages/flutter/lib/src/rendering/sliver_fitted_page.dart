// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'sliver_fill.dart';
/// @docImport 'viewport.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_fixed_extent_list.dart';
import 'sliver_multi_box_adaptor.dart';

/// A mixin for [RenderSliver] objects that can report their effective
/// cross-axis extent based on the current scroll position.
///
/// This is used by viewports that adapt their cross-axis size to their
/// content, such as when a [PageView] uses `wrapCrossAxis: true`.
///
/// See also:
///
///  * [RenderSliverFittedPage], which uses this mixin to report page
///    cross-axis sizes to its parent viewport.
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
/// visible children. This is used by [RenderCrossAxisFittedViewport] to
/// dynamically size the viewport's cross axis.
///
/// See also:
///
///  * [RenderSliverFillViewport], which forces children to fill both axes.
///  * [RenderCrossAxisFittedViewport], which uses this sliver's
///    [effectiveCrossAxisExtent] to size itself.
class RenderSliverFittedPage extends RenderSliverFixedExtentBoxAdaptor
    with RenderSliverCrossAxisAdaptable {
  /// Creates a sliver that sizes children to fill the main axis but adapts
  /// to children's natural cross-axis sizes.
  RenderSliverFittedPage({
    required super.childManager,
    double viewportFraction = 1.0,
  }) : assert(viewportFraction > 0.0),
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
      // Fall back to the maximum known extent.
      return _childCrossAxisExtents.values.fold(0.0, math.max);
    }

    if (fraction < precisionErrorTolerance) {
      return currentExtent;
    }

    final double? nextExtent = _childCrossAxisExtents[currentPage + 1];
    if (nextExtent == null) {
      return currentExtent;
    }

    // Linear interpolation between current and next page.
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

    final int firstIndex = getMinChildIndexForScrollOffset(
      scrollOffset, deprecatedExtraItemExtent,
    );
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(
            targetEndScrollOffset, deprecatedExtraItemExtent,
          )
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
      final double layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent, firstIndex,
      );
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
      final RenderBox? child = insertAndLayoutLeadingChild(
        childConstraints,
        parentUsesSize: true,
      );
      if (child == null) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: indexToLayoutOffset(
            deprecatedExtraItemExtent, index,
          ),
        );
        return;
      }
      final childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent, index,
      );
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
      _trackChildCrossAxisExtent(child, index);
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(childConstraints, parentUsesSize: true);
      final childParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent, firstIndex,
      );
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
          estimatedMaxScrollOffset = indexToLayoutOffset(
            deprecatedExtraItemExtent, index,
          );
          break;
        }
      } else {
        child.layout(childConstraints, parentUsesSize: true);
      }
      trailingChildWithLayout = child;
      final childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent,
        childParentData.index!,
      );
      _trackChildCrossAxisExtent(child, index);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(
      deprecatedExtraItemExtent, firstIndex,
    );
    final double trailingScrollOffset = indexToLayoutOffset(
      deprecatedExtraItemExtent,
      lastIndex + 1,
    );

    assert(
      firstIndex == 0 ||
          childScrollOffset(firstChild!)! - scrollOffset <=
              precisionErrorTolerance,
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
        ? getMaxChildIndexForScrollOffset(
            targetEndScrollOffsetForPaint, deprecatedExtraItemExtent,
          )
        : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow:
          (targetLastIndexForPaint != null &&
              lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    // Compute the effective cross-axis extent based on the current scroll
    // position. This value is read by RenderCrossAxisFittedViewport.
    effectiveCrossAxisExtent = _computeEffectiveCrossAxisExtent(
      constraints.scrollOffset,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
