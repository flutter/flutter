// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  const Rect region = Rect.fromLTWH(0, 0, 300, 300);

  late BitmapCanvas canvas;

  setUp(() {
    canvas = BitmapCanvas(region, RenderStrategy());
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('draws lines with varying strokeWidth', () async {

    paintLines(canvas);

    domDocument.body!.append(canvas.rootElement);
    await matchGoldenFile('canvas_lines_thickness.png', region: region);
  });
}

void paintLines(BitmapCanvas canvas) {
  final SurfacePaintData nullPaint = SurfacePaintData()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  final SurfacePaintData paint1 = SurfacePaintData()
      ..color = const Color(0xFF9E9E9E) // Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
  final SurfacePaintData paint2 = SurfacePaintData()
      ..color = const Color(0x7fff0000)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
  final SurfacePaintData paint3 = SurfacePaintData()
      ..color = const Color(0xFF4CAF50) //Colors.green
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
  // Draw markers around 100x100 box
  canvas.drawLine(const Offset(50, 40), const Offset(148, 40), nullPaint);
  canvas.drawLine(const Offset(50, 50), const Offset(52, 50), paint1);
  canvas.drawLine(const Offset(150, 50), const Offset(148, 50), paint1);
  canvas.drawLine(const Offset(50, 150), const Offset(52, 150), paint1);
  canvas.drawLine(const Offset(150, 150), const Offset(148, 150), paint1);
  // Draw diagonal
  canvas.drawLine(const Offset(50, 50), const Offset(150, 150), paint2);
  // Draw horizontal
  paint3.strokeWidth = 1.0;
  paint3.color = const Color(0xFFFF0000);
  canvas.drawLine(const Offset(50, 55), const Offset(150, 55), paint3);
  paint3.strokeWidth = 2.0;
  paint3.color = const Color(0xFF2196F3); // Colors.blue;
  canvas.drawLine(const Offset(50, 60), const Offset(150, 60), paint3);
  paint3.strokeWidth = 4.0;
  paint3.color = const Color(0xFFFF9800); // Colors.orange;
  canvas.drawLine(const Offset(50, 70), const Offset(150, 70), paint3);
}
