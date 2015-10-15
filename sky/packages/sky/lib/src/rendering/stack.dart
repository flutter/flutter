// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// Parent data for use with [RenderStack]
class StackParentData extends ContainerBoxParentDataMixin<RenderBox> {
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

abstract class RenderStackBase extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, StackParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStackBase({
    List<RenderBox> children,
    double horizontalAlignment: 0.0,
    double verticalAlignment: 0.0
  }) : _horizontalAlignment = horizontalAlignment, _verticalAlignment = verticalAlignment {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = new StackParentData();
  }

  double get horizontalAlignment => _horizontalAlignment;
  double _horizontalAlignment;
  void set horizontalAlignment (double value) {
    if (_horizontalAlignment != value) {
      _horizontalAlignment = value;
      markNeedsLayout();
    }
  }

  double get verticalAlignment => _verticalAlignment;
  double _verticalAlignment;
  void set verticalAlignment (double value) {
    if (_verticalAlignment != value) {
      _verticalAlignment = value;
      markNeedsLayout();
    }
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    double width = constraints.minWidth;
    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned)
        width = math.max(width, child.getMinIntrinsicWidth(constraints));
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    assert(width == constraints.constrainWidth(width));
    return width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    bool hasNonPositionedChildren = false;
    double width = constraints.minWidth;
    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;
        width = math.max(width, child.getMaxIntrinsicWidth(constraints));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
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
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned)
        height = math.max(height, child.getMinIntrinsicHeight(constraints));
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    assert(height == constraints.constrainHeight(height));
    return height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    bool hasNonPositionedChildren = false;
    double height = constraints.minHeight;
    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;
        height = math.max(height, child.getMaxIntrinsicHeight(constraints));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
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
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;

        child.layout(constraints, parentUsesSize: true);
        childParentData.position = Point.origin;

        final Size childSize = child.size;
        width = math.max(width, childSize.width);
        height = math.max(height, childSize.height);
      }

      child = childParentData.nextSibling;
    }

    if (hasNonPositionedChildren) {
      size = new Size(width, height);
      assert(size.width == constraints.constrainWidth(width));
      assert(size.height == constraints.constrainHeight(height));
    } else {
      size = constraints.biggest;
    }

    assert(!size.isInfinite);

    child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        double x = (size.width - child.size.width) * horizontalAlignment;
        double y = (size.height - child.size.height) * verticalAlignment;
        childParentData.position = new Point(x, y);
      } else {
        BoxConstraints childConstraints = const BoxConstraints();

        if (childParentData.left != null && childParentData.right != null)
          childConstraints = childConstraints.tightenWidth(size.width - childParentData.right - childParentData.left);

        if (childParentData.top != null && childParentData.bottom != null)
          childConstraints = childConstraints.tightenHeight(size.height - childParentData.bottom - childParentData.top);

        child.layout(childConstraints, parentUsesSize: true);

        double x = 0.0;
        if (childParentData.left != null)
          x = childParentData.left;
        else if (childParentData.right != null)
          x = size.width - childParentData.right - child.size.width;

        if (x < 0.0 || x + child.size.width > size.width)
          _hasVisualOverflow = true;

        double y = 0.0;
        if (childParentData.top != null)
          y = childParentData.top;
        else if (childParentData.bottom != null)
          y = size.height - childParentData.bottom - child.size.height;

        if (y < 0.0 || y + child.size.height > size.height)
          _hasVisualOverflow = true;

        childParentData.position = new Point(x, y);
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paintStack(PaintingContext context, Offset offset);

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow) {
      context.canvas.save();
      context.canvas.clipRect(offset & size);
      paintStack(context, offset);
      context.canvas.restore();
    } else {
      paintStack(context, offset);
    }
  }
}

/// Implements the stack layout algorithm
///
/// In a stack layout, the children are positioned on top of each other in the
/// order in which they appear in the child list. First, the non-positioned
/// children (those with null values for top, right, bottom, and left) are
/// initially layed out and placed in the upper-left corner of the stack. The
/// stack is then sized to enclose all of the non-positioned children. If there
/// are no non-positioned children, the stack becomes as large as possible.
///
/// The final location of non-positioned children is determined by the alignment
/// parameters. The left of each non-positioned child becomes the
/// difference between the child's width and the stack's width scaled by
/// horizontalAlignment. The top of each non-positioned child is computed
/// similarly and scaled by verticalAlignement. So if the alignment parameters
/// are 0.0 (the default) then the non-positioned children remain in the
/// upper-left corner. If the alignment parameters are 0.5 then the
/// non-positioned children are centered within the stack.
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
class RenderStack extends RenderStackBase {
  RenderStack({
    List<RenderBox> children,
    double horizontalAlignment: 0.0,
    double verticalAlignment: 0.0
  }) : super(
   children: children,
   horizontalAlignment: horizontalAlignment,
   verticalAlignment: verticalAlignment
 );

  void paintStack(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

/// Implements the same layout algorithm as RenderStack but only paints the child
/// specified by index.
/// Note: although only one child is displayed, the cost of the layout algorithm is
/// still O(N), like an ordinary stack.
class RenderIndexedStack extends RenderStackBase {
  RenderIndexedStack({
    List<RenderBox> children,
    double horizontalAlignment: 0.0,
    double verticalAlignment: 0.0,
    int index: 0
  }) : _index = index, super(
   children: children,
   horizontalAlignment: horizontalAlignment,
   verticalAlignment: verticalAlignment
  );

  int get index => _index;
  int _index;
  void set index (int value) {
    if (_index != value) {
      _index = value;
      markNeedsLayout();
    }
  }

  RenderBox _childAtIndex() {
    RenderBox child = firstChild;
    int i = 0;
    while (child != null && i < index) {
      final StackParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
      i += 1;
    }
    assert(i == index);
    assert(child != null);
    return child;
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    if (firstChild == null)
      return;
    assert(position != null);
    RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    Point transformed = new Point(position.x - childParentData.position.x,
                                  position.y - childParentData.position.y);
    child.hitTest(result, position: transformed);
  }

  void paintStack(PaintingContext context, Offset offset) {
    if (firstChild == null)
      return;
    RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.position + offset);
  }
}
