// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as sky;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Material design colors. :p
List<Color> kColors = [
  Colors.teal[500],
  Colors.amber[500],
  Colors.purple[500],
  Colors.lightBlue[500],
  Colors.deepPurple[500],
  Colors.lime[500],
];

class Dot {
  final Paint _paint;
  Point position = Point.origin;
  double radius = 0.0;

  Dot({ Color color }) : _paint = new Paint()..color = color;

  void update(sky.PointerEvent event) {
    position = new Point(event.x, event.y);
    radius = 5 + (95 * event.pressure);
  }

  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawCircle(position + offset, radius, _paint);
  }
}

class RenderTouchDemo extends RenderBox {
  Map<int, Dot> dots = new Map();

  RenderTouchDemo();

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event is sky.PointerEvent) {
      switch (event.type) {
        case 'pointerdown':
          Color color = kColors[event.pointer.remainder(kColors.length)];
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
  }

  void performLayout() {
    size = constraints.biggest;
  }

  void paint(PaintingContext context, Offset offset) {
    final PaintingCanvas canvas = context.canvas;
    Paint white = new Paint()
        ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(offset & size, white);
    for (Dot dot in dots.values)
      dot.paint(context, offset);
  }
}

void main() {
  var paragraph = new RenderParagraph(new PlainTextSpan("Touch me!"));
  var stack = new RenderStack(children: [
    new RenderTouchDemo(),
    paragraph,
  ]);
  // Prevent the RenderParagraph from filling the whole screen so
  // that it doesn't eat events.
  paragraph.parentData..top = 40.0
                      ..left = 20.0;
  new FlutterBinding(root: stack);
}
