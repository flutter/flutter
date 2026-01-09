// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:math' as math;

import 'package:flutter/src/rendering/viewport.dart';
import 'package:vector_math/vector_math_64.dart';

import 'object.dart';
import 'sliver.dart';

/// A sliver that places multiple sliver children in a linear array along the
/// main axis.
///
/// The layout algorithm lays out slivers one by one. If the sliver is at the top
/// of the viewport or above the top, then we pass in a nonzero [SliverConstraints.scrollOffset]
/// to inform the sliver at what point along the main axis we should start layout.
/// For the slivers that come after it, we compute the amount of space taken up so
/// far to be used as the [SliverPhysicalParentData.paintOffset] and the
/// [SliverConstraints.remainingPaintExtent] to be passed in as a constraint.
///
/// Finally, this sliver will also ensure that all child slivers are painted within
/// the total scroll extent of the group by adjusting the child's
/// [SliverPhysicalParentData.paintOffset] as necessary. This can happen for
/// slivers such as [SliverPersistentHeader] which, when pinned, positions itself
/// at the top of the [Viewport] regardless of the scroll offset.
class RenderNestedSlivers extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData>,
        SliverSequenceMixin {
  RenderNestedSlivers({SliverPaintOrder? paintOrder}) : _paintOrder = paintOrder;

  @override
  SliverPaintOrder get paintOrder {
    return _paintOrder ??
        switch (RenderAbstractViewport.maybeOf(this)) {
          RenderViewportBase(:final SliverPaintOrder paintOrder) => paintOrder,
          _ => SliverPaintOrder.firstIsTop,
        };
  }

  SliverPaintOrder? _paintOrder;
  set paintOrder(SliverPaintOrder? value) {
    if (_paintOrder == value) {
      return;
    }
    _paintOrder = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
    }
  }

  @override
  double? childScrollOffset(RenderSliver child) {
    assert(child.parent == this);

    return scrollOffsetOf(child, -_maxScrollObstructionExtentBefore(child));
  }

  double _maxScrollObstructionExtentBefore(RenderSliver child) {
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        var pinnedExtent = 0.0;
        RenderSliver? current = firstChild;
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        var pinnedExtent = 0.0;
        RenderSliver? current = lastChild;
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    final Offset childPaintOffset = paintOffsetOf(child);
    return switch (applyGrowthDirectionToAxisDirection(
      child.constraints.axisDirection,
      child.constraints.growthDirection,
    )) {
      AxisDirection.down => childPaintOffset.dy,
      AxisDirection.right => childPaintOffset.dx,
      AxisDirection.up => geometry!.paintExtent - child.geometry!.paintExtent - childPaintOffset.dy,
      AxisDirection.left =>
        geometry!.paintExtent - child.geometry!.paintExtent - childPaintOffset.dx,
    };
  }

  @override
  double childCrossAxisPosition(RenderSliver child) => 0.0;

  @override
  void performLayout() {
    final RenderSliver? leadingChild;
    final RenderSliver? Function(RenderSliver) advance;

    switch (constraints.growthDirection) {
      case GrowthDirection.forward:
        leadingChild = firstChild;
        advance = childAfter;
      case GrowthDirection.reverse:
        leadingChild = lastChild;
        advance = childBefore;
    }

    if (leadingChild == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    final double scrollOffsetCorrection = layoutChildSequence(
      child: leadingChild,
      axisDirection: constraints.axisDirection,
      crossAxisDirection: constraints.crossAxisDirection,
      scrollOffset: constraints.scrollOffset,
      overlap: constraints.overlap,
      layoutOffset: -math.min(constraints.overlap, 0.0),
      remainingPaintExtent: constraints.remainingPaintExtent,
      mainAxisExtent: constraints.remainingPaintExtent,
      crossAxisExtent: constraints.crossAxisExtent,
      userScrollDirection: constraints.userScrollDirection,
      growthDirection: constraints.growthDirection,
      advance: advance,
      remainingCacheExtent: constraints.remainingCacheExtent,
      cacheOrigin: constraints.cacheOrigin,
      updateParentGeometry: (geometry) {
        this.geometry = geometry;
      },
    );

    if (scrollOffsetCorrection != 0.0) {
      geometry = SliverGeometry(scrollOffsetCorrection: scrollOffsetCorrection);
    }

    final AxisDirection appliedGrowthDirectionToAxisDirection = applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    );

    if (appliedGrowthDirectionToAxisDirection == AxisDirection.left ||
        appliedGrowthDirectionToAxisDirection == AxisDirection.up) {
      RenderSliver? child = leadingChild;
      while (child != null) {
        final childParentData = child.parentData! as SliverPhysicalParentData;
        childParentData.paintOffset += switch (axisDirectionToAxis(
          appliedGrowthDirectionToAxisDirection,
        )) {
          Axis.horizontal => Offset(geometry!.paintExtent, 0.0),
          Axis.vertical => Offset(0.0, geometry!.paintExtent),
        };
        child = advance(child);
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => paintContents(context, offset);

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final childParentData = child.parentData! as SliverPhysicalParentData;
    return childParentData.paintOffset;
  }

  @override
  void applyPaintTransform(RenderSliver child, Matrix4 transform) {
    final childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    RenderSliver? child = firstChild;
    while (child != null) {
      final Offset paintOffset = (child.parentData! as SliverPhysicalParentData).paintOffset;
      final bool isHit = result.addWithAxisOffset(
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
        paintOffset: paintOffset,
        mainAxisOffset: childMainAxisPosition(child),
        crossAxisOffset: childCrossAxisPosition(child),
        hitTest: child.hitTest,
      );
      if (isHit) {
        return true;
      }
      child = childAfter(child);
    }
    return false;
  }

  @override
  RenderSliver? get origin => switch (applyGrowthDirectionToAxisDirection(
    constraints.axisDirection,
    constraints.growthDirection,
  )) {
    AxisDirection.left || AxisDirection.up => lastChild,
    AxisDirection.right || AxisDirection.down => firstChild,
  };

  @override
  void updateChildLayoutOffset(
    RenderSliver child,
    double layoutOffset,
    GrowthDirection growthDirection,
  ) {
    final childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.paintOffset = switch (applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    )) {
      AxisDirection.left => Offset(-layoutOffset - child.geometry!.paintExtent, 0.0),
      AxisDirection.up => Offset(0.0, -layoutOffset - child.geometry!.paintExtent),
      AxisDirection.right => Offset(layoutOffset, 0.0),
      AxisDirection.down => Offset(0.0, layoutOffset),
    };
  }

  @override
  bool get ensureSemantics {
    RenderSliver? child = firstChild;
    while (child != null) {
      if (child.ensureSemantics) {
        return true;
      }
      child = childAfter(child);
    }
    return false;
  }
}
