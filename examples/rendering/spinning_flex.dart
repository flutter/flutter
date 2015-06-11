// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/flex.dart';
import 'package:sky/framework/scheduler.dart';
import '../lib/solid_color_box.dart';

AppView app;
double timeBase;
RenderTransform transformBox;

void main() {
  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);

  void addFlexChildSolidColor(RenderFlex parent, sky.Color backgroundColor, { int flex: 0 }) {
    RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
    parent.add(child);
    child.parentData.flex = flex;
  }

  addFlexChildSolidColor(flexRoot, const sky.Color(0xFFFF00FF), flex: 1);
  addFlexChildSolidColor(flexRoot, const sky.Color(0xFFFFFF00), flex: 2);
  addFlexChildSolidColor(flexRoot, const sky.Color(0xFF00FFFF), flex: 1);

  transformBox = new RenderTransform(child: flexRoot, transform: new Matrix4.identity());

  RenderPadding root = new RenderPadding(padding: new EdgeDims.all(20.0), child: transformBox);

  app = new AppView(root);

  addPersistentFrameCallback(rotate);
}

void rotate(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase) / 1000; // radians

  transformBox.setIdentity();
  transformBox.translate(transformBox.size.width / 2.0, transformBox.size.height / 2.0);
  transformBox.rotateZ(delta);
  transformBox.translate(-transformBox.size.width / 2.0, -transformBox.size.height / 2.0);
}
