// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';

/// Abstract class for one-child-layout render boxes that provide control over
/// the child's position.
abstract class RenderShiftedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  /// Initializes the [child] property for sublasses.
  RenderShiftedBox(RenderBox child) {
    this.child = child;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    double result;
    if (child != null) {
      assert(!debugNeedsLayout);
      result = child.getDistanceToActualBaseline(baseline);
      final BoxParentData childParentData = child.parentData;
      if (result != null)
        result += childParentData.offset.dy;
    } else {
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      return child.hitTest(result, position: position - childParentData.offset);
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
  /// Creates a render object that insets its child.
  ///
  /// The [padding] argument must not be null and must have non-negative insets.
  RenderPadding({
    @required EdgeInsets padding,
    RenderBox child
  }) : assert(padding != null),
       assert(padding.isNonNegative),
       _padding = padding,
       super(child);

  /// The amount to pad the child in each dimension.
  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    assert(value != null);
    assert(value.isNonNegative);
    if (_padding == value)
      return;
    _padding = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double totalHorizontalPadding = padding.left + padding.right;
    final double totalVerticalPadding = padding.top + padding.bottom;
    if (child != null) // next line relies on double.INFINITY absorption
      return child.getMinIntrinsicWidth(math.max(0.0, height - totalVerticalPadding)) + totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double totalHorizontalPadding = padding.left + padding.right;
    final double totalVerticalPadding = padding.top + padding.bottom;
    if (child != null) // next line relies on double.INFINITY absorption
      return child.getMaxIntrinsicWidth(math.max(0.0, height - totalVerticalPadding)) + totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double totalHorizontalPadding = padding.left + padding.right;
    final double totalVerticalPadding = padding.top + padding.bottom;
    if (child != null) // next line relies on double.INFINITY absorption
      return child.getMinIntrinsicHeight(math.max(0.0, width - totalHorizontalPadding)) + totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double totalHorizontalPadding = padding.left + padding.right;
    final double totalVerticalPadding = padding.top + padding.bottom;
    if (child != null) // next line relies on double.INFINITY absorption
      return child.getMaxIntrinsicHeight(math.max(0.0, width - totalHorizontalPadding)) + totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  void performLayout() {
    assert(padding != null);
    if (child == null) {
      size = constraints.constrain(new Size(
        padding.left + padding.right,
        padding.top + padding.bottom
      ));
      return;
    }
    final BoxConstraints innerConstraints = constraints.deflate(padding);
    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData;
    childParentData.offset = new Offset(padding.left, padding.top);
    size = constraints.constrain(new Size(
      padding.left + child.size.width + padding.right,
      padding.top + child.size.height + padding.bottom
    ));
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Rect outerRect = offset & size;
      debugPaintPadding(context.canvas, outerRect, child != null ? padding.deflateRect(outerRect) : null);
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('padding: $padding');
  }
}

/// Abstract class for one-child-layout render boxes that use a
/// [FractionalOffset] to align their children.
abstract class RenderAligningShiftedBox extends RenderShiftedBox {
  /// Initializes member variables for subclasses.
  ///
  /// The [alignment] argument must not be null.
  RenderAligningShiftedBox({
    FractionalOffset alignment: FractionalOffset.center,
    RenderBox child
  }) : assert(alignment != null && alignment.dx != null && alignment.dy != null),
       _alignment = alignment,
       super(child);

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
  /// Sets the alignment to a new value, and triggers a layout update.
  ///
  /// The new alignment must not be null or have any null properties.
  set alignment(FractionalOffset value) {
    assert(value != null && value.dx != null && value.dy != null);
    if (_alignment == value)
      return;
    _alignment = value;
    markNeedsLayout();
  }

  /// Apply the current [alignment] to the [child].
  ///
  /// Subclasses should call this method if they have a child, to have
  /// this class perform the actual alignment. If there is no child,
  /// do not call this method.
  ///
  /// This method must be called after the child has been laid out and
  /// this object's own size has been set.
  void alignChild() {
    assert(child != null);
    assert(!child.debugNeedsLayout);
    assert(child.hasSize);
    assert(hasSize);
    final BoxParentData childParentData = child.parentData;
    childParentData.offset = alignment.alongOffset(size - child.size);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
  }
}

/// Positions its child using a [FractionalOffset].
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [FractionalOffset.bottomRight].
///
/// By default, sizes to be as big as possible in both axes. If either axis is
/// unconstrained, then in that direction it will be sized to fit the child's
/// dimensions. Using widthFactor and heightFactor you can force this latter
/// behavior in all cases.
class RenderPositionedBox extends RenderAligningShiftedBox {
  /// Creates a render object that positions its child.
  RenderPositionedBox({
    RenderBox child,
    double widthFactor,
    double heightFactor,
    FractionalOffset alignment: FractionalOffset.center
  }) : assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0),
       _widthFactor = widthFactor,
       _heightFactor = heightFactor,
       super(child: child, alignment: alignment);

  /// If non-null, sets its width to the child's width multipled by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double get widthFactor => _widthFactor;
  double _widthFactor;
  set widthFactor(double value) {
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
  set heightFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value)
      return;
    _heightFactor = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final bool shrinkWrapWidth = _widthFactor != null || constraints.maxWidth == double.INFINITY;
    final bool shrinkWrapHeight = _heightFactor != null || constraints.maxHeight == double.INFINITY;

    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(new Size(shrinkWrapWidth ? child.size.width * (_widthFactor ?? 1.0) : double.INFINITY,
                                            shrinkWrapHeight ? child.size.height * (_heightFactor ?? 1.0) : double.INFINITY));
      alignChild();
    } else {
      size = constraints.constrain(new Size(shrinkWrapWidth ? 0.0 : double.INFINITY,
                                            shrinkWrapHeight ? 0.0 : double.INFINITY));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      Paint paint;
      if (child != null && !child.size.isEmpty) {
        Path path;
        paint = new Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = debugPaintBoxArrowColor;
        path = new Path();
        final BoxParentData childParentData = child.parentData;
        if (childParentData.offset.dy > 0.0) {
          // vertical alignment arrows
          final double headSize = math.min(childParentData.offset.dy * 0.2, 10.0);
          path
            ..moveTo(offset.dx + size.width / 2.0, offset.dy)
            ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, 0.0)
            ..moveTo(offset.dx + size.width / 2.0, offset.dy + size.height)
            ..relativeLineTo(0.0, -childParentData.offset.dy + headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(headSize, 0.0);
          context.canvas.drawPath(path, paint);
        }
        if (childParentData.offset.dx > 0.0) {
          // horizontal alignment arrows
          final double headSize = math.min(childParentData.offset.dx * 0.2, 10.0);
          path
            ..moveTo(offset.dx, offset.dy + size.height / 2.0)
            ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(0.0, headSize)
            ..moveTo(offset.dx + size.width, offset.dy + size.height / 2.0)
            ..relativeLineTo(-childParentData.offset.dx + headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(0.0, headSize);
          context.canvas.drawPath(path, paint);
        }
      } else {
        paint = new Paint()
          ..color = debugPaintSpacingColor;
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('widthFactor: ${_widthFactor ?? "expand"}');
    description.add('heightFactor: ${_heightFactor ?? "expand"}');
  }
}

/// A render object that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// A render overflow box proxies most functions in the render box protocol to
/// its child, except that when laying out its child, it passes constraints
/// based on the minWidth, maxWidth, minHeight, and maxHeight fields instead of
/// just passing the parent's constraints in. Specifically, it overrides any of
/// the equivalent fields on the constraints given by the parent with the
/// constraints given by these fields for each such field that is not null. It
/// then sizes itself based on the parent's constraints' maxWidth and maxHeight,
/// ignoring the child's dimensions.
///
/// For example, if you wanted a box to always render 50 pixels high, regardless
/// of where it was rendered, you would wrap it in a
/// RenderConstrainedOverflowBox with minHeight and maxHeight set to 50.0.
/// Generally speaking, to avoid confusing behavior around hit testing, a
/// RenderConstrainedOverflowBox should usually be wrapped in a RenderClipRect.
///
/// The child is positioned according to [alignment]. To position a smaller
/// child inside a larger parent, use [RenderPositionedBox] and
/// [RenderConstrainedBox] rather than RenderConstrainedOverflowBox.
class RenderConstrainedOverflowBox extends RenderAligningShiftedBox {
  /// Creates a render object that lets its child overflow itself.
  RenderConstrainedOverflowBox({
    RenderBox child,
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
    FractionalOffset alignment: FractionalOffset.center
  }) : _minWidth = minWidth,
       _maxWidth = maxWidth,
       _minHeight = minHeight,
       _maxHeight = maxHeight,
       super(child: child, alignment: alignment);

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get minWidth => _minWidth;
  double _minWidth;
  set minWidth(double value) {
    if (_minWidth == value)
      return;
    _minWidth = value;
    markNeedsLayout();
  }

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get maxWidth => _maxWidth;
  double _maxWidth;
  set maxWidth(double value) {
    if (_maxWidth == value)
      return;
    _maxWidth = value;
    markNeedsLayout();
  }

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get minHeight => _minHeight;
  double _minHeight;
  set minHeight(double value) {
    if (_minHeight == value)
      return;
    _minHeight = value;
    markNeedsLayout();
  }

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get maxHeight => _maxHeight;
  double _maxHeight;
  set maxHeight(double value) {
    if (_maxHeight == value)
      return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: _minWidth ?? constraints.minWidth,
      maxWidth: _maxWidth ?? constraints.maxWidth,
      minHeight: _minHeight ?? constraints.minHeight,
      maxHeight: _maxHeight ?? constraints.maxHeight
    );
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      alignChild();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('minWidth: ${minWidth ?? "use parent minWidth constraint"}');
    description.add('maxWidth: ${maxWidth ?? "use parent maxWidth constraint"}');
    description.add('minHeight: ${minHeight ?? "use parent minHeight constraint"}');
    description.add('maxHeight: ${maxHeight ?? "use parent maxHeight constraint"}');
  }
}

