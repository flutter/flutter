// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';

export 'package:flutter/gestures.dart' show
  PointerEvent,
  PointerDownEvent,
  PointerMoveEvent,
  PointerUpEvent,
  PointerCancelEvent;
export 'package:flutter/painting.dart' show Decoration, BoxDecoration;

/// A base class for render objects that resemble their children.
///
/// A proxy box has a single child and simply mimics all the properties of that
/// child by calling through to the child for each function in the render box
/// protocol. For example, a proxy box determines its size by askings its child
/// to layout with the same constraints and then matching the size.
///
/// A proxy box isn't useful on its own because you might as well just replace
/// the proxy box with its child. However, RenderProxyBox is a useful base class
/// for render objects that wish to mimic most, but not all, of the properties
/// of their child.
class RenderProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  RenderProxyBox([RenderBox child = null]) {
    this.child = child;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(constraints);
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints);
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(constraints);
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints);
    return super.getMaxIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

/// Imposes additional constraints on its child.
///
/// A render constrained box proxies most functions in the render box protocol
/// to its child, except that when laying out its child, it tightens the
/// constraints provided by its parent by enforcing the [additionalConstraints]
/// as well.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)`` as the
/// [additionalConstraints].
class RenderConstrainedBox extends RenderProxyBox {
  RenderConstrainedBox({
    RenderBox child,
    BoxConstraints additionalConstraints
  }) : _additionalConstraints = additionalConstraints, super(child) {
    assert(additionalConstraints != null);
  }

