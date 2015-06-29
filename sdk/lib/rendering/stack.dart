// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

class StackParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> {
  double top;
  double right;
  double bottom;
  double left;

  void merge(StackParentData other) {
    if (other.top != null)
      top = other.top;
    if (other.right != null)
      right = other.right;
    if (other.bottom != null)
      bottom = other.bottom;
    if (other.left != null)
      left = other.left;
    super.merge(other);
  }

  bool get isPositioned => top != null || right != null || bottom != null || left != null;

  String toString() => '${super.toString()}; top=$top; right=$right; bottom=$bottom, left=$left';
}

class RenderStack extends RenderBox with ContainerRenderObjectMixin<RenderBox, StackParentData>,
                                         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStack({
    List<RenderBox> children
  }) {
    addAll(children);
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = new StackParentData();
  }


  double getMinIntrinsicWidth(BoxConstraints constraints) {
    double width = constraints.minWidth;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      if (!child.parentData.isPositioned)
        width = math.max(width, child.getMinIntrinsicWidth(constraints));
      child = child.parentData.nextSibling;
    }
    assert(width == constraints.constrainWidth(width));
    return width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    bool hasNonPositionedChildren = false;
    double width = constraints.minWidth;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      if (!child.parentData.isPositioned) {
        hasNonPositionedChildren = true;
        width = math.max(width, child.getMaxIntrinsicWidth(constraints));
      }
      child = child.parentData.nextSibling;
    }
    if (!hasNonPositionedChildren)
      return constraints.constrainWidth();
    assert(width == constraints.constrainWidth(width));
    return width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    double height = constraints.minHeight;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      if (!child.parentData.isPositioned)
        height = math.max(height, child.getMinIntrinsicHeight(constraints));
      child = child.parentData.nextSibling;
    }
    assert(height == constraints.constrainHeight(height));
    return height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    bool hasNonPositionedChildren = false;
    double height = constraints.minHeight;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      if (!child.parentData.isPositioned) {
        hasNonPositionedChildren = true;
        height = math.max(height, child.getMaxIntrinsicHeight(constraints));
      }
      child = child.parentData.nextSibling;
    }
    if (!hasNonPositionedChildren)
      return constraints.constrainHeight();
    assert(height == constraints.constrainHeight(height));
    return height;
  }

  double getDistanceToActualBaseline(TextBaseline baseline) {
    return defaultGetDistanceToHighestActualBaseline(baseline);
  }

  void performLayout() {
    bool hasNonPositionedChildren = false;

    double width = 0.0;
    double height = 0.0;

    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      final StackParentData parentData = child.parentData;

      if (!parentData.isPositioned) {
        hasNonPositionedChildren = true;

        child.layout(constraints, parentUsesSize: true);
        parentData.position = Point.origin;

        final Size childSize = child.size;
        width = math.max(width, childSize.width);
        height = math.max(height, childSize.height);
      }

      child = parentData.nextSibling;
    }

    if (hasNonPositionedChildren)
      size = new Size(width, height);
    else
      size = constraints.biggest;

    assert(!size.isInfinite);
    assert(size.width == constraints.constrainWidth(width));
    assert(size.height == constraints.constrainHeight(height));

    BoxConstraints innerConstraints = new BoxConstraints.loose(size);

    child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      final StackParentData childData = child.parentData;

      if (childData.isPositioned) {
        BoxConstraints childConstraints = innerConstraints;

        if (childData.left != null && childData.right != null)
          childConstraints = childConstraints.applyWidth(childData.right - childData.left);
        else if (childData.left != null)
          childConstraints = childConstraints.applyMaxWidth(size.width - childData.left);
        else if (childData.right != null)
          childConstraints = childConstraints.applyMaxWidth(size.width - childData.right);

        if (childData.top != null && childData.bottom != null)
          childConstraints = childConstraints.applyHeight(childData.bottom - childData.top);
        else if (childData.top != null)
          childConstraints = childConstraints.applyMaxHeight(size.height - childData.top);
        else if (childData.bottom != null)
          childConstraints = childConstraints.applyMaxHeight(size.width - childData.bottom);

        child.layout(childConstraints, parentUsesSize: true);

        double x = 0.0;
        if (childData.left != null)
          x = childData.left;
        else if (childData.right != null)
          x = size.width - childData.right - child.size.width;
        assert(x >= 0.0 && x + child.size.width <= size.width);

        double y = 0.0;
        if (childData.top != null)
          y = childData.top;
        else if (childData.bottom != null)
          y = size.height - childData.bottom - child.size.height;
        assert(y >= 0.0 && y + child.size.height <= size.height);

        childData.position = new Point(x, y);
      }

      child = childData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderCanvas canvas, Offset offset) {
    defaultPaint(canvas, offset);
  }
}
