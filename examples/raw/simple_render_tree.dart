// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:sky';
import 'package:sky/framework/layout2.dart';

class RenderBlueCircle extends RenderBox {
  void paint(RenderNodeDisplayList canvas) {
    double radius = min(width, height) * 0.45;
    Paint paint = new Paint()..setARGB(255, 0, 255, 255);
    canvas.drawCircle(width / 2, height / 2, radius, paint);
  }
}

void main() {
  RenderView renderView = new RenderView(root: new RenderBlueCircle());
  renderView.layout(newWidth: view.width, newHeight: view.height);
  renderView.paintFrame();
}
