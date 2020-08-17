// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500)}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);
    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // golden screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  test('Should draw linear gradient using rectangle.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    Rect shaderRect = const Rect.fromLTRB(50, 50, 300, 300);
    final Paint paint = Paint()..shader = Gradient.linear(
        Offset(shaderRect.left, shaderRect.top),
        Offset(shaderRect.right, shaderRect.bottom),
        [Color(0xFFcfdfd2), Color(0xFF042a85)]);
    rc.drawRect(shaderRect, paint);
    expect(rc.hasArbitraryPaint, isTrue);
    await _checkScreenshot(rc, 'linear_gradient_rect');
  });

  test('Should draw linear gradient with transform.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    List<double> angles = [0.0, 90.0, 180.0];
    double yOffset = 0;
    for (double angle in angles) {
      final Rect shaderRect = Rect.fromLTWH(50, 50 + yOffset, 100, 100);
      final Paint paint = Paint()
        ..shader = Gradient.linear(
            Offset(shaderRect.left, shaderRect.top),
            Offset(shaderRect.right, shaderRect.bottom),
            [Color(0xFFFF0000), Color(0xFF042a85)],
            null,
            TileMode.clamp,
            Matrix4
                .rotationZ((angle / 180) * math.pi)
                .toFloat64());
      rc.drawRect(shaderRect, Paint()
        ..color = Color(0xFF000000));
      rc.drawOval(shaderRect, paint);
      yOffset += 120;
    }
    expect(rc.hasArbitraryPaint, isTrue);
    await _checkScreenshot(rc, 'linear_gradient_oval_matrix');
  });

  // Regression test for https://github.com/flutter/flutter/issues/50010
  test('Should draw linear gradient using rounded rect.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    Rect shaderRect = const Rect.fromLTRB(50, 50, 300, 300);
    final Paint paint = Paint()..shader = Gradient.linear(
        Offset(shaderRect.left, shaderRect.top),
        Offset(shaderRect.right, shaderRect.bottom),
        [Color(0xFFcfdfd2), Color(0xFF042a85)]);
    rc.drawRRect(RRect.fromRectAndRadius(shaderRect, Radius.circular(16)), paint);
    expect(rc.hasArbitraryPaint, isTrue);
    await _checkScreenshot(rc, 'linear_gradient_rounded_rect');
  });
}
