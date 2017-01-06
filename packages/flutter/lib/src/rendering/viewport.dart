// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

/// The end of the viewport from which the paint offset is computed.
enum ViewportAnchor {
  /// The start (e.g., top or left, depending on the axis) of the first item
  /// should be aligned with the start (e.g., top or left, depending on the
  /// axis) of the viewport.
  start,

  /// The end (e.g., bottom or right, depending on the axis) of the last item
  /// should be aligned with the end (e.g., bottom or right, depending on the
  /// axis) of the viewport.
  end,
}

/// The interior and exterior dimensions of a viewport.
class ViewportDimensions {
  /// Creates dimensions for a viewport.
  ///
  /// By default, the content and container sizes are zero.
  const ViewportDimensions({
    this.contentSize: Size.zero,
    this.containerSize: Size.zero
  });

  /// A viewport that has zero size, both inside and outside.
  static const ViewportDimensions zero = const ViewportDimensions();

  /// The size of the content inside the viewport.
  final Size contentSize;

  /// The size of the outside of the viewport.
  final Size containerSize;

  bool get _debugHasAtLeastOneCommonDimension {
    return contentSize.width == containerSize.width
        || contentSize.height == containerSize.height;
  }

  /// Returns the offset at which to paint the content, accounting for the given
  /// anchor and the dimensions of the viewport.
  Offset getAbsolutePaintOffset({ Offset paintOffset, ViewportAnchor anchor }) {
    assert(_debugHasAtLeastOneCommonDimension);
    switch (anchor) {
      case ViewportAnchor.start:
        return paintOffset;
      case ViewportAnchor.end:
        return paintOffset + (containerSize - contentSize);
    }
    assert(anchor != null);
    return null;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! ViewportDimensions)
      return false;
    final ViewportDimensions typedOther = other;
    return contentSize == typedOther.contentSize &&
           containerSize == typedOther.containerSize;
  }

  @override
  int get hashCode => hashValues(contentSize, containerSize);

  @override
  String toString() => 'ViewportDimensions(container: $containerSize, content: $contentSize)';
}

/// A base class for render objects that are bigger on the inside.
///
/// This class holds the common fields for viewport render objects but does not
/// have a child model. See [RenderViewport] for a viewport with a single child
/// and [RenderVirtualViewport] for a viewport with multiple children.
class RenderViewportBase extends RenderBox {
  /// Initializes fields for subclasses.
  ///
  /// The [paintOffset] and [mainAxis] arguments must not be null.
  ///
  /// This constructor uses positional arguments rather than named arguments to
  /// work around limitations of mixins.
  RenderViewportBase(
    Offset paintOffset,
    Axis mainAxis,
    ViewportAnchor anchor
  ) : _paintOffset = paintOffset,
      _mainAxis = mainAxis,
      _anchor = anchor {
    assert(paintOffset != null);
    assert(mainAxis != null);
    assert(_offsetIsSane(_paintOffset, mainAxis));
  }

  bool _offsetIsSane(Offset offset, Axis direction) {
    switch (direction) {
      case Axis.horizontal:
        return offset.dy == 0.0;
      case Axis.vertical:
        return offset.dx == 0.0;
    }
    assert(direction != null);
    return null;
  }

