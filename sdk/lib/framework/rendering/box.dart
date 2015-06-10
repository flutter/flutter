// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:typed_data';
import 'object.dart';
import '../painting/shadows.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sky/framework/net/image_cache.dart' as image_cache;

// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

class EdgeDims {
  // used for e.g. padding
  const EdgeDims(this.top, this.right, this.bottom, this.left);
  const EdgeDims.all(double value)
      : top = value, right = value, bottom = value, left = value;
  const EdgeDims.only({ this.top: 0.0,
                        this.right: 0.0,
                        this.bottom: 0.0,
                        this.left: 0.0 });
  const EdgeDims.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : top = vertical, left = horizontal, bottom = vertical, right = horizontal;

  final double top;
  final double right;
  final double bottom;
  final double left;

  operator ==(EdgeDims other) => (top == other.top) ||
                                 (right == other.right) ||
                                 (bottom == other.bottom) ||
                                 (left == other.left);

  int get hashCode {
    int value = 373;
    value = 37 * value + top.hashCode;
    value = 37 * value + left.hashCode;
    value = 37 * value + bottom.hashCode;
    value = 37 * value + right.hashCode;
    return value;
  }
  String toString() => "EdgeDims($top, $right, $bottom, $left)";
}

class BoxConstraints {
  const BoxConstraints({
    this.minWidth: 0.0,
    this.maxWidth: double.INFINITY,
    this.minHeight: 0.0,
    this.maxHeight: double.INFINITY});

  BoxConstraints.tight(Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  BoxConstraints.loose(Size size)
    : minWidth = 0.0,
      maxWidth = size.width,
      minHeight = 0.0,
      maxHeight = size.height;

  BoxConstraints deflate(EdgeDims edges) {
    assert(edges != null);
    double horizontal = edges.left + edges.right;
    double vertical = edges.top + edges.bottom;
    return new BoxConstraints(
      minWidth: math.max(0.0, minWidth - horizontal),
      maxWidth: maxWidth - horizontal,
      minHeight: math.max(0.0, minHeight - vertical),
      maxHeight: maxHeight - vertical
    );
  }

  BoxConstraints apply(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: math.max(minWidth, constraints.minWidth),
      maxWidth: math.min(maxWidth, constraints.maxWidth),
      minHeight: math.max(minHeight, constraints.minHeight),
      maxHeight: math.min(maxHeight, constraints.maxHeight));
  }

  BoxConstraints applyWidth(double width) {
    return new BoxConstraints(minWidth: math.max(minWidth, width),
                              maxWidth: math.min(maxWidth, width),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyMinWidth(double width) {
    return new BoxConstraints(minWidth: math.max(minWidth, width),
                              maxWidth: maxWidth,
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyMaxWidth(double width) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: math.min(maxWidth, width),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyHeight(double height) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: math.max(minHeight, height),
                              maxHeight: math.min(maxHeight, height));
  }

  BoxConstraints applyMinHeight(double height) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: math.max(minHeight, height),
                              maxHeight: maxHeight);
  }

  BoxConstraints applyMaxHeight(double height) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: minHeight,
                              maxHeight: math.min(maxHeight, height));
  }

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  static double _clamp({double min: 0.0, double value: 0.0, double max: double.INFINITY}) {
    assert(min != null);
    assert(value != null);
    assert(max != null);
    return math.max(min, math.min(max, value));
  }

  double constrainWidth(double width) {
    return _clamp(min: minWidth, max: maxWidth, value: width);
  }

  double constrainHeight(double height) {
    return _clamp(min: minHeight, max: maxHeight, value: height);
  }

  Size constrain(Size size) {
    return new Size(constrainWidth(size.width), constrainHeight(size.height));
  }

  bool get isInfinite => maxWidth >= double.INFINITY || maxHeight >= double.INFINITY;

  int get hashCode {
    int value = 373;
    value = 37 * value + minWidth.hashCode;
    value = 37 * value + maxWidth.hashCode;
    value = 37 * value + minHeight.hashCode;
    value = 37 * value + maxHeight.hashCode;
    return value;
  }
  String toString() => "BoxConstraints($minWidth<=w<$maxWidth, $minHeight<=h<$maxHeight)";
}

class BoxHitTestEntry extends HitTestEntry {
  const BoxHitTestEntry(RenderBox target, this.localPosition)
    : super(target);

  final Point localPosition;
}

class BoxParentData extends ParentData {
  Point _position = Point.origin;
  Point get position => _position;
  void set position(Point value) {
    assert(RenderObject.debugDoingLayout);
    _position = value;
  }
  String toString() => 'position=$position';
}

