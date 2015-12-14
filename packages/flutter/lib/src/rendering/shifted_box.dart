// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'box.dart';
import 'object.dart';

/// Abstract class for one-child-layout render boxes that provide control over
/// the child's position.
abstract class RenderShiftedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderShiftedBox(RenderBox child) {
    this.child = child;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return child.getMinIntrinsicWidth(constraints);
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints);
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return child.getMinIntrinsicHeight(constraints);
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints);
    return super.getMaxIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    double result;
    if (child != null) {
      assert(!needsLayout);
      result = child.getDistanceToActualBaseline(baseline);
      final BoxParentData childParentData = child.parentData;
      if (result != null)
        result += childParentData.position.y;
    } else {
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      final Point childPosition = new Point(position.x - childParentData.position.x,
                                            position.y - childParentData.position.y);
      return child.hitTest(result, position: childPosition);
    }
    return false;
  }

}

/// Insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
class RenderPadding extends RenderShiftedBox {
  RenderPadding({
    EdgeDims padding,
    RenderBox child
  }) : _padding = padding, super(child) {
    assert(padding != null);
    assert(padding.isNonNegative);
  }

  /// The amount to pad the child in each dimension.
  EdgeDims get padding => _padding;
  EdgeDims _padding;
  void set padding (EdgeDims value) {
    assert(value != null);
    assert(value.isNonNegative);
    if (_padding == value)
      return;
    _padding = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMinIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMinIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  void performLayout() {
    assert(padding != null);
    if (child == null) {
      size = constraints.constrain(new Size(
        padding.left + padding.right,
        padding.top + padding.bottom
      ));
      return;
    }
    BoxConstraints innerConstraints = constraints.deflate(padding);
    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData;
    childParentData.position = new Point(padding.left, padding.top);
    size = constraints.constrain(new Size(
      padding.left + child.size.width + padding.right,
      padding.top + child.size.height + padding.bottom
    ));
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('padding: $padding');
  }
}

/// Aligns its child box within itself.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with horizontal and vertical set to 1.0.
class RenderPositionedBox extends RenderShiftedBox {
  RenderPositionedBox({
    RenderBox child,
    FractionalOffset alignment: const FractionalOffset(0.5, 0.5),
    double widthFactor,
    double heightFactor
  }) : _alignment = alignment,
       _widthFactor = widthFactor,
       _heightFactor = heightFactor,
       super(child) {
    assert(alignment != null && alignment.x != null && alignment.y != null);
    assert(widthFactor == null || widthFactor >= 0.0);
    assert(heightFactor == null || heightFactor >= 0.0);
  }

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively.  An x value of 0.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.5 means that the center of the child is aligned
  /// with the center of the parent.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  void set alignment (FractionalOffset newAlignment) {
    assert(newAlignment != null && newAlignment.x != null && newAlignment.y != null);
    if (_alignment == newAlignment)
      return;
    _alignment = newAlignment;
    markNeedsLayout();
  }

  /// If non-null, sets its width to the child's width multipled by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double get widthFactor => _widthFactor;
  double _widthFactor;
  void set widthFactor (double value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value)
      return;
    _widthFactor = value;
    markNeedsLayout();
  }

  /// If non-null, sets its height to the child's height multipled by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double get heightFactor => _heightFactor;
  double _heightFactor;
  void set heightFactor (double value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value)
      return;
    _heightFactor = value;
    markNeedsLayout();
  }

  void performLayout() {
    final bool shrinkWrapWidth = _widthFactor != null || constraints.maxWidth == double.INFINITY;
    final bool shrinkWrapHeight = _heightFactor != null || constraints.maxHeight == double.INFINITY;

    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(new Size(shrinkWrapWidth ? child.size.width * (_widthFactor ?? 1.0) : double.INFINITY,
                                            shrinkWrapHeight ? child.size.height * (_heightFactor ?? 1.0) : double.INFINITY));
      final Offset delta = size - child.size;
      final BoxParentData childParentData = child.parentData;
      childParentData.position = delta.scale(_alignment.x, _alignment.y).toPoint();
    } else {
      size = constraints.constrain(new Size(shrinkWrapWidth ? 0.0 : double.INFINITY,
                                            shrinkWrapHeight ? 0.0 : double.INFINITY));
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('alignment: $alignment');
  }
}

/// A delegate for computing the layout of a render object with a single child.
class OneChildLayoutDelegate {
  /// Returns the size of this object given the incoming constraints.
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  /// Returns the box constraints for the child given the incoming constraints.
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints;

  /// Returns the position where the child should be placed given the size of this object and the size of the child.
  Point getPositionForChild(Size size, Size childSize) => Point.origin;

  /// Override this method to return true when the child needs to be laid out.
  bool shouldRelayout(OneChildLayoutDelegate oldDelegate) => true;
}

/// Defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
class RenderCustomOneChildLayoutBox extends RenderShiftedBox {
  RenderCustomOneChildLayoutBox({
    RenderBox child,
    OneChildLayoutDelegate delegate
  }) : _delegate = delegate, super(child) {
    assert(delegate != null);
  }

  /// A delegate that controls this object's layout.
  OneChildLayoutDelegate get delegate => _delegate;
  OneChildLayoutDelegate _delegate;
  void set delegate (OneChildLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    if (newDelegate.runtimeType != _delegate.runtimeType || newDelegate.shouldRelayout(_delegate))
      markNeedsLayout();
    _delegate = newDelegate;
  }

  Size _getSize(BoxConstraints constraints) {
    return constraints.constrain(_delegate.getSize(constraints));
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _getSize(constraints).width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _getSize(constraints).width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _getSize(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return _getSize(constraints).height;
  }

  bool get sizedByParent => true;

  void performResize() {
    size = _getSize(constraints);
  }

  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = delegate.getConstraintsForChild(constraints);
      assert(childConstraints.isNormalized);
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      childParentData.position = delegate.getPositionForChild(size, childConstraints.isTight ? childConstraints.smallest : child.size);
    }
  }
}

/// Positions its child vertically according to the child's baseline.
class RenderBaseline extends RenderShiftedBox {

  RenderBaseline({
    RenderBox child,
    double baseline,
    TextBaseline baselineType
  }) : _baseline = baseline,
       _baselineType = baselineType,
       super(child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

  /// The number of logical pixels from the top of this box at which to position
  /// the child's baseline.
  double get baseline => _baseline;
  double _baseline;
  void set baseline (double value) {
    assert(value != null);
    if (_baseline == value)
      return;
    _baseline = value;
    markNeedsLayout();
  }

  /// The type of baseline to use for positioning the child.
  TextBaseline get baselineType => _baselineType;
  TextBaseline _baselineType;
  void set baselineType (TextBaseline value) {
    assert(value != null);
    if (_baselineType == value)
      return;
    _baselineType = value;
    markNeedsLayout();
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      double delta = baseline - child.getDistanceToBaseline(baselineType);
      final BoxParentData childParentData = child.parentData;
      childParentData.position = new Point(0.0, delta);
    } else {
      performResize();
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('baseline: $baseline');
    settings.add('baselineType: $baselineType');
  }
}
