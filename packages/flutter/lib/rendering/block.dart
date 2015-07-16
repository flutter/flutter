// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

class BlockParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> { }

abstract class RenderBlockBase extends RenderBox with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
                                                      RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {

  // lays out RenderBox children in a vertical stack
  // uses the maximum width provided by the parent

  RenderBlockBase({
    List<RenderBox> children
  }) {
    addAll(children);
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  double _childrenHeight;
  double get childrenHeight => _childrenHeight;

  void markNeedsLayout() {
    _childrenHeight = null;
    super.markNeedsLayout();
  }

  void performLayout() {
    assert(constraints is BoxConstraints);
    double width = constraints.constrainWidth(constraints.maxWidth);
    BoxConstraints innerConstraints = new BoxConstraints.tightFor(width: width);
    double y = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      assert(child.parentData is BlockParentData);
      child.parentData.position = new Point(0.0, y);
      y += child.size.height;
      child = child.parentData.nextSibling;
    }
    _childrenHeight = y;
  }

}

class RenderBlock extends RenderBlockBase {

  // sizes itself to the height of its child stack

  RenderBlock({ List<RenderBox> children }) : super(children: children);

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    double width = 0.0;
    BoxConstraints innerConstraints = constraints.widthConstraints();
    RenderBox child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMinIntrinsicWidth(innerConstraints));
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }
    return width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    double width = 0.0;
    BoxConstraints innerConstraints = constraints.widthConstraints();
    RenderBox child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMaxIntrinsicWidth(innerConstraints));
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }
    return width;
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    double height = 0.0;
    double width = constraints.constrainWidth(constraints.maxWidth);
    BoxConstraints innerConstraints = new BoxConstraints.tightFor(width: width);
    RenderBox child = firstChild;
    while (child != null) {
      double childHeight = child.getMinIntrinsicHeight(innerConstraints);
      assert(childHeight == child.getMaxIntrinsicHeight(innerConstraints));
      height += childHeight;
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }
    return height;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  void performLayout() {
    assert(constraints.maxHeight >= double.INFINITY);
    super.performLayout();
    size = constraints.constrain(new Size(constraints.maxWidth, childrenHeight));
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

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position + new Offset(0.0, -startOffset));
  }

}