/// A render box that is a specific size but passes its original constraints
/// through to its child, which will probably overflow.
class RenderSizedOverflowBox extends RenderAligningShiftedBox {
  /// Creates a render box of a given size that lets its child overflow.
  ///
  /// The [requestedSize] argument must not be null.
  RenderSizedOverflowBox({
    RenderBox child,
    @required Size requestedSize,
    FractionalOffset alignment: FractionalOffset.center
  }) : assert(requestedSize != null),
       _requestedSize = requestedSize,
       super(child: child, alignment: alignment);

  /// The size this render box should attempt to be.
  Size get requestedSize => _requestedSize;
  Size _requestedSize;
  set requestedSize(Size value) {
    assert(value != null);
    if (_requestedSize == value)
      return;
    _requestedSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _requestedSize.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _requestedSize.width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _requestedSize.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _requestedSize.height;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    size = constraints.constrain(_requestedSize);
    if (child != null) {
      child.layout(constraints);
      alignChild();
    }
  }
}

/// Sizes its child to a fraction of the total available space.
///
/// For both its width and height, this render object imposes a tight
/// constraint on its child that is a multiple (typically less than 1.0) of the
/// maximum constraint it received from its parent on that axis. If the factor
/// for a given axis is null, then the constraints from the parent are just
/// passed through instead.
///
/// It then tries to size itself to the size of its child.
class RenderFractionallySizedOverflowBox extends RenderAligningShiftedBox {
  /// Creates a render box that sizes its child to a fraction of the total available space.
  ///
  /// If non-null, the [widthFactor] and [heightFactor] arguments must be
  /// non-negative.
  RenderFractionallySizedOverflowBox({
    RenderBox child,
    double widthFactor,
    double heightFactor,
    FractionalOffset alignment: FractionalOffset.center
  }) : _widthFactor = widthFactor,
       _heightFactor = heightFactor,
       super(child: child, alignment: alignment) {
    assert(_widthFactor == null || _widthFactor >= 0.0);
    assert(_heightFactor == null || _heightFactor >= 0.0);
  }