abstract class RenderBox extends RenderObject {

  void setParentData(RenderObject child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  // getMinIntrinsicWidth() should return the minimum width that this box could 
  // be without failing to render its contents within itself.
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  // getMaxIntrinsicWidth() should return the smallest width beyond which 
  // increasing the width never decreases the height.
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  // getMinIntrinsicHeight() should return the minimum height that this box could 
  // be without failing to render its contents within itself.
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  // getMaxIntrinsicHeight should return the smallest height beyond which
  // increasing the height never decreases the width.
  // If the layout algorithm used is width-in-height-out, i.e. the height
  // depends on the width and not vice versa, then this will return the same
  // as getMinIntrinsicHeight().
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  BoxConstraints get constraints { BoxConstraints result = super.constraints; return result; }
  void performResize() {
    // default behaviour for subclasses that have sizedByParent = true
    size = constraints.constrain(Size.zero);
    assert(size.height < double.INFINITY);
    assert(size.width < double.INFINITY);
  }
  void performLayout() {
    // descendants have to either override performLayout() to set both
    // width and height and lay out children, or, set sizedByParent to
    // true so that performResize()'s logic above does its thing.
    assert(sizedByParent);
  }

  bool hitTest(HitTestResult result, { Point position }) {
    hitTestChildren(result, position: position);
    result.add(new BoxHitTestEntry(this, position));
    return true;
  }
  void hitTestChildren(HitTestResult result, { Point position }) { }

  Size _size = Size.zero;
  Size get size => _size;
  void set size(Size value) {
    assert(RenderObject.debugDoingLayout);
    _size = value;
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}size: ${size}\n';
}

abstract class RenderProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderProxyBox(RenderBox child) {
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

  void paint(RenderObjectDisplayList canvas) {
    if (child != null)
      child.paint(canvas);
  }
}

class RenderSizedBox extends RenderProxyBox {

  RenderSizedBox({
    RenderBox child,
    Size desiredSize: Size.infinite
  }) : super(child), _desiredSize = desiredSize {
    assert(desiredSize != null);
  }

  Size _desiredSize;
  Size get desiredSize => _desiredSize;
  void set desiredSize (Size value) {
    assert(value != null);
    if (_desiredSize == value)
      return;
    _desiredSize = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_desiredSize.width);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_desiredSize.width);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(_desiredSize.height);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(_desiredSize.height);
  }

  void performLayout() {
    size = constraints.constrain(_desiredSize);
    if (child != null)
      child.layout(new BoxConstraints.tight(size));
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}desiredSize: ${desiredSize}\n';
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
      return child.getMinIntrinsicWidth(constraints.apply(_additionalConstraints));
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints.apply(_additionalConstraints));
    return constraints.constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(constraints.apply(_additionalConstraints));
    return constraints.constrainHeight(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints.apply(_additionalConstraints));
    return constraints.constrainHeight(0.0);
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints.apply(_additionalConstraints));
      size = child.size;
    } else {
      performResize();
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}additionalConstraints: ${additionalConstraints}\n';
}

class RenderShrinkWrapWidth extends RenderProxyBox {
  RenderShrinkWrapWidth({ RenderBox child }) : super(child);

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    double width = child.getMaxIntrinsicWidth(constraints);
    assert(width == constraints.constrainWidth(width));
    return constraints.applyWidth(width);
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints);
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints);
    return constraints.constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(_getInnerConstraints(constraints));
    return constraints.constrainWidth(0.0);
  }

  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints));
      size = child.size;
    } else {
      performResize();
    }
  }
}

class RenderClip extends RenderProxyBox {
  RenderClip({ RenderBox child }) : super(child);

  void paint(RenderObjectDisplayList canvas) {
    if (child != null) {
      canvas.save();
      canvas.clipRect(new Rect.fromSize(size));
      child.paint(canvas);
      canvas.restore();
    }
  }
}

class RenderPadding extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  RenderPadding({ EdgeDims padding, RenderBox child }) {
    assert(padding != null);
    this.padding = padding;
    this.child = child;
  }

  EdgeDims _padding;
  EdgeDims get padding => _padding;
  void set padding (EdgeDims value) {
    assert(value != null);
    if (_padding == value)
      return;
    _padding = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMinIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMinIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  void performLayout() {
    assert(padding != null);
    BoxConstraints innerConstraints = constraints.deflate(padding);
    if (child == null) {
      size = innerConstraints.constrain(
          new Size(padding.left + padding.right, padding.top + padding.bottom));
      return;
    }
    child.layout(innerConstraints, parentUsesSize: true);
    assert(child.parentData is BoxParentData);
    child.parentData.position = new Point(padding.left, padding.top);
    size = constraints.constrain(new Size(padding.left + child.size.width + padding.right,
                                              padding.top + child.size.height + padding.bottom));
  }

  void paint(RenderObjectDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, child.parentData.position);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Rect childBounds = new Rect.fromPointAndSize(child.parentData.position, child.size);
      if (childBounds.contains(position)) {
        child.hitTest(result, position: new Point(position.x - child.parentData.position.x,
                                                      position.y - child.parentData.position.y));
      }
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}padding: ${padding}\n';
}

