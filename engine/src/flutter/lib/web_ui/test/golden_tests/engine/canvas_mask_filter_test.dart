// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName, ui.Rect screenRect, {bool write = false}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: screenRect, maxDiffRatePercent: 0.0, write: write);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    ui.debugEmulateFlutterTesterEnvironment = true;
    await ui.webOnlyInitializePlatform();
    ui.webOnlyFontCollection.debugRegisterTestFonts();
    await ui.webOnlyFontCollection.ensureFontsLoaded();
  });

  tearDown(() {
    ContextStateHandle.debugEmulateWebKitMaskFilter = false;
  });

  // Regression test for https://github.com/flutter/flutter/issues/55930
  void testMaskFilterBlur({bool isSafariMode}) {
    final String browser = isSafariMode ? 'Safari' : 'Chrome';

    test('renders MaskFilter.blur in $browser', () async {
      const double screenWidth = 800.0;
      const double screenHeight = 150.0;
      const ui.Rect screenRect = ui.Rect.fromLTWH(0, 0, screenWidth, screenHeight);

      ContextStateHandle.debugEmulateWebKitMaskFilter = isSafariMode;
      final RecordingCanvas rc = RecordingCanvas(screenRect);
      rc.translate(0, 75);

      final SurfacePaint paint = SurfacePaint()
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5);

      rc.translate(50, 0);
      rc.drawRect(
        ui.Rect.fromCircle(center: ui.Offset.zero, radius: 30),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF00FF00);
      rc.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(center: ui.Offset.zero, radius: 30),
          ui.Radius.circular(20),
        ),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF0000FF);
      rc.drawCircle(ui.Offset.zero, 30, paint);

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF00FFFF);
      rc.drawPath(
        SurfacePath()
          ..moveTo(-20, 0)
          ..lineTo(0, -50)
          ..lineTo(20, 0)
          ..lineTo(0, 50)
          ..close(),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFFFF00FF);
      rc.drawOval(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: 40, height: 100),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF888800);
      paint.strokeWidth = 5;
      rc.drawLine(
        ui.Offset(-20, -50),
        ui.Offset(20, 50),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF888888);
      rc.drawDRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(center: ui.Offset.zero, radius: 35),
          ui.Radius.circular(20),
        ),
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(center: ui.Offset.zero, radius: 15),
          ui.Radius.circular(7),
        ),
        paint,
      );

      rc.translate(100, 0);
      paint.color = ui.Color(0xFF6500C9);
      rc.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList([-10, -10, -10, 10, 10, -10, 10, 10]),
        paint,
      );

      await _checkScreenshot(rc, 'mask_filter_$browser', screenRect);
    });

    test('renders transformed MaskFilter.blur in $browser', () async {
      const double screenWidth = 300.0;
      const double screenHeight = 300.0;
      const ui.Rect screenRect = ui.Rect.fromLTWH(0, 0, screenWidth, screenHeight);

      ContextStateHandle.debugEmulateWebKitMaskFilter = isSafariMode;
      final RecordingCanvas rc = RecordingCanvas(screenRect);
      rc.translate(150, 150);

      final SurfacePaint paint = SurfacePaint()
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5);

      final List<ui.Color> colors = <ui.Color>[
        ui.Color(0xFF000000),
        ui.Color(0xFF00FF00),
        ui.Color(0xFF0000FF),
        ui.Color(0xFF00FFFF),
        ui.Color(0xFFFF00FF),
        ui.Color(0xFF888800),
        ui.Color(0xFF888888),
        ui.Color(0xFF6500C9),
      ];

      for (ui.Color color in colors) {
        paint.color = color;
        rc.rotate(math.pi / 4);
        rc.drawRect(
          ui.Rect.fromCircle(center: const ui.Offset(90, 0), radius: 20),
          paint,
        );
      }

      await _checkScreenshot(rc, 'mask_filter_transformed_$browser', screenRect);
    });
  }

  testMaskFilterBlur(isSafariMode: false);
  testMaskFilterBlur(isSafariMode: true);

  for (int testDpr in <int>[1, 2, 4]) {
    test('MaskFilter.blur blurs correctly for device-pixel ratio $testDpr', () async {
      window.debugOverrideDevicePixelRatio(testDpr.toDouble());
      const ui.Rect screenRect = ui.Rect.fromLTWH(0, 0, 150, 150);

      final RecordingCanvas rc = RecordingCanvas(screenRect);
      rc.translate(0, 75);

      final SurfacePaint paint = SurfacePaint()
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5);

      rc.translate(75, 0);
      rc.drawRect(
        ui.Rect.fromCircle(center: ui.Offset.zero, radius: 30),
        paint,
      );

      await _checkScreenshot(rc, 'mask_filter_blur_dpr_$testDpr', screenRect);
      window.debugOverrideDevicePixelRatio(1.0);
    });
  }
}
