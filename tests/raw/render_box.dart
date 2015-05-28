// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import 'dart:sky' as sky;
import 'package:sky/framework/layout2.dart';

class RenderSizedBox extends RenderBox {
  final sky.Size desiredSize;

  RenderSizedBox({ this.desiredSize });

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             width: desiredSize.width,
                                             height: desiredSize.height);
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
  }
}

void main() {
  initUnit();

  test("should size to render view", () {
    RenderSizedBox root = new RenderSizedBox(desiredSize: new sky.Size.infinite());
    RenderView renderView = new RenderView(child: root);
    renderView.layout(new ViewConstraints(width: sky.view.width, height: sky.view.height));
    expect(root.size.width, equals(sky.view.width));
    expect(root.size.height, equals(sky.view.height));
  });
}
