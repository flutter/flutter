// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/theme/shadows.dart';

void main() {
  initUnit();

  test("should size to render view", () {
    RenderBox root = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const sky.Color(0xFF00FF00),
        gradient: new RadialGradient(
          center: Point.origin, radius: 500.0,
          colors: [Yellow[500], Blue[500]]),
        boxShadow: shadows[3])
    );
    new TestRenderView(root);
    expect(root.size.width, equals(sky.view.width));
    expect(root.size.height, equals(sky.view.height));
  });
}
