// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class RenderOffStage extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  /// Creates an off-stage render object.
  RenderOffStage({ RenderBox child }) {
    this.child = child;
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.smallest;
  }

  @override
  void performLayout() {
    if (child != null)
      child.layout(constraints);
  }

  @override
  bool hitTest(HitTestResult result, { Point position }) => false;

  @override
  void paint(PaintingContext context, Offset offset) { }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) { }
}
