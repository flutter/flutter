// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  final Rect region = Rect.fromLTWH(0, 0, 400, 600);

  BitmapCanvas canvas;

  setUp(() {
    canvas = BitmapCanvas(region);
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('draws points in all 3 modes', () async {
    final SurfacePaintData paint = SurfacePaintData();
    paint.strokeWidth = 2.0;
    paint.color = Color(0xFF0000FF);
    final Float32List points = offsetListToFloat32List(<Offset>[
      Offset(10, 10),
      Offset(50, 10),
      Offset(70, 70),
      Offset(170, 70)
    ]);
    canvas.drawPoints(PointMode.points, points, paint);
    final Float32List points2 = offsetListToFloat32List(<Offset>[
      Offset(10, 110),
      Offset(50, 110),
      Offset(70, 170),
      Offset(170, 170)
    ]);
    canvas.drawPoints(PointMode.lines, points2, paint);
    final Float32List points3 = offsetListToFloat32List(<Offset>[
      Offset(10, 210),
      Offset(50, 210),
      Offset(70, 270),
      Offset(170, 270)
    ]);
    canvas.drawPoints(PointMode.polygon, points3, paint);

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_draw_points.png', region: region);
  });
}
