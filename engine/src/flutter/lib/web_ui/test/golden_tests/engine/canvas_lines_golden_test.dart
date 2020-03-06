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

  test('draws lines with varying strokeWidth', () async {

    paintLines(canvas);

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_lines_thickness.png', region: region);
  });
}

void paintLines(BitmapCanvas canvas) {
    final SurfacePaintData paint1 = SurfacePaintData()
      ..color = Color(0xFF9E9E9E) // Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final SurfacePaintData paint2 = SurfacePaintData()
      ..color = Color(0x7fff0000)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final SurfacePaintData paint3 = SurfacePaintData()
      ..color = Color(0xFF4CAF50) //Colors.green
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    // Draw markers around 100x100 box
    canvas.drawLine(Offset(50, 50), Offset(52, 50), paint1);
    canvas.drawLine(Offset(150, 50), Offset(148, 50), paint1);
    canvas.drawLine(Offset(50, 150), Offset(52, 150), paint1);
    canvas.drawLine(Offset(150, 150), Offset(148, 150), paint1);
    // Draw diagonal
    canvas.drawLine(Offset(50, 50), Offset(150, 150), paint2);
    // Draw horizontal
    paint3.strokeWidth = 1.0;
    paint3.color = Color(0xFFFF0000);
    canvas.drawLine(Offset(50, 55), Offset(150, 55), paint3);
    paint3.strokeWidth = 2.0;
    paint3.color = Color(0xFF2196F3); // Colors.blue;
    canvas.drawLine(Offset(50, 60), Offset(150, 60), paint3);
    paint3.strokeWidth = 4.0;
    paint3.color = Color(0xFFFF9800); // Colors.orange;
    canvas.drawLine(Offset(50, 70), Offset(150, 70), paint3);
}
