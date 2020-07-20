// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;

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
      double maxDiffRatePercent = null}) async {
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

  test('Should draw transformed line.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    final Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(300, 200);
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));
    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, 20);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_line');
  });

  test('Should draw transformed line.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    final Path path = Path();
    path.addRect(Rect.fromLTRB(50, 40, 300, 100));
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));
    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, 20);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_rect');
  });

  test('Should draw transformed quadratic curve.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    final Path path = Path();
    path.moveTo(100, 100);
    path.quadraticBezierTo(100, 300, 400, 300);
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));
    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, -80);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_quadratic_curve');
  });

  test('Should draw transformed conic.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    const double yStart = 20;

    const Offset p0 = Offset(25, yStart + 25);
    const Offset pc = Offset(60, yStart + 150);
    const Offset p2 = Offset(100, yStart + 50);

    final Path path = Path();
    path.moveTo(p0.dx, p0.dy);
    path.conicTo(pc.dx, pc.dy, p2.dx, p2.dy, 0.5);
    path.close();
    path.moveTo(p0.dx, p0.dy + 100);
    path.conicTo(pc.dx, pc.dy + 100, p2.dx, p2.dy + 100, 10);
    path.close();

    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));
    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, -80);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_conic');
  });

  test('Should draw transformed arc.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));

    final Path path = Path();
    path.moveTo(350, 280);
    path.arcToPoint(Offset(450, 90),
        radius: Radius.elliptical(200, 50),
        rotation: -math.pi / 6.0,
        largeArc: true,
        clockwise: true);
    path.close();

    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));

    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, 10);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_arc',
        maxDiffRatePercent: 1.4);
  });

  test('Should draw transformed rrect.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));

    final Path path = Path();
    path.addRRect(RRect.fromLTRBR(50, 50, 300, 200, Radius.elliptical(4, 8)));

    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));

    final Path transformedPath = Path();
    final Matrix4 testMatrixTranslateRotate =
        Matrix4.rotationZ(math.pi * 30.0 / 180.0)..translate(100, -80);
    transformedPath.addPath(path, Offset.zero,
        matrix4: testMatrixTranslateRotate.toFloat64());
    rc.drawPath(
        transformedPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color.fromRGBO(0, 128, 255, 1.0));
    await _checkScreenshot(rc, 'path_transform_with_rrect');
  });
}