  /// Additional constraints to apply to [child] during layout
  BoxConstraints get additionalConstraints => _additionalConstraints;
  BoxConstraints _additionalConstraints;
  void set additionalConstraints (BoxConstraints newConstraints) {
    assert(newConstraints != null);
    if (_additionalConstraints == newConstraints)
      return;
    _additionalConstraints = newConstraints;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(_additionalConstraints.enforce(constraints));
    return _additionalConstraints.enforce(constraints).constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(_additionalConstraints.enforce(constraints));
    return _additionalConstraints.enforce(constraints).constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(_additionalConstraints.enforce(constraints));
    return _additionalConstraints.enforce(constraints).constrainHeight(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(_additionalConstraints.enforce(constraints));
    return _additionalConstraints.enforce(constraints).constrainHeight(0.0);
  }

  void performLayout() {
    if (child != null) {
      child.layout(_additionalConstraints.enforce(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      size = _additionalConstraints.enforce(constraints).constrain(Size.zero);
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('additionalConstraints: $additionalConstraints');
  }
}

/// A render object that, for both width and height, imposes a tight constraint
/// on its child that is a multiple (typically less than 1.0) of the maximum
/// constraint it received from its parent on that axis. If the factor for a
/// given axis is null, then the constraints from the parent are just passed
/// through instead.
///
/// It then tries to size itself the size of its child.
class RenderFractionallySizedBox extends RenderProxyBox {
  RenderFractionallySizedBox({
    RenderBox child,
    double widthFactor,
    double heightFactor
  }) : _widthFactor = widthFactor, _heightFactor = heightFactor, super(child) {
    assert(_widthFactor == null || _widthFactor >= 0.0);
    assert(_heightFactor == null || _heightFactor >= 0.0);
  }

  /// The multiple to apply to the incoming maximum width constraint to use as
  /// the tight width constraint for the child, or null to pass through the
  /// constraints given by the parent.
  double get widthFactor => _widthFactor;
  double _widthFactor;
  void set widthFactor (double value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value)
      return;
    _widthFactor = value;
    markNeedsLayout();
  }

  /// The multiple to apply to the incoming maximum height constraint to use as
  /// the tight height constraint for the child, or null to pass through the
  /// constraints given by the parent.
  double get heightFactor => _heightFactor;
  double _heightFactor;
  void set heightFactor (double value) {
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
      double width = maxWidth * _widthFactor;
      minWidth = width;
      maxWidth = width;
    }
    double minHeight = constraints.minHeight;
    double maxHeight = constraints.maxHeight;
    if (_heightFactor != null) {
      double height = maxHeight * _heightFactor;
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

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(_getInnerConstraints(constraints));
    return _getInnerConstraints(constraints).constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(_getInnerConstraints(constraints));
    return _getInnerConstraints(constraints).constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(_getInnerConstraints(constraints));
    return _getInnerConstraints(constraints).constrainHeight(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(_getInnerConstraints(constraints));
    return _getInnerConstraints(constraints).constrainHeight(0.0);
  }

  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      size = _getInnerConstraints(constraints).constrain(Size.zero);
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('widthFactor: ${_widthFactor ?? "pass-through"}');
    settings.add('heightFactor: ${_heightFactor ?? "pass-through"}');
  }
}

/// Forces child to layout at a specific aspect ratio.
///
/// The width of this render object is the largest width permited by the layout
/// constraints. The height of the render object is determined by applying the
/// given aspect ratio to the width, expressed as a ratio of width to height.
/// For example, a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
///
/// For example, given an aspect ratio of 2.0 and layout constraints that
/// require the width to be between 0.0 and 100.0 and the height to be between
/// 0.0 and 100.0, we'll select a width of 100.0 (the biggest allowed) and a
/// height of 50.0 (to match the aspect ratio).
///
/// In that same situation, if the aspect ratio is 0.5, we'll also select a
/// width of 100.0 (still the biggest allowed) and we'll attempt to use a height
/// of 200.0. Unfortunately, that violates the constraints and we'll end up with
/// a height of 100.0 instead.
class RenderAspectRatio extends RenderProxyBox {
  RenderAspectRatio({
    RenderBox child,
    double aspectRatio
  }) : _aspectRatio = aspectRatio, super(child) {
    assert(_aspectRatio != null);
  }

  /// The aspect ratio to use when computing the height from the width.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  double get aspectRatio => _aspectRatio;
  double _aspectRatio;
  void set aspectRatio (double newAspectRatio) {
    assert(newAspectRatio != null);
    if (_aspectRatio == newAspectRatio)
      return;
    _aspectRatio = newAspectRatio;
    markNeedsLayout();
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _applyAspectRatio(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _applyAspectRatio(constraints).height;
  }

  Size _applyAspectRatio(BoxConstraints constraints) {
    double width = constraints.constrainWidth();
    double height = constraints.constrainHeight(width / _aspectRatio);
    return new Size(width, height);
  }

  bool get sizedByParent => true;

  void performResize() {
    size = _applyAspectRatio(constraints);
  }

  void performLayout() {
    if (child != null)
      child.layout(new BoxConstraints.tight(size));
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('aspectRatio: $aspectRatio');
  }
}

/// Sizes its child to the child's intrinsic width.
///
/// Sizes its child's width to the child's maximum intrinsic width. If
/// [stepWidth] is non-null, the child's width will be snapped to a multiple of
/// the [stepWidth]. Similarly, if [stepHeight] is non-null, the child's height
/// will be snapped to a multiple of the [stepHeight].
///
/// This class is useful, for example, when unlimited width is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable width.
///
/// This class is relatively expensive. Avoid using it where possible.
class RenderIntrinsicWidth extends RenderProxyBox {

  RenderIntrinsicWidth({
    double stepWidth,
    double stepHeight,
    RenderBox child
  }) : _stepWidth = stepWidth, _stepHeight = stepHeight, super(child);

  /// If non-null, force the child's width to be a multiple of this value.
  double get stepWidth => _stepWidth;
  double _stepWidth;
  void set stepWidth(double newStepWidth) {
    if (newStepWidth == _stepWidth)
      return;
    _stepWidth = newStepWidth;
    markNeedsLayout();
  }

  /// If non-null, force the child's height to be a multiple of this value.
  double get stepHeight => _stepHeight;
  double _stepHeight;
  void set stepHeight(double newStepHeight) {
    if (newStepHeight == _stepHeight)
      return;
    _stepHeight = newStepHeight;
    markNeedsLayout();
  }

  static double _applyStep(double input, double step) {
    if (step == null)
      return input;
    return (input / step).ceil() * step;
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    assert(child != null);
    if (constraints.hasTightWidth)
      return constraints;
    double width = child.getMaxIntrinsicWidth(constraints);
    assert(width == constraints.constrainWidth(width));
    return constraints.tightenWidth(_applyStep(width, _stepWidth));
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return getMaxIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    double childResult = child.getMaxIntrinsicWidth(constraints);
    return constraints.constrainWidth(_applyStep(childResult, _stepWidth));
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainHeight(0.0);
    double childResult = child.getMinIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainHeight(_applyStep(childResult, _stepHeight));
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainHeight(0.0);
    double childResult = child.getMaxIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainHeight(_applyStep(childResult, _stepHeight));
  }

  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = _getInnerConstraints(constraints);
      if (_stepHeight != null)
        childConstraints.tightenHeight(getMaxIntrinsicHeight(childConstraints));
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('stepWidth: $stepWidth');
    settings.add('stepHeight: $stepHeight');
  }
}

/// Sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// This class is relatively expensive. Avoid using it where possible.
class RenderIntrinsicHeight extends RenderProxyBox {

  RenderIntrinsicHeight({
    RenderBox child
  }) : super(child);

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    assert(child != null);
    if (constraints.hasTightHeight)
      return constraints;
    double height = child.getMaxIntrinsicHeight(constraints);
    assert(height == constraints.constrainHeight(height));
    return constraints.tightenHeight(height);
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    return child.getMinIntrinsicWidth(_getInnerConstraints(constraints));
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    return child.getMaxIntrinsicWidth(_getInnerConstraints(constraints));
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return getMaxIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainHeight(0.0);
    return child.getMaxIntrinsicHeight(constraints);
  }

  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

}

/// Makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// This class is relatively expensive because it requires painting the child
/// into an intermediate buffer.
class RenderOpacity extends RenderProxyBox {
  RenderOpacity({ RenderBox child, double opacity })
    : this._opacity = opacity, super(child) {
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  double get opacity => _opacity;
  double _opacity;
  void set opacity (double newOpacity) {
    assert(newOpacity != null);
    assert(newOpacity >= 0.0 && newOpacity <= 1.0);
    if (_opacity == newOpacity)
      return;
    _opacity = newOpacity;
    markNeedsPaint();
  }

  int get _alpha => (_opacity * 255).round();

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      int a = _alpha;
      if (a == 0)
        return;
      if (a == 255) {
        context.paintChild(child, offset);
        return;
      }
      // TODO(abarth): We should pass bounds here.
      context.pushOpacity(needsCompositing, offset, null, a, super.paint);
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('opacity: ${opacity.toStringAsFixed(1)}');
  }
}

class RenderShaderMask extends RenderProxyBox {
  RenderShaderMask({ RenderBox child, ShaderCallback shaderCallback, TransferMode transferMode })
    : _shaderCallback = shaderCallback, _transferMode = transferMode, super(child);

  ShaderCallback get shaderCallback => _shaderCallback;
  ShaderCallback _shaderCallback;
  void set shaderCallback (ShaderCallback newShaderCallback) {
    assert(newShaderCallback != null);
    if (_shaderCallback == newShaderCallback)
      return;
    _shaderCallback = newShaderCallback;
    markNeedsPaint();
  }

  TransferMode get transferMode => _transferMode;
  TransferMode _transferMode;
  void set transferMode (TransferMode newTransferMode) {
    assert(newTransferMode != null);
    if (_transferMode == newTransferMode)
      return;
    _transferMode = newTransferMode;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.pushShaderMask(needsCompositing, offset, Point.origin & size, _shaderCallback, _transferMode, super.paint);
  }
}

/// A class that provides custom clips.
abstract class CustomClipper<T> {
  /// Returns a description of the clip given that the render object being
  /// clipped is of the given size.
  T getClip(Size size);
  bool shouldRepaint(CustomClipper oldClipper);
}

abstract class _RenderCustomClip<T> extends RenderProxyBox {
  _RenderCustomClip({
    RenderBox child,
    CustomClipper<T> clipper
  }) : _clipper = clipper, super(child);

  /// If non-null, determines which clip to use on the child.
  CustomClipper<T> get clipper => _clipper;
  CustomClipper<T> _clipper;
  void set clipper (CustomClipper<T> newClipper) {
    if (_clipper == newClipper)
      return;
    CustomClipper<T> oldClipper = _clipper;
    _clipper = newClipper;
    if (newClipper == null) {
      assert(oldClipper != null);
      markNeedsPaint();
    } else if (oldClipper == null ||
        oldClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldRepaint(oldClipper)) {
      markNeedsPaint();
    }
  }

  T get _defaultClip;
  T get _clip => _clipper?.getClip(size) ?? _defaultClip;
}

/// Clips its child using a rectangle.
///
/// Prevents its child from painting outside its bounds.
class RenderClipRect extends _RenderCustomClip<Rect> {
  RenderClipRect({
    RenderBox child,
    CustomClipper<Rect> clipper
  }) : super(child: child, clipper: clipper);

  Rect get _defaultClip => Point.origin & size;

  bool hitTest(HitTestResult result, { Point position }) {
    if (_clipper != null) {
      Rect clipRect = _clip;
      if (!clipRect.contains(position))
        return false;
    }
    return super.hitTest(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.pushClipRect(needsCompositing, offset, _clip, super.paint);
  }
}

/// Clips its child using a rounded rectangle.
///
/// Creates a rounded rectangle from its layout dimensions and the given x and
/// y radius values and prevents its child from painting outside that rounded
/// rectangle.
class RenderClipRRect extends RenderProxyBox {
  RenderClipRRect({
    RenderBox child,
    double xRadius,
    double yRadius
  }) : _xRadius = xRadius, _yRadius = yRadius, super(child) {
    assert(_xRadius != null);
    assert(_yRadius != null);
  }

  /// The radius of the rounded corners in the horizontal direction in logical pixels.
  ///
  /// Values are clamped to be between zero and half the width of the render
  /// object.
  double get xRadius => _xRadius;
  double _xRadius;
  void set xRadius (double newXRadius) {
    assert(newXRadius != null);
    if (_xRadius == newXRadius)
      return;
    _xRadius = newXRadius;
    markNeedsPaint();
  }

  /// The radius of the rounded corners in the vertical direction in logical pixels.
  ///
  /// Values are clamped to be between zero and half the height of the render
  /// object.
  double get yRadius => _yRadius;
  double _yRadius;
  void set yRadius (double newYRadius) {
    assert(newYRadius != null);
    if (_yRadius == newYRadius)
      return;
    _yRadius = newYRadius;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Rect rect = Point.origin & size;
      ui.RRect rrect = new ui.RRect.fromRectXY(rect, xRadius, yRadius);
      context.pushClipRRect(needsCompositing, offset, rect, rrect, super.paint);
    }
  }
}

/// Clips its child using an oval.
///
/// Inscribes an oval into its layout dimensions and prevents its child from
/// painting outside that oval.
class RenderClipOval extends _RenderCustomClip<Rect> {
  RenderClipOval({
    RenderBox child,
    CustomClipper<Rect> clipper
  }) : super(child: child, clipper: clipper);

  Rect _cachedRect;
  Path _cachedPath;

  Path _getClipPath(Rect rect) {
    if (rect != _cachedRect) {
      _cachedRect = rect;
      _cachedPath = new Path()..addOval(_cachedRect);
    }
    return _cachedPath;
  }

  Rect get _defaultClip => Point.origin & size;

  bool hitTest(HitTestResult result, { Point position }) {
    Rect clipBounds = _clip;
    Point center = clipBounds.center;
    // convert the position to an offset from the center of the unit circle
    Offset offset = new Offset((position.x - center.x) / clipBounds.width,
                               (position.y - center.y) / clipBounds.height);
    // check if the point is outside the unit circle
    if (offset.distanceSquared > 0.25) // x^2 + y^2 > r^2
      return false;
    return super.hitTest(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Rect clipBounds = _clip;
      context.pushClipPath(needsCompositing, offset, clipBounds, _getClipPath(clipBounds), super.paint);
    }
  }
}

/// Where to paint a box decoration.
enum DecorationPosition {
  /// Paint the box decoration behind the children.
  background,

  /// Paint the box decoration in front of the children.
  foreground,
}

/// Paints a [Decoration] either before or after its child paints.
class RenderDecoratedBox extends RenderProxyBox {

  RenderDecoratedBox({
    Decoration decoration,
    DecorationPosition position: DecorationPosition.background,
    RenderBox child
  }) : _decoration = decoration,
       _position = position,
       super(child) {
    assert(decoration != null);
    assert(position != null);
  }

  BoxPainter _painter;

  /// What decoration to paint.
  Decoration get decoration => _decoration;
  Decoration _decoration;
  void set decoration (Decoration newDecoration) {
    assert(newDecoration != null);
    if (newDecoration == _decoration)
      return;
    _removeListenerIfNeeded();
    _painter = null;
    _decoration = newDecoration;
    _addListenerIfNeeded();
    markNeedsPaint();
  }

  /// Where to paint the box decoration.
  DecorationPosition get position => _position;
  DecorationPosition _position;
  void set position (DecorationPosition newPosition) {
    assert(newPosition != null);
    if (newPosition == _position)
      return;
    _position = newPosition;
    markNeedsPaint();
  }

  bool get _needsListeners {
    return attached && _decoration.needsListeners;
  }

  void _addListenerIfNeeded() {
    if (_needsListeners)
      _decoration.addChangeListener(markNeedsPaint);
  }

  void _removeListenerIfNeeded() {
    if (_needsListeners)
      _decoration.removeChangeListener(markNeedsPaint);
  }

  void attach() {
    super.attach();
    _addListenerIfNeeded();
  }

  void detach() {
    _removeListenerIfNeeded();
    super.detach();
  }

  bool hitTestSelf(Point position) {
    return _decoration.hitTest(size, position);
  }

  void paint(PaintingContext context, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    _painter ??= _decoration.createBoxPainter();
    if (position == DecorationPosition.background)
      _painter.paint(context.canvas, offset & size);
    super.paint(context, offset);
    if (position == DecorationPosition.foreground)
      _painter.paint(context.canvas, offset & size);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('decoration:');
    settings.addAll(_decoration.toString("  ").split('\n'));
  }
}

/// Applies a transformation before painting its child.
class RenderTransform extends RenderProxyBox {
  RenderTransform({
    Matrix4 transform,
    Offset origin,
    FractionalOffset alignment,
    RenderBox child
  }) : super(child) {
    assert(transform != null);
    assert(alignment == null || (alignment.x != null && alignment.y != null));
    this.transform = transform;
    this.alignment = alignment;
    this.origin = origin;
  }

  /// The origin of the coordinate system (relative to the upper left corder of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  Offset get origin => _origin;
  Offset _origin;
  void set origin (Offset newOrigin) {
    if (_origin == newOrigin)
      return;
    _origin = newOrigin;
    markNeedsPaint();
  }

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specificed at the same time as an offset, both are applied.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  void set alignment (FractionalOffset newAlignment) {
    assert(newAlignment == null || (newAlignment.x != null && newAlignment.y != null));
    if (_alignment == newAlignment)
      return;
    _alignment = newAlignment;
    markNeedsPaint();
  }

  // Note the lack of a getter for transform because Matrix4 is not immutable
  Matrix4 _transform;

  /// The matrix to transform the child by during painting.
  void set transform(Matrix4 newTransform) {
    assert(newTransform != null);
    if (_transform == newTransform)
      return;
    _transform = new Matrix4.copy(newTransform);
    markNeedsPaint();
  }

  /// Sets the transform to the identity matrix.
  void setIdentity() {
    _transform.setIdentity();
    markNeedsPaint();
  }

  /// Concatenates a rotation about the x axis into the transform.
  void rotateX(double radians) {
    _transform.rotateX(radians);
    markNeedsPaint();
  }

  /// Concatenates a rotation about the y axis into the transform.
  void rotateY(double radians) {
    _transform.rotateY(radians);
    markNeedsPaint();
  }

  /// Concatenates a rotation about the z axis into the transform.
  void rotateZ(double radians) {
    _transform.rotateZ(radians);
    markNeedsPaint();
  }

  /// Concatenates a translation by (x, y, z) into the transform.
  void translate(x, [double y = 0.0, double z = 0.0]) {
    _transform.translate(x, y, z);
    markNeedsPaint();
  }

  /// Concatenates a scale into the transform.
  void scale(x, [double y, double z]) {
    _transform.scale(x, y, z);
    markNeedsPaint();
  }

  Matrix4 get _effectiveTransform {
    if (_origin == null && _alignment == null)
      return _transform;
    Matrix4 result = new Matrix4.identity();
    if (_origin != null)
      result.translate(_origin.dx, _origin.dy);
    if (_alignment != null)
      result.translate(_alignment.x * size.width, _alignment.y * size.height);
    result.multiply(_transform);
    if (_alignment != null)
      result.translate(-_alignment.x * size.width, -_alignment.y * size.height);
    if (_origin != null)
      result.translate(-_origin.dx, -_origin.dy);
    return result;
  }

  bool hitTest(HitTestResult result, { Point position }) {
    Matrix4 inverse = new Matrix4.zero();
    // TODO(abarth): Check the determinant for degeneracy.
    inverse.copyInverse(_effectiveTransform);

    Vector3 position3 = new Vector3(position.x, position.y, 0.0);
    Vector3 transformed3 = inverse.transform3(position3);
    Point transformed = new Point(transformed3.x, transformed3.y);
    return super.hitTest(result, position: transformed);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Matrix4 transform = _effectiveTransform;
      Offset childOffset = MatrixUtils.getAsTranslation(transform);
      if (childOffset == null)
        context.pushTransform(needsCompositing, offset, transform, super.paint);
      else
        super.paint(context, offset + childOffset);
    }
  }

  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
    transform.multiply(_effectiveTransform);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('transform matrix:');
    settings.addAll(debugDescribeTransform(_transform));
    settings.add('origin: $origin');
    settings.add('alignment: $alignment');
  }
}

