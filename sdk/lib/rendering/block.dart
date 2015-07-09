// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

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

  BoxConstraints _getInnerConstraintsForWidth(double width) {
    return new BoxConstraints(minWidth: width, maxWidth: width);
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    double height = 0.0;
    double width = constraints.constrainWidth(constraints.maxWidth);
    BoxConstraints innerConstraints = _getInnerConstraintsForWidth(width);
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

  double _childrenHeight;
  double get childrenHeight => _childrenHeight;

  void markNeedsLayout() {
    _childrenHeight = null;
    super.markNeedsLayout();
  }

  void performLayout() {
    assert(constraints is BoxConstraints);
    double width = constraints.constrainWidth(constraints.maxWidth);
    BoxConstraints innerConstraints = _getInnerConstraintsForWidth(width);
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

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    defaultPaint(canvas, offset);
  }

}

class RenderBlock extends RenderBlockBase {

  // sizes itself to the height of its child stack

  RenderBlock({ List<RenderBox> children }) : super(children: children);

  bool _hasVisualOverflow = false;

  void performLayout() {
    super.performLayout();
    size = constraints.constrain(new Size(constraints.maxWidth, childrenHeight));
    assert(!size.isInfinite);

    // FIXME(eseidel): Block lays out its children with unconstrained height
    // yet itself remains constrained. Remember that our children wanted to
    // be taller than we are so we know to clip them (and not cause confusing
    // mismatch of painting vs. hittesting).
    _hasVisualOverflow = childrenHeight > size.height;
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    if (_hasVisualOverflow) {
      canvas.save();
      canvas.clipRect(offset & size);
    }
    super.paint(canvas, offset);
    if (_hasVisualOverflow) {
      canvas.restore();
    }
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
      markNeedsLayout();
  }

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.biggest;
    assert(!size.isInfinite);
  }

  bool get debugDoesLayoutWithCallback => true;
  void performLayout() {
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
    super.paint(canvas, offset.translate(0.0, _startOffset));
    canvas.restore();
  }

}

