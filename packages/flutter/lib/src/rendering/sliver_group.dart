// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vector_math/vector_math_64.dart';

import 'object.dart';
import 'sliver.dart';

/// A sliver that places multiple sliver children in a linear array along the cross
/// axis.
///
/// Since the extent of the viewport in the cross axis direction is finite,
/// this extent will be divided up and allocated to the children sliver.
///
/// The algorithm for dividing up the cross axis extent is as follows.
/// Every widget has a [SliverPhysicalParentData.crossAxisFlex] value associated with them.
/// First, lay out all of the slivers with flex of 0, in which case the slivers themselves will
/// figure out how much cross axis extent to take up. Then [RenderSliverCrossAxisGroup] will
/// divide up the remaining space to all the remaining children proportionally to each child's flex value.
/// Flex values can be specified via the [SliverCrossAxisExpanded] widgets, but if
/// a sliver without [SliverCrossAxisExpanded] or [SliverConstrainedCrossAxis] is passed in,
/// it is assumed to have a flex value of 1.
class RenderSliverCrossAxisGroup extends RenderSliver with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
    }
  }

  @override
  double childMainAxisPosition(RenderSliver child) => 0.0;

  @override
  double childCrossAxisPosition(RenderSliver child) {
    switch (constraints.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.down:
        return (child.parentData! as SliverPhysicalParentData).paintOffset.dx;
      case AxisDirection.left:
      case AxisDirection.right:
        return (child.parentData! as SliverPhysicalParentData).paintOffset.dy;
    }
  }

  @override
  void performLayout() {
    // Iterate through each sliver.
    // Get the parent's dimensions.
    final double crossAxisExtent = constraints.crossAxisExtent;
    assert(crossAxisExtent.isFinite);

    // First, layout each child with flex == 0 or null.
    int totalFlex = 0;
    double usedUpExtent = 0.0;
    RenderSliver? child = firstChild;
    while (child != null) {
      final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
      final int flex = childParentData.crossAxisFlex ?? 0;
      if (flex == 0) {
        // If flex is 0 or null, then the child sliver must provide their own crossAxisExtent.
        child.layout(constraints, parentUsesSize: true);
        assert(child.geometry!.crossAxisExtent != null);
        usedUpExtent += child.geometry!.crossAxisExtent!;
      } else {
        totalFlex += flex;
      }
      child = childAfter(child);
    }
    final double extentPerFlexValue = (crossAxisExtent - usedUpExtent) / totalFlex;

    child = firstChild;
    double offset = 0.0;

    // At this point, all slivers with constrained cross axis should already be laid out.
    // Layout the rest and keep track of the child geometry with greatest scrollExtent.
    geometry = SliverGeometry.zero;
    while (child != null) {
      final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
      final int flex = childParentData.crossAxisFlex ?? 0;
      double childExtent;
      if (flex != 0) {
        childExtent = extentPerFlexValue * flex;
        child.layout(constraints.copyWith(
          crossAxisExtent: extentPerFlexValue * flex,
        ), parentUsesSize: true);
      } else {
        childExtent = child.geometry!.crossAxisExtent!;
      }
      // Set child parent data.
      switch (constraints.axis) {
        case Axis.vertical:
          childParentData.paintOffset = Offset(offset, 0.0);
        case Axis.horizontal:
          childParentData.paintOffset = Offset(0.0, offset);
      }
      offset += childExtent;
      if (geometry!.scrollExtent < child.geometry!.scrollExtent) {
        geometry = child.geometry;
      }
      child = childAfter(child);
    }

    // Update the child's geometry with the correct crossAxisExtent.
    geometry = geometry!.copyWith(crossAxisExtent: constraints.crossAxisExtent);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderSliver? child = firstChild;

    while (child != null) {
      final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
      context.paintChild(child, offset + childParentData.paintOffset);
      child = childAfter(child);
    }
  }

  @override
  void applyPaintTransform(RenderSliver child, Matrix4 transform) {
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {required double mainAxisPosition, required double crossAxisPosition}) {
    RenderSliver? child = lastChild;
    while (child != null) {
      final bool isHit = result.addWithAxisOffset(
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
        paintOffset: null,
        mainAxisOffset: childMainAxisPosition(child),
        crossAxisOffset: childCrossAxisPosition(child),
        hitTest: child.hitTest,
      );
      if (isHit) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }
}
