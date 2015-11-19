// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'box.dart';
import 'object.dart';

/// An immutable 2D, axis-aligned, floating-point rectangle whose coordinates
/// are given relative to another rectangle's edges, known as the container.
/// Since the dimensions of the rectangle are relative to those of the
/// container, this class has no width and height members. To determine the
/// width or height of the rectangle, convert it to a [Rect] using [toRect()]
/// (passing the container's own Rect), and then examine that object.
class RelativeRect {

  /// Creates a RelativeRect with the given values.
  const RelativeRect.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Creates a RelativeRect from a Rect and a Size. The Rect (first argument)
  /// and the RelativeRect (the output) are in the coordinate space of the
  /// rectangle described by the Size, with 0,0 being at the top left.
  factory RelativeRect.fromSize(Rect rect, Size container) {
    return new RelativeRect.fromLTRB(rect.left, rect.top, container.width - rect.right, container.height - rect.bottom);
  }

  /// Creates a RelativeRect from two Rects. The second Rect provides the
  /// container, the first provides the rectangle, in the same coordinate space,
  /// that is to be converted to a RelativeRect. The output will be in the
  /// container's coordinate space.
  ///
  /// For example, if the top left of the rect is at 0,0, and the top left of
  /// the container is at 100,100, then the top left of the output will be at
  /// -100,-100.
  ///
  /// If the first rect is actually in the container's coordinate space, then
  /// use [RelativeRect.fromSize] and pass the container's size as the second
  /// argument instead.
  factory RelativeRect.fromRect(Rect rect, Rect container) {
    return new RelativeRect.fromLTRB(
      rect.left - container.left,
      rect.top - container.top,
      container.right - rect.right,
      container.bottom - rect.bottom
    );
  }

  static final RelativeRect fill = new RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0);

  /// Distance from the left side of the container to the left side of this rectangle.
  final double left;

  /// Distance from the top side of the container to the top side of this rectangle.
  final double top;

  /// Distance from the right side of the container to the right side of this rectangle.
  final double right;

  /// Distance from the bottom side of the container to the bottom side of this rectangle.
  final double bottom;

  /// Returns a new rectangle object translated by the given offset.
  RelativeRect shift(Offset offset) {
    return new RelativeRect.fromLTRB(left + offset.dx, top + offset.dy, right + offset.dx, bottom + offset.dy);
  }

  /// Returns a new rectangle with edges moved outwards by the given delta.
  RelativeRect inflate(double delta) {
    return new RelativeRect.fromLTRB(left - delta, top - delta, right + delta, bottom + delta);
  }

  /// Returns a new rectangle with edges moved inwards by the given delta.
  RelativeRect deflate(double delta) {
    return inflate(-delta);
  }

  /// Returns a new rectangle that is the intersection of the given rectangle and this rectangle.
  RelativeRect intersect(RelativeRect other) {
    return new RelativeRect.fromLTRB(
      math.max(left, other.left),
      math.max(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom)
    );
  }

  /// Convert this RelativeRect to a Rect, in the coordinate space of the container.
  Rect toRect(Rect container) {
    return new Rect.fromLTRB(left, top, container.width - right, container.height - bottom);
  }

  /// Linearly interpolate between two RelativeRects.
  ///
  /// If either rect is null, this function interpolates from [RelativeRect.fill].
  static RelativeRect lerp(RelativeRect a, RelativeRect b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new RelativeRect.fromLTRB(b.left * t, b.top * t, b.right * t, b.bottom * t);
    if (b == null) {
      double k = 1.0 - t;
      return new RelativeRect.fromLTRB(b.left * k, b.top * k, b.right * k, b.bottom * k);
    }
    return new RelativeRect.fromLTRB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t)
    );
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! RelativeRect)
      return false;
    final RelativeRect typedOther = other;
    return left == typedOther.left &&
           top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + left.hashCode;
    value = 37 * value + top.hashCode;
    value = 37 * value + right.hashCode;
    value = 37 * value + bottom.hashCode;
    return value;
  }

  String toString() => "RelativeRect.fromLTRB(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})";
}

