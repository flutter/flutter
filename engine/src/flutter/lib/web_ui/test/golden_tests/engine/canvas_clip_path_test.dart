// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart' as engine;

import 'screenshot.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 500.0;
  const double screenHeight = 500.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

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
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    final Path path = Path();
    path.addOval(Rect.fromLTWH(100, 30, testWidth, testHeight));
    rc.clipPath(path);
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTWH(100, 30, testWidth, testHeight), engine.SurfacePaint());
    rc.restore();
    await canvasScreenshot(rc, 'image_clipped_by_oval',
      region: screenRect);
  });

  // Regression test for https://github.com/flutter/flutter/issues/48683
  test('Clips triangle with oval clip path', () async {
    final engine.RecordingCanvas rc =
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
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
        engine.SurfacePaint()
          ..color = Color(0xFF00FF00)
          ..style = PaintingStyle.fill);
    rc.restore();
    await canvasScreenshot(rc, 'triangle_clipped_by_oval',
      region: screenRect);
  });

  // Regression test for https://github.com/flutter/flutter/issues/78782
  test('Clips on Safari when clip bounds off screen', () async {
    final engine.RecordingCanvas rc =
    engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    rc.save();
    double testWidth = 200;
    double testHeight = 150;

    final Path paintPath = new Path();
    paintPath.addRect(Rect.fromLTWH(-50, 0, testWidth, testHeight));
    paintPath.close();
    rc.drawPath(paintPath,
        engine.SurfacePaint()
          ..color = Color(0xFF000000)
          ..style = PaintingStyle.stroke);

    final Path path = Path();
    path.moveTo(-200, 0);
    path.lineTo(100, 75);
    path.lineTo(-200, 150);
    path.close();
    rc.clipPath(path);
    rc.drawImageRect(createTestImage(), Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTWH(-50, 0, testWidth, testHeight), engine.SurfacePaint());
    rc.restore();
    await canvasScreenshot(rc, 'image_clipped_by_triangle_off_screen');
  });

  // Tests oval clipping using border radius 50%.
  test('Clips against oval', () async {
    final engine.RecordingCanvas rc =
    engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    rc.save();
    double testWidth = 200;
    double testHeight = 150;

    final Path paintPath = new Path();
    paintPath.addRect(Rect.fromLTWH(-50, 0, testWidth, testHeight));
    paintPath.close();
    rc.drawPath(paintPath,
        engine.SurfacePaint()
          ..color = Color(0xFF000000)
          ..style = PaintingStyle.stroke);

    final Path path = Path();
    path.addOval(Rect.fromLTRB(-200, 0, 100, 150));
    rc.clipPath(path);
    rc.drawImageRect(createTestImage(), Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTWH(-50, 0, testWidth, testHeight), engine.SurfacePaint());
    rc.restore();
    await canvasScreenshot(rc, 'image_clipped_by_oval_path');
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
