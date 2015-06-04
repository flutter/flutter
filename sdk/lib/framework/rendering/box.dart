// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:typed_data';
import 'object.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sky/framework/net/image_cache.dart' as image_cache;

// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

class EdgeDims {
  // used for e.g. padding
  const EdgeDims(this.top, this.right, this.bottom, this.left);
  const EdgeDims.all(double value)
      : top = value, right = value, bottom = value, left = value;

  const EdgeDims.onlyLeft(double value)
      : top = 0.0, right = 0.0, bottom = 0.0, left = value;
  const EdgeDims.onlyRight(double value)
    : top = 0.0, right = value, bottom = 0.0, left = 0.0;
  const EdgeDims.onlyTop(double value)
    : top = value, right = 0.0, bottom = 0.0, left = 0.0;
  const EdgeDims.onlyBottom(double value)
    : top = 0.0, right = 0.0, bottom = value, left = 0.0;

  final double top;
  final double right;
  final double bottom;
  final double left;

  operator ==(EdgeDims other) => (top == other.top) ||
                                 (right == other.right) ||
                                 (bottom == other.bottom) ||
                                 (left == other.left);

  int get hashCode {
    value = 373;
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

  BoxConstraints.tight(sky.Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  BoxConstraints.loose(sky.Size size)
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

  sky.Size constrain(sky.Size size) {
    return new sky.Size(constrainWidth(size.width), constrainHeight(size.height));
  }

  bool get isInfinite => maxWidth >= double.INFINITY || maxHeight >= double.INFINITY;

  int get hashCode {
    value = 373;
    value = 37 * value + minWidth.hashCode;
    value = 37 * value + maxWidth.hashCode;
    value = 37 * value + minHeight.hashCode;
    value = 37 * value + maxHeight.hashCode;
    return value;
  }
  String toString() => "BoxConstraints($minWidth<=w<$maxWidth, $minHeight<=h<$maxHeight)";
}

class BoxParentData extends ParentData {
  sky.Point position = new sky.Point(0.0, 0.0);
}

abstract class RenderBox extends RenderObject {

  void setParentData(RenderObject child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  // override this to report what dimensions you would have if you
  // were laid out with the given constraints this can walk the tree
  // if it must, but it should be as cheap as possible; just get the
  // dimensions and nothing else (e.g. don't calculate hypothetical
  // child positions if they're not needed to determine dimensions)
  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    return constraints.constrain(new sky.Size(0.0, 0.0));
  }

  BoxConstraints get constraints => super.constraints as BoxConstraints;
  void performResize() {
    // default behaviour for subclasses that have sizedByParent = true
    size = constraints.constrain(new sky.Size(0.0, 0.0));
    assert(size.height < double.INFINITY);
    assert(size.width < double.INFINITY);
  }
  void performLayout() {
    // descendants have to either override performLayout() to set both
    // width and height and lay out children, or, set sizedByParent to
    // true so that performResize()'s logic above does its thing.
    assert(sizedByParent);
  }

  bool hitTest(HitTestResult result, { sky.Point position }) {
    hitTestChildren(result, position: position);
    result.add(this);
    return true;
  }
  void hitTestChildren(HitTestResult result, { sky.Point position }) { }

  sky.Size size = new sky.Size(0.0, 0.0);
}

abstract class RenderProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderProxyBox(RenderBox child) {
    this.child = child;
  }

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    if (child != null)
      return child.getIntrinsicDimensions(constraints);
    return super.getIntrinsicDimensions(constraints);
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
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
    sky.Size desiredSize: const sky.Size.infinite()
  }) : super(child) {
    assert(desiredSize != null);
    this.desiredSize = desiredSize;
  }

  sky.Size _desiredSize;
  sky.Size get desiredSize => _desiredSize;
  void set desiredSize (sky.Size value) {
    assert(value != null);
    if (_desiredSize == value)
      return;
    _desiredSize = value;
    markNeedsLayout();
  }

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    return constraints.constrain(_desiredSize);
  }

  void performLayout() {
    size = constraints.constrain(_desiredSize);
    if (child != null)
      child.layout(new BoxConstraints.tight(size));
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

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    assert(padding != null);
    constraints = constraints.deflate(padding);
    if (child == null)
      return super.getIntrinsicDimensions(constraints);
    return child.getIntrinsicDimensions(constraints);
  }

  void performLayout() {
    assert(padding != null);
    BoxConstraints innerConstraints = constraints.deflate(padding);
    if (child == null) {
      size = innerConstraints.constrain(
          new sky.Size(padding.left + padding.right, padding.top + padding.bottom));
      return;
    }
    child.layout(innerConstraints, parentUsesSize: true);
    assert(child.parentData is BoxParentData);
    child.parentData.position = new sky.Point(padding.left, padding.top);
    size = constraints.constrain(new sky.Size(padding.left + child.size.width + padding.right,
                                              padding.top + child.size.height + padding.bottom));
  }

  void paint(RenderObjectDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, child.parentData.position);
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      sky.Rect childBounds = new sky.Rect.fromPointAndSize(child.parentData.position, child.size);
      if (childBounds.contains(position)) {
        child.hitTest(result, position: new sky.Point(position.x - child.parentData.position.x,
                                                      position.y - child.parentData.position.y));
      }
    }
  }

}

