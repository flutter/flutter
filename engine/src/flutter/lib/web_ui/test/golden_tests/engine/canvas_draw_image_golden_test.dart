// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:js_util' as js_util;

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);
  final Paint testPaint = Paint()..color = const Color(0xFFFF0000);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      { Rect region = const Rect.fromLTWH(0, 0, 500, 500) }) async {

    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.apply(engineCanvas);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region, maxDiffRate: 0.2);
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

  test('Paints image', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.drawImage(createTestImage(), Offset(0, 0), new Paint());
    await _checkScreenshot(rc, 'draw_image');
  });

  test('Paints image with transform', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    rc.drawImage(createTestImage(), Offset(0, 0), new Paint());
    await _checkScreenshot(rc, 'draw_image_with_transform');
  });

  test('Paints image with transform and offset', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    rc.drawImage(createTestImage(), Offset(30, 20), new Paint());
    await _checkScreenshot(rc, 'draw_image_with_transform_and_offset');
  });

  test('Paints image with transform using destination', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    await _checkScreenshot(rc, 'draw_image_rect_with_transform');
  });

  test('Paints image with source and destination', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(testImage, Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    await _checkScreenshot(rc, 'draw_image_rect_with_source');
  });

  test('Paints image with source and destination and round clip', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.save();
    rc.clipRRect(RRect.fromLTRBR(100, 30, 2 * testWidth, 2 * testHeight, Radius.circular(16)));
    rc.drawImageRect(testImage, Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    await _checkScreenshot(rc, 'draw_image_rect_with_source_and_clip');
  });

  test('Paints image with transform using source and destination', () async {
    final RecordingCanvas rc =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 6.0);
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(testImage, Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    await _checkScreenshot(rc, 'draw_image_rect_with_transform_source');
  });
}

HtmlImage createTestImage() {
  const int width = 100;
  const int height = 50;
  html.CanvasElement canvas = new html.CanvasElement(width: width, height: height);
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
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', []);
  return HtmlImage(imageElement, width, height);
}