/// Parent data for use with [RenderStack]
class StackParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// The offset of the child's top edge from the top of the stack.
  double top;

  /// The offset of the child's right edge from the right of the stack.
  double right;

  /// The offset of the child's bottom edge from the bottom of the stack.
  double bottom;

  /// The offset of the child's left edge from the left of the stack.
  double left;

  /// The child's width.
  ///
  /// Ignored if both left and right are non-null.
  double width;

  /// The child's height.
  ///
  /// Ignored if both top and bottom are non-null.
  double height;

  /// Get or set the current values in terms of a RelativeRect object.
  RelativeRect get rect => new RelativeRect.fromLTRB(left, top, right, bottom);
  void set rect(RelativeRect value) {
    left = value.left;
    top = value.top;
    right = value.right;
    bottom = value.bottom;
  }

  void merge(StackParentData other) {
    if (other.top != null)
      top = other.top;
    if (other.right != null)
      right = other.right;
    if (other.bottom != null)
      bottom = other.bottom;
    if (other.left != null)
      left = other.left;
    if (other.width != null)
      width = other.width;
    if (other.height != null)
      height = other.height;
    super.merge(other);
  }

  /// Whether this child is considered positioned
  ///
  /// A child is positioned if any of the top, right, bottom, or left offsets
  /// are non-null. Positioned children do not factor into determining the size
  /// of the stack but are instead placed relative to the non-positioned
  /// children in the stack.
  bool get isPositioned => top != null || right != null || bottom != null || left != null || width != null || height != null;

  String toString() => '${super.toString()}; top=$top; right=$right; bottom=$bottom, left=$left';
}

abstract class RenderStackBase extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, StackParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStackBase({
    List<RenderBox> children,
    alignment: const FractionalOffset(0.0, 0.0)
  }) : _alignment = alignment {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = new StackParentData();
  }

  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  void set alignment (FractionalOffset value) {
    if (_alignment != value) {
      _alignment = value;
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
        double x = (size.width - child.size.width) * alignment.x;
        double y = (size.height - child.size.height) * alignment.y;
        childParentData.position = new Point(x, y);
      } else {
        BoxConstraints childConstraints = const BoxConstraints();

        if (childParentData.left != null && childParentData.right != null)
          childConstraints = childConstraints.tightenWidth(size.width - childParentData.right - childParentData.left);
        else if (childParentData.width != null)
          childConstraints = childConstraints.tightenWidth(childParentData.width);

        if (childParentData.top != null && childParentData.bottom != null)
          childConstraints = childConstraints.tightenHeight(size.height - childParentData.bottom - childParentData.top);
        else if (childParentData.height != null)
          childConstraints = childConstraints.tightenHeight(childParentData.height);

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

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void paintStack(PaintingContext context, Offset offset);

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow) {
      context.pushClipRect(needsCompositing, offset, Point.origin & size, paintStack);
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
/// parameter. The left of each non-positioned child becomes the
/// difference between the child's width and the stack's width scaled by
/// alignment.x. The top of each non-positioned child is computed
/// similarly and scaled by alignement.y. So if the alignment x and y properties
/// are 0.0 (the default) then the non-positioned children remain in the
/// upper-left corner. If the alignment x and y properties are 0.5 then the
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
    alignment: const FractionalOffset(0.0, 0.0)
  }) : super(
   children: children,
   alignment: alignment
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
    alignment: const FractionalOffset(0.0, 0.0),
    int index: 0
  }) : _index = index, super(
   children: children,
   alignment: alignment
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

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (firstChild == null)
      return false;
    assert(position != null);
    RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    Point transformed = new Point(position.x - childParentData.position.x,
                                  position.y - childParentData.position.y);
    return child.hitTest(result, position: transformed);
  }

  void paintStack(PaintingContext context, Offset offset) {
    if (firstChild == null)
      return;
    RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.offset + offset);
  }
}
