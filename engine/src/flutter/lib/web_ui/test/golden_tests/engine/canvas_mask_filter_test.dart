// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName, Rect screenRect) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: screenRect, maxDiffRatePercent: 0.0);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
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
      const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

      ContextStateHandle.debugEmulateWebKitMaskFilter = isSafariMode;
      final RecordingCanvas rc = RecordingCanvas(screenRect);
      rc.translate(0, 75);

      final SurfacePaint paint = SurfacePaint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

      rc.translate(50, 0);
      rc.drawRect(
        Rect.fromCircle(center: Offset.zero, radius: 30),
        paint,
      );

      rc.translate(100, 0);
      paint.color = Color(0xFF00FF00);
      rc.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset.zero, radius: 30),
          Radius.circular(20),
        ),
        paint,
      );

      rc.translate(100, 0);
      paint.color = Color(0xFF0000FF);
      rc.drawCircle(Offset.zero, 30, paint);

      rc.translate(100, 0);
      paint.color = Color(0xFF00FFFF);
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
      paint.color = Color(0xFFFF00FF);
      rc.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 100),
        paint,
      );

      rc.translate(100, 0);
      paint.color = Color(0xFF888800);
      paint.strokeWidth = 5;
      rc.drawLine(
        Offset(-20, -50),
        Offset(20, 50),
        paint,
      );

      rc.translate(100, 0);
      paint.color = Color(0xFF888888);
      rc.drawDRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset.zero, radius: 35),
          Radius.circular(20),
        ),
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset.zero, radius: 15),
          Radius.circular(7),
        ),
        paint,
      );

      rc.translate(100, 0);
      paint.color = Color(0xFF6500C9);
      rc.drawRawPoints(
        PointMode.points,
        Float32List.fromList([-10, -10, -10, 10, 10, -10, 10, 10]),
        paint,
      );

      await _checkScreenshot(rc, 'mask_filter_$browser', screenRect);
    });

    test('renders transformed MaskFilter.blur in $browser', () async {
      const double screenWidth = 300.0;
      const double screenHeight = 300.0;
      const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

      ContextStateHandle.debugEmulateWebKitMaskFilter = isSafariMode;
      final RecordingCanvas rc = RecordingCanvas(screenRect);
      rc.translate(150, 150);

      final SurfacePaint paint = SurfacePaint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

      final List<Color> colors = <Color>[
        Color(0xFF000000),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFF00FFFF),
        Color(0xFFFF00FF),
        Color(0xFF888800),
        Color(0xFF888888),
        Color(0xFF6500C9),
      ];

      for (Color color in colors) {
        paint.color = color;
        rc.rotate(math.pi / 4);
        rc.drawRect(
          Rect.fromCircle(center: const Offset(90, 0), radius: 20),
          paint,
        );
      }

      await _checkScreenshot(rc, 'mask_filter_transformed_$browser', screenRect);
    });
  }

  testMaskFilterBlur(isSafariMode: false);
  testMaskFilterBlur(isSafariMode: true);
}
