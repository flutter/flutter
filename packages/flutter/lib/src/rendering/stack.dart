// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble, hashValues;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';

/// An immutable 2D, axis-aligned, floating-point rectangle whose coordinates
/// are given relative to another rectangle's edges, known as the container.
/// Since the dimensions of the rectangle are relative to those of the
/// container, this class has no width and height members. To determine the
/// width or height of the rectangle, convert it to a [Rect] using [toRect()]
/// (passing the container's own Rect), and then examine that object.
///
/// If you create the RelativeRect with null values, the methods on
/// RelativeRect will not work usefully (or at all).
@immutable
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

  /// A rect that covers the entire container.
  static final RelativeRect fill = const RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0);

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
    return new RelativeRect.fromLTRB(left + offset.dx, top + offset.dy, right - offset.dx, bottom - offset.dy);
  }

  /// Returns a new rectangle with edges moved outwards by the given delta.
  RelativeRect inflate(double delta) {
    return new RelativeRect.fromLTRB(left - delta, top - delta, right - delta, bottom - delta);
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

  /// Convert this [RelativeRect] to a [Rect], in the coordinate space of the container.
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
      final double k = 1.0 - t;
      return new RelativeRect.fromLTRB(b.left * k, b.top * k, b.right * k, b.bottom * k);
    }
    return new RelativeRect.fromLTRB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t)
    );
  }

  @override
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

  @override
  int get hashCode => hashValues(left, top, right, bottom);

  @override
  String toString() => "RelativeRect.fromLTRB(${left?.toStringAsFixed(1)}, ${top?.toStringAsFixed(1)}, ${right?.toStringAsFixed(1)}, ${bottom?.toStringAsFixed(1)})";
}

/// Parent data for use with [RenderStack].
class StackParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// The distance by which the child's top edge is inset from the top of the stack.
  double top;

  /// The distance by which the child's right edge is inset from the right of the stack.
  double right;

  /// The distance by which the child's bottom edge is inset from the bottom of the stack.
  double bottom;

  /// The distance by which the child's left edge is inset from the left of the stack.
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
  set rect(RelativeRect value) {
    top = value.top;
    right = value.right;
    bottom = value.bottom;
    left = value.left;
  }

  /// Whether this child is considered positioned.
  ///
  /// A child is positioned if any of the top, right, bottom, or left properties
  /// are non-null. Positioned children do not factor into determining the size
  /// of the stack but are instead placed relative to the non-positioned
  /// children in the stack.
  bool get isPositioned => top != null || right != null || bottom != null || left != null || width != null || height != null;

  @override
  String toString() {
    final List<String> values = <String>[];
    if (top != null)
      values.add('top=$top');
    if (right != null)
      values.add('right=$right');
    if (bottom != null)
      values.add('bottom=$bottom');
    if (left != null)
      values.add('left=$left');
    if (width != null)
      values.add('width=$width');
    if (height != null)
      values.add('height=$height');
    if (values.isEmpty)
      values.add('not positioned');
    values.add(super.toString());
    return values.join('; ');
  }
}

/// How to size the non-positioned children of a [Stack].
///
/// This enum is used with [Stack.fit] and [RenderStack.fit] to control
/// how the [BoxConstraints] passed from the stack's parent to the stack's child
/// are adjusted.
///
/// See also:
///
///  * [Stack], the widget that uses this.
///  * [RenderStack], the render object that implements the stack algorithm.
enum StackFit {
  /// The constraints passed to the stack from its parent are loosened.
  ///
  /// For example, if the stack has constraints that force it to 350x600, then
  /// this would allow the non-positioned children of the stack to have any
  /// width from zero to 350 and any height from zero to 600.
  ///
  /// See also:
  ///
  ///  * [Center], which loosens the constraints passed to its child and then
  ///    centers the child in itself.
  ///  * [BoxConstraints.loosen], which implements the loosening of box
  ///    constraints.
  loose,

  /// The constraints passed to the stack from its parent are tightened to the
  /// biggest size allowed.
  ///
  /// For example, if the stack has loose constraints with a width in the range
  /// 10 to 100 and a height in the range 0 to 600, then the non-positioned
  /// children of the stack would all be sized as 100 pixels wide and 600 high.
  expand,

  /// The constraints passed to the stack from its parent are passed unmodified
  /// to the non-positioned children.
  ///
  /// For example, if a [Stack] is an [Expanded] child of a [Row], the
  /// horizontal constraints will be tight and the vertical constraints will be
  /// loose.
  passthrough,
}

/// Whether overflowing children should be clipped, or their overflow be
/// visible.
enum Overflow {
  /// Overflowing children will be visible.
  visible,

  /// Overflowing children will be clipped to the bounds of their parent.
  clip,
}

