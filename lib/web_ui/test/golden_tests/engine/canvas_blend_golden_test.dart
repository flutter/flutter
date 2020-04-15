// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
       double maxDiffRatePercent = 0.0}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region, maxDiffRatePercent: maxDiffRatePercent);
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

  test('Blend circles with difference and color', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.drawRect(
        Rect.fromLTRB(0, 0, 400, 400),
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(255, 255, 255, 255));
    rc.drawCircle(
        Offset(100, 100),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(128, 255, 0, 0)
          ..blendMode = BlendMode.difference);

    rc.drawCircle(
        Offset(170, 100),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.color
          ..color = const Color.fromARGB(128, 0, 255, 0));

    rc.drawCircle(
        Offset(135, 170),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(128, 255, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'canvas_blend_circle_diff_color',
        maxDiffRatePercent: operatingSystem == OperatingSystem.macOs ? 2.95 : 0);
  });

  test('Blend circle and text with multiply', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.drawRect(
        Rect.fromLTRB(0, 0, 400, 400),
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(255, 255, 255, 255));
    rc.drawCircle(
        Offset(100, 100),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(128, 255, 0, 0)
          ..blendMode = BlendMode.difference);
    rc.drawCircle(
        Offset(170, 100),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.color
          ..color = const Color.fromARGB(128, 0, 255, 0));

    rc.drawCircle(
        Offset(135, 170),
        80.0,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color.fromARGB(128, 255, 0, 0));
    rc.drawImage(createTestImage(), Offset(135.0, 130.0),
        Paint()..blendMode = BlendMode.multiply);
    rc.restore();
    await _checkScreenshot(rc, 'canvas_blend_image_multiply',
        maxDiffRatePercent: operatingSystem == OperatingSystem.macOs ? 2.95 : 0);
  });
}

HtmlImage createTestImage() {
  const int width = 100;
  const int height = 50;
  html.CanvasElement canvas =
      new html.CanvasElement(width: width, height: height);
  html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, 33, 50);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(33, 0, 33, 50);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(66, 0, 33, 50);
  ctx.fill();
  html.ImageElement imageElement = html.ImageElement();
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', <dynamic>[]);
  return HtmlImage(imageElement, width, height);
}
