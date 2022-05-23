// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  const Rect region = Rect.fromLTWH(0, 0, 400, 600);

  late BitmapCanvas canvas;

  setUp(() {
    canvas = BitmapCanvas(region, RenderStrategy());
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('draws points in all 3 modes', () async {
    final SurfacePaintData paint = SurfacePaintData();
    paint.strokeWidth = 2.0;
    paint.color = const Color(0xFF0000FF);
    final Float32List points = offsetListToFloat32List(const <Offset>[
      Offset(10, 10),
      Offset(50, 10),
      Offset(70, 70),
      Offset(170, 70)
    ]);
    canvas.drawPoints(PointMode.points, points, paint);
    final Float32List points2 = offsetListToFloat32List(const <Offset>[
      Offset(10, 110),
      Offset(50, 110),
      Offset(70, 170),
      Offset(170, 170)
    ]);
    canvas.drawPoints(PointMode.lines, points2, paint);
    final Float32List points3 = offsetListToFloat32List(const <Offset>[
      Offset(10, 210),
      Offset(50, 210),
      Offset(70, 270),
      Offset(170, 270)
    ]);
    canvas.drawPoints(PointMode.polygon, points3, paint);

    domDocument.body!.append(canvas.rootElement);
    await matchGoldenFile('canvas_draw_points.png', region: region);
  });

  test('Should draw points with strokeWidth', () async {
    final SurfacePaintData nullStrokePaint =
      SurfacePaintData()..color = const Color(0xffff0000);
    canvas.drawPoints(PointMode.lines, Float32List.fromList(<double>[
      30.0, 20.0, 200.0, 20.0]), nullStrokePaint);
    final SurfacePaintData strokePaint1 = SurfacePaintData()
      ..strokeWidth = 1.0
      ..color = const Color(0xff0000ff);
    canvas.drawPoints(PointMode.lines, Float32List.fromList(<double>[
      30.0, 30.0, 200.0, 30.0]), strokePaint1);
    final SurfacePaintData strokePaint3 = SurfacePaintData()
      ..strokeWidth = 3.0
      ..color = const Color(0xff00a000);
    canvas.drawPoints(PointMode.lines, Float32List.fromList(<double>[
      30.0, 40.0, 200.0, 40.0]), strokePaint3);
    canvas.drawPoints(PointMode.points, Float32List.fromList(<double>[
      30.0, 50.0, 40.0, 50.0, 50.0, 50.0]), strokePaint3);
    domDocument.body!.append(canvas.rootElement);
    await matchGoldenFile('canvas_draw_points_stroke.png', region: region);
  });
}
