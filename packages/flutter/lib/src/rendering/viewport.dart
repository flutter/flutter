// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

enum ViewportAnchor {
  start,
  end,
}

abstract class HasScrollDirection {
  Axis get scrollDirection;
}

/// A render object that's bigger on the inside.
///
/// The child of a viewport can layout to a larger size than the viewport
/// itself. If that happens, only a portion of the child will be visible through
/// the viewport. The portion of the child that is visible is controlled by the
/// scroll offset.
///
/// Viewport is the core scrolling primitive in the system, but it can be used
/// in other situations.
class RenderViewport extends RenderBox with RenderObjectWithChildMixin<RenderBox>
    implements HasScrollDirection {

  RenderViewport({
    RenderBox child,
    Offset scrollOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical
  }) : _scrollOffset = scrollOffset,
       _scrollDirection = scrollDirection {
    assert(_offsetIsSane(scrollOffset, scrollDirection));
    this.child = child;
  }

  bool _offsetIsSane(Offset offset, Axis direction) {
    switch (direction) {
      case Axis.horizontal:
        return offset.dy == 0.0;
      case Axis.vertical:
        return offset.dx == 0.0;
    }
  }

  /// The offset at which to paint the child.
  ///
  /// The offset can be non-zero only in the [scrollDirection].
  Offset get scrollOffset => _scrollOffset;
  Offset _scrollOffset;
  void set scrollOffset(Offset value) {
    if (value == _scrollOffset)
      return;
    assert(_offsetIsSane(value, scrollDirection));
    _scrollOffset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The direction in which the child is permitted to be larger than the viewport
  ///
  /// If the viewport is scrollable in a particular direction (e.g., vertically),
  /// the child is given layout constraints that are fully unconstrainted in
  /// that direction (e.g., the child can be as tall as it wants).
  Axis get scrollDirection => _scrollDirection;
  Axis _scrollDirection;
  void set scrollDirection(Axis value) {
    if (value == _scrollDirection)
      return;
    assert(_offsetIsSane(scrollOffset, value));
    _scrollDirection = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    BoxConstraints innerConstraints;
    switch (scrollDirection) {
      case Axis.horizontal:
        innerConstraints = constraints.heightConstraints();
        break;
      case Axis.vertical:
        innerConstraints = constraints.widthConstraints();
        break;
    }
    return innerConstraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return constraints.constrainWidth(child.getMinIntrinsicWidth(_getInnerConstraints(constraints)));
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return constraints.constrainWidth(child.getMaxIntrinsicWidth(_getInnerConstraints(constraints)));
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return constraints.constrainHeight(child.getMinIntrinsicHeight(_getInnerConstraints(constraints)));
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    if (child != null)
      return constraints.constrainHeight(child.getMaxIntrinsicHeight(_getInnerConstraints(constraints)));
    return super.getMaxIntrinsicHeight(constraints);
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll the RenderViewport, it would shift in its parent if the
  // parent was baseline-aligned, which makes no sense.

  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = Offset.zero;
    } else {
      performResize();
    }
  }

  Offset get _scrollOffsetRoundedToIntegerDevicePixels {
    double devicePixelRatio = ui.window.devicePixelRatio;
    int dxInDevicePixels = (scrollOffset.dx * devicePixelRatio).round();
    int dyInDevicePixels = (scrollOffset.dy * devicePixelRatio).round();
    return new Offset(dxInDevicePixels / devicePixelRatio,
                      dyInDevicePixels / devicePixelRatio);
  }

  bool _wouldNeedClipAtOffset(Offset offset) {
    assert(child != null);
    return offset < Offset.zero || !(Offset.zero & size).contains(((Offset.zero - offset) & child.size).bottomRight);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      Offset roundedScrollOffset = _scrollOffsetRoundedToIntegerDevicePixels;
      bool _needsClip = _wouldNeedClipAtOffset(roundedScrollOffset);
      if (_needsClip) {
        context.pushClipRect(needsCompositing, offset, Point.origin & size, (PaintingContext context, Offset offset) {
          context.paintChild(child, offset - roundedScrollOffset);
        });
      } else {
        context.paintChild(child, offset - roundedScrollOffset);
      }
    }
  }

  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translate(-scrollOffset.dx, -scrollOffset.dy);
    super.applyPaintTransform(child, transform);
  }

  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null &&
        _wouldNeedClipAtOffset(_scrollOffsetRoundedToIntegerDevicePixels))
      return Point.origin & size;
    return null;
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Point transformed = position + _scrollOffsetRoundedToIntegerDevicePixels;
      return child.hitTest(result, position: transformed);
    }
    return false;
  }
}

abstract class RenderVirtualViewport<T extends ContainerBoxParentDataMixin<RenderBox>>
    extends RenderBox with ContainerRenderObjectMixin<RenderBox, T>,
                           RenderBoxContainerDefaultsMixin<RenderBox, T> {
  RenderVirtualViewport({
    int virtualChildCount,
    Offset paintOffset,
    LayoutCallback callback,
    Painter overlayPainter
  }) : _virtualChildCount = virtualChildCount,
       _paintOffset = paintOffset,
       _callback = callback,
       _overlayPainter = overlayPainter;

  int get virtualChildCount => _virtualChildCount;
  int _virtualChildCount;
  void set virtualChildCount(int value) {
    if (_virtualChildCount == value)
      return;
    _virtualChildCount = value;
    markNeedsLayout();
  }

  /// The offset at which to paint the first item.
  ///
  /// Note: you can modify this property from within [callback], if necessary.
  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  void set paintOffset(Offset value) {
    assert(value != null);
    if (value == _paintOffset)
      return;
    _paintOffset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// Called during [layout] to determine the grid's children.
  ///
  /// Typically the callback will mutate the child list appropriately, for
  /// example so the child list contains only visible children.
  LayoutCallback get callback => _callback;
  LayoutCallback _callback;
  void set callback(LayoutCallback value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  Painter get overlayPainter => _overlayPainter;
  Painter _overlayPainter;
  void set overlayPainter(Painter value) {
    if (_overlayPainter == value)
      return;
    if (attached)
      _overlayPainter?.detach();
    _overlayPainter = value;
    if (attached)
      _overlayPainter?.attach(this);
    markNeedsPaint();
  }

  void attach() {
    super.attach();
    _overlayPainter?.attach(this);
  }

  void detach() {
    super.detach();
    _overlayPainter?.detach();
  }

  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    super.applyPaintTransform(child, transform.translate(paintOffset.dx, paintOffset.dy));
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position + -paintOffset);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    defaultPaint(context, offset + paintOffset);
    _overlayPainter?.paint(context, offset);
  }

  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  Rect describeApproximatePaintClip(RenderObject child) => Point.origin & size;
}
