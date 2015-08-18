// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/box.dart';
import 'package:vector_math/vector_math.dart';

enum ScrollDirection { horizontal, vertical, both }

class RenderViewport extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  RenderViewport({
    RenderBox child,
    Offset scrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical
  }) : _scrollOffset = scrollOffset,
       _scrollDirection = scrollDirection {
    assert(_offsetIsSane(scrollOffset, scrollDirection));
    this.child = child;
  }

  bool _offsetIsSane(Offset offset, ScrollDirection direction) {
    switch (direction) {
      case ScrollDirection.both:
        return true;
      case ScrollDirection.horizontal:
        return offset.dy == 0.0;
      case ScrollDirection.vertical:
        return offset.dx == 0.0;
    }
  }

  Offset _scrollOffset;
  Offset get scrollOffset => _scrollOffset;
  void set scrollOffset(Offset value) {
    if (value == _scrollOffset)
      return;
    assert(_offsetIsSane(value, scrollDirection));
    _scrollOffset = value;
    markNeedsPaint();
  }

  ScrollDirection _scrollDirection;
  ScrollDirection get scrollDirection => _scrollDirection;
  void set scrollDirection(ScrollDirection value) {
    if (value == _scrollDirection)
      return;
    assert(_offsetIsSane(scrollOffset, value));
    _scrollDirection = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    BoxConstraints innerConstraints;
    switch (scrollDirection) {
      case ScrollDirection.both:
        innerConstraints = new BoxConstraints();
        break;
      case ScrollDirection.horizontal:
        innerConstraints = constraints.heightConstraints();
        break;
      case ScrollDirection.vertical:
        innerConstraints = constraints.widthConstraints();
        break;
    }
    return innerConstraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(_getInnerConstraints(constraints));
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(_getInnerConstraints(constraints));
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(_getInnerConstraints(constraints));
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(_getInnerConstraints(constraints));
    return super.getMaxIntrinsicHeight(constraints);
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behaviour (returning null). Otherwise, as you
  // scroll the RenderViewport, it would shift in its parent if the
  // parent was baseline-aligned, which makes no sense.

  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      assert(child.parentData is BoxParentData);
      child.parentData.position = Point.origin;
    } else {
      performResize();
    }
  }

  Offset get _scrollOffsetRoundedToIntegerDevicePixels {
    double devicePixelRatio = sky.view.devicePixelRatio;
    int dxInDevicePixels = (scrollOffset.dx * devicePixelRatio).round();
    int dyInDevicePixels = (scrollOffset.dy * devicePixelRatio).round();
    return new Offset(dxInDevicePixels / devicePixelRatio,
                      dyInDevicePixels / devicePixelRatio);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Offset roundedScrollOffset = _scrollOffsetRoundedToIntegerDevicePixels;
      bool _needsClip = offset < Offset.zero ||
                        !(offset & size).contains(((offset - roundedScrollOffset) & child.size).bottomRight);
      if (_needsClip)
        context.paintChildWithClipRect(child, (offset - roundedScrollOffset).toPoint(), offset & size);
      else
        context.paintChild(child, (offset - roundedScrollOffset).toPoint());
    }
  }

  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
    transform.translate(-scrollOffset.dx, -scrollOffset.dy);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Point transformed = position + _scrollOffsetRoundedToIntegerDevicePixels;
      child.hitTest(result, position: transformed);
    }
  }
}
