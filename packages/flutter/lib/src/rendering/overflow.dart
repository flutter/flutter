// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

export 'package:flutter/src/painting/box_painter.dart';

/// A render box that's a specific size but passes its original constraints through to its child, which will probably overflow
class RenderSizedOverflowBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderSizedOverflowBox({
    RenderBox child,
    Size requestedSize
  }) : _requestedSize = requestedSize {
    assert(requestedSize != null);
    this.child = child;
  }

  /// The size this render box should attempt to be.
  Size get requestedSize => _requestedSize;
  Size _requestedSize;
  void set requestedSize (Size value) {
    assert(value != null);
    if (_requestedSize == value)
      return;
    _requestedSize = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(_requestedSize.width);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(_requestedSize.width);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(_requestedSize.height);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(_requestedSize.height);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    size = constraints.constrain(_requestedSize);
    if (child != null)
      child.layout(constraints);
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class RenderOffStage extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderOffStage({ RenderBox child }) {
    this.child = child;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;
  double getMaxIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;
  double getMinIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;
  double getMaxIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.smallest;
  }

  void performLayout() {
    if (child != null)
      child.layout(constraints);
  }

  bool hitTest(HitTestResult result, { Point position }) => false;
  void paint(PaintingContext context, Offset offset) { }
  void visitChildrenForSemantics(RenderObjectVisitor visitor) { }
}
