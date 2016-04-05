// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

/// Parent data for use with [RenderBlockBase].
class BlockParentData extends ContainerBoxParentDataMixin<RenderBox> { }

typedef double _ChildSizingFunction(RenderBox child, BoxConstraints constraints);
typedef double _Constrainer(double value);

/// Implements the block layout algorithm.
///
/// In block layout, children are arranged linearly along the main axis (either
/// horizontally or vertically). In the cross axis, children are stretched to
/// match the block's cross-axis extent. In the main axis, children are given
/// unlimited space and the block expands its main axis to contain all its
/// children. Because blocks expand in the main axis, blocks must be given
/// unlimited space in the main axis, typically by being contained in a
/// viewport with a scrolling direction that matches the block's main axis.
abstract class RenderBlockBase extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData>
    implements HasMainAxis {

  RenderBlockBase({
    List<RenderBox> children,
    Axis mainAxis: Axis.vertical,
    double itemExtent,
    double minExtent: 0.0
  }) : _mainAxis = mainAxis, _itemExtent = itemExtent, _minExtent = minExtent {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  /// The direction to use as the main axis.
  @override
  Axis get mainAxis => _mainAxis;
  Axis _mainAxis;
  void set mainAxis (Axis value) {
    if (_mainAxis != value) {
      _mainAxis = value;
      markNeedsLayout();
    }
  }

  /// If non-null, forces children to be exactly this large in the main axis.
  double get itemExtent => _itemExtent;
  double _itemExtent;
  void set itemExtent(double value) {
    if (value != _itemExtent) {
      _itemExtent = value;
      markNeedsLayout();
    }
  }

  /// Forces the block to be at least this large in the main-axis.
  double get minExtent => _minExtent;
  double _minExtent;
  void set minExtent(double value) {
    if (value != _minExtent) {
      _minExtent = value;
      markNeedsLayout();
    }
  }

  /// Whether the main axis is vertical.
  bool get isVertical => _mainAxis == Axis.vertical;

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (_mainAxis) {
      case Axis.horizontal:
        return new BoxConstraints.tightFor(height: constraints.maxHeight, width: itemExtent);
      case Axis.vertical:
        return new BoxConstraints.tightFor(width: constraints.maxWidth, height: itemExtent);
    }
  }

  double get _mainAxisExtent {
    RenderBox child = lastChild;
    if (child == null)
      return minExtent;
    BoxParentData parentData = child.parentData;
    return isVertical ?
        math.max(minExtent, parentData.offset.dy + child.size.height) :
        math.max(minExtent, parentData.offset.dx + child.size.width);
  }

  @override
  void performLayout() {
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double position = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final BlockParentData childParentData = child.parentData;
      childParentData.offset = isVertical ? new Offset(0.0, position) : new Offset(position, 0.0);
      position += isVertical ? child.size.height : child.size.width;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    size = isVertical ?
        constraints.constrain(new Size(constraints.maxWidth, _mainAxisExtent)) :
        constraints.constrain(new Size(_mainAxisExtent, constraints.maxHeight));
    assert(!size.isInfinite);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('mainAxis: $mainAxis');
  }
}

/// A block layout with a concrete set of children.
class RenderBlock extends RenderBlockBase {

  RenderBlock({
    List<RenderBox> children,
    Axis mainAxis: Axis.vertical,
    double itemExtent,
    double minExtent: 0.0
  }) : super(children: children, mainAxis: mainAxis, itemExtent: itemExtent, minExtent: minExtent);