  /// If non-null, the factor of the incoming width to use.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multipled by this factor.  If null, the child is
  /// given the incoming width constraints.
  double get widthFactor => _widthFactor;
  double _widthFactor;
  set widthFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value)
      return;
    _widthFactor = value;
    markNeedsLayout();
  }

  /// If non-null, the factor of the incoming height to use.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming width constraint multipled by this factor.  If null, the child is
  /// given the incoming width constraints.
  double get heightFactor => _heightFactor;
  double _heightFactor;
  set heightFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value)
      return;
    _heightFactor = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    double minWidth = constraints.minWidth;
    double maxWidth = constraints.maxWidth;
    if (_widthFactor != null) {
      final double width = maxWidth * _widthFactor;
      minWidth = width;
      maxWidth = width;
    }
    double minHeight = constraints.minHeight;
    double maxHeight = constraints.maxHeight;
    if (_heightFactor != null) {
      final double height = maxHeight * _heightFactor;
      minHeight = height;
      maxHeight = height;
    }
    return new BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double result;
    if (child == null) {
      result = super.computeMinIntrinsicWidth(height);
    } else { // the following line relies on double.INFINITY absorption
      result = child.getMinIntrinsicWidth(height * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double result;
    if (child == null) {
      result = super.computeMaxIntrinsicWidth(height);
    } else { // the following line relies on double.INFINITY absorption
      result = child.getMaxIntrinsicWidth(height * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double result;
    if (child == null) {
      result = super.computeMinIntrinsicHeight(width);
    } else { // the following line relies on double.INFINITY absorption
      result = child.getMinIntrinsicHeight(width * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    double result;
    if (child == null) {
      result = super.computeMaxIntrinsicHeight(width);
    } else { // the following line relies on double.INFINITY absorption
      result = child.getMaxIntrinsicHeight(width * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      alignChild();
    } else {
      size = constraints.constrain(_getInnerConstraints(constraints).constrain(Size.zero));
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('widthFactor: ${_widthFactor ?? "pass-through"}');
    description.add('heightFactor: ${_heightFactor ?? "pass-through"}');
  }
}

/// A delegate for computing the layout of a render object with a single child.
///
/// Used by [CustomSingleChildLayout] (in the widgets library) and
/// [RenderCustomSingleChildLayoutBox] (in the rendering library).
///
/// When asked to layout, [CustomSingleChildLayout] first calls [getSize] with
/// its incoming constraints to determine its size. It then calls
/// [getConstraintsForChild] to determine the constraints to apply to the child.
/// After the child completes its layout, [RenderCustomSingleChildLayoutBox]
/// calls [getPositionForChild] to determine the child's position.
///
/// The [shouldRelayout] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to trigger a relayout is to supply a relayout
/// argument to the constructor of the [SingleChildLayoutDelegate]. The custom
/// object will listen to this value and relayout whenever the animation
/// ticks, avoiding both the build phase of the pipeline.
///
/// See also:
///
///  * [CustomSingleChildLayout], the widget that uses this delegate.
///  * [RenderCustomSingleChildLayoutBox], render object that uses this
///    delegate.
abstract class SingleChildLayoutDelegate {
  /// Creates a layout delegate.
  ///
  /// The layout will update whenever [relayout] notifies its listeners.
  const SingleChildLayoutDelegate({ Listenable relayout }) : _relayout = relayout;

  final Listenable _relayout;

  /// The size of this object given the incoming constraints.
  ///
  /// Defaults to the biggest size that satifies the given constraints.
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  /// The constraints for the child given the incoming constraints.
  ///
  /// During layout, the child is given the layout constraints returned by this
  /// function. The child is required to pick a size for itself that satisfies
  /// these constraints.
  ///
  /// Defaults to the given constraints.
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints;

  /// The position where the child should be placed.
  ///
  /// The `size` argument is the size of the parent, which might be different
  /// from the value returned by [getSize] if that size doesn't satisfy the
  /// constraints passed to [getSize]. The `childSize` argument is the size of
  /// the child, which will satisfy the constraints returned by
  /// [getConstraintsForChild].
  ///
  /// Defaults to positioning the child in the upper left corner of the parent.
  Offset getPositionForChild(Size size, Size childSize) => Offset.zero;

  /// Called whenever a new instance of the custom layout delegate class is
  /// provided to the [RenderCustomSingleChildLayoutBox] object, or any time
  /// that a new [CustomSingleChildLayout] object is created with a new instance
  /// of the custom layout delegate class (which amounts to the same thing,
  /// because the latter is implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [getSize],
  /// [getConstraintsForChild], and [getPositionForChild] calls might be
  /// optimized away.
  ///
  /// It's possible that the layout methods will get called even if
  /// [shouldRelayout] returns false (e.g. if an ancestor changed its layout).
  /// It's also possible that the layout method will get called
  /// without [shouldRelayout] being called at all (e.g. if the parent changes
  /// size).
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate);
}

/// Defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
class RenderCustomSingleChildLayoutBox extends RenderShiftedBox {
  /// Creates a render box that defers its layout to a delgate.
  ///
  /// The [delegate] argument must not be null.
  RenderCustomSingleChildLayoutBox({
    RenderBox child,
    @required SingleChildLayoutDelegate delegate
  }) : assert(delegate != null),
       _delegate = delegate,
       super(child);

  /// A delegate that controls this object's layout.
  SingleChildLayoutDelegate get delegate => _delegate;
  SingleChildLayoutDelegate _delegate;
  set delegate(SingleChildLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    final SingleChildLayoutDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate))
      markNeedsLayout();
    _delegate = newDelegate;
    if (attached) {
      oldDelegate?._relayout?.removeListener(markNeedsLayout);
      newDelegate?._relayout?.addListener(markNeedsLayout);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate?._relayout?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _delegate?._relayout?.removeListener(markNeedsLayout);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
    return constraints.constrain(_delegate.getSize(constraints));
  }

  // TODO(ianh): It's a bit dubious to be using the getSize function from the delegate to
  // figure out the intrinsic dimensions. We really should either not support intrinsics,
  // or we should expose intrinsic delegate callbacks and throw if they're not implemented.

  @override
  double computeMinIntrinsicWidth(double height) {
    final double width = _getSize(new BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double width = _getSize(new BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double height = _getSize(new BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double height = _getSize(new BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  void performLayout() {
    size = _getSize(constraints);
    if (child != null) {
      final BoxConstraints childConstraints = delegate.getConstraintsForChild(constraints);
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = delegate.getPositionForChild(size, childConstraints.isTight ? childConstraints.smallest : child.size);
    }
  }
}

/// Shifts the child down such that the child's baseline (or the
/// bottom of the child, if the child has no baseline) is [baseline]
/// logical pixels below the top of this box, then sizes this box to
/// contain the child.
///
/// If [baseline] is less than the distance from the top of the child
/// to the baseline of the child, then the child will overflow the top
/// of the box. This is typically not desireable, in particular, that
/// part of the child will not be found when doing hit tests, so the
/// user cannot interact with that part of the child.
///
/// This box will be sized so that its bottom is coincident with the
/// bottom of the child. This means if this box shifts the child down,
/// there will be space between the top of this box and the top of the
/// child, but there is never space between the bottom of the child
/// and the bottom of the box.
class RenderBaseline extends RenderShiftedBox {
  /// Creates a [RenderBaseline] object.
  ///
  /// The [baseline] and [baselineType] arguments must not be null.
  RenderBaseline({
    RenderBox child,
    @required double baseline,
    @required TextBaseline baselineType
  }) : assert(baseline != null),
       assert(baselineType != null),
       _baseline = baseline,
       _baselineType = baselineType,
       super(child);

  /// The number of logical pixels from the top of this box at which to position
  /// the child's baseline.
  double get baseline => _baseline;
  double _baseline;
  set baseline(double value) {
    assert(value != null);
    if (_baseline == value)
      return;
    _baseline = value;
    markNeedsLayout();
  }

  /// The type of baseline to use for positioning the child.
  TextBaseline get baselineType => _baselineType;
  TextBaseline _baselineType;
  set baselineType(TextBaseline value) {
    assert(value != null);
    if (_baselineType == value)
      return;
    _baselineType = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      final double childBaseline = child.getDistanceToBaseline(baselineType);
      final double actualBaseline = baseline;
      final double top = actualBaseline - childBaseline;
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = new Offset(0.0, top);
      final Size childSize = child.size;
      size = constraints.constrain(new Size(childSize.width, top + childSize.height));
    } else {
      performResize();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('baseline: $baseline');
    description.add('baselineType: $baselineType');
  }
}
