// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

class _MultiChildParentData extends ContainerBoxParentDataMixin<RenderBox> { }

abstract class MultiChildLayoutDelegate {
  final List<RenderBox> _indexToChild = <RenderBox>[];

  /// Returns the size of this object given the incomming constraints.
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  /// Ask the child to update its layout within the limits specified by
  /// the constraints parameter. The child's size is returned.
  Size layoutChild(int childIndex, BoxConstraints constraints) {
    final RenderBox child = _indexToChild[childIndex];
    child.layout(constraints, parentUsesSize: true);
    return child.size;
  }

  /// Specify the child's origin relative to this origin.
  void positionChild(int childIndex, Point position) {
    final RenderBox child = _indexToChild[childIndex];
    final _MultiChildParentData childParentData = child.parentData;
    childParentData.position = position;
  }

  void _callPerformLayout(Size size, BoxConstraints constraints, RenderBox firstChild) {
    RenderBox child = firstChild;
    while (child != null) {
      _indexToChild.add(child);
      final _MultiChildParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    performLayout(size, constraints, _indexToChild.length);
    _indexToChild.clear();
  }

  /// Layout and position all children given this widget's size and the specified
  /// constraints. This method must apply layoutChild() to each child. It should
  /// specify the final position of each child with positionChild().
  void performLayout(Size size, BoxConstraints constraints, int childCount);
}

class RenderCustomMultiChildLayoutBox extends RenderBox
  with ContainerRenderObjectMixin<RenderBox, _MultiChildParentData>,
       RenderBoxContainerDefaultsMixin<RenderBox, _MultiChildParentData> {
  RenderCustomMultiChildLayoutBox({
    List<RenderBox> children,
    MultiChildLayoutDelegate delegate
  }) : _delegate = delegate {
    assert(delegate != null);
    addAll(children);
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! _MultiChildParentData)
      child.parentData = new _MultiChildParentData();
  }

  MultiChildLayoutDelegate get delegate => _delegate;
  MultiChildLayoutDelegate _delegate;
  void set delegate (MultiChildLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    _delegate = newDelegate;
    markNeedsLayout();
  }

  Size _getSize(BoxConstraints constraints) {
    return constraints.constrain(_delegate.getSize(constraints));
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return _getSize(constraints).width;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _getSize(constraints).width;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getSize(constraints).height;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getSize(constraints).height;
  }

  bool get sizedByParent => true;

  void performResize() {
    size = _getSize(constraints);
  }

  void performLayout() {
    delegate._callPerformLayout(size, constraints, firstChild);
  }

  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }
}
