// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

import 'scuba.dart';

const Color _kShadowColor = Color.fromARGB(255, 0, 0, 0);

void main() async {
  final Rect region = Rect.fromLTWH(0, 0, 550, 300);

  SurfaceSceneBuilder builder;

  setUpStableTestFonts();

  setUp(() {
    builder = SurfaceSceneBuilder();
  });

  void _paintShapeOutline() {
    final EnginePictureRecorder recorder = PictureRecorder();
    final RecordingCanvas canvas = recorder.beginRecording(Rect.largest);
    canvas.drawRect(
      const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0),
      SurfacePaint()
        ..color = Color.fromARGB(255, 0, 0, 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    builder.addPicture(Offset.zero, recorder.endRecording());
  }

  void _paintShadowBounds(SurfacePath path, double elevation) {
    final Rect shadowBounds =
        computePenumbraBounds(path.getBounds(), elevation);
    final EnginePictureRecorder recorder = PictureRecorder();
    final RecordingCanvas canvas = recorder.beginRecording(Rect.largest);
    canvas.drawRect(
      shadowBounds,
      SurfacePaint()
        ..color = Color.fromARGB(255, 0, 255, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    builder.addPicture(Offset.zero, recorder.endRecording());
  }

  void _paintPhysicalShapeShadow(double elevation, Offset offset) {
    final SurfacePath path = SurfacePath()
      ..addRect(const Rect.fromLTRB(0, 0, 20, 20));
    builder.pushOffset(offset.dx, offset.dy);
    builder.pushPhysicalShape(
      path: path,
      elevation: elevation,
      shadowColor: _kShadowColor,
      color: Color.fromARGB(255, 255, 255, 255),
    );
    builder.pop(); // physical shape
    _paintShapeOutline();
    _paintShadowBounds(path, elevation);
    builder.pop(); // offset
  }

  void _paintBitmapCanvasShadow(double elevation, Offset offset) {
    final SurfacePath path = SurfacePath()
      ..addRect(const Rect.fromLTRB(0, 0, 20, 20));
    builder.pushOffset(offset.dx, offset.dy);

    final EnginePictureRecorder recorder = PictureRecorder();
    final RecordingCanvas canvas = recorder.beginRecording(Rect.largest);
    canvas
        .debugEnforceArbitraryPaint(); // make sure DOM canvas doesn't take over
    canvas.drawShadow(
      path,
      _kShadowColor,
      elevation,
      false,
    );
    builder.addPicture(Offset.zero, recorder.endRecording());
    _paintShapeOutline();
    _paintShadowBounds(path, elevation);

    builder.pop(); // offset
  }

  void _paintBitmapCanvasComplexPathShadow(double elevation, Offset offset) {
    final SurfacePath path = SurfacePath()
      ..moveTo(10, 0)
      ..lineTo(20, 10)
      ..lineTo(10, 20)
      ..lineTo(0, 10)
      ..close();
    builder.pushOffset(offset.dx, offset.dy);

    final EnginePictureRecorder recorder = PictureRecorder();
    final RecordingCanvas canvas = recorder.beginRecording(Rect.largest);
    canvas
        .debugEnforceArbitraryPaint(); // make sure DOM canvas doesn't take over
    canvas.drawShadow(
      path,
      _kShadowColor,
      elevation,
      false,
    );
    canvas.drawPath(
      path,
      SurfacePaint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.fromARGB(255, 0, 0, 255),
    );
    builder.addPicture(Offset.zero, recorder.endRecording());
    _paintShadowBounds(path, elevation);

    builder.pop(); // offset
  }

  test(
    'renders shadows correctly',
    () async {
      // Physical shape clips. We want to see that clipping in the screenshot.
      debugShowClipLayers = false;

      builder.pushOffset(10, 20);

      for (int i = 0; i < 10; i++) {
        _paintPhysicalShapeShadow(i.toDouble(), Offset(50.0 * i, 0));
      }

      for (int i = 0; i < 10; i++) {
        _paintBitmapCanvasShadow(i.toDouble(), Offset(50.0 * i, 60));
      }

      for (int i = 0; i < 10; i++) {
        _paintBitmapCanvasComplexPathShadow(
            i.toDouble(), Offset(50.0 * i, 120));
      }

      builder.pop();

      final html.Element sceneElement = builder.build().webOnlyRootElement;
      html.document.body.append(sceneElement);

      await matchGoldenFile(
        'shadows.png',
        region: region,
        maxDiffRatePercent: 0.0,
        pixelComparison: PixelComparison.precise,
      );
    },
    testOn: 'chrome',
  );
}
