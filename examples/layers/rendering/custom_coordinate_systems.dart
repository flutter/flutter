// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to build a render tree with a non-cartesian coordinate
// system. Most of the guts of this examples are in src/sector_layout.dart.

import 'package:flutter/rendering.dart';
import 'src/binding.dart';
import 'src/sector_layout.dart';

RenderBox buildSectorExample() {
  final rootCircle = RenderSectorRing(padding: 20.0);
  rootCircle.add(RenderSolidColor(const Color(0xFF00FFFF), desiredDeltaTheta: kTwoPi * 0.15));
  rootCircle.add(RenderSolidColor(const Color(0xFF0000FF), desiredDeltaTheta: kTwoPi * 0.4));
  final stack = RenderSectorSlice(padding: 2.0);
  stack.add(RenderSolidColor(const Color(0xFFFFFF00), desiredDeltaRadius: 20.0));
  stack.add(RenderSolidColor(const Color(0xFFFF9000), desiredDeltaRadius: 20.0));
  stack.add(RenderSolidColor(const Color(0xFF00FF00)));
  rootCircle.add(stack);
  return RenderBoxToRenderSectorAdapter(innerRadius: 50.0, child: rootCircle);
}

void main() {
  ViewRenderingFlutterBinding(root: buildSectorExample()).scheduleFrame();
}
