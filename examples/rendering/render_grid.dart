// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'solid_color_box.dart';

Color randomColor() {
  final List<Color> allColors = [
    colors.Blue,
    colors.Indigo
  ].map((p) => p.values).fold([], (a, b) => a..addAll(b));
  final random = new math.Random();
  return allColors[random.nextInt(allColors.length)];
}

RenderBox buildGridExample() {
  List<RenderBox> children = new List.generate(30, (_) => new RenderSolidColorBox(randomColor()));
  return new RenderGrid(children: children, maxChildExtent: 100.0);
}

main() => new SkyBinding(root: buildGridExample());
