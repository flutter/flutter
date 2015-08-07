// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:vector_math/vector_math.dart';

class BlockParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> { }

enum BlockDirection { horizontal, vertical }

typedef double _ChildSizingFunction(RenderBox child, BoxConstraints constraints);

abstract class RenderBlockBase extends RenderBox with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
                                                      RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {

  // lays out RenderBox children in a vertical stack
  // uses the maximum width provided by the parent

  RenderBlockBase({
    List<RenderBox> children,
    BlockDirection direction: BlockDirection.vertical
  }) : _direction = direction {
    addAll(children);
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  BlockDirection _direction;
  BlockDirection get direction => _direction;
  void set direction (BlockDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  bool get _isVertical => _direction == BlockDirection.vertical;

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    if (_isVertical)
      return new BoxConstraints.tightFor(width: constraints.constrainWidth(constraints.maxWidth));
    return new BoxConstraints.tightFor(height: constraints.constrainHeight(constraints.maxHeight));
  }

  void performLayout() {
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double position = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      assert(child.parentData is BlockParentData);
      child.parentData.position = _isVertical ? new Point(0.0, position) : new Point(position, 0.0);
      position += _isVertical ? child.size.height : child.size.width;
      child = child.parentData.nextSibling;
    }
  }

}

class RenderBlock extends RenderBlockBase {

  RenderBlock({
    List<RenderBox> children,
    BlockDirection direction: BlockDirection.vertical
  }) : super(children: children, direction: direction);

  double _getIntrinsicCrossAxis(BoxConstraints constraints, _ChildSizingFunction childSize) {
    double extent = 0.0;
    BoxConstraints innerConstraints = _isVertical ? constraints.widthConstraints() : constraints.heightConstraints();
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child, innerConstraints));
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(BoxConstraints constraints) {
    double extent = 0.0;
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    RenderBox child = firstChild;
    while (child != null) {
      double childExtent = _isVertical ?
        child.getMinIntrinsicHeight(innerConstraints) :
        child.getMinIntrinsicWidth(innerConstraints);
      assert(() {
        if (_isVertical)
          return childExtent == child.getMaxIntrinsicHeight(innerConstraints);
        return childExtent == child.getMaxIntrinsicWidth(innerConstraints);
      });
      extent += childExtent;
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }
    return extent;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (_isVertical) {
      return _getIntrinsicCrossAxis(constraints,
        (c, innerConstraints) => c.getMinIntrinsicWidth(innerConstraints));
    }
    return _getIntrinsicMainAxis(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (_isVertical) {
      return _getIntrinsicCrossAxis(constraints,
          (c, innerConstraints) => c.getMaxIntrinsicWidth(innerConstraints));
    }
    return _getIntrinsicMainAxis(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (_isVertical)
      return _getIntrinsicMainAxis(constraints);
    return _getIntrinsicCrossAxis(constraints,
        (c, innerConstraints) => c.getMinIntrinsicWidth(innerConstraints));
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (_isVertical)
      return _getIntrinsicMainAxis(constraints);
    return _getIntrinsicCrossAxis(constraints,
        (c, innerConstraints) => c.getMaxIntrinsicWidth(innerConstraints));
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  double get _mainAxisExtent {
    RenderBox child = lastChild;
    if (child == null)
      return 0.0;
    BoxParentData parentData = child.parentData;
    return _isVertical ?
        parentData.position.y + child.size.height :
        parentData.position.x + child.size.width;
  }

  void performLayout() {
    assert(_isVertical ? constraints.maxHeight >= double.INFINITY : constraints.maxWidth >= double.INFINITY);
    super.performLayout();
    size = _isVertical ?
        constraints.constrain(new Size(constraints.maxWidth, _mainAxisExtent)) :
        constraints.constrain(new Size(_mainAxisExtent, constraints.maxHeight));
    assert(!size.isInfinite);
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    defaultPaint(canvas, offset);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

}

class RenderBlockViewport extends RenderBlockBase {

  // sizes itself to the given constraints
  // at the start of layout, calls callback

  RenderBlockViewport({
    LayoutCallback callback,
    List<RenderBox> children,
    double startOffset: 0.0
  }) : _callback = callback, _startOffset = startOffset, super(children: children);

  bool _inCallback = false;

  LayoutCallback _callback;
  LayoutCallback get callback => _callback;
  void set callback(LayoutCallback value) {
    assert(!_inCallback);
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  // you can set this from within the callback if necessary
  double _startOffset;
  double get startOffset => _startOffset;
  void set startOffset(double value) {
    if (value == _startOffset)
      return;
    _startOffset = value;
    if (!_inCallback)
      markNeedsPaint();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth();
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth();
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight();
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight();
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behaviour (returning null). Otherwise, as you
  // scroll the RenderBlockViewport, it would shift in its parent if
  // the parent was baseline-aligned, which makes no sense.

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.biggest;
    assert(!size.isInfinite);
  }

  bool get debugDoesLayoutWithCallback => true;
  void performLayout() {
    assert(constraints.maxHeight < double.INFINITY);
    if (_callback != null) {
      try {
        _inCallback = true;
        invokeLayoutCallback(_callback);
      } finally {
        _inCallback = false;
      }
    }
    super.performLayout();
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    canvas.save();
    canvas.clipRect(offset & size);
    defaultPaint(canvas, offset.translate(0.0, startOffset));
    canvas.restore();
  }

  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
    transform.translate(0.0, startOffset);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position + new Offset(0.0, -startOffset));
  }

}
