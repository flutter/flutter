// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/object.dart';

/// Parent data for use with [RenderStack]
class StackParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> {
  /// The offset of the child's top edge from the top of the stack
  double top;

  /// The offset of the child's right edge from the right of the stack
  double right;

  /// The offset of the child's bottom edge from the bottom of the stack
  double bottom;

  /// The offset of the child's left edge from the left of the stack
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

  /// Whether this child is considered positioned
  ///
  /// A child is positioned if any of the top, right, bottom, or left offsets
  /// are non-null. Positioned children do not factor into determining the size
  /// of the stack but are instead placed relative to the non-positioned
  /// children in the stack.
  bool get isPositioned => top != null || right != null || bottom != null || left != null;

  String toString() => '${super.toString()}; top=$top; right=$right; bottom=$bottom, left=$left';
}

/// Implements the stack layout algorithm
///
/// In a stack layout, the children are positioned on top of each other in the
/// order in which they appear in the child list. First, the non-positioned
/// children (those with null values for top, right, bottom, and left) are
/// layed out and placed in the upper-left corner of the stack. The stack is
/// then sized to enclose all of the non-positioned children. If there are no
/// non-positioned children, the stack becomes as large as possible.
///
/// Next, the positioned children are laid out. If a child has top and bottom
/// values that are both non-null, the child is given a fixed height determined
/// by deflating the width of the stack by the sum of the top and bottom values.
/// Similarly, if the child has rigth and left values that are both non-null,
/// the child is given a fixed width. Otherwise, the child is given unbounded
/// space in the non-fixed dimensions.
///
/// Once the child is laid out, the stack positions the child according to the
/// top, right, bottom, and left offsets. For example, if the top value is 10.0,
/// the top edge of the child will be placed 10.0 pixels from the top edge of
/// the stack. If the child extends beyond the bounds of the stack, the stack
/// will clip the child's painting to the bounds of the stack.
class RenderStack extends RenderBox with ContainerRenderObjectMixin<RenderBox, StackParentData>,
                                         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStack({
    Iterable<RenderBox> children
  }) {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

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

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  void performLayout() {
    _hasVisualOverflow = false;
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

    child = firstChild;
    while (child != null) {
      assert(child.parentData is StackParentData);
      final StackParentData childData = child.parentData;

      if (childData.isPositioned) {
        BoxConstraints childConstraints = const BoxConstraints();

        if (childData.left != null && childData.right != null)
          childConstraints = childConstraints.tightenWidth(size.width - childData.right - childData.left);

        if (childData.top != null && childData.bottom != null)
          childConstraints = childConstraints.tightenHeight(size.height - childData.bottom - childData.top);

        child.layout(childConstraints, parentUsesSize: true);

        double x = 0.0;
        if (childData.left != null)
          x = childData.left;
        else if (childData.right != null)
          x = size.width - childData.right - child.size.width;

        if (x < 0.0 || x + child.size.width > size.width)
          _hasVisualOverflow = true;

        double y = 0.0;
        if (childData.top != null)
          y = childData.top;
        else if (childData.bottom != null)
          y = size.height - childData.bottom - child.size.height;

        if (y < 0.0 || y + child.size.height > size.height)
          _hasVisualOverflow = true;

        childData.position = new Point(x, y);
      }

      child = childData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow) {
      context.canvas.save();
      context.canvas.clipRect(offset & size);
      defaultPaint(context, offset);
      context.canvas.restore();
    } else {
      defaultPaint(context, offset);
    }
  }
}
