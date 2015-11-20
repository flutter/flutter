// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

/// Parent data for use with [RenderBlockBase]
class BlockParentData extends ContainerBoxParentDataMixin<RenderBox> { }

/// The direction in which the block should lay out
enum BlockDirection {
  /// Children are arranged horizontally, from left to right
  horizontal,
  /// Children are arranged vertically, from top to bottom
  vertical
}

typedef double _ChildSizingFunction(RenderBox child, BoxConstraints constraints);
typedef double _Constrainer(double value);

/// Implements the block layout algorithm
///
/// In block layout, children are arranged linearly along the main axis (either
/// horizontally or vertically). In the cross axis, children are stretched to
/// match the block's cross-axis extent. In the main axis, children are given
/// unlimited space and the block expands its main axis to contain all its
/// children. Because blocks expand in the main axis, blocks must be given
/// unlimited space in the main axis, typically by being contained in a
/// viewport with a scrolling direction that matches the block's main axis.
abstract class RenderBlockBase extends RenderBox with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
                                                      RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {

  RenderBlockBase({
    List<RenderBox> children,
    BlockDirection direction: BlockDirection.vertical,
    double itemExtent,
    double minExtent: 0.0
  }) : _direction = direction, _itemExtent = itemExtent, _minExtent = minExtent {
    addAll(children);
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  /// The direction to use as the main axis
  BlockDirection get direction => _direction;
  BlockDirection _direction;
  void set direction (BlockDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// If non-null, forces children to be exactly this large in the main axis
  double get itemExtent => _itemExtent;
  double _itemExtent;
  void set itemExtent(double value) {
    if (value != _itemExtent) {
      _itemExtent = value;
      markNeedsLayout();
    }
  }

  /// Forces the block to be at least this large in the main-axis
  double get minExtent => _minExtent;
  double _minExtent;
  void set minExtent(double value) {
    if (value != _minExtent) {
      _minExtent = value;
      markNeedsLayout();
    }
  }

  /// Whether the main axis is vertical
  bool get isVertical => _direction == BlockDirection.vertical;

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    if (isVertical)
      return new BoxConstraints.tightFor(width: constraints.constrainWidth(constraints.maxWidth),
                                         height: itemExtent);
    return new BoxConstraints.tightFor(height: constraints.constrainHeight(constraints.maxHeight),
                                       width: itemExtent);
  }

  double get _mainAxisExtent {
    RenderBox child = lastChild;
    if (child == null)
      return minExtent;
    BoxParentData parentData = child.parentData;
    return isVertical ?
        math.max(minExtent, parentData.position.y + child.size.height) :
        math.max(minExtent, parentData.position.x + child.size.width);
  }

  void performLayout() {
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double position = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final BlockParentData childParentData = child.parentData;
      childParentData.position = isVertical ? new Point(0.0, position) : new Point(position, 0.0);
      position += isVertical ? child.size.height : child.size.width;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    size = isVertical ?
        constraints.constrain(new Size(constraints.maxWidth, _mainAxisExtent)) :
        constraints.constrain(new Size(_mainAxisExtent, constraints.maxHeight));
    assert(!size.isInfinite);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('direction: $direction');
  }
}

/// A block layout with a concrete set of children
class RenderBlock extends RenderBlockBase {

  RenderBlock({
    List<RenderBox> children,
    BlockDirection direction: BlockDirection.vertical,
    double itemExtent,
    double minExtent: 0.0
  }) : super(children: children, direction: direction, itemExtent: itemExtent, minExtent: minExtent);

  double _getIntrinsicCrossAxis(BoxConstraints constraints, _ChildSizingFunction childSize) {
    double extent = 0.0;
    BoxConstraints innerConstraints = isVertical ? constraints.widthConstraints() : constraints.heightConstraints();
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child, innerConstraints));
      final BlockParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(BoxConstraints constraints) {
    double extent = 0.0;
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    RenderBox child = firstChild;
    while (child != null) {
      double childExtent = isVertical ?
        child.getMinIntrinsicHeight(innerConstraints) :
        child.getMinIntrinsicWidth(innerConstraints);
      assert(() {
        if (isVertical)
          return childExtent == child.getMaxIntrinsicHeight(innerConstraints);
        return childExtent == child.getMaxIntrinsicWidth(innerConstraints);
      });
      extent += childExtent;
      final BlockParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return math.max(extent, minExtent);
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (isVertical) {
      return _getIntrinsicCrossAxis(
        constraints,
        (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints)
      );
    }
    return _getIntrinsicMainAxis(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (isVertical) {
      return _getIntrinsicCrossAxis(
        constraints,
        (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints)
      );
    }
    return _getIntrinsicMainAxis(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (isVertical)
      return _getIntrinsicMainAxis(constraints);
    return _getIntrinsicCrossAxis(
      constraints,
      (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints)
    );
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (isVertical)
      return _getIntrinsicMainAxis(constraints);
    return _getIntrinsicCrossAxis(
      constraints,
      (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints)
    );
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  void performLayout() {
    assert((isVertical ? constraints.maxHeight >= double.INFINITY : constraints.maxWidth >= double.INFINITY) &&
           'RenderBlock does not clip or resize its children, so it must be placed in a parent that does not constrain ' +
           'the block\'s main direction. You probably want to put the RenderBlock inside a RenderViewport.' is String);
    super.performLayout();
  }

  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

}

/// A block layout whose children depend on its layout
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
    ExtentCallback totalExtentCallback,
    ExtentCallback maxCrossAxisDimensionCallback,
    ExtentCallback minCrossAxisDimensionCallback,
    Painter overlayPainter,
    BlockDirection direction: BlockDirection.vertical,
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
       super(children: children, direction: direction, itemExtent: itemExtent, minExtent: minExtent);

  bool _inCallback = false;
  bool get hasLayer => true;

  /// Called during [layout] to determine the blocks children
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

  /// Returns the total main-axis extent of all the children that could be included by [callback] in one go
  ExtentCallback get totalExtentCallback => _totalExtentCallback;
  ExtentCallback _totalExtentCallback;
  void set totalExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _totalExtentCallback)
      return;
    _totalExtentCallback = value;
    markNeedsLayout();
  }

  /// Returns the minimum cross-axis extent across all the children that could be included by [callback] in one go
  ExtentCallback get minCrossAxisExtentCallback => _minCrossAxisExtentCallback;
  ExtentCallback _minCrossAxisExtentCallback;
  void set minCrossAxisExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _minCrossAxisExtentCallback)
      return;
    _minCrossAxisExtentCallback = value;
    markNeedsLayout();
  }

  /// Returns the maximum cross-axis extent across all the children that could be included by [callback] in one go
  ExtentCallback get maxCrossAxisExtentCallback => _maxCrossAxisExtentCallback;
  ExtentCallback _maxCrossAxisExtentCallback;
  void set maxCrossAxisExtentCallback(ExtentCallback value) {
    assert(!_inCallback);
    if (value == _maxCrossAxisExtentCallback)
      return;
    _maxCrossAxisExtentCallback = value;
    markNeedsLayout();
  }

  Painter get overlayPainter => _overlayPainter;
  Painter _overlayPainter;
  void set overlayPainter(Painter value) {
    if (_overlayPainter == value)
      return;
    _overlayPainter?.detach();
    _overlayPainter = value;
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

  /// The offset at which to paint the first child
  ///
  /// Note: you can modify this property from within [callback], if necessary.
  double get startOffset => _startOffset;
  double _startOffset;
  void set startOffset(double value) {
    if (value != _startOffset) {
      _startOffset = value;
      markNeedsPaint();
    }
  }

  double _getIntrinsicDimension(BoxConstraints constraints, ExtentCallback intrinsicCallback, _Constrainer constrainer) {
    assert(!_inCallback);
    double result;
    if (intrinsicCallback == null) {
      assert(() {
        'RenderBlockViewport does not support returning intrinsic dimensions if the relevant callbacks have not been specified.';
        return false;
      });
      return constrainer(0.0);
    }
    try {
      _inCallback = true;
      result = intrinsicCallback(constraints);
      if (result == null)
        result = constrainer(0.0);
      else
        result = constrainer(result);
    } finally {
      _inCallback = false;
    }
    return result;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (isVertical)
      return _getIntrinsicDimension(constraints, minCrossAxisExtentCallback, constraints.constrainWidth);
    return constraints.constrainWidth(minExtent);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (isVertical)
      return _getIntrinsicDimension(constraints, maxCrossAxisExtentCallback, constraints.constrainWidth);
    return _getIntrinsicDimension(constraints, totalExtentCallback, new BoxConstraints(minWidth: minExtent).enforce(constraints).constrainWidth);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (!isVertical)
      return _getIntrinsicDimension(constraints, minCrossAxisExtentCallback, constraints.constrainHeight);
    return constraints.constrainHeight(0.0);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (!isVertical)
      return _getIntrinsicDimension(constraints, maxCrossAxisExtentCallback, constraints.constrainHeight);
    return _getIntrinsicDimension(constraints, totalExtentCallback, new BoxConstraints(minHeight: minExtent).enforce(constraints).constrainHeight);
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behaviour (returning null). Otherwise, as you
  // scroll the RenderBlockViewport, it would shift in its parent if
  // the parent was baseline-aligned, which makes no sense.

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

  void _paintContents(PaintingContext context, Offset offset) {
    if (isVertical)
      defaultPaint(context, offset.translate(0.0, startOffset));
    else
      defaultPaint(context, offset.translate(startOffset, 0.0));

    overlayPainter?.paint(context, offset);
  }

  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
    if (isVertical)
      transform.translate(0.0, startOffset);
    else
      transform.translate(startOffset, 0.0);
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (isVertical)
      return defaultHitTestChildren(result, position: position + new Offset(0.0, -startOffset));
    else
      return defaultHitTestChildren(result, position: position + new Offset(-startOffset, 0.0));
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('startOffset: $startOffset');
  }
}