/// Called when a size changes.
typedef void SizeChangedCallback(Size newSize);

/// Calls [onSizeChanged] whenever the child's layout size changes
///
/// Because size observer calls its callback during layout, you cannot modify
/// layout information during the callback.
class RenderSizeObserver extends RenderProxyBox {
  RenderSizeObserver({
    this.onSizeChanged,
    RenderBox child
  }) : super(child) {
    assert(onSizeChanged != null);
  }

  /// The callback to call whenever the child's layout size changes
  SizeChangedCallback onSizeChanged;

  void performLayout() {
    Size oldSize = hasSize ? size : null;
    super.performLayout();
    if (oldSize != size) {
      // We make a copy of the Size object here because if we leak a _DebugSize
      // object out of the render tree, we can get confused later if it comes
      // back and gets set as the size property of a RenderBox.
      onSizeChanged(new Size(size.width, size.height));
    }
  }
}

abstract class CustomPainter {
  const CustomPainter();

  void paint(Canvas canvas, Size size);
  bool shouldRepaint(CustomPainter oldDelegate);
  bool hitTest(Point position) => null;
}

/// Delegates its painting
///
/// When asked to paint, custom paint first asks painter to paint with the
/// current canvas and then paints its children. After painting its children,
/// custom paint asks foregroundPainter to paint. The coodinate system of the
/// canvas matches the coordinate system of the custom paint object. The
/// painters are expected to paint within a rectangle starting at the origin
/// and encompassing a region of the given size. If the painters paints outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.
///
/// Because custom paint calls its painters during paint, you cannot dirty
/// layout or paint information during the callback.
class RenderCustomPaint extends RenderProxyBox {
  RenderCustomPaint({
    CustomPainter painter,
    CustomPainter foregroundPainter,
    RenderBox child
  }) : _painter = painter, _foregroundPainter = foregroundPainter, super(child);

