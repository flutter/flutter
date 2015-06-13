// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/framework/net/image_cache.dart' as image_cache;
import 'package:vector_math/vector_math.dart';

import '../debug/utils.dart';
import '../painting/box_painter.dart';
import 'object.dart';

export '../painting/box_painter.dart';

// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

// This class should only be used in debug builds
class _DebugSize extends Size {
  _DebugSize(Size source, this._owner, this._canBeUsedByParent): super.copy(source);
  final RenderBox _owner;
  final bool _canBeUsedByParent;
}

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
    this.maxHeight: double.INFINITY
  });

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

  BoxConstraints loosen() {
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight
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

  double constrainWidth(double width) {
    return clamp(min: minWidth, max: maxWidth, value: width);
  }

  double constrainHeight(double height) {
    return clamp(min: minHeight, max: maxHeight, value: height);
  }

  Size constrain(Size size) {
    Size result = new Size(constrainWidth(size.width), constrainHeight(size.height));
    if (size is _DebugSize)
      result = new _DebugSize(result, size._owner, size._canBeUsedByParent);
    return result;
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

  // This whole block should only be here in debug builds
  bool _debugDoingThisLayout = false;
  bool _debugCanParentUseSize;
  void layoutWithoutResize() {
    _debugDoingThisLayout = true;
    _debugCanParentUseSize = false;
    super.layoutWithoutResize();
    _debugCanParentUseSize = null;
    _debugDoingThisLayout = false;
  }
  void layout(dynamic constraints, { bool parentUsesSize: false }) {
    _debugDoingThisLayout = true;
    _debugCanParentUseSize = parentUsesSize;
    super.layout(constraints, parentUsesSize: parentUsesSize);
    _debugCanParentUseSize = null;
    _debugDoingThisLayout = false;
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

  // TODO(ianh): In non-debug builds, this should all just be:
  // Size size = Size.zero;
  // In debug builds, however:
  Size _size = Size.zero;
  Size get size => _size;
  void set size(Size value) {
    assert(RenderObject.debugDoingLayout);
    assert(_debugDoingThisLayout);
    if (value is _DebugSize) {
      assert(value._canBeUsedByParent);
      assert(value._owner.parent == this);
    }
    _size = inDebugBuild ? new _DebugSize(value, this, _debugCanParentUseSize) : value;
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}size: ${size}\n';
}

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
      child.layout(constraints.apply(_additionalConstraints), parentUsesSize: true);
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
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }
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
    markNeedsPaint();
  }

  void paint(RenderObjectDisplayList canvas) {
    if (child != null) {
      int a = (_opacity * 255).round();

      if (a == 0)
        return;

      if (a == 255) {
        child.paint(canvas);
        return;
      }

      Paint paint = new Paint()
        ..color = new Color.fromARGB(a, 0, 0, 0)
        ..setTransferMode(sky.TransferMode.srcOverMode);
      canvas.saveLayer(null, paint);
      child.paint(canvas);
      canvas.restore();
    }
  }
}

class RenderClipRect extends RenderProxyBox {
  RenderClipRect({ RenderBox child }) : super(child);

  void paint(RenderObjectDisplayList canvas) {
    if (child != null) {
      canvas.save();
      canvas.clipRect(new Rect.fromSize(size));
      child.paint(canvas);
      canvas.restore();
    }
  }
}

class RenderClipOval extends RenderProxyBox {
  RenderClipOval({ RenderBox child }) : super(child);

  void paint(RenderObjectDisplayList canvas) {
    if (child != null) {
      Rect rect = new Rect.fromSize(size);
      canvas.saveLayer(rect, new Paint());
      Path path = new Path();
      path.addOval(rect);
      canvas.clipPath(path);
      child.paint(canvas);
      canvas.restore();
    }
  }
}

abstract class RenderShiftedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  // Abstract class for one-child-layout render boxes

  RenderShiftedBox(RenderBox child) {
    this.child = child;
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

}

class RenderPadding extends RenderShiftedBox {

  RenderPadding({ EdgeDims padding, RenderBox child }) : super(child) {
    assert(padding != null);
    this.padding = padding;
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

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}padding: ${padding}\n';
}

class RenderPositionedBox extends RenderShiftedBox {

  RenderPositionedBox({
    RenderBox child,
    double horizontal: 0.5,
    double vertical: 0.5
  }) : _horizontal = horizontal,
       _vertical = vertical,
       super(child) {
    assert(horizontal != null);
    assert(vertical != null);
  }

  double _horizontal;
  double get horizontal => _horizontal;
  void set horizontal (double value) {
    assert(value != null);
    if (_horizontal == value)
      return;
    _horizontal = value;
    markNeedsLayout();
  }

  double _vertical;
  double get vertical => _vertical;
  void set vertical (double value) {
    assert(value != null);
    if (_vertical == value)
      return;
    _vertical = value;
    markNeedsLayout();
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
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      assert(child.parentData is BoxParentData);
      Size delta = size - child.size;
      child.parentData.position = new Point(delta.width * horizontal, delta.height * vertical);
    } else {
      performResize();
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}horizontal: ${horizontal}\n${prefix}vertical: ${vertical}\n';
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
    if (value == null)
      value = const Size(null, null);
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

class RenderDecoratedBox extends RenderProxyBox {

  RenderDecoratedBox({
    BoxDecoration decoration,
    RenderBox child
  }) : _painter = new BoxPainter(decoration), super(child);

  BoxPainter _painter;
  BoxDecoration get decoration => _painter.decoration;
  void set decoration (BoxDecoration value) {
    assert(value != null);
    if (value == _painter.decoration)
      return;
    _painter.decoration = value;
    markNeedsPaint();
  }

  void paint(RenderObjectDisplayList canvas) {
    assert(size.width != null);
    assert(size.height != null);
    _painter.paint(canvas, new Rect.fromSize(size));
    super.paint(canvas);
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

typedef void CustomPaintCallback(sky.Canvas canvas, Size size);

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
    _callback(canvas, size);
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
