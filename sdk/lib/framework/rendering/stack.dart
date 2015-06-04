// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'box.dart';
import 'object.dart';

class StackParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> { }

class RenderStack extends RenderBox with ContainerRenderObjectMixin<RenderBox, StackParentData>,
                                         RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStack({
    List<RenderBox> children
  }) {
    if (children != null)
      children.forEach((child) { add(child); });
  }

  void setParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = new StackParentData();
  }

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    return constraints.constrain(new sky.Size.infinite());
  }

  void performLayout() {
    size = constraints.constrain(new sky.Size.infinite());
    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
    BoxConstraints innerConstraints = new BoxConstraints.loose(size);

    sky.Point origin = new sky.Point(0.0, 0.0);
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(innerConstraints);
      assert(child.parentData is StackParentData);
      child.parentData.position = origin;
      child = child.parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderObjectDisplayList canvas) {
    defaultPaint(canvas);
  }
}