  CustomPainter get painter => _painter;
  CustomPainter _painter;
  void set painter (CustomPainter newPainter) {
    if (_painter == newPainter)
      return;
    CustomPainter oldPainter = _painter;
    _painter = newPainter;
    _checkForRepaint(_painter, oldPainter);
  }

  CustomPainter get foregroundPainter => _foregroundPainter;
  CustomPainter _foregroundPainter;
  void set foregroundPainter (CustomPainter newPainter) {
    if (_foregroundPainter == newPainter)
      return;
    CustomPainter oldPainter = _foregroundPainter;
    _foregroundPainter = newPainter;
    _checkForRepaint(_foregroundPainter, oldPainter);
  }

  void _checkForRepaint(CustomPainter newPainter, CustomPainter oldPainter) {
    if (newPainter == null) {
      assert(oldPainter != null); // We should be called only for changes.
      markNeedsPaint();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (_foregroundPainter != null && (_foregroundPainter.hitTest(position) ?? false))
      return true;
    return super.hitTestChildren(result, position: position);
  }

  bool hitTestSelf(Point position) {
    return _painter != null && (_painter.hitTest(position) ?? true);
  }

  void _paintWithPainter(Canvas canvas, Offset offset, CustomPainter painter) {
    canvas.translate(offset.dx, offset.dy);
    painter.paint(canvas, size);
    canvas.translate(-offset.dx, -offset.dy);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_painter != null)
      _paintWithPainter(context.canvas, offset, _painter);
    super.paint(context, offset);
    if (_foregroundPainter != null)
      _paintWithPainter(context.canvas, offset, _foregroundPainter);
  }
}

