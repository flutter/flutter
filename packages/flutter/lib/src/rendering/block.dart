// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// Parent data for use with [RenderListBody].
class ListBodyParentData extends ContainerBoxParentData<RenderBox> { }

typedef double _ChildSizingFunction(RenderBox child);

/// Displays its children sequentially along a given axis, forcing them to the
/// dimensions of the parent in the other axis.
///
/// This layout algorithm arranges its children linearly along the main axis
/// (either horizontally or vertically). In the cross axis, children are
/// stretched to match the box's cross-axis extent. In the main axis, children
/// are given unlimited space and the box expands its main axis to contain all
/// its children. Because [RenderListBody] boxes expand in the main axis, they
/// must be given unlimited space in the main axis, typically by being contained
/// in a viewport with a scrolling direction that matches the box's main axis.
class RenderListBody extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ListBodyParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, ListBodyParentData> {
  /// Creates a render object that arranges its children sequentially along a
  /// given axis.
  ///
  /// By default, children are arranged along the vertical axis.
  RenderListBody({
    List<RenderBox> children,
    Axis mainAxis: Axis.vertical,
  }) : _mainAxis = mainAxis {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ListBodyParentData)
      child.parentData = new ListBodyParentData();
  }

  /// The direction to use as the main axis.
  Axis get mainAxis => _mainAxis;
  Axis _mainAxis;
  set mainAxis(Axis value) {
    if (_mainAxis != value) {
      _mainAxis = value;
      markNeedsLayout();
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    assert(_mainAxis != null);
    switch (_mainAxis) {
      case Axis.horizontal:
        return new BoxConstraints.tightFor(height: constraints.maxHeight);
      case Axis.vertical:
        return new BoxConstraints.tightFor(width: constraints.maxWidth);
    }
    return null;
  }

  double get _mainAxisExtent {
    final RenderBox child = lastChild;
    if (child == null)
      return 0.0;
    final BoxParentData parentData = child.parentData;
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return parentData.offset.dx + child.size.width;
      case Axis.vertical:
        return parentData.offset.dy + child.size.height;
    }
    return null;
  }

  @override
  void performLayout() {
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (!constraints.hasBoundedWidth)
            return true;
          break;
        case Axis.vertical:
          if (!constraints.hasBoundedHeight)
            return true;
          break;
      }
      throw new FlutterError(
        'RenderListBody must have unlimited space along its main axis.\n'
        'RenderListBody does not clip or resize its children, so it must be '
        'placed in a parent that does not constrain the main '
        'axis. You probably want to put the RenderListBody inside a '
        'RenderViewport with a matching main axis.'
      );
    });
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (constraints.hasBoundedHeight)
            return true;
          break;
        case Axis.vertical:
          if (constraints.hasBoundedWidth)
            return true;
          break;
      }
      // TODO(ianh): Detect if we're actually nested blocks and say something
      // more specific to the exact situation in that case, and don't mention
      // nesting blocks in the negative case.
      throw new FlutterError(
        'RenderListBody must have a bounded constraint for its cross axis.\n'
        'RenderListBody forces its children to expand to fit the RenderListBody\'s container, '
        'so it must be placed in a parent that constrains the cross '
        'axis to a finite dimension. If you are attempting to nest a RenderListBody with '
        'one direction inside one of another direction, you will want to '
        'wrap the inner one inside a box that fixes the dimension in that direction, '
        'for example, a RenderIntrinsicWidth or RenderIntrinsicHeight object. '
        'This is relatively expensive, however.' // (that's why we don't do it automatically)
      );
    });
    final BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double position = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final ListBodyParentData childParentData = child.parentData;
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

    assert(size.isFinite);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('mainAxis: $mainAxis');
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final ListBodyParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final ListBodyParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis((RenderBox child) => child.getMinIntrinsicWidth(height));
      case Axis.vertical:
        return _getIntrinsicCrossAxis((RenderBox child) => child.getMinIntrinsicWidth(height));
    }
    return null;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis((RenderBox child) => child.getMaxIntrinsicWidth(height));
      case Axis.vertical:
        return _getIntrinsicCrossAxis((RenderBox child) => child.getMaxIntrinsicWidth(height));
    }
    return null;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis((RenderBox child) => child.getMinIntrinsicHeight(width));
      case Axis.vertical:
        return _getIntrinsicCrossAxis((RenderBox child) => child.getMinIntrinsicHeight(width));
    }
    return null;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis((RenderBox child) => child.getMaxIntrinsicHeight(width));
      case Axis.vertical:
        return _getIntrinsicCrossAxis((RenderBox child) => child.getMaxIntrinsicHeight(width));
    }
    return null;
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
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

}
