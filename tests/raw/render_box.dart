// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import 'dart:sky' as sky;
import 'package:sky/framework/layout2.dart';

class RenderSizedBox extends RenderBox {
  final double desiredHeight;
  final double desiredWidth;

  RenderSizedBox({ this.desiredHeight: double.INFINITY,
                   this.desiredWidth: double.INFINITY });

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             height: desiredHeight,
                                             width: desiredWidth);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    width = constraints.constrainWidth(desiredWidth);
    height = constraints.constrainHeight(desiredHeight);
    layoutDone();
  }
}

void main() {
  initUnit();

  test("should size to render view", () {
    RenderSizedBox root = new RenderSizedBox();
    RenderView renderView = new RenderView(child: root);
    renderView.layout(newWidth: sky.view.width, newHeight: sky.view.height);
    expect(root.width, equals(sky.view.width));
    expect(root.height, equals(sky.view.height));
  });
}