typedef void PointerDownEventListener(PointerDownEvent event);
typedef void PointerMoveEventListener(PointerMoveEvent event);
typedef void PointerUpEventListener(PointerUpEvent event);
typedef void PointerCancelEventListener(PointerCancelEvent event);

enum HitTestBehavior {
  deferToChild,
  opaque,
  translucent,
}

/// Invokes the callbacks in response to pointer events.
class RenderPointerListener extends RenderProxyBox {
  RenderPointerListener({
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.behavior: HitTestBehavior.deferToChild,
    RenderBox child
  }) : super(child);

  PointerDownEventListener onPointerDown;
  PointerMoveEventListener onPointerMove;
  PointerUpEventListener onPointerUp;
  PointerCancelEventListener onPointerCancel;
  HitTestBehavior behavior;

  bool hitTest(HitTestResult result, { Point position }) {
    bool hitTarget = false;
    if (position.x >= 0.0 && position.x < size.width &&
        position.y >= 0.0 && position.y < size.height) {
      hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position);
      if (hitTarget || behavior == HitTestBehavior.translucent)
        result.add(new BoxHitTestEntry(this, position));
    }
    return hitTarget;
  }

  bool hitTestSelf(Point position) => behavior == HitTestBehavior.opaque;

  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (onPointerDown != null && event is PointerDownEvent)
      return onPointerDown(event);
    if (onPointerMove != null && event is PointerMoveEvent)
      return onPointerMove(event);
    if (onPointerUp != null && event is PointerUpEvent)
      return onPointerUp(event);
    if (onPointerCancel != null && event is PointerCancelEvent)
      return onPointerCancel(event);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    List<String> listeners = <String>[];
    if (onPointerDown != null)
      listeners.add('down');
    if (onPointerMove != null)
      listeners.add('move');
    if (onPointerUp != null)
      listeners.add('up');
    if (onPointerCancel != null)
      listeners.add('cancel');
    if (listeners.isEmpty)
      listeners.add('<none>');
    settings.add('listeners: ${listeners.join(", ")}');
    switch (behavior) {
      case HitTestBehavior.translucent:
        settings.add('behavior: translucent');
        break;
      case HitTestBehavior.opaque:
        settings.add('behavior: opaque');
        break;
      case HitTestBehavior.deferToChild:
        settings.add('behavior: defer-to-child');
        break;
    }
  }
}

/// Force this subtree to have a layer
///
/// This render object creates a separate display list for its child, which
/// can improve performance if the subtree repaints at different times than
/// the surrounding parts of the tree. Specifically, when the child does not
/// repaint but its parent does, we can re-use the display list we recorded
/// previously. Similarly, when the child repaints but the surround tree does
/// not, we can re-record its display list without re-recording the display list
/// for the surround tree.
class RenderRepaintBoundary extends RenderProxyBox {
  bool get hasLayer => true;
}

/// Is invisible during hit testing.
///
/// When [ignoring] is true, this render object (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events because it returns
/// false from [hitTest].
class RenderIgnorePointer extends RenderProxyBox {
  RenderIgnorePointer({ RenderBox child, this.ignoring: true }) : super(child);

  bool ignoring;

  bool hitTest(HitTestResult result, { Point position }) {
    return ignoring ? false : super.hitTest(result, position: position);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('ignoring: $ignoring');
  }
}

/// Holds opaque meta data in the render tree
class RenderMetaData extends RenderProxyBox {
  RenderMetaData({ RenderBox child, this.metaData }) : super(child);

  /// Opaque meta data ignored by the render tree
  dynamic metaData;
}
