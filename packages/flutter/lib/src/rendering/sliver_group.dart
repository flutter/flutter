// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A sliver that lays out its sliver children along the main axis of the view port.
///
/// See also:
///
/// * [RenderFlex], boxes to place multiple box children in a linear array.
/// * [RenderSliverList], a sliver to place multiple box children in a linear array along the main axis.
/// * [RenderViewport], a box to place multiple sliver children in a linear array.
/// * [RenderSliverToBoxAdapter], to place a single box child where a sliver is expected.
class RenderSliverGroup extends RenderSliver with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
  /// Creates a render object that lays out it children along the main axis of the viewport
  RenderSliverGroup({List<RenderSliver> children}) {
    addAll(children);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = SliverPhysicalContainerParentData();
  }

  @override
  void performLayout() {
    RenderSliver child = firstChild;

    double layoutOffset = 0;
    double scrollOffset = constraints.scrollOffset;
    double precedingScrollExtent = constraints.precedingScrollExtent;
    double maxPaintOffset = layoutOffset + constraints.overlap;

    geometry = SliverGeometry.zero;

    while (child != null) {
      final double childScrollOffset = math.max(0, scrollOffset - layoutOffset);

      child.layout(
        constraints.copyWith(
          scrollOffset: childScrollOffset,
          precedingScrollExtent: precedingScrollExtent,
          overlap: maxPaintOffset - layoutOffset,
          remainingPaintExtent: math.max(0, constraints.remainingPaintExtent - layoutOffset),
          remainingCacheExtent: math.max(0, constraints.remainingCacheExtent - layoutOffset),
          cacheOrigin: math.max(-childScrollOffset, constraints.cacheOrigin),
        ),
        parentUsesSize: true
      );

      final SliverPhysicalContainerParentData childParentData = child.parentData;
      final SliverGeometry childGeometry = child.geometry;

      geometry = SliverGeometry(
        scrollExtent: geometry.scrollExtent + childGeometry.scrollExtent,
        paintExtent: math.max(geometry.paintExtent, layoutOffset + childGeometry.paintOrigin + childGeometry.paintExtent),
        layoutExtent: geometry.layoutExtent + childGeometry.layoutExtent,
        maxPaintExtent: geometry.maxPaintExtent + childGeometry.maxPaintExtent,
        maxScrollObstructionExtent: geometry.maxScrollObstructionExtent + childGeometry.maxScrollObstructionExtent,
        hitTestExtent: geometry.hitTestExtent + childGeometry.hitTestExtent,
        visible: geometry.visible || childGeometry.visible,
        hasVisualOverflow: geometry.hasVisualOverflow || childGeometry.hasVisualOverflow,
        scrollOffsetCorrection: childGeometry.scrollOffsetCorrection,
        cacheExtent: geometry.cacheExtent + childGeometry.cacheExtent,
      );

      // No need to layout other children as parent has to correct the scrollOffset
      // and layout us again.
      if (geometry.scrollOffsetCorrection != null) {
        return;
      }

      final double effectiveLayoutOffset = layoutOffset + childGeometry.paintOrigin;

      childParentData.paintOffset = _computeAbsolutePaintOffset(child, effectiveLayoutOffset);

      maxPaintOffset = math.max(effectiveLayoutOffset + childGeometry.paintExtent, maxPaintOffset);

      layoutOffset = layoutOffset + math.min(constraints.remainingPaintExtent, childGeometry.layoutExtent);
      precedingScrollExtent += childGeometry.scrollExtent;
      scrollOffset -= childGeometry.scrollExtent;

      child = childParentData.nextSibling;
    }
  }

  Offset _computeAbsolutePaintOffset(RenderSliver child, double layoutOffset) {
    assert(child != null);
    assert(child.geometry != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
      case AxisDirection.down:
        return Offset(0.0, layoutOffset);
      case AxisDirection.right:
      case AxisDirection.left:
        return Offset(layoutOffset, 0.0);
    }
    return null;
  }

  @override
  double childMainAxisPosition(RenderObject child) {
    assert(child.parent == this);
    final SliverPhysicalContainerParentData childParentData = child.parentData;
    // TODO: implement childMainAxisPosition
  }

  @override
  double childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    // TODO
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final RenderSliver child in _childrenInPaintOrder) {
      final SliverPhysicalContainerParentData childParentData = child.parentData;
      if (child.geometry.visible) {
        context.paintChild(child, offset + childParentData.paintOffset);
      }
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {@required double mainAxisPosition, @required double crossAxisPosition}) {
    assert(mainAxisPosition != null);
    assert(crossAxisPosition != null);
    for (final RenderSliver child in _childrenInPaintOrder) {
      if (child.geometry.visible &&
          child.hitTest(
            result,
            mainAxisPosition: _computeChildMainAxisPosition(child, mainAxisPosition),
            crossAxisPosition: crossAxisPosition,
          )) {
        return true;
      }
    }
    return false;
  }

  double _computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        return parentMainAxisPosition - childParentData.paintOffset.dy;
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.paintOffset.dx;
      case AxisDirection.up:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dy);
      case AxisDirection.left:
        return child.geometry.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dx);
    }
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  Iterable<RenderSliver> get _childrenInPaintOrder sync* {
    RenderSliver child = lastChild;
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }
}
