// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/object.dart';

import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  test("should size to render view", () {
    RenderSizedBox root = new RenderSizedBox(
      child: new RenderDecoratedBox(
        decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00))
      )
    );
    new TestRenderView(root);
    expect(root.size.width, equals(sky.view.width));
    expect(root.size.height, equals(sky.view.height));
  });
}
