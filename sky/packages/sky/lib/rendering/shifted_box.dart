// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/box_painter.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/box.dart';

abstract class RenderShiftedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {

  // Abstract class for one-child-layout render boxes

  RenderShiftedBox(RenderBox child) {
    this.child = child;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicWidth(constraints);
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints);
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMinIntrinsicHeight(constraints);
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints);
    return super.getMaxIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    double result;
    if (child != null) {
      assert(!needsLayout);
      result = child.getDistanceToActualBaseline(baseline);
      assert(child.parentData is BoxParentData);
      if (result != null)
        result += child.parentData.position.y;
    } else {
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, child.parentData.position + offset);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      child.hitTest(result, position: new Point(position.x - child.parentData.position.x,
                                                position.y - child.parentData.position.y));
    }
  }

}

class RenderPadding extends RenderShiftedBox {

  RenderPadding({ EdgeDims padding, RenderBox child }) : super(child) {
    assert(padding != null);
    this.padding = padding;
  }

  EdgeDims _padding;
  EdgeDims get padding => _padding;
  void set padding (EdgeDims value) {
    assert(value != null);
    if (_padding == value)
      return;
    _padding = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMinIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    double totalPadding = padding.left + padding.right;
    if (child != null)
      return child.getMaxIntrinsicWidth(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainWidth(totalPadding);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMinIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    double totalPadding = padding.top + padding.bottom;
    if (child != null)
      return child.getMaxIntrinsicHeight(constraints.deflate(padding)) + totalPadding;
    return constraints.constrainHeight(totalPadding);
  }

  void performLayout() {
    assert(padding != null);
    if (child == null) {
      size = constraints.constrain(new Size(
        padding.left + padding.right,
        padding.top + padding.bottom
      ));
      return;
    }
    BoxConstraints innerConstraints = constraints.deflate(padding);
    child.layout(innerConstraints, parentUsesSize: true);
    assert(child.parentData is BoxParentData);
    child.parentData.position = new Point(padding.left, padding.top);
    size = constraints.constrain(new Size(
      padding.left + child.size.width + padding.right,
      padding.top + child.size.height + padding.bottom
    ));
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}padding: ${padding}\n';
}

class RenderPositionedBox extends RenderShiftedBox {

  // This box aligns a child box within itself. It's only useful for
  // children that don't always size to fit their parent. For example,
  // to align a box at the bottom right, you would pass this box a
  // tight constraint that is bigger than the child's natural size,
  // with horizontal and vertical set to 1.0.

  RenderPositionedBox({
    RenderBox child,
    double horizontal: 0.5,
    double vertical: 0.5
  }) : _horizontal = horizontal,
       _vertical = vertical,
       super(child) {
    assert(horizontal != null);
    assert(vertical != null);
  }

  double _horizontal;
  double get horizontal => _horizontal;
  void set horizontal (double value) {
    assert(value != null);
    if (_horizontal == value)
      return;
    _horizontal = value;
    markNeedsLayout();
  }

  double _vertical;
  double get vertical => _vertical;
  void set vertical (double value) {
    assert(value != null);
    if (_vertical == value)
      return;
    _vertical = value;
    markNeedsLayout();
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      assert(child.parentData is BoxParentData);
      Offset delta = size - child.size;
      child.parentData.position = (delta.scale(horizontal, vertical)).toPoint();
    } else {
      performResize();
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}horizontal: ${horizontal}\n${prefix}vertical: ${vertical}\n';
}

class RenderBaseline extends RenderShiftedBox {

  RenderBaseline({
    RenderBox child,
    double baseline,
    TextBaseline baselineType
  }) : _baseline = baseline,
       _baselineType = baselineType,
       super(child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

  double _baseline;
  double get baseline => _baseline;
  void set baseline (double value) {
    assert(value != null);
    if (_baseline == value)
      return;
    _baseline = value;
    markNeedsLayout();
  }

  TextBaseline _baselineType;
  TextBaseline get baselineType => _baselineType;
  void set baselineType (TextBaseline value) {
    assert(value != null);
    if (_baselineType == value)
      return;
    _baselineType = value;
    markNeedsLayout();
  }

  void performLayout() {
    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(child.size);
      assert(child.parentData is BoxParentData);
      double delta = baseline - child.getDistanceToBaseline(baselineType);
      child.parentData.position = new Point(0.0, delta);
    } else {
      performResize();
    }
  }

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}baseline: ${baseline}\nbaselineType: ${baselineType}';
}
