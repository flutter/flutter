// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    return constraints.constrainWidth(double.INFINITY);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(double.INFINITY);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(double.INFINITY);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(double.INFINITY);
  }

  void performLayout() {
    size = constraints.constrain(Size.infinite);
    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
    BoxConstraints innerConstraints = new BoxConstraints.loose(size);

    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      StackParentData parentData = child.parentData;

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

      child = child.parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderObjectDisplayList canvas) {
    defaultPaint(canvas);
  }
}
