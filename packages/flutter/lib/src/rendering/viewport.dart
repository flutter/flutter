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

/// A base class for render objects that are bigger on the inside.
///
/// This class holds the common fields for viewport render objects but does not
/// have a child model. See [RenderViewport] for a viewport with a single child
/// and [RenderVirtualViewport] for a viewport with multiple children.
class RenderViewportBase extends RenderBox implements HasScrollDirection {
  RenderViewportBase(
    Offset paintOffset,
    Axis scrollDirection,
    Painter overlayPainter
  ) : _paintOffset = paintOffset,
      _scrollDirection = scrollDirection,
      _overlayPainter = overlayPainter {
    assert(paintOffset != null);
    assert(scrollDirection != null);
    assert(_offsetIsSane(_paintOffset, scrollDirection));
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
  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  void set paintOffset(Offset value) {
    assert(value != null);
    if (value == _paintOffset)
      return;
    assert(_offsetIsSane(value, scrollDirection));
    _paintOffset = value;
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
    assert(value != null);
    if (value == _scrollDirection)
      return;
    assert(_offsetIsSane(_paintOffset, value));
    _scrollDirection = value;
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

  Offset get _paintOffsetRoundedToIntegerDevicePixels {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    int dxInDevicePixels = (_paintOffset.dx * devicePixelRatio).round();
    int dyInDevicePixels = (_paintOffset.dy * devicePixelRatio).round();
    return new Offset(dxInDevicePixels / devicePixelRatio,
                      dyInDevicePixels / devicePixelRatio);
  }

  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset effectivePaintOffset = _paintOffsetRoundedToIntegerDevicePixels;
    super.applyPaintTransform(child, transform.translate(effectivePaintOffset.dx, effectivePaintOffset.dy));
  }

}

/// A render object that's bigger on the inside.
///
/// The child of a viewport can layout to a larger size than the viewport
/// itself. If that happens, only a portion of the child will be visible through
/// the viewport. The portion of the child that is visible is controlled by the
/// paint offset.
class RenderViewport extends RenderViewportBase with RenderObjectWithChildMixin<RenderBox> {

  RenderViewport({
    RenderBox child,
    Offset paintOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical,
    Painter overlayPainter
  }) : super(paintOffset, scrollDirection, overlayPainter) {
    this.child = child;
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

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    return paintOffset < Offset.zero || !(Offset.zero & size).contains((paintOffset & child.size).bottomRight);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Offset effectivePaintOffset = _paintOffsetRoundedToIntegerDevicePixels;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child, offset + effectivePaintOffset);
        _overlayPainter?.paint(context, offset);
      }

      if (_shouldClipAtPaintOffset(effectivePaintOffset)) {
        context.pushClipRect(needsCompositing, offset, Point.origin & size, paintContents);
      } else {
        paintContents(context, offset);
      }
    }
  }

  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtPaintOffset(_paintOffsetRoundedToIntegerDevicePixels))
      return Point.origin & size;
    return null;
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Point transformed = position + -_paintOffsetRoundedToIntegerDevicePixels;
      return child.hitTest(result, position: transformed);
    }
    return false;
  }
}

abstract class RenderVirtualViewport<T extends ContainerBoxParentDataMixin<RenderBox>>
    extends RenderViewportBase with ContainerRenderObjectMixin<RenderBox, T>,
                                    RenderBoxContainerDefaultsMixin<RenderBox, T> {
  RenderVirtualViewport({
    int virtualChildCount,
    LayoutCallback callback,
    Offset paintOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical,
    Painter overlayPainter
  }) : _virtualChildCount = virtualChildCount,
       _callback = callback,
       super(paintOffset, scrollDirection, overlayPainter);

  int get virtualChildCount => _virtualChildCount;
  int _virtualChildCount;
  void set virtualChildCount(int value) {
    if (_virtualChildCount == value)
      return;
    _virtualChildCount = value;
    markNeedsLayout();
  }

  /// Called during [layout] to determine the render object's children.
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

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position + -_paintOffsetRoundedToIntegerDevicePixels);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    defaultPaint(context, offset + _paintOffsetRoundedToIntegerDevicePixels);
    _overlayPainter?.paint(context, offset);
  }

  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  Rect describeApproximatePaintClip(RenderObject child) => Point.origin & size;
}
