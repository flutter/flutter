// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

import 'object.dart';
import 'sliver.dart';

/// A sliver that places multiple sliver children in a linear array along the cross
/// axis.
///
/// Since the extent of the viewport in the cross axis direction is finite,
/// this extent will be divided up and allocated to the children slivers.
///
/// The algorithm for dividing up the cross axis extent is as follows.
/// Every widget has a [SliverPhysicalParentData.crossAxisFlex] value associated with them.
/// First, lay out all of the slivers with flex of 0 or null, in which case the slivers themselves will
/// figure out how much cross axis extent to take up. For example, [SliverConstrainedCrossAxis]
/// is an example of a widget which sets its own flex to 0. Then [RenderSliverCrossAxisGroup] will
/// divide up the remaining space to all the remaining children proportionally
/// to each child's flex factor. By default, children of [SliverCrossAxisGroup]
/// are setup to have a flex factor of 1, but a different flex factor can be
/// specified via the [SliverCrossAxisExpanded] widgets.
class RenderSliverCrossAxisGroup extends RenderSliver with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
      (child.parentData! as SliverPhysicalParentData).crossAxisFlex = 1;
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
    double remainingExtent = crossAxisExtent;
    RenderSliver? child = firstChild;
    while (child != null) {
      final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
      final int flex = childParentData.crossAxisFlex ?? 0;
      if (flex == 0) {
        // If flex is 0 or null, then the child sliver must provide their own crossAxisExtent.
        assert(_assertOutOfExtent(remainingExtent));
        child.layout(constraints.copyWith(crossAxisExtent: remainingExtent), parentUsesSize: true);
        final double? childCrossAxisExtent = child.geometry!.crossAxisExtent;
        assert(childCrossAxisExtent != null);
        remainingExtent = math.max(0.0, remainingExtent - childCrossAxisExtent!);
      } else {
        totalFlex += flex;
      }
      child = childAfter(child);
    }
    final double extentPerFlexValue = remainingExtent / totalFlex;

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
        assert(_assertOutOfExtent(childExtent));
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

    // Set the geometry with the proper crossAxisExtent.
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

bool _assertOutOfExtent(double extent) {
  if(extent <= 0.0) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('SliverCrossAxisGroup ran out of extent before child could be laid out.'),
      ErrorDescription(
        'SliverCrossAxisGroup lays out any slivers with a constrained cross '
        'axis before laying out those which expand. In this case, cross axis '
        'extent was used up before the next sliver could be laid out.'
      ),
      ErrorHint(
        'Make sure that the total amount of extent allocated by constrained '
        'child slivers does not exceed the cross axis extent that is available '
        'for the SliverCrossAxisGroup.'
      ),
    ]);
  }
  return true;
}