  /// The offset at which to paint the child.
  ///
  /// The offset can be non-zero only in the [mainAxis].
  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  set paintOffset(Offset value) {
    assert(value != null);
    if (value == _paintOffset)
      return;
    assert(_offsetIsSane(value, mainAxis));
    _paintOffset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The direction in which the child is permitted to be larger than the viewport.
  ///
  /// The child is given layout constraints that are fully unconstrained along
  /// the main axis (e.g., the child can be as tall as it wants if the main axis
  /// is vertical).
  Axis get mainAxis => _mainAxis;
  Axis _mainAxis;
  set mainAxis(Axis value) {
    assert(value != null);
    if (value == _mainAxis)
      return;
    assert(_offsetIsSane(_paintOffset, value));
    _mainAxis = value;
    markNeedsLayout();
  }

  /// The end of the viewport from which the paint offset is computed.
  ///
  /// See [ViewportAnchor] for more detail.
  ViewportAnchor get anchor => _anchor;
  ViewportAnchor _anchor;
  set anchor(ViewportAnchor value) {
    assert(value != null);
    if (value == _anchor)
      return;
    _anchor = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The interior and exterior extent of the viewport.
  ViewportDimensions get dimensions => _dimensions;
  ViewportDimensions _dimensions = ViewportDimensions.zero;
  set dimensions(ViewportDimensions value) {
    assert(debugDoingThisLayout);
    _dimensions = value;
  }

  Offset get _effectivePaintOffset {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    int dxInDevicePixels = (_paintOffset.dx * devicePixelRatio).round();
    int dyInDevicePixels = (_paintOffset.dy * devicePixelRatio).round();
    return _dimensions.getAbsolutePaintOffset(
      paintOffset: new Offset(dxInDevicePixels / devicePixelRatio, dyInDevicePixels / devicePixelRatio),
      anchor: _anchor
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset effectivePaintOffset = _effectivePaintOffset;
    super.applyPaintTransform(child, transform..translate(effectivePaintOffset.dx, effectivePaintOffset.dy));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('paintOffset: $paintOffset');
    description.add('mainAxis: $mainAxis');
    description.add('anchor: $anchor');
  }
}

/// Signature for notifications about [RenderViewport] dimensions changing.
///
/// Used by [RenderViewport.onPaintOffsetUpdateNeeded].
typedef Offset ViewportDimensionsChangeCallback(ViewportDimensions dimensions);

/// A render object that's bigger on the inside.
///
/// The child of a viewport can layout to a larger size along the viewport's
/// [mainAxis] than the viewport itself. If that happens, only a portion of the
/// child will be visible through the viewport. The portion of the child that is
/// visible can be controlled with the [paintOffset].
///
/// See also:
///
///  * [RenderVirtualViewport] (which works with more than one child)
class RenderViewport extends RenderViewportBase with RenderObjectWithChildMixin<RenderBox> {
  /// Creates a render object that's bigger on the inside.
  ///
  /// The [paintOffset] and [mainAxis] arguments must not be null.
  RenderViewport({
    RenderBox child,
    Offset paintOffset: Offset.zero,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    this.onPaintOffsetUpdateNeeded
  }) : super(paintOffset, mainAxis, anchor) {
    this.child = child;
  }

  /// Called during [layout] to report the dimensions of the viewport
  /// and its child.
  ///
  /// The return value of this function is used as the new [paintOffset] and
  /// must not be null.
  ViewportDimensionsChangeCallback onPaintOffsetUpdateNeeded;

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    BoxConstraints innerConstraints;
    switch (mainAxis) {
      case Axis.horizontal:
        innerConstraints = constraints.heightConstraints();
        break;
      case Axis.vertical:
        innerConstraints = constraints.widthConstraints();
        break;
    }
    return innerConstraints;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll the RenderViewport, it would shift in its parent if the
  // parent was baseline-aligned, which makes no sense.

  @override
  void performLayout() {
    final ViewportDimensions oldDimensions = dimensions;
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = Offset.zero;
      dimensions = new ViewportDimensions(containerSize: size, contentSize: child.size);
    } else {
      performResize();
      dimensions = new ViewportDimensions(containerSize: size);
    }
    if (onPaintOffsetUpdateNeeded != null && dimensions != oldDimensions)
      paintOffset = onPaintOffsetUpdateNeeded(dimensions);
    assert(paintOffset != null);
  }

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    return paintOffset < Offset.zero || !(Offset.zero & size).contains((paintOffset & child.size).bottomRight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Offset effectivePaintOffset = _effectivePaintOffset;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child, offset + effectivePaintOffset);
      }

      if (_shouldClipAtPaintOffset(effectivePaintOffset)) {
        context.pushClipRect(needsCompositing, offset, Point.origin & size, paintContents);
      } else {
        paintContents(context, offset);
      }
    }
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtPaintOffset(_effectivePaintOffset))
      return Point.origin & size;
    return null;
  }

  // Workaround for https://github.com/dart-lang/sdk/issues/25232
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    super.applyPaintTransform(child, transform);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Point transformed = position + -_effectivePaintOffset;
      return child.hitTest(result, position: transformed);
    }
    return false;
  }
}

/// A render object that shows a subset of its children.
///
/// The children of a viewport can layout to a larger size along the viewport's
/// [mainAxis] than the viewport itself. If that happens, only a subset of the
/// children will be visible through the viewport. The subset of children that
/// are visible can be controlled with the [paintOffset].
///
/// See also:
///
///  * [RenderList] (which arranges its children linearly)
///  * [RenderGrid] (which arranges its children into tiles)
///  * [RenderViewport] (which is easier to use with a single child)
abstract class RenderVirtualViewport<T extends ContainerBoxParentDataMixin<RenderBox>>
    extends RenderViewportBase with ContainerRenderObjectMixin<RenderBox, T>,
                                    RenderBoxContainerDefaultsMixin<RenderBox, T> {
  /// Initializes fields for subclasses.
  ///
  /// The [paintOffset] and [mainAxis] arguments must not be null.
  RenderVirtualViewport({
    int virtualChildCount,
    LayoutCallback<BoxConstraints> callback,
    Offset paintOffset: Offset.zero,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start
  }) : _virtualChildCount = virtualChildCount,
       _callback = callback,
       super(paintOffset, mainAxis, anchor);

  /// The overall number of children this viewport could potentially display.
  ///
  /// If null, the viewport might display an unbounded number of children.
  int get virtualChildCount => _virtualChildCount;
  int _virtualChildCount;
  set virtualChildCount(int value) {
    if (_virtualChildCount == value)
      return;
    _virtualChildCount = value;
    markNeedsLayout();
  }

  /// Called during [layout] to determine the render object's children.
  ///
  /// Typically the callback will mutate the child list appropriately, for
  /// example so the child list contains only visible children.
  LayoutCallback<BoxConstraints> get callback => _callback;
  LayoutCallback<BoxConstraints> _callback;
  set callback(LayoutCallback<BoxConstraints> value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  /// Throws an exception if asserts are enabled, unless the
  /// [RenderObject.debugCheckingIntrinsics] flag is set.
  ///
  /// This is a convenience function for subclasses to call from their
  /// intrinsic-sizing functions if they don't have a good way to generate the
  /// numbers.
  @protected
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw new FlutterError(
          '$runtimeType does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require walking the entire '
          'child list, which cannot reliably and efficiently be done for render '
          'objects that potentially generate their child list during layout.'
        );
      }
      return true;
    });
    return true;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position + -_effectivePaintOffset);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    defaultPaint(context, offset + _effectivePaintOffset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => Point.origin & size;

  // Workaround for https://github.com/dart-lang/sdk/issues/25232
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    super.applyPaintTransform(child, transform);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('virtual child count: $virtualChildCount');
  }
}
