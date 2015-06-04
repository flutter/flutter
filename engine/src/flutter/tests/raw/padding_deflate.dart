// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import '../resources/display_list.dart';
import 'package:sky/framework/rendering/box.dart';

void main() {
  initUnit();

  test("should not have a 0 sized colored Box", () {
    var coloredBox = new RenderDecoratedBox(
      decoration: new BoxDecoration()
    );
    var paddingBox = new RenderPadding(padding: const EdgeDims.all(10.0),
        child: coloredBox);
    RenderBox root = new RenderDecoratedBox(
      decoration: new BoxDecoration(),
      child: paddingBox
    );
    TestView renderView = new TestView(child: root);
    renderView.layout(new ViewConstraints(width: sky.view.width, height: sky.view.height));
    expect(coloredBox.size.width, equals(sky.view.width - 20));
    expect(coloredBox.size.height, equals(sky.view.height - 20));
  });
}