/// Implements the stack layout algorithm
///
/// In a stack layout, the children are positioned on top of each other in the
/// order in which they appear in the child list. First, the non-positioned
/// children (those with null values for top, right, bottom, and left) are
/// laid out and initially placed in the upper-left corner of the stack. The
/// stack is then sized to enclose all of the non-positioned children. If there
/// are no non-positioned children, the stack becomes as large as possible.
///
/// The final location of non-positioned children is determined by the alignment
/// parameter. The left of each non-positioned child becomes the
/// difference between the child's width and the stack's width scaled by
/// alignment.x. The top of each non-positioned child is computed
/// similarly and scaled by alignment.y. So if the alignment x and y properties
/// are 0.0 (the default) then the non-positioned children remain in the
/// upper-left corner. If the alignment x and y properties are 0.5 then the
/// non-positioned children are centered within the stack.
///
/// Next, the positioned children are laid out. If a child has top and bottom
/// values that are both non-null, the child is given a fixed height determined
/// by subtracting the sum of the top and bottom values from the height of the stack.
/// Similarly, if the child has right and left values that are both non-null,
/// the child is given a fixed width derived from the stack's width.
/// Otherwise, the child is given unbounded constraints in the non-fixed dimensions.
///
/// Once the child is laid out, the stack positions the child
/// according to the top, right, bottom, and left properties of their
/// [StackParentData]. For example, if the bottom value is 10.0, the
/// bottom edge of the child will be inset 10.0 pixels from the bottom
/// edge of the stack. If the child extends beyond the bounds of the
/// stack, the stack will clip the child's painting to the bounds of
/// the stack.
///
/// See also:
///
///  * [RenderFlow]
class RenderStack extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, StackParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  /// Creates a stack render object.
  ///
  /// By default, the non-positioned children of the stack are aligned by their
  /// top left corners.
  RenderStack({
    List<RenderBox> children,
    FractionalOffset alignment: FractionalOffset.center,
    StackFit fit: StackFit.loose,
    Overflow overflow: Overflow.clip
  }) : _alignment = alignment,
       _fit = fit,
       _overflow = overflow {
    assert(alignment != null);
    assert(fit != null);
    assert(overflow != null);
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = new StackParentData();
  }

  /// How to align the non-positioned children in the stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [FractionalOffset.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  set alignment(FractionalOffset value) {
    assert(value != null);
    if (_alignment != value) {
      _alignment = value;
      markNeedsLayout();
    }
  }

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [RenderStack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  StackFit get fit => _fit;
  StackFit _fit;
  set fit(StackFit value) {
    assert(value != null);
    if (_fit != value) {
      _fit = value;
      markNeedsLayout();
    }
  }

  /// Whether overflowing children should be clipped. See [Overflow].
  ///
  /// Some children in a stack might overflow its box. When this flag is set to
  /// [Overflow.clip], children cannot paint outside of the stack's box.
  Overflow get overflow => _overflow;
  Overflow _overflow;
  set overflow(Overflow value) {
    assert(value != null);
    if (_overflow != value) {
      _overflow = value;
      markNeedsPaint();
    }
  }

  double _getIntrinsicDimension(double mainChildSizeGetter(RenderBox child)) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned)
        extent = math.max(extent, mainChildSizeGetter(child));
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicDimension((RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicDimension((RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicDimension((RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicDimension((RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;
    bool hasNonPositionedChildren = false;

    double width = constraints.minWidth;
    double height = constraints.minHeight;

    BoxConstraints nonPositionedConstraints;
    assert(fit != null);
    switch (fit) {
      case StackFit.loose:
        nonPositionedConstraints = constraints.loosen();
        break;
      case StackFit.expand:
        nonPositionedConstraints = new BoxConstraints.tight(constraints.biggest);
        break;
      case StackFit.passthrough:
        nonPositionedConstraints = constraints;
        break;
    }
    assert(nonPositionedConstraints != null);

    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;

        child.layout(nonPositionedConstraints, parentUsesSize: true);

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

    assert(size.isFinite);

    child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        childParentData.offset = alignment.alongOffset(size - child.size);
      } else {
        BoxConstraints childConstraints = const BoxConstraints();

        if (childParentData.left != null && childParentData.right != null)
          childConstraints = childConstraints.tighten(width: size.width - childParentData.right - childParentData.left);
        else if (childParentData.width != null)
          childConstraints = childConstraints.tighten(width: childParentData.width);

        if (childParentData.top != null && childParentData.bottom != null)
          childConstraints = childConstraints.tighten(height: size.height - childParentData.bottom - childParentData.top);
        else if (childParentData.height != null)
          childConstraints = childConstraints.tighten(height: childParentData.height);

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

        childParentData.offset = new Offset(x, y);
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  /// Override in subclasses to customize how the stack paints.
  ///
  /// By default, the stack uses [defaultPaint]. This function is called by
  /// [paint] after potentially applying a clip to contain visual overflow.
  @protected
  void paintStack(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_overflow == Overflow.clip && _hasVisualOverflow) {
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, paintStack);
    } else {
      paintStack(context, offset);
    }
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
    description.add('fit: $fit');
    description.add('overflow: $overflow');
  }
}

/// Implements the same layout algorithm as RenderStack but only paints the child
/// specified by index.
///
/// Although only one child is displayed, the cost of the layout algorithm is
/// still O(N), like an ordinary stack.
class RenderIndexedStack extends RenderStack {
  /// Creates a stack render object that paints a single child.
  ///
  /// If the [index] parameter is null, nothing is displayed.
  RenderIndexedStack({
    List<RenderBox> children,
    FractionalOffset alignment: FractionalOffset.topLeft,
    int index: 0
  }) : _index = index, super(
    children: children,
    alignment: alignment
  );

  /// The index of the child to show, null if nothing is to be displayed.
  int get index => _index;
  int _index;
  set index(int value) {
    if (_index != value) {
      _index = value;
      markNeedsLayout();
    }
  }

  RenderBox _childAtIndex() {
    assert(index != null);
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

  @override
  bool hitTestChildren(HitTestResult result, { @required Offset position }) {
    if (firstChild == null || index == null)
      return false;
    assert(position != null);
    final RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    return child.hitTest(result, position: position - childParentData.offset);
  }

  @override
  void paintStack(PaintingContext context, Offset offset) {
    if (firstChild == null || index == null)
      return;
    final RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('index: $index');
  }
}
