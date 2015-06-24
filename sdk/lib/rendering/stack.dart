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
    if (children != null)
      children.forEach((child) { add(child); });
  }

  void setParentData(RenderBox child) {
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
      return constraints.constrainWidth(double.INFINITY);
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
      return constraints.constrainHeight(double.INFINITY);
    assert(height == constraints.constrainHeight(height));
    return height;
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
      size = constraints.constrain(Size.infinite);

    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
    assert(size.width == constraints.constrainWidth(width));
    assert(size.height == constraints.constrainHeight(height));

    BoxConstraints innerConstraints = new BoxConstraints.loose(size);

    child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      final StackParentData parentData = child.parentData;

      if (parentData.isPositioned) {
        BoxConstraints childConstraints = innerConstraints;

        if (parentData.left != null && parentData.right != null)
          childConstraints = childConstraints.applyWidth(parentData.right - parentData.left);
        else if (parentData.left != null)
          childConstraints = childConstraints.applyMaxWidth(size.width - parentData.left);
        else if (parentData.right != null)
          childConstraints = childConstraints.applyMaxWidth(size.width - parentData.right);

        if (parentData.top != null && parentData.bottom != null)
          childConstraints = childConstraints.applyHeight(parentData.bottom - parentData.top);
        else if (parentData.top != null)
          childConstraints = childConstraints.applyMaxHeight(size.height - parentData.top);
        else if (parentData.bottom != null)
          childConstraints = childConstraints.applyMaxHeight(size.width - parentData.bottom);

        child.layout(childConstraints);

        double x = 0.0;
        if (parentData.left != null)
          x = parentData.left;
        else if (parentData.right != null)
          x = size.width - parentData.right - child.size.width;
        assert(x >= 0.0 && x + child.size.width <= size.width);

        double y = 0.0;
        if (parentData.top != null)
          y = parentData.top;
        else if (parentData.bottom != null)
          y = size.height - parentData.bottom - child.size.height;
        assert(y >= 0.0 && y + child.size.height <= size.height);

        parentData.position = new Point(x, y);
      }

      child = parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderCanvas canvas) {
    defaultPaint(canvas);
  }
}