class RenderImage extends RenderBox {

  RenderImage(String url, Size dimensions) {
    requestedSize = dimensions;
    src = url;
  }

  sky.Image _image;
  String _src;
  String get src => _src;
  void set src (String value) {
    if (value == _src)
      return;
    _src = value;
    image_cache.load(_src, (result) {
      _image = result;
      if (requestedSize.width == null || requestedSize.height == null)
        markNeedsLayout();
      markNeedsPaint();
    });
  }

  Size _requestedSize;
  Size get requestedSize => _requestedSize;
  void set requestedSize (Size value) {
    if (value == _requestedSize)
      return;
    _requestedSize = value;
    markNeedsLayout();
  }

  Size _sizeForConstraints(BoxConstraints innerConstraints) {
    // If there's no image, we can't size ourselves automatically
    if (_image == null) {
      double width = requestedSize.width == null ? 0.0 : requestedSize.width;
      double height = requestedSize.height == null ? 0.0 : requestedSize.height;
      return constraints.constrain(new Size(width, height));
    }

    // If neither height nor width are specified, use inherent image dimensions
    // If only one dimension is specified, adjust the other dimension to
    // maintain the aspect ratio
    if (requestedSize.width == null) {
      if (requestedSize.height == null) {
        return constraints.constrain(new Size(_image.width.toDouble(), _image.height.toDouble()));
      } else {
        double width = requestedSize.height * _image.width / _image.height;
        return constraints.constrain(new Size(width, requestedSize.height));
      }
    } else if (requestedSize.height == null) {
      double height = requestedSize.width * _image.height / _image.width;
      return constraints.constrain(new Size(requestedSize.width, height));
    } else {
      return constraints.constrain(requestedSize);
    }
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (requestedSize.width == null && requestedSize.height == null)
      return constraints.constrainWidth(0.0);
    return _sizeForConstraints(constraints).width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _sizeForConstraints(constraints).width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (requestedSize.width == null && requestedSize.height == null)
      return constraints.constrainHeight(0.0);
    return _sizeForConstraints(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _sizeForConstraints(constraints).height;
  }

  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  void paint(RenderObjectDisplayList canvas) {
    if (_image == null) return;
    bool needsScale = size.width != _image.width || size.height != _image.height;
    if (needsScale) {
      double widthScale = size.width / _image.width;
      double heightScale = size.height / _image.height;
      canvas.save();
      canvas.scale(widthScale, heightScale);
    }
    Paint paint = new Paint();
    canvas.drawImage(_image, 0.0, 0.0, paint);
    if (needsScale)
      canvas.restore();
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}url: ${src}\n${prefix}dimensions: ${requestedSize}\n';
}

class BorderSide {
  const BorderSide({
    this.color: const Color(0xFF000000),
    this.width: 1.0
  });
  final Color color;
  final double width;

  static const none = const BorderSide(width: 0.0);

  int get hashCode {
    int value = 373;
    value = 37 * value * color.hashCode;
    value = 37 * value * width.hashCode;
    return value;
  }
  String toString() => 'BorderSide($color, $width)';
}

class Border {
  const Border({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none
  });

  const Border.all(BorderSide side) :
    top = side,
    right = side,
    bottom = side,
    left = side;

  final BorderSide top;
  final BorderSide right;
  final BorderSide bottom;
  final BorderSide left;

  int get hashCode {
    int value = 373;
    value = 37 * value * top.hashCode;
    value = 37 * value * right.hashCode;
    value = 37 * value * bottom.hashCode;
    value = 37 * value * left.hashCode;
    return value;
  }
  String toString() => 'Border($top, $right, $bottom, $left)';
}

class BoxShadow {
  const BoxShadow({
    this.color,
    this.offset,
    this.blur
  });

  final Color color;
  final Size offset;
  final double blur;

  String toString() => 'BoxShadow($color, $offset, $blur)';
}

abstract class Gradient {
  sky.Shader createShader();
}

class LinearGradient extends Gradient {
  LinearGradient({
    this.endPoints,
    this.colors,
    this.colorStops,
    this.tileMode: sky.TileMode.clamp
  });

