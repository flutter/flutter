// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

/// Parent data for use with [RenderList].
class ListParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class RenderList extends RenderVirtualViewport<ListParentData> {
  RenderList({
    List<RenderBox> children,
    double itemExtent,
    int virtualChildCount,
    Offset paintOffset: Offset.zero,
    LayoutCallback callback
  }) : _itemExtent = itemExtent, super(
    virtualChildCount: virtualChildCount,
    paintOffset: paintOffset,
    callback: callback
  ) {
    assert(itemExtent != null);
    addAll(children);
  }

  double get itemExtent => _itemExtent;
  double _itemExtent;
  void set itemExtent (double newValue) {
    assert(newValue != null);
    if (_itemExtent == newValue)
      return;
    _itemExtent = newValue;
    markNeedsLayout();
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! ListParentData)
      child.parentData = new ListParentData();
  }

  double get _preferredMainAxisExtent => itemExtent * virtualChildCount;

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainHeight(_preferredMainAxisExtent);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainHeight(_preferredMainAxisExtent);
  }

  void performLayout() {
    double height = _preferredMainAxisExtent;
    size = new Size(constraints.maxWidth, constraints.constrainHeight(height));

    if (callback != null)
      invokeLayoutCallback(callback);

    BoxConstraints innerConstraints =
        new BoxConstraints.tightFor(width: size.width, height: itemExtent);

    int childIndex = 0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints);
      final ListParentData childParentData = child.parentData;
      childParentData.offset = new Offset(0.0, childIndex * itemExtent);
      childIndex += 1;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }
}