  double _getIntrinsicCrossAxis(BoxConstraints constraints, _ChildSizingFunction childSize, _Constrainer constrainer) {
    double extent = 0.0;
    BoxConstraints innerConstraints = isVertical ? constraints.widthConstraints() : constraints.heightConstraints();
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child, innerConstraints));
      final BlockParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return constrainer(extent);
  }

  double _getIntrinsicMainAxis(BoxConstraints constraints, _Constrainer constrainer) {
    double extent = 0.0;
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    RenderBox child = firstChild;
    while (child != null) {
      double childExtent = isVertical ?
        child.getMinIntrinsicHeight(innerConstraints) :
        child.getMinIntrinsicWidth(innerConstraints);
      extent += childExtent;
      final BlockParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return constrainer(math.max(extent, minExtent));
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical) {
      return _getIntrinsicCrossAxis(
        constraints,
        (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints),
        constraints.constrainWidth
      );
    }
    return _getIntrinsicMainAxis(constraints, constraints.constrainWidth);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical) {
      return _getIntrinsicCrossAxis(
        constraints,
        (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints),
        constraints.constrainWidth
      );
    }
    return _getIntrinsicMainAxis(constraints, constraints.constrainWidth);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical)
      return _getIntrinsicMainAxis(constraints, constraints.constrainHeight);
    return _getIntrinsicCrossAxis(
      constraints,
      (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints),
      constraints.constrainHeight
    );
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical)
      return _getIntrinsicMainAxis(constraints, constraints.constrainHeight);
    return _getIntrinsicCrossAxis(
      constraints,
      (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints),
      constraints.constrainHeight
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  void performLayout() {
    assert((isVertical ? constraints.maxHeight >= double.INFINITY : constraints.maxWidth >= double.INFINITY) &&
           'RenderBlock does not clip or resize its children, so it must be placed in a parent that does not constrain '
           'the block\'s main direction. You probably want to put the RenderBlock inside a RenderViewport.' is String);
    super.performLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

}

/// A block layout whose children depend on its layout.
///
/// This class invokes a callbacks for layout and intrinsic dimensions. The main
/// [callback] (constructor argument and property) is expected to modify the
/// element's child list. The regular block layout algorithm is then applied to
/// the children. The intrinsic dimension callbacks are called to determine
/// intrinsic dimensions; if no value can be returned, they should not be set
/// or, if set, should return null.
class RenderBlockViewport extends RenderBlockBase {

  RenderBlockViewport({
    LayoutCallback callback,
    VoidCallback postLayoutCallback,
    ExtentCallback totalExtentCallback,
    ExtentCallback maxCrossAxisDimensionCallback,
    ExtentCallback minCrossAxisDimensionCallback,
    RenderObjectPainter overlayPainter,
    Axis mainAxis: Axis.vertical,
    double itemExtent,
    double minExtent: 0.0,
    double startOffset: 0.0,
    List<RenderBox> children
  }) : _callback = callback,
       _totalExtentCallback = totalExtentCallback,
       _maxCrossAxisExtentCallback = maxCrossAxisDimensionCallback,
       _minCrossAxisExtentCallback = minCrossAxisDimensionCallback,
       _overlayPainter = overlayPainter,
       _startOffset = startOffset,
       super(children: children, mainAxis: mainAxis, itemExtent: itemExtent, minExtent: minExtent);

  bool _inCallback = false;

  @override
  bool get isRepaintBoundary => true;

  /// Called during [layout] to determine the block's children.
  ///
  /// Typically the callback will mutate the child list appropriately, for
  /// example so the child list contains only visible children.
  LayoutCallback get callback => _callback;
  LayoutCallback _callback;
  void set callback(LayoutCallback value) {
    assert(!_inCallback);
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  /// Called during after [layout].
  ///
  /// This callback cannot mutate the tree. To mutate the tree during
  /// layout, use [callback].
  VoidCallback postLayoutCallback;

  /// Returns the total main-axis extent of all the children that could be included by [callback] in one go.
  ExtentCallback get totalExtentCallback => _totalExtentCallback;
  ExtentCallback _totalExtentCallback;
  void set totalExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _totalExtentCallback)
      return;
    _totalExtentCallback = value;
    markNeedsLayout();
  }

  /// Returns the minimum cross-axis extent across all the children that could be included by [callback] in one go.
  ExtentCallback get minCrossAxisExtentCallback => _minCrossAxisExtentCallback;
  ExtentCallback _minCrossAxisExtentCallback;
  void set minCrossAxisExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _minCrossAxisExtentCallback)
      return;
    _minCrossAxisExtentCallback = value;
    markNeedsLayout();
  }

  /// Returns the maximum cross-axis extent across all the children that could be included by [callback] in one go.
  ExtentCallback get maxCrossAxisExtentCallback => _maxCrossAxisExtentCallback;
  ExtentCallback _maxCrossAxisExtentCallback;
  void set maxCrossAxisExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _maxCrossAxisExtentCallback)
      return;
    _maxCrossAxisExtentCallback = value;
    markNeedsLayout();
  }

  RenderObjectPainter get overlayPainter => _overlayPainter;
  RenderObjectPainter _overlayPainter;
  void set overlayPainter(RenderObjectPainter value) {
    if (_overlayPainter == value)
      return;
    if (attached)
      _overlayPainter?.detach();
    _overlayPainter = value;
    if (attached)
      _overlayPainter?.attach(this);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayPainter?.attach(this);
  }

  @override
  void detach() {
    super.detach();
    _overlayPainter?.detach();
  }

  /// The offset at which to paint the first child.
  ///
  /// Note: you can modify this property from within [callback], if necessary.
  double get startOffset => _startOffset;
  double _startOffset;
  void set startOffset(double value) {
    if (value != _startOffset) {
      _startOffset = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  double _getIntrinsicDimension(BoxConstraints constraints, ExtentCallback intrinsicCallback, _Constrainer constrainer) {
    assert(!_inCallback);
    double result;
    if (intrinsicCallback == null) {
      assert(() {
        if (!RenderObject.debugCheckingIntrinsics)
          throw new UnsupportedError('$runtimeType does not support returning intrinsic dimensions if the relevant callbacks have not been specified.');
        return true;
      });
      return constrainer(0.0);
    }
    try {
      _inCallback = true;
      result = intrinsicCallback(constraints);
      result = constrainer(result ?? 0.0);
    } finally {
      _inCallback = false;
    }
    return result;
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical)
      return _getIntrinsicDimension(constraints, minCrossAxisExtentCallback, constraints.constrainWidth);
    return constraints.constrainWidth(minExtent);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (isVertical)
      return _getIntrinsicDimension(constraints, maxCrossAxisExtentCallback, constraints.constrainWidth);
    return _getIntrinsicDimension(constraints, totalExtentCallback, new BoxConstraints(minWidth: minExtent).enforce(constraints).constrainWidth);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (!isVertical)
      return _getIntrinsicDimension(constraints, minCrossAxisExtentCallback, constraints.constrainHeight);
    return constraints.constrainHeight(0.0);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (!isVertical)
      return _getIntrinsicDimension(constraints, maxCrossAxisExtentCallback, constraints.constrainHeight);
    return _getIntrinsicDimension(constraints, totalExtentCallback, new BoxConstraints(minHeight: minExtent).enforce(constraints).constrainHeight);
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll the RenderBlockViewport, it would shift in its parent if
  // the parent was baseline-aligned, which makes no sense.

  @override
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
    if (postLayoutCallback != null)
      postLayoutCallback();
  }

  void _paintContents(PaintingContext context, Offset offset) {
    if (isVertical)
      defaultPaint(context, offset.translate(0.0, startOffset));
    else
      defaultPaint(context, offset.translate(startOffset, 0.0));

    overlayPainter?.paint(context, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (isVertical)
      transform.translate(0.0, startOffset);
    else
      transform.translate(startOffset, 0.0);
    super.applyPaintTransform(child, transform);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => Point.origin & size;

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (isVertical)
      return defaultHitTestChildren(result, position: position + new Offset(0.0, -startOffset));
    else
      return defaultHitTestChildren(result, position: position + new Offset(-startOffset, 0.0));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('startOffset: $startOffset');
  }
}
