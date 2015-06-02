// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/node.dart';

// Material design colors. :p
List<int> colors = [
  0xFF009688,
  0xFFFFC107,
  0xFF9C27B0,
  0xFF03A9F4,
  0xFF673AB7,
  0xFFCDDC39,
];

class Dot {
  final Paint _paint;
  double x = 0.0;
  double y = 0.0;
  double radius = 0.0;

  Dot({int color}) : _paint = new Paint()..color = color;

  void update(PointerEvent event) {
    x = event.x;
    y = event.y;
    radius = 5 + (95 * event.pressure);
  }

  void paint(RenderNodeDisplayList canvas) {
    canvas.drawCircle(x, y, radius, _paint);
  }
}

class RenderTouchDemo extends RenderBox {
  Map<int, Dot> dots = new Map();

  RenderTouchDemo();

  void handlePointer(PointerEvent event) {
    switch (event.type) {
      case 'pointerdown':
        int color = colors[event.pointer.remainder(colors.length)];
        dots[event.pointer] = new Dot(color: color)..update(event);
        break;
      case 'pointerup':
        dots.remove(event.pointer);
        break;
      case 'pointercancel':
        dots = new Map();
        break;
      case 'pointermove':
        dots[event.pointer].update(event);
        break;
    }
    markNeedsPaint();
  }

  void performLayout() {
    size = constraints.constrain(new Size.infinite());
  }

  void paint(RenderNodeDisplayList canvas) {
    dots.forEach((_, Dot dot) {
      dot.paint(canvas);
    });
  }
}

AppView app;

void main() {
  app = new AppView(new RenderTouchDemo());
}
