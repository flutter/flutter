// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'node.dart';
import 'dart:sky' as sky;

// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

class EdgeDims {
  // used for e.g. padding
  const EdgeDims(this.top, this.right, this.bottom, this.left);
  final double top;
  final double right;
  final double bottom;
  final double left;
  operator ==(EdgeDims other) => (top == other.top) ||
                                 (right == other.right) ||
                                 (bottom == other.bottom) ||
                                 (left == other.left);
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

  BoxConstraints deflate(EdgeDims edges) {
    assert(edges != null);
    return new BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth - (edges.left + edges.right),
      minHeight: minHeight,
      maxHeight: maxHeight - (edges.top + edges.bottom)
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
}

class BoxParentData extends ParentData {
  sky.Point position = new sky.Point(0.0, 0.0);
}

abstract class RenderBox extends RenderNode {

  void setParentData(RenderNode child) {
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

abstract class RenderProxyBox extends RenderBox with RenderNodeWithChildMixin<RenderBox> {
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

  void paint(RenderNodeDisplayList canvas) {
    if (child != null)
      child.paint(canvas);
  }
}

class RenderSizedBox extends RenderProxyBox {
  final sky.Size desiredSize;

  RenderSizedBox({
    RenderBox child, 
    this.desiredSize: const sky.Size.infinite()
  }) : super(child);

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    return constraints.constrain(desiredSize);
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
    child.layout(new BoxConstraints.tight(size));
  }
}

class RenderPadding extends RenderBox with RenderNodeWithChildMixin<RenderBox> {

  RenderPadding(EdgeDims padding, RenderBox child) {
    assert(padding != null);
    this.padding = padding;
    this.child = child;
  }

  EdgeDims _padding;
  EdgeDims get padding => _padding;
  void set padding (EdgeDims value) {
    assert(value != null);
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
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

  void paint(RenderNodeDisplayList canvas) {
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

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  // TODO(mpcomplete): go through and change the users of this class to pass
  // a Color object.
  BoxDecoration({
    backgroundColor
  }) : backgroundColor = new sky.Color(backgroundColor);

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

  void paint(RenderNodeDisplayList canvas) {
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


// RENDER VIEW LAYOUT MANAGER

class ViewConstraints {

  const ViewConstraints({
    this.width: 0.0, this.height: 0.0, this.orientation: null
  });

  final double width;
  final double height;
  final int orientation;

}

class RenderView extends RenderNode with RenderNodeWithChildMixin<RenderBox> {

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

  void paint(RenderNodeDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, new sky.Point(0.0, 0.0));
  }

  void paintFrame() {
    RenderNode.debugDoingPaint = true;
    var canvas = new RenderNodeDisplayList(sky.view.width, sky.view.height);
    paint(canvas);
    sky.view.picture = canvas.endRecording();
    RenderNode.debugDoingPaint = false;
  }

}

// DEFAULT BEHAVIORS FOR RENDERBOX CONTAINERS
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerParentDataMixin<ChildType>> implements ContainerRenderNodeMixin<ChildType, ParentDataType> {

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

  void defaultPaint(RenderNodeDisplayList canvas) {
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      canvas.paintChild(child, child.parentData.position);
      child = child.parentData.nextSibling;
    }
  }
}
