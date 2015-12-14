// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'lib/sector_layout.dart';

RenderBox buildSectorExample() {
  RenderSectorRing rootCircle = new RenderSectorRing(padding: 20.0);
  rootCircle.add(new RenderSolidColor(const Color(0xFF00FFFF), desiredDeltaTheta: kTwoPi * 0.15));
  rootCircle.add(new RenderSolidColor(const Color(0xFF0000FF), desiredDeltaTheta: kTwoPi * 0.4));
  RenderSectorSlice stack = new RenderSectorSlice(padding: 2.0);
  stack.add(new RenderSolidColor(const Color(0xFFFFFF00), desiredDeltaRadius: 20.0));
  stack.add(new RenderSolidColor(const Color(0xFFFF9000), desiredDeltaRadius: 20.0));
  stack.add(new RenderSolidColor(const Color(0xFF00FF00)));
  rootCircle.add(stack);
  return new RenderBoxToRenderSectorAdapter(innerRadius: 50.0, child: rootCircle);
}

void main() {
  new RenderingFlutterBinding(root: buildSectorExample());
}
