// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/box_painter.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/box.dart';
import 'package:vector_math/vector_math.dart';

export 'package:sky/painting/box_painter.dart';

class RenderProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  // ProxyBox assumes the child will be at 0,0 and will have the same size

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

  void hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null)
      child.hitTest(result, position: position);
    else
      super.hitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset.toPoint());
  }
}

class RenderConstrainedBox extends RenderProxyBox {
  RenderConstrainedBox({
    RenderBox child,
    BoxConstraints additionalConstraints
  }) : super(child), _additionalConstraints = additionalConstraints {
    assert(additionalConstraints != null);
  }

  BoxConstraints _additionalConstraints;
  BoxConstraints get additionalConstraints => _additionalConstraints;
  void set additionalConstraints (BoxConstraints value) {
    assert(value != null);
    if (_additionalConstraints == value)
      return;
    _additionalConstraints = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(_additionalConstraints.apply(constraints));
    return _additionalConstraints.apply(constraints).constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(_additionalConstraints.apply(constraints));
    return _additionalConstraints.apply(constraints).constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(_additionalConstraints.apply(constraints));
    return _additionalConstraints.apply(constraints).constrainHeight(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(_additionalConstraints.apply(constraints));
    return _additionalConstraints.apply(constraints).constrainHeight(0.0);
  }

  void performLayout() {
    if (child != null) {
      child.layout(_additionalConstraints.apply(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      size = _additionalConstraints.apply(constraints).constrain(Size.zero);
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}additionalConstraints: ${additionalConstraints}\n';
}

class RenderAspectRatio extends RenderProxyBox {
  RenderAspectRatio({
    RenderBox child,
    double aspectRatio
  }) : super(child), _aspectRatio = aspectRatio {
    assert(_aspectRatio != null);
  }

  double _aspectRatio;
  double get aspectRatio => _aspectRatio;
  void set aspectRatio (double value) {
    assert(value != null);
    if (_aspectRatio == value)
      return;
    _aspectRatio = value;
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

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}aspectRatio: ${aspectRatio}\n';
}

class RenderShrinkWrapWidth extends RenderProxyBox {

  // This class will attempt to size its child to the child's maximum
  // intrinsic width, snapped to a multiple of the stepWidth, if one
  // is provided, and given the provided constraints; and will then
  // adopt the child's resulting dimensions.

  // Note: laying out this class is relatively expensive. Avoid using
  // it where possible.

  RenderShrinkWrapWidth({
    double stepWidth,
    double stepHeight,
    RenderBox child
  }) : _stepWidth = stepWidth, _stepHeight = stepHeight, super(child);

  double _stepWidth;
  double get stepWidth => _stepWidth;
  void set stepWidth(double value) {
    if (value == _stepWidth)
      return;
    _stepWidth = value;
    markNeedsLayout();
  }

  double _stepHeight;
  double get stepHeight => _stepHeight;
  void set stepHeight(double value) {
    if (value == _stepHeight)
      return;
    _stepHeight = value;
    markNeedsLayout();
  }

  static double applyStep(double input, double step) {
    if (step == null)
      return input;
    return (input / step).ceil() * step;
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    if (constraints.hasTightWidth)
      return constraints;
    double width = child.getMaxIntrinsicWidth(constraints);
    assert(width == constraints.constrainWidth(width));
    return constraints.applyWidth(applyStep(width, _stepWidth));
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return getMaxIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    double childResult = child.getMaxIntrinsicWidth(constraints);
    return constraints.constrainWidth(applyStep(childResult, _stepWidth));
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    double childResult = child.getMinIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainHeight(applyStep(childResult, _stepHeight));
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child == null)
      return constraints.constrainWidth(0.0);
    double childResult = child.getMaxIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainHeight(applyStep(childResult, _stepHeight));
  }

  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = _getInnerConstraints(constraints);
      if (_stepHeight != null)
        childConstraints.applyHeight(getMaxIntrinsicHeight(childConstraints));
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}stepWidth: ${stepWidth}\n${prefix}stepHeight: ${stepHeight}\n';

}

class RenderOpacity extends RenderProxyBox {
  RenderOpacity({ RenderBox child, double opacity })
    : this._opacity = opacity, super(child) {
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

  double _opacity;
  double get opacity => _opacity;
  void set opacity (double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (_opacity == value)
      return;
    _opacity = value;
    _cachedPaint = null;
    markNeedsPaint();
  }

  int get _alpha => (_opacity * 255).round();

  Paint _cachedPaint;
  Paint get _paint {
    if (_cachedPaint == null) {
      _cachedPaint = new Paint()
        ..color = new Color.fromARGB(_alpha, 0, 0, 0)
        ..setTransferMode(sky.TransferMode.srcOver)
        ..isAntiAlias = false;
    }
    return _cachedPaint;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      int a = _alpha;
      if (a == 0)
        return;
      if (a == 255)
        context.paintChild(child, offset.toPoint());
      else
        context.paintChildWithPaint(child, offset.toPoint(), null, _paint);
    }
  }
}

class RenderColorFilter extends RenderProxyBox {
  RenderColorFilter({ RenderBox child, Color color, sky.TransferMode transferMode })
    : _color = color, _transferMode = transferMode, super(child) {
  }

  Color _color;
  Color get color => _color;
  void set color (Color value) {
    assert(value != null);
    if (_color == value)
      return;
    _color = value;
    _cachedPaint = null;
    markNeedsPaint();
  }

  sky.TransferMode _transferMode;
  sky.TransferMode get transferMode => _transferMode;
  void set transferMode (sky.TransferMode value) {
    assert(value != null);
    if (_transferMode == value)
      return;
    _transferMode = value;
    _cachedPaint = null;
    markNeedsPaint();
  }

  Paint _cachedPaint;
  Paint get _paint {
    if (_cachedPaint == null) {
      _cachedPaint = new Paint()
        ..setColorFilter(new sky.ColorFilter.mode(_color, _transferMode))
        ..isAntiAlias = false;
    }
    return _cachedPaint;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChildWithPaint(child, offset.toPoint(), offset & size, _paint);
  }
}

class RenderClipRect extends RenderProxyBox {
  RenderClipRect({ RenderBox child }) : super(child);

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChildWithClipRect(child, offset.toPoint(), offset & size);
  }
}

class RenderClipRRect extends RenderProxyBox {
  RenderClipRRect({ RenderBox child, double xRadius, double yRadius })
    : _xRadius = xRadius, _yRadius = yRadius, super(child) {
    assert(_xRadius != null);
    assert(_yRadius != null);
  }

