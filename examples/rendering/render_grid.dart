// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'lib/solid_color_box.dart';

Color randomColor() {
  final List<Color> allColors = [
    Colors.blue,
    Colors.indigo
  ].map((p) => p.values).fold([], (a, b) => a..addAll(b));
  final random = new math.Random();
  return allColors[random.nextInt(allColors.length)];
}

RenderBox buildGridExample() {
  List<RenderBox> children = new List<RenderBox>.generate(30, (_) => new RenderSolidColorBox(randomColor()));
  return new RenderGrid(children: children, maxChildExtent: 100.0);
}

main() => new RenderingFlutterBinding(root: buildGridExample());
