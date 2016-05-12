// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

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
class RenderBlock extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {

  RenderBlock({
    List<RenderBox> children,
    Axis mainAxis: Axis.vertical
  }) : _mainAxis = mainAxis {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  /// The direction to use as the main axis.
  Axis get mainAxis => _mainAxis;
  Axis _mainAxis;
  set mainAxis (Axis value) {
    if (_mainAxis != value) {
      _mainAxis = value;
      markNeedsLayout();
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (_mainAxis) {
      case Axis.horizontal:
        return new BoxConstraints.tightFor(height: constraints.maxHeight);
      case Axis.vertical:
        return new BoxConstraints.tightFor(width: constraints.maxWidth);
    }
  }

  double get _mainAxisExtent {
    RenderBox child = lastChild;
    if (child == null)
      return 0.0;
    BoxParentData parentData = child.parentData;
    switch (mainAxis) {
      case Axis.horizontal:
        return parentData.offset.dx + child.size.width;
      case Axis.vertical:
        return parentData.offset.dy + child.size.height;
    }
  }

  @override
  void performLayout() {
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (constraints.maxWidth.isInfinite)
            return true;
          break;
        case Axis.vertical:
          if (constraints.maxHeight.isInfinite)
            return true;
          break;
      }
      throw new FlutterError(
        'RenderBlock must have unlimited space along its main axis.\n'
        'RenderBlock does not clip or resize its children, so it must be '
        'placed in a parent that does not constrain the block\'s main '
        'axis. You probably want to put the RenderBlock inside a '
        'RenderViewport with a matching main axis.'
      );
      return false;
    });
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (!constraints.maxHeight.isInfinite)
            return true;
          break;
        case Axis.vertical:
          if (!constraints.maxWidth.isInfinite)
            return true;
          break;
      }
      // TODO(ianh): Detect if we're actually nested blocks and say something
      // more specific to the exact situation in that case, and don't mention
      // nesting blocks in the negative case.
      throw new FlutterError(
        'RenderBlock must have a bounded constraint for its cross axis.\n'
        'RenderBlock forces its children to expand to fit the block\'s container, '
        'so it must be placed in a parent that does constrain the block\'s cross '
        'axis to a finite dimension. If you are attempting to nest a block with '
        'one direction inside a block of another direction, you will want to '
        'wrap the inner one inside a box that fixes the dimension in that direction, '
        'for example, a RenderIntrinsicWidth or RenderIntrinsicHeight object. '
        'This is relatively expensive, however.' // (that's why we don't do it automatically)
      );
      return false;
    });
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double position = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final BlockParentData childParentData = child.parentData;
      switch (mainAxis) {
        case Axis.horizontal:
          childParentData.offset = new Offset(position, 0.0);
          position += child.size.width;
          break;
        case Axis.vertical:
          childParentData.offset = new Offset(0.0, position);
          position += child.size.height;
          break;
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    switch (mainAxis) {
      case Axis.horizontal:
        size = constraints.constrain(new Size(_mainAxisExtent, constraints.maxHeight));
        break;
      case Axis.vertical:
        size = constraints.constrain(new Size(constraints.maxWidth, _mainAxisExtent));
        break;
    }

    assert(!size.isInfinite);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('mainAxis: $mainAxis');
  }

  double _getIntrinsicCrossAxis(BoxConstraints constraints, _ChildSizingFunction childSize, _Constrainer constrainer) {
    double extent = 0.0;
    BoxConstraints innerConstraints;
    switch (mainAxis) {
      case Axis.horizontal:
        innerConstraints = constraints.heightConstraints();
        break;
      case Axis.vertical:
        innerConstraints = constraints.widthConstraints();
        break;
    }
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
      switch (mainAxis) {
        case Axis.horizontal:
          extent += child.getMaxIntrinsicWidth(innerConstraints);
          break;
        case Axis.vertical:
          extent += child.getMinIntrinsicHeight(innerConstraints);
          break;
      }
      final BlockParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return constrainer(extent);
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(constraints, constraints.constrainWidth);
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
          constraints,
          (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints),
          constraints.constrainWidth
        );
    }
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(constraints, constraints.constrainWidth);
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
          constraints,
          (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints),
          constraints.constrainWidth
        );
    }
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicCrossAxis(
          constraints,
          (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicHeight(innerConstraints),
          constraints.constrainHeight
        );
      case Axis.vertical:
        return _getIntrinsicMainAxis(constraints, constraints.constrainHeight);
    }
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicCrossAxis(
          constraints,
          (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicHeight(innerConstraints),
          constraints.constrainHeight
        );
      case Axis.vertical:
        return _getIntrinsicMainAxis(constraints, constraints.constrainHeight);
    }
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
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
