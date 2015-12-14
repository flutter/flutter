// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'lib/solid_color_box.dart';

Duration timeBase;
RenderTransform transformBox;

void main() {
  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);

  void addFlexChildSolidColor(RenderFlex parent, ui.Color backgroundColor, { int flex: 0 }) {
    RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
    parent.add(child);
    final FlexParentData childParentData = child.parentData;
    childParentData.flex = flex;
  }

  addFlexChildSolidColor(flexRoot, const ui.Color(0xFFFF00FF), flex: 1);
  addFlexChildSolidColor(flexRoot, const ui.Color(0xFFFFFF00), flex: 2);
  addFlexChildSolidColor(flexRoot, const ui.Color(0xFF00FFFF), flex: 1);

  transformBox = new RenderTransform(child: flexRoot, transform: new Matrix4.identity());

  RenderPadding root = new RenderPadding(padding: new EdgeDims.all(20.0), child: transformBox);

  new RenderingFlutterBinding(root: root)
    ..addPersistentFrameCallback(rotate);
}

void rotate(Duration timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase).inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND; // radians

  transformBox.setIdentity();
  transformBox.translate(transformBox.size.width / 2.0, transformBox.size.height / 2.0);
  transformBox.rotateZ(delta);
  transformBox.translate(-transformBox.size.width / 2.0, -transformBox.size.height / 2.0);
}