  double _xRadius;
  double get xRadius => _xRadius;
  void set xRadius (double value) {
    assert(value != null);
    if (_xRadius == value)
      return;
    _xRadius = value;
    markNeedsPaint();
  }

  double _yRadius;
  double get yRadius => _yRadius;
  void set yRadius (double value) {
    assert(value != null);
    if (_yRadius == value)
      return;
    _yRadius = value;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Rect rect = offset & size;
      sky.RRect rrect = new sky.RRect()..setRectXY(rect, xRadius, yRadius);
      context.paintChildWithClipRRect(child, offset.toPoint(), rect, rrect);
    }
  }
}

class RenderClipOval extends RenderProxyBox {
  RenderClipOval({ RenderBox child }) : super(child);

  Rect _cachedRect;
  Path _cachedPath;

  Path _getPath(Rect rect) {
    if (rect != _cachedRect) {
      _cachedRect = rect;
      _cachedPath = new Path()..addOval(_cachedRect);
    }
    return _cachedPath;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Rect rect = offset & size;
      context.paintChildWithClipPath(child, offset.toPoint(), rect, _getPath(rect));
    }
  }
}

enum BoxDecorationPosition {
  background,
  foreground,
}

class RenderDecoratedBox extends RenderProxyBox {

  RenderDecoratedBox({
    BoxDecoration decoration,
    RenderBox child,
    this.position: BoxDecorationPosition.background
  }) : _painter = new BoxPainter(decoration), super(child);

  BoxDecorationPosition position;
  final BoxPainter _painter;

  BoxDecoration get decoration => _painter.decoration;
  void set decoration (BoxDecoration value) {
    assert(value != null);
    if (value == _painter.decoration)
      return;
    _removeBackgroundImageListenerIfNeeded();
    _painter.decoration = value;
    _addBackgroundImageListenerIfNeeded();
    markNeedsPaint();
  }

  bool get _needsBackgroundImageListener {
    return attached &&
        _painter.decoration != null &&
        _painter.decoration.backgroundImage != null;
  }