  String toString() =>
      'LinearGradient($endPoints, $colors, $colorStops, $tileMode)';

  sky.Shader createShader() {
    return new sky.Gradient.Linear(this.endPoints, this.colors, this.colorStops,
                                   this.tileMode);
  }

  final List<Point> endPoints;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;
}

class RadialGradient extends Gradient {
  RadialGradient({
    this.center,
    this.radius,
    this.colors,
    this.colorStops,
    this.tileMode: sky.TileMode.clamp
  });

  String toString() =>
      'RadialGradient($center, $radius, $colors, $colorStops, $tileMode)';

  sky.Shader createShader() {
    return new sky.Gradient.Radial(this.center, this.radius, this.colors,
                                   this.colorStops, this.tileMode);
  }

  final Point center;
  final double radius;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;
}

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  const BoxDecoration({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient
  });

  final Color backgroundColor;
  final double borderRadius;
  final Border border;
  final List<BoxShadow> boxShadow;
  final Gradient gradient;

  String toString([String prefix = '']) {
    List<String> result = [];
    if (backgroundColor != null)
      result.add('${prefix}backgroundColor: $backgroundColor');
    if (border != null)
      result.add('${prefix}border: $border');
    if (borderRadius != null)
      result.add('${prefix}borderRadius: $borderRadius');
    if (boxShadow != null)
      result.add('${prefix}boxShadow: ${boxShadow.map((shadow) => shadow.toString())}');
    if (gradient != null)
      result.add('${prefix}gradient: $gradient');
    if (result.isEmpty)
      return '${prefix}<no decorations specified>';
    return result.join('\n');
  }
}

class RenderDecoratedBox extends RenderProxyBox {

  RenderDecoratedBox({
    BoxDecoration decoration,
    RenderBox child
  }) : _decoration = decoration, super(child) {
    assert(_decoration != null);
  }

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  void set decoration (BoxDecoration value) {
    assert(value != null);
    if (value == _decoration)
      return;
    _decoration = value;
    _cachedBackgroundPaint = null;
    markNeedsPaint();
  }

  Paint _cachedBackgroundPaint;
  Paint get _backgroundPaint {
    if (_cachedBackgroundPaint == null) {
      Paint paint = new Paint();

      if (_decoration.backgroundColor != null)
        paint.color = _decoration.backgroundColor;

      if (_decoration.boxShadow != null) {
        var builder = new ShadowDrawLooperBuilder();
        for (BoxShadow boxShadow in _decoration.boxShadow)
          builder.addShadow(boxShadow.offset, boxShadow.color, boxShadow.blur);
        paint.setDrawLooper(builder.build());
      }

      if (_decoration.gradient != null)
        paint.setShader(_decoration.gradient.createShader());

      _cachedBackgroundPaint = paint;
    }

    return _cachedBackgroundPaint;
  }

  void paint(RenderObjectDisplayList canvas) {
    assert(size.width != null);
    assert(size.height != null);

    if (_decoration.backgroundColor != null || _decoration.boxShadow != null ||
        _decoration.gradient != null) {
      Rect rect = new Rect.fromLTRB(0.0, 0.0, size.width, size.height);
      if (_decoration.borderRadius == null)
        canvas.drawRect(rect, _backgroundPaint);
      else
        canvas.drawRRect(new sky.RRect()..setRectXY(rect, _decoration.borderRadius, _decoration.borderRadius), _backgroundPaint);
    }

    if (_decoration.border != null) {
      assert(_decoration.borderRadius == null); // TODO(abarth): Implement borders with border radius.

      assert(_decoration.border.top != null);
      assert(_decoration.border.right != null);
      assert(_decoration.border.bottom != null);
      assert(_decoration.border.left != null);

      Paint paint = new Paint();
      Path path;

      paint.color = _decoration.border.top.color;
      path = new Path();
      path.moveTo(0.0,0.0);
      path.lineTo(_decoration.border.left.width, _decoration.border.top.width);
      path.lineTo(size.width - _decoration.border.right.width, _decoration.border.top.width);
      path.lineTo(size.width, 0.0);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.right.color;
      path = new Path();
      path.moveTo(size.width, 0.0);
      path.lineTo(size.width - _decoration.border.right.width, _decoration.border.top.width);
      path.lineTo(size.width - _decoration.border.right.width, size.height - _decoration.border.bottom.width);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.bottom.color;
      path = new Path();
      path.moveTo(size.width, size.height);
      path.lineTo(size.width - _decoration.border.right.width, size.height - _decoration.border.bottom.width);
      path.lineTo(_decoration.border.left.width, size.height - _decoration.border.bottom.width);
      path.lineTo(0.0, size.height);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.left.color;
      path = new Path();
      path.moveTo(0.0, size.height);
      path.lineTo(_decoration.border.left.width, size.height - _decoration.border.bottom.width);
      path.lineTo(_decoration.border.left.width, _decoration.border.top.width);
      path.lineTo(0.0,0.0);
      path.close();
      canvas.drawPath(path, paint);
    }

    super.paint(canvas);
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}decoration:\n${decoration.toString(prefix + "  ")}\n';
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

