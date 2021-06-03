// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'screenshot.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 400.0;
  const double screenHeight = 400.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);
  final HtmlImage testImage = createTestImage();

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  void _drawShapes(RecordingCanvas rc, SurfacePaint paint, Rect shaderRect) {
    /// Rect.
    rc.drawRect(shaderRect, paint);
    shaderRect = shaderRect.translate(100, 0);

    /// Circle.
    rc.drawCircle(shaderRect.center, shaderRect.width / 2, paint);
    shaderRect = shaderRect.translate(110, 0);

    /// Oval.
    rc.drawOval(Rect.fromLTWH(shaderRect.left, shaderRect.top, shaderRect.width, shaderRect.height / 2), paint);
    shaderRect = shaderRect.translate(-210, 120);

    /// Path.
    Path path = Path()
      ..moveTo(shaderRect.center.dx, shaderRect.top)
      ..lineTo(shaderRect.right, shaderRect.bottom)
      ..lineTo(shaderRect.left, shaderRect.bottom)
      ..close();
    rc.drawPath(path, paint);
    shaderRect = shaderRect.translate(100, 0);

    /// RRect.
    rc.drawRRect(RRect.fromRectXY(shaderRect, 10, 20), paint);
    shaderRect = shaderRect.translate(110, 0);

    /// DRRect.
    rc.drawDRRect(RRect.fromRectXY(shaderRect, 20, 30),
        RRect.fromRectXY(shaderRect.deflate(24), 16, 24),
        paint);
    shaderRect = shaderRect.translate(-200, 120);
  }

  Future<void> testImageShader(
      TileMode tmx, TileMode tmy, String fileName,
      {double maxDiffRatePercent = 0.0}) async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, screenWidth, screenHeight));
    //Rect shaderRect = const Rect.fromLTRB(20, 20, 100, 100);
    Rect shaderRect = const Rect.fromLTRB(0, 0, 100, 100);
    final SurfacePaint paint = Paint() as SurfacePaint;
    paint.shader =
        ImageShader(testImage, tmx, tmy, Matrix4.identity().toFloat64()
            , filterQuality: FilterQuality.high);

    _drawShapes(rc, paint, shaderRect);

    expect(rc.renderStrategy.hasArbitraryPaint, isTrue);
    await canvasScreenshot(rc, fileName,
        region: screenRect, maxDiffRatePercent: maxDiffRatePercent);
  }

  test('Should draw with tiled imageshader.', () async {
    await testImageShader(
        TileMode.repeated, TileMode.repeated, 'image_shader_tiled',
        maxDiffRatePercent: 5.0);
  });

  test('Should draw with horizontally mirrored imageshader.', () async {
    await testImageShader(
        TileMode.mirror, TileMode.repeated, 'image_shader_horiz_mirror',
        maxDiffRatePercent: 6.0);
  });

  test('Should draw with vertically mirrored imageshader.', () async {
    await testImageShader(
        TileMode.repeated, TileMode.mirror, 'image_shader_vert_mirror',
        maxDiffRatePercent: 5.0);
  });

  test('Should draw with mirrored imageshader.', () async {
    await testImageShader(
        TileMode.mirror, TileMode.mirror, 'image_shader_mirror',
        maxDiffRatePercent: 6.0);
  });

  test('Should draw with horizontal clamp imageshader.', () async {
    await testImageShader(
        TileMode.clamp, TileMode.repeated, 'image_shader_clamp_horiz',
        maxDiffRatePercent: 13.0);
  });

  test('Should draw with vertical clamp imageshader.', () async {
    await testImageShader(
        TileMode.repeated, TileMode.clamp, 'image_shader_clamp_vertical',
        maxDiffRatePercent: 1.0);
  });
  test('Should draw with clamp imageshader.', () async {
    await testImageShader(
        TileMode.clamp, TileMode.clamp, 'image_shader_clamp',
        maxDiffRatePercent: 1.0);
  });
}

HtmlImage createTestImage() {
  const int width = 16;
  const int width2 = width ~/ 2;
  const int height = 16;
  html.CanvasElement canvas =
      new html.CanvasElement(width: width, height: height);
  html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, width2, width2);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(width2, 0, width2, width2);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(width2, width2, width2, width2);
  ctx.fill();
  html.ImageElement imageElement = html.ImageElement();
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', <dynamic>[]);
  return HtmlImage(imageElement, width, height);
}
