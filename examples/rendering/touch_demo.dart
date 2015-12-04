// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

// Material design colors. :p
List<Color> kColors = <Color>[
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

  void update(PointerEvent event) {
    position = event.position;
    radius = 5 + (95 * event.pressure);
  }

  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawCircle(position + offset, radius, _paint);
  }
}

class RenderTouchDemo extends RenderBox {
  final Map<int, Dot> dots = <int, Dot>{};

  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      Color color = kColors[event.pointer.remainder(kColors.length)];
      dots[event.pointer] = new Dot(color: color)..update(event);
    } else if (event is PointerUpEvent) {
      dots.remove(event.pointer);
    } else if (event is PointerCancelEvent) {
      dots.clear();
    } else if (event is PointerMoveEvent) {
      dots[event.pointer].update(event);
    } else {
      return;
    }
    markNeedsPaint();
  }

  void performLayout() {
    size = constraints.biggest;
  }

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    Paint white = new Paint()
        ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(offset & size, white);
    for (Dot dot in dots.values)
      dot.paint(context, offset);
  }
}

void main() {
  RenderParagraph paragraph = new RenderParagraph(new PlainTextSpan("Touch me!"));
  RenderStack stack = new RenderStack(children: <RenderBox>[
    new RenderTouchDemo(),
    paragraph,
  ]);
  // Prevent the RenderParagraph from filling the whole screen so
  // that it doesn't eat events.
  final StackParentData paragraphParentData = paragraph.parentData;
  paragraphParentData..top = 40.0
                     ..left = 20.0;
  new FlutterBinding(root: stack);
}
