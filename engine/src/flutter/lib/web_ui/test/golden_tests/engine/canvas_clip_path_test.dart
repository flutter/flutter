// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart' as engine;

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(engine.RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500)}) async {
    final engine.EngineCanvas engineCanvas = engine.BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region, maxDiffRatePercent: 0.0);
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

  // Regression test for https://github.com/flutter/flutter/issues/48683
  // Should clip image with oval.
  test('Clips image with oval clip path', () async {
    final engine.RecordingCanvas rc =
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    final Path path = Path();
    path.addOval(Rect.fromLTWH(100, 30, testWidth, testHeight));
    rc.clipPath(path);
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTWH(100, 30, testWidth, testHeight), Paint());
    rc.restore();
    await _checkScreenshot(rc, 'image_clipped_by_oval');
  });

  // Regression test for https://github.com/flutter/flutter/issues/48683
  test('Clips triangle with oval clip path', () async {
    final engine.RecordingCanvas rc =
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    double testWidth = 200;
    double testHeight = 150;
    final Path path = Path();
    path.addOval(Rect.fromLTWH(100, 30, testWidth, testHeight));
    rc.clipPath(path);
    final Path paintPath = new Path();
    paintPath.moveTo(testWidth / 2, 0);
    paintPath.lineTo(testWidth, testHeight);
    paintPath.lineTo(0, testHeight);
    paintPath.close();
    rc.drawPath(
        paintPath,
        Paint()
          ..color = Color(0xFF00FF00)
          ..style = PaintingStyle.fill);
    rc.restore();
    await _checkScreenshot(rc, 'triangle_clipped_by_oval');
  });
}

engine.HtmlImage createTestImage({int width = 200, int height = 150}) {
  html.CanvasElement canvas =
      new html.CanvasElement(width: width, height: height);
  html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(width / 3, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(2 * width / 3, 0, width / 3, height);
  ctx.fill();
  html.ImageElement imageElement = html.ImageElement();
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', <dynamic>[]);
  return engine.HtmlImage(imageElement, width, height);
}