class RenderImage extends RenderBox {

  RenderImage(String url, sky.Size dimensions) {
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

  sky.Size _requestedSize;
  sky.Size get requestedSize => _requestedSize;
  void set requestedSize (sky.Size value) {
    if (value == _requestedSize)
      return;
    _requestedSize = value;
    markNeedsLayout();
  }

  void performLayout() {
    // If there's no image, we can't size ourselves automatically
    if (_image == null) {
      double width = requestedSize.width == null ? 0.0 : requestedSize.width;
      double height = requestedSize.height == null ? 0.0 : requestedSize.height;
      size = constraints.constrain(new sky.Size(width, height));
      return;
    }

    // If neither height nor width are specified, use inherent image dimensions
    // If only one dimension is specified, adjust the other dimension to
    // maintain the aspect ratio
    if (requestedSize.width == null) {
      if (requestedSize.height == null) {
        size = constraints.constrain(new sky.Size(_image.width, _image.height));
      } else {
        double width = requestedSize.height * _image.width / _image.height;
        size = constraints.constrain(new sky.Size(width, requestedSize.height));
      }
    } else if (requestedSize.height == null) {
      double height = requestedSize.width * _image.height / _image.width;
      size = constraints.constrain(new sky.Size(requestedSize.width, height));
    } else {
      size = constraints.constrain(requestedSize);
    }
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
    sky.Paint paint = new sky.Paint();
    canvas.drawImage(_image, 0.0, 0.0, paint);
    if (needsScale)
      canvas.restore();
  }
}

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  const BoxDecoration({this.backgroundColor});

  final sky.Color backgroundColor;
}

class RenderDecoratedBox extends RenderProxyBox {

  RenderDecoratedBox({
    BoxDecoration decoration,
    RenderBox child
  }) : _decoration = decoration, super(child);

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  void set decoration (BoxDecoration value) {
    if (value == _decoration)
      return;
    _decoration = value;
    markNeedsPaint();
  }

  void paint(RenderObjectDisplayList canvas) {
    assert(size.width != null);
    assert(size.height != null);

    if (_decoration == null)
      return;

    if (_decoration.backgroundColor != null) {
      sky.Paint paint = new sky.Paint()..color = _decoration.backgroundColor;
      canvas.drawRect(new sky.Rect.fromLTRB(0.0, 0.0, size.width, size.height), paint);
    }
    super.paint(canvas);
  }
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

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    Matrix4 inverse = new Matrix4.zero();
    double det = inverse.copyInverse(_transform);
    // TODO(abarth): Check the determinant for degeneracy.

    Vector3 position3 = new Vector3(position.x, position.y, 0.0);
    Vector3 transformed3 = inverse.transform3(position3);
    sky.Point transformed = new sky.Point(transformed3.x, transformed3.y);
    super.hitTestChildren(result, position: transformed);
  }

  void paint(RenderObjectDisplayList canvas) {
    Float32List storage = _transform.storage;

    canvas.save();
    canvas.concat([
      storage[ 0], storage[ 4], storage[12],
      storage[ 1], storage[ 5], storage[13],
      storage[ 3], storage[ 7], storage[15],
    ]);
    super.paint(canvas);
    canvas.restore();
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

  sky.Size _size = new sky.Size(0.0, 0.0);
  double get width => _size.width;
  double get height => _size.height;

  int _orientation; // 0..3
  int get orientation => _orientation;
  Duration timeForRotation;

  ViewConstraints get constraints => super.constraints as ViewConstraints;
  bool get sizedByParent => true;
  void performResize() {
    if (constraints.orientation != _orientation) {
      if (_orientation != null && child != null)
        child.rotate(oldAngle: _orientation, newAngle: constraints.orientation, time: timeForRotation);
      _orientation = constraints.orientation;
    }
    _size = new sky.Size(constraints.width, constraints.height);
    assert(_size.height < double.INFINITY);
    assert(_size.width < double.INFINITY);
  }
  void performLayout() {
    if (child != null) {
      child.layout(new BoxConstraints.tight(_size));
      assert(child.size.width == width);
      assert(child.size.height == height);
    }
  }

  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our performResize()
  }

  bool hitTest(HitTestResult result, { sky.Point position }) {
    if (child != null) {
      sky.Rect childBounds = new sky.Rect.fromSize(child.size);
      if (childBounds.contains(position))
        child.hitTest(result, position: position);
    }
    result.add(this);
    return true;
  }

  void paint(RenderObjectDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, new sky.Point(0.0, 0.0));
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

  void defaultHitTestChildren(HitTestResult result, { sky.Point position }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      sky.Rect childBounds = new sky.Rect.fromPointAndSize(child.parentData.position, child.size);
      if (childBounds.contains(position)) {
        if (child.hitTest(result, position: new sky.Point(position.x - child.parentData.position.x,
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
