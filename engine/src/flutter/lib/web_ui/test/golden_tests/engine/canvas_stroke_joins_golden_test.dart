// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  final Rect region = Rect.fromLTWH(0, 0, 300, 300);

  BitmapCanvas canvas;

  setUp(() {
    canvas = BitmapCanvas(region);
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('draws stroke joins', () async {

    paintStrokeJoins(canvas);

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_stroke_joins.png', region: region);
  });

}

void paintStrokeJoins(BitmapCanvas canvas) {
  canvas.drawRect(Rect.fromLTRB(0, 0, 300, 300),
      SurfacePaintData()
        ..color = Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill); // white

  Offset start = Offset(20, 10);
  Offset mid = Offset(120, 10);
  Offset end = Offset(120, 20);

  var strokeCaps = [StrokeCap.butt, StrokeCap.round, StrokeCap.square];
  for (StrokeCap cap in strokeCaps) {
    var joints = [StrokeJoin.miter, StrokeJoin.bevel, StrokeJoin.round];
    var colors = [Color(0xFFF44336), Color(0xFF4CAF50), Color(0xFF2196F3)]; // red, green, blue
    for (int i = 0; i < joints.length; i++) {
      var join = joints[i];
      var color = colors[i % colors.length];

      Path path = new Path();
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, SurfacePaintData()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = color
            ..strokeJoin = join
            ..strokeCap = cap);

      start = start.translate(0, 20);
      mid = mid.translate(0, 20);
      end = end.translate(0, 20);
    }
  }
}