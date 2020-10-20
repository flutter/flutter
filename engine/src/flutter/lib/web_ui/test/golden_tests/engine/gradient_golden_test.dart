// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'package:web_engine_tester/golden_tester.dart';

import 'scuba.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 240),
        double maxDiffRatePercent = 0.0, bool write: false}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png',
          region: region, maxDiffRatePercent: maxDiffRatePercent, write: write);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
  });

  setUpStableTestFonts();

  test('Paints sweep gradient rectangles', () async {
    final RecordingCanvas canvas =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    canvas.save();

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color(0xFF000000);

    List<Color> colors = <Color>[
      Color(0xFF000000),
      Color(0xFFFF3C38),
      Color(0xFFFF8C42),
      Color(0xFFFFF275),
      Color(0xFF6699CC),
      Color(0xFF656D78),];
    List<double> stops = <double>[0.0, 0.05, 0.4, 0.6, 0.9, 1.0];

    EngineGradient sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    EngineGradient sweepGradientRotated = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    const double kBoxWidth = 150;
    const double kBoxHeight = 80;
    // Gradient with default center.
    Rect rectBounds = Rect.fromLTWH(10, 20, kBoxWidth, kBoxHeight);
    canvas.drawRect(rectBounds,
        Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with shifted center and rotation.
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    canvas.drawRect(rectBounds,
        Paint()..shader = engineGradientToShader(sweepGradientRotated, Rect.fromLTWH(rectBounds.center.dx, rectBounds.top, rectBounds.width / 2, rectBounds.height)));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with start/endangle.
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    canvas.drawRect(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode repeat
    rectBounds = Rect.fromLTWH(10, 110, kBoxWidth, kBoxHeight);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.repeated,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    canvas.drawRect(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode mirror
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.mirror,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);
    canvas.drawRect(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    canvas.restore();
    await _checkScreenshot(canvas, 'sweep_gradient_rect');
  });

  test('Paints sweep gradient ovals', () async {
    final RecordingCanvas canvas =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    canvas.save();

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color(0xFF000000);

    List<Color> colors = <Color>[
      Color(0xFF000000),
      Color(0xFFFF3C38),
      Color(0xFFFF8C42),
      Color(0xFFFFF275),
      Color(0xFF6699CC),
      Color(0xFF656D78),];
    List<double> stops = <double>[0.0, 0.05, 0.4, 0.6, 0.9, 1.0];

    EngineGradient sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    EngineGradient sweepGradientRotated = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    const double kBoxWidth = 150;
    const double kBoxHeight = 80;
    // Gradient with default center.
    Rect rectBounds = Rect.fromLTWH(10, 20, kBoxWidth, kBoxHeight);
    canvas.drawOval(rectBounds,
        Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with shifted center and rotation.
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    canvas.drawOval(rectBounds,
        Paint()..shader = engineGradientToShader(sweepGradientRotated, Rect.fromLTWH(rectBounds.center.dx, rectBounds.top, rectBounds.width / 2, rectBounds.height)));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with start/endangle.
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    canvas.drawOval(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode repeat
    rectBounds = Rect.fromLTWH(10, 110, kBoxWidth, kBoxHeight);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.repeated,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    canvas.drawOval(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode mirror
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.mirror,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);
    canvas.drawOval(rectBounds,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    canvas.restore();
    await _checkScreenshot(canvas, 'sweep_gradient_oval');
  });

  test('Paints sweep gradient paths', () async {
    final RecordingCanvas canvas =
    RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    canvas.save();

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color(0xFF000000);

    List<Color> colors = <Color>[
      Color(0xFF000000),
      Color(0xFFFF3C38),
      Color(0xFFFF8C42),
      Color(0xFFFFF275),
      Color(0xFF6699CC),
      Color(0xFF656D78),];
    List<double> stops = <double>[0.0, 0.05, 0.4, 0.6, 0.9, 1.0];

    EngineGradient sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    EngineGradient sweepGradientRotated = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        0, 360.0 / 180.0 * math.pi,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    const double kBoxWidth = 150;
    const double kBoxHeight = 80;
    // Gradient with default center.
    Rect rectBounds = Rect.fromLTWH(10, 20, kBoxWidth, kBoxHeight);
    Path path = samplePathFromRect(rectBounds);
    canvas.drawPath(path,
        Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with shifted center and rotation.
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    path = samplePathFromRect(rectBounds);
    canvas.drawPath(path,
        Paint()..shader = engineGradientToShader(sweepGradientRotated, Rect.fromLTWH(rectBounds.center.dx, rectBounds.top, rectBounds.width / 2, rectBounds.height)));
    canvas.drawRect(rectBounds, borderPaint);

    // Gradient with start/endangle.
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.clamp,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    path = samplePathFromRect(rectBounds);
    canvas.drawPath(path,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode repeat
    rectBounds = Rect.fromLTWH(10, 110, kBoxWidth, kBoxHeight);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.repeated,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);

    path = samplePathFromRect(rectBounds);
    canvas.drawPath(path,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    // Tile mode mirror
    rectBounds = rectBounds.translate(kBoxWidth + 10, 0);
    sweepGradient = GradientSweep(Offset(0.5, 0.5),
        colors, stops, TileMode.mirror,
        math.pi / 6, 3 * math.pi / 4,
        Matrix4.rotationZ(math.pi / 6.0).storage);
    path = samplePathFromRect(rectBounds);
    canvas.drawPath(path,
        new Paint()..shader = engineGradientToShader(sweepGradient, rectBounds));
    canvas.drawRect(rectBounds, borderPaint);

    canvas.restore();
    await _checkScreenshot(canvas, 'sweep_gradient_path');
  });
}

Shader engineGradientToShader(GradientSweep gradient, Rect rect) {
  return Gradient.sweep(
      Offset(rect.left + gradient.center.dx * rect.width,
          rect.top + gradient.center.dy * rect.height),
      gradient.colors, gradient.colorStops, gradient.tileMode,
      gradient.startAngle,
      gradient.endAngle,
      gradient.matrix4 == null ? null :
          Float64List.fromList(gradient.matrix4),
  );
}

Path samplePathFromRect(Rect rectBounds) =>
  Path()
    ..moveTo(rectBounds.center.dx, rectBounds.top)
    ..lineTo(rectBounds.left, rectBounds.bottom)
    ..quadraticBezierTo(rectBounds.center.dx + 20, rectBounds.bottom - 40,
        rectBounds.right, rectBounds.bottom)
    ..close();