  void _addBackgroundImageListenerIfNeeded() {
    if (_needsBackgroundImageListener)
      _painter.decoration.backgroundImage.addChangeListener(markNeedsPaint);
  }

  void _removeBackgroundImageListenerIfNeeded() {
    if (_needsBackgroundImageListener)
      _painter.decoration.backgroundImage.removeChangeListener(markNeedsPaint);
  }

  void attach() {
    super.attach();
    _addBackgroundImageListenerIfNeeded();
  }

  void detach() {
    _removeBackgroundImageListenerIfNeeded();
    super.detach();
  }

  void paint(PaintingContext context, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    if (position == BoxDecorationPosition.background)
      _painter.paint(context.canvas, offset & size);
    super.paint(context, offset);
    if (position == BoxDecorationPosition.foreground)
      _painter.paint(context.canvas, offset & size);
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}decoration:\n${_painter.decoration.toString(prefix + "  ")}\n';
}

class RenderTransform extends RenderProxyBox {
  RenderTransform({
    Matrix4 transform,
    RenderBox child
  }) : super(child) {
    assert(transform != null);
    this.transform = transform;
  }

  Matrix4 _transform;

  void set transform(Matrix4 value) {
    assert(value != null);
    if (_transform == value)
      return;
    _transform = new Matrix4.copy(value);
    markNeedsPaint();
  }

  void setIdentity() {
    _transform.setIdentity();
    markNeedsPaint();
  }

  void rotateX(double radians) {
    _transform.rotateX(radians);
    markNeedsPaint();
  }

  void rotateY(double radians) {
    _transform.rotateY(radians);
    markNeedsPaint();
  }

  void rotateZ(double radians) {
    _transform.rotateZ(radians);
    markNeedsPaint();
  }

  void translate(x, [double y = 0.0, double z = 0.0]) {
    _transform.translate(x, y, z);
    markNeedsPaint();
  }

  void scale(x, [double y, double z]) {
    _transform.scale(x, y, z);
    markNeedsPaint();
  }

  bool hitTest(HitTestResult result, { Point position }) {
    Matrix4 inverse = new Matrix4.zero();
    // TODO(abarth): Check the determinant for degeneracy.
    inverse.copyInverse(_transform);

    Vector3 position3 = new Vector3(position.x, position.y, 0.0);
    Vector3 transformed3 = inverse.transform3(position3);
    Point transformed = new Point(transformed3.x, transformed3.y);
    return super.hitTest(result, position: transformed);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChildWithTransform(child, offset.toPoint(), _transform);
  }

  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
    transform.multiply(_transform);
  }

  String debugDescribeSettings(String prefix) {
    List<String> result = _transform.toString().split('\n').map((s) => '$prefix  $s\n').toList();
    result.removeLast();
    return '${super.debugDescribeSettings(prefix)}${prefix}transform matrix:\n${result.join()}';
  }
}

typedef void SizeChangedCallback(Size newSize);

class RenderSizeObserver extends RenderProxyBox {
  RenderSizeObserver({
    this.callback,
    RenderBox child
  }) : super(child) {
    assert(callback != null);
  }

  SizeChangedCallback callback;

  void performLayout() {
    Size oldSize = size;

    super.performLayout();

    if (oldSize != size)
      callback(size);
  }
}

typedef void CustomPaintCallback(PaintingCanvas canvas, Size size);

class RenderCustomPaint extends RenderProxyBox {

  RenderCustomPaint({
    CustomPaintCallback callback,
    RenderBox child
  }) : super(child) {
    assert(callback != null);
    _callback = callback;
  }

  CustomPaintCallback _callback;
  void set callback (CustomPaintCallback value) {
    assert(value != null || !attached);
    if (_callback == value)
      return;
    _callback = value;
    markNeedsPaint();
  }

  void attach() {
    assert(_callback != null);
    super.attach();
  }

  void paint(PaintingContext context, Offset offset) {
    assert(_callback != null);
    context.canvas.translate(offset.dx, offset.dy);
    _callback(context.canvas, size);
    // TODO(abarth): We should translate back before calling super because in
    // the future, super.paint might switch our compositing layer.
    super.paint(context, Offset.zero);
    context.canvas.translate(-offset.dx, -offset.dy);
  }
}

class RenderIgnorePointer extends RenderProxyBox {
  RenderIgnorePointer({ RenderBox child }) : super(child);
  bool hitTest(HitTestResult result, { Point position }) {
    return false;
  }
}
