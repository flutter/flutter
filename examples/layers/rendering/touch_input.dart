// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Material design colors. :p
List<Color> _kColors = <Color>[
  Colors.teal[500],
  Colors.amber[500],
  Colors.purple[500],
  Colors.lightBlue[500],
  Colors.deepPurple[500],
  Colors.lime[500],
];

/// A simple model object for a dot that reacts to pointer pressure.
class Dot {
  Dot({ Color color }) : _paint = new Paint()..color = color;

  final Paint _paint;
  Point position = Point.origin;
  double radius = 0.0;

  void update(PointerEvent event) {
    position = event.position;
    radius = 5 + (95 * event.pressure);
  }

  void paint(Canvas canvas, Offset offset) {
    canvas.drawCircle(position + offset, radius, _paint);
  }
}

/// A render object that draws dots under each pointer.
class RenderDots extends RenderConstrainedBox {
  RenderDots() : super(additionalConstraints: const BoxConstraints.expand());

  /// State to remember which dots to paint.
  final Map<int, Dot> _dots = <int, Dot>{};

  /// Makes this render object hittable so that it receives pointer events.
  bool hitTestSelf(Point position) => true;

  /// Processes pointer events by mutating state and invalidating its previous
  /// painting commands.
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      Color color = _kColors[event.pointer.remainder(_kColors.length)];
      _dots[event.pointer] = new Dot(color: color)..update(event);
      markNeedsPaint();
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _dots.remove(event.pointer);
      markNeedsPaint();
    } else if (event is PointerMoveEvent) {
      _dots[event.pointer].update(event);
      markNeedsPaint();
    }
  }

  /// Issues new painting commands.
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    canvas.drawRect(offset & size, new Paint()..color = const Color(0xFFFFFFFF));
    for (Dot dot in _dots.values)
      dot.paint(canvas, offset);
    super.paint(context, offset);
  }
}

void main() {
  RenderParagraph paragraph = new RenderParagraph(
    new StyledTextSpan(
      new TextStyle(color: Colors.black87),
      [ new PlainTextSpan("Touch me!") ]
    )
  );
  RenderStack stack = new RenderStack(
    children: <RenderBox>[
      new RenderDots(),
      paragraph,
    ]
  );
  // Prevent the RenderParagraph from filling the whole screen so
  // that it doesn't eat events.
  final StackParentData paragraphParentData = paragraph.parentData;
  paragraphParentData
    ..top = 40.0
    ..left = 20.0;
  new RenderingFlutterBinding(root: stack);
}
