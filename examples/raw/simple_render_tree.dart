// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:sky';
import 'package:sky/framework/layout2.dart';

class RenderSolidColor extends RenderDecoratedBox {
  RenderSolidColor(int backgroundColor)
      : super(new BoxDecoration(backgroundColor: backgroundColor));

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints, height: 200.0);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    setWidth(constraints, constraints.maxWidth);
    setHeight(constraints, 200.0);
    layoutDone();
  }
}

void main() {
  var root = new RenderBlock(
      decoration: new BoxDecoration(backgroundColor: 0xFF00FFFF));

  root.add(new RenderSolidColor(0xFF00FF00));
  root.add(new RenderSolidColor(0xFF0000FF));

  RenderView renderView = new RenderView(root: root);
  renderView.layout(newWidth: view.width, newHeight: view.height);
  renderView.paintFrame();
}
