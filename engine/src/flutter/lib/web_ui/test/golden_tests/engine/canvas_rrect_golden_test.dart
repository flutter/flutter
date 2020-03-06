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
  final Rect region = Rect.fromLTWH(8, 8, 500, 100); // Compensate for old scuba tester padding

  BitmapCanvas canvas;

  final SurfacePaintData niceRRectPaint = SurfacePaintData()
    ..color = const Color.fromRGBO(250, 186, 218, 1.0) // #fabada
    ..style = PaintingStyle.fill;

  // Some values to see how the algo behaves as radius get absurdly large
  const List<double> rRectRadii = <double>[0, 10, 20, 80, 8000];

  const Radius someFixedRadius = Radius.circular(10);

  setUp(() {
    canvas = BitmapCanvas(const Rect.fromLTWH(0, 0, 500, 100));
    canvas.translate(10, 10); // Center
  });

  tearDown(() {
    canvas.rootElement.remove();
  });

  test('round square with big (equal) radius ends up as a circle', () async {
    for (int i = 0; i < 5; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(100 * i.toDouble(), 0, 80, 80),
              Radius.circular(rRectRadii[i])),
          niceRRectPaint);
    }

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_rrect_round_square.png', region: region);
  });

  test('round rect with big radius scale down smaller radius', () async {
    for (int i = 0; i < 5; i++) {
      final Radius growingRadius = Radius.circular(rRectRadii[i]);
      final RRect rrect = RRect.fromRectAndCorners(
          Rect.fromLTWH(100 * i.toDouble(), 0, 80, 80),
          bottomRight: someFixedRadius,
          topRight: growingRadius,
          bottomLeft: growingRadius);

      canvas.drawRRect(rrect, niceRRectPaint);
    }

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_rrect_overlapping_radius.png', region: region);
  });

  test('diff round rect with big radius scale down smaller radius', () async {
    for (int i = 0; i < 5; i++) {
      final Radius growingRadius = Radius.circular(rRectRadii[i]);
      final RRect outerRRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(100 * i.toDouble(), 0, 80, 80),
          bottomRight: someFixedRadius,
          topRight: growingRadius,
          bottomLeft: growingRadius);

      // Inner is half of outer, but offset a little so it looks nicer
      final RRect innerRRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(100 * i.toDouble() + 5, 5, 40, 40),
          bottomRight: someFixedRadius / 2,
          topRight: growingRadius / 2,
          bottomLeft: growingRadius / 2);

      canvas.drawDRRect(outerRRect, innerRRect, niceRRectPaint);
    }

    html.document.body.append(canvas.rootElement);
    await matchGoldenFile('canvas_drrect_overlapping_radius.png', region: region);
  });
}
