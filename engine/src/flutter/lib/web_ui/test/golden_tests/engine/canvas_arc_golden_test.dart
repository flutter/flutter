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
  final Rect region = Rect.fromLTWH(0, 0, 400, 600);

  BitmapCanvas canvas;

  setUp(() {
    canvas = BitmapCanvas(region);
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('draws arcs with largeArc , anticlockwise variations', () async {
    paintArc(canvas, Offset(0, 0),
        largeArc: false, clockwise: false, distance: 20);
    paintArc(canvas, Offset(200, 0),
        largeArc: true, clockwise: false, distance: 20);
    paintArc(canvas, Offset(0, 150),
        largeArc: false, clockwise: true, distance: 20);
    paintArc(canvas, Offset(200, 150),
        largeArc: true, clockwise: true, distance: 20);
    paintArc(canvas, Offset(0, 300),
        largeArc: false, clockwise: false, distance: -20);
    paintArc(canvas, Offset(200, 300),
        largeArc: true, clockwise: false, distance: -20);
    paintArc(canvas, Offset(0, 400),
        largeArc: false, clockwise: true, distance: -20);
    paintArc(canvas, Offset(200, 400),
        largeArc: true, clockwise: true, distance: -20);


    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_arc_to_point.png', region: region);
  });

}

void paintArc(BitmapCanvas canvas, Offset offset,
      {bool largeArc = false, bool clockwise = false, double distance = 0}) {

  final Offset startP =
      Offset(75 - distance + offset.dx, 75 - distance + offset.dy);
  final Offset endP =
      Offset(75.0 + distance + offset.dx, 75.0 + distance + offset.dy);
  canvas.drawRect(
      Rect.fromLTRB(startP.dx, startP.dy, endP.dx, endP.dy),
      SurfacePaintData()
        ..strokeWidth = 1
        ..color = Color(0xFFFF9800) // orange
        ..style = PaintingStyle.stroke);
  final Path path = Path();
  path.moveTo(startP.dx, startP.dy);
  path.arcToPoint(endP,
      rotation: 45,
      radius: const Radius.elliptical(40, 60),
      largeArc: largeArc,
      clockwise: clockwise);
  canvas.drawPath(
      path,
      SurfacePaintData()
        ..strokeWidth = 2
        ..color = Color(0x61000000) // black38
        ..style = PaintingStyle.stroke);
}