// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

/// Doc
abstract class RenderProxySliver extends RenderSliver with RenderObjectWithChildMixin<RenderSliver> {
  /// Doc
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