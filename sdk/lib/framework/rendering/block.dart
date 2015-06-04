// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'box.dart';
import 'object.dart';

class BlockParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> { }

class RenderBlock extends RenderBox with ContainerRenderObjectMixin<RenderBox, BlockParentData>,
                                         RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {
  // lays out RenderBox children in a vertical stack
  // uses the maximum width provided by the parent
  // sizes itself to the height of its child stack

  RenderBlock({
    List<RenderBox> children
  }) {
    if (children != null)
      children.forEach((child) { add(child); });
  }

  void setParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  // override this to report what dimensions you would have if you
  // were laid out with the given constraints this can walk the tree
  // if it must, but it should be as cheap as possible; just get the
  // dimensions and nothing else (e.g. don't calculate hypothetical
  // child positions if they're not needed to determine dimensions)
  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    double height = 0.0;
    double width = constraints.constrainWidth(constraints.maxWidth);
    assert(width < double.INFINITY);
    RenderBox child = firstChild;
    BoxConstraints innerConstraints = new BoxConstraints(minWidth: width,
                                                         maxWidth: width);
    while (child != null) {
      height += child.getIntrinsicDimensions(innerConstraints).height;
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }

    return new sky.Size(width, constraints.constrainHeight(height));
  }

  void performLayout() {
    assert(constraints is BoxConstraints);
    double width = constraints.constrainWidth(constraints.maxWidth);
    double y = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(new BoxConstraints(minWidth: width, maxWidth: width), parentUsesSize: true);
      assert(child.parentData is BlockParentData);
      child.parentData.position = new sky.Point(0.0, y);
      y += child.size.height;
      child = child.parentData.nextSibling;
    }
    size = new sky.Size(width, constraints.constrainHeight(y));
    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderObjectDisplayList canvas) {
    defaultPaint(canvas);
  }

}

