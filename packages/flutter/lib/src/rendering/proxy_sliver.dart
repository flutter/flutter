// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

/// A base class for sliver render objects that resemble their children.
///
/// A proxy sliver has a single child and simply mimics all the properties of
/// that child by calling through to the child for each function in the render
/// sliver protocol. For example, a proxy sliver determines its geometry by
/// asking its sliver child to layout with the same constraints and then
/// matching the geometry.
///
/// A proxy sliver isn't useful on its own because you might as well just
/// replace the proxy sliver with its child. However, RenderProxySliver is a
/// useful base class for render objects that wish to mimic most, but not all,
/// of the properties of their sliver child.
abstract class RenderProxySliver extends RenderSliver with RenderObjectWithChildMixin<RenderSliver> {
  /// Creates a proxy render sliver.
  ///
  /// Proxy render slivers aren't created directly because they simply proxy
  /// the render sliver protocol to their sliver [child]. Instead, use one of
  /// the subclasses.
  RenderProxySliver([RenderSliver child]) {
    this.child = child;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    assert(child != null);
    child.layout(constraints, parentUsesSize: true);
    geometry = child.geometry;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {double mainAxisPosition, double crossAxisPosition}) {
    return child != null
      && child.geometry.hitTestExtent > 0
      && child.hitTest(
        result,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    assert(child != null);
    assert(child == this.child);
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null)
      visitor(child);
  }
}