// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

export 'package:flutter/src/painting/box_painter.dart';

/// A render object that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// A render overflow box proxies most functions in the render box protocol to
/// its child, except that when laying out its child, it passes constraints
/// based on the minWidth, maxWidth, minHeight, and maxHeight fields instead of
/// just passing the parent's constraints in. Specifically, it overrides any of
/// the equivalent fields on the constraints given by the parent with the
/// constraints given by these fields for each such field that is not null. It
/// then sizes itself based on the parent's constraints' maxWidth and maxHeight,
/// ignoring the child's dimensions.
///
/// For example, if you wanted a box to always render 50 pixels high, regardless
/// of where it was rendered, you would wrap it in a RenderOverflow with
/// minHeight and maxHeight set to 50.0. Generally speaking, to avoid confusing
/// behaviour around hit testing, a RenderOverflowBox should usually be wrapped
/// in a RenderClipRect.
///
/// The child is positioned at the top left of the box. To position a smaller
/// child inside a larger parent, use [RenderPositionedBox] and
/// [RenderConstrainedBox] rather than RenderOverflowBox.
class RenderOverflowBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderOverflowBox({
    RenderBox child,
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight
  }) : _minWidth = minWidth, _maxWidth = maxWidth, _minHeight = minHeight, _maxHeight = maxHeight {
    this.child = child;
  }

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get minWidth => _minWidth;
  double _minWidth;
  void set minWidth (double value) {
    if (_minWidth == value)
      return;
    _minWidth = value;
    markNeedsLayout();
  }

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get maxWidth => _maxWidth;
  double _maxWidth;
  void set maxWidth (double value) {
    if (_maxWidth == value)
      return;
    _maxWidth = value;
    markNeedsLayout();
  }

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get minHeight => _minHeight;
  double _minHeight;
  void set minHeight (double value) {
    if (_minHeight == value)
      return;
    _minHeight = value;
    markNeedsLayout();
  }

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  double get maxHeight => _maxHeight;
  double _maxHeight;
  void set maxHeight (double value) {
    if (_maxHeight == value)
      return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: _minWidth ?? constraints.minWidth,
      maxWidth: _maxWidth ?? constraints.maxWidth,
      minHeight: _minHeight ?? constraints.minHeight,
      maxHeight: _maxHeight ?? constraints.maxHeight
    );
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth();
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth();
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight();
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight();
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.biggest;
  }

  void performLayout() {
    if (child != null)
      child.layout(_getInnerConstraints(constraints));
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('minWidth: ${minWidth ?? "use parent minWidth constraint"}');
    settings.add('maxWidth: ${maxWidth ?? "use parent maxWidth constraint"}');
    settings.add('minHeight: ${minHeight ?? "use parent minHeight constraint"}');
    settings.add('maxHeight: ${maxHeight ?? "use parent maxHeight constraint"}');
  }
}

/// A render box that's a specific size but passes its original constraints through to its child, which will probably overflow
class RenderSizedOverflowBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderSizedOverflowBox({
    RenderBox child,
    Size requestedSize
  }) : _requestedSize = requestedSize {
    assert(requestedSize != null);
    this.child = child;
  }

  /// The size this render box should attempt to be.
  Size get requestedSize => _requestedSize;
  Size _requestedSize;
  void set requestedSize (Size value) {
    assert(value != null);
    if (_requestedSize == value)
      return;
    _requestedSize = value;
    markNeedsLayout();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_requestedSize.width);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_requestedSize.width);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainWidth(_requestedSize.height);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainWidth(_requestedSize.height);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    size = constraints.constrain(_requestedSize);
    if (child != null)
      child.layout(constraints);
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class RenderOffStage extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderOffStage({ RenderBox child }) {
    this.child = child;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;
  double getMaxIntrinsicWidth(BoxConstraints constraints) => constraints.minWidth;
  double getMinIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;
  double getMaxIntrinsicHeight(BoxConstraints constraints) => constraints.minHeight;

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.smallest;
  }

  void performLayout() {
    if (child != null)
      child.layout(constraints);
  }

  bool hitTest(HitTestResult result, { Point position }) => false;
  void paint(PaintingContext context, Offset offset) { }
}