  void set transform (Matrix4 value) {
    assert(value != null);
    if (_transform == value)
      return;
    _transform = new Matrix4.copy(value);
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

  void hitTestChildren(HitTestResult result, { Point position }) {
    Matrix4 inverse = new Matrix4.zero();
    double det = inverse.copyInverse(_transform);
    // TODO(abarth): Check the determinant for degeneracy.

    Vector3 position3 = new Vector3(position.x, position.y, 0.0);
    Vector3 transformed3 = inverse.transform3(position3);
    Point transformed = new Point(transformed3.x, transformed3.y);
    super.hitTestChildren(result, position: transformed);
  }

  void paint(RenderObjectDisplayList canvas) {
    canvas.save();
    canvas.concat(_transform.storage);
    super.paint(canvas);
    canvas.restore();
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

typedef void CustomPaintCallback(sky.Canvas canvas);

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

  void paint(RenderObjectDisplayList canvas) {
    assert(_callback != null);
    _callback(canvas);
    super.paint(canvas);
  }
}

// RENDER VIEW LAYOUT MANAGER

class ViewConstraints {

  const ViewConstraints({
    this.width: 0.0, this.height: 0.0, this.orientation: null
  });

  final double width;
  final double height;
  final int orientation;

}

class RenderView extends RenderObject with RenderObjectWithChildMixin<RenderBox> {

  RenderView({
    RenderBox child,
    this.timeForRotation: const Duration(microseconds: 83333)
  }) {
    this.child = child;
  }

  Size _size = Size.zero;
  double get width => _size.width;
  double get height => _size.height;

  int _orientation; // 0..3
  int get orientation => _orientation;
  Duration timeForRotation;

  ViewConstraints _rootConstraints;
  ViewConstraints get rootConstraints => _rootConstraints;
  void set rootConstraints(ViewConstraints value) {
    if (_rootConstraints == value)
      return;
    _rootConstraints = value;
    markNeedsLayout();
  }

  void performLayout() {
    if (_rootConstraints.orientation != _orientation) {
      if (_orientation != null && child != null)
        child.rotate(oldAngle: _orientation, newAngle: _rootConstraints.orientation, time: timeForRotation);
      _orientation = _rootConstraints.orientation;
    }
    _size = new Size(_rootConstraints.width, _rootConstraints.height);
    assert(_size.height < double.INFINITY);
    assert(_size.width < double.INFINITY);

    if (child != null) {
      child.layout(new BoxConstraints.tight(_size));
      assert(child.size.width == width);
      assert(child.size.height == height);
    }
  }

  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our performResize()
  }

  bool hitTest(HitTestResult result, { Point position }) {
    if (child != null) {
      Rect childBounds = new Rect.fromSize(child.size);
      if (childBounds.contains(position))
        child.hitTest(result, position: position);
    }
    result.add(new HitTestEntry(this));
    return true;
  }

  void paint(RenderObjectDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, Point.origin);
  }

  void paintFrame() {
    RenderObject.debugDoingPaint = true;
    RenderObjectDisplayList canvas = new RenderObjectDisplayList(sky.view.width, sky.view.height);
    paint(canvas);
    sky.view.picture = canvas.endRecording();
    RenderObject.debugDoingPaint = false;
  }

}

// DEFAULT BEHAVIORS FOR RENDERBOX CONTAINERS
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerParentDataMixin<ChildType>> implements ContainerRenderObjectMixin<ChildType, ParentDataType> {

  void defaultHitTestChildren(HitTestResult result, { Point position }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      Rect childBounds = new Rect.fromPointAndSize(child.parentData.position, child.size);
      if (childBounds.contains(position)) {
        if (child.hitTest(result, position: new Point(position.x - child.parentData.position.x,
                                                          position.y - child.parentData.position.y)))
          break;
      }
      child = child.parentData.previousSibling;
    }
  }

  void defaultPaint(RenderObjectDisplayList canvas) {
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      canvas.paintChild(child, child.parentData.position);
      child = child.parentData.nextSibling;
    }
  }
}
