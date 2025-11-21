// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect region = ui.Rect.fromLTRB(0, 0, 500, 500);

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  group('BackdropFilter', () {
    setUp(() {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1);
    });

    test('blur renders to the edges', () async {
      // Make a checkerboard picture so we can see the blur.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);
      canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.srcOver);
      final double sideLength = region.width / 20;
      final int rows = (region.height / sideLength).ceil();

      for (int row = 0; row < rows; row++) {
        for (int column = 0; column < 10; column++) {
          final ui.Rect rect = ui.Rect.fromLTWH(
            row.isEven ? (column * 2) * sideLength : (column * 2 + 1) * sideLength,
            row * sideLength,
            sideLength,
            sideLength,
          );
          canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xffff0000));
        }
      }
      final ui.Picture checkerboard = recorder.endRecording();

      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      builder.addPicture(ui.Offset.zero, checkerboard);
      builder.pushBackdropFilter(ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10));
      await renderScene(builder.build());

      await matchGoldenFile('ui_backdropfilter_blur_edges.png', region: region);
    });
    test('ImageFilter with ColorFilter as child', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      const ui.Rect region = ui.Rect.fromLTRB(0, 0, 500, 250);

      builder.pushOffset(0, 0);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);
      final ui.ColorFilter colorFilter = ui.ColorFilter.mode(
        const ui.Color(0XFF00FF00).withOpacity(0.55),
        ui.BlendMode.darken,
      );

      // using a colorFilter as an imageFilter for backDrop filter
      builder.pushBackdropFilter(colorFilter);
      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle1 = recorder.endRecording();
      builder.addPicture(ui.Offset.zero, redCircle1);

      await renderScene(builder.build());
      await matchGoldenFile('ui_red_circle_green_backdrop_colorFilter.png', region: region);
    });

    test('works with an invisible platform view inside', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
        isVisible: false,
      );
      await createPlatformView(0, 'test-platform-view');

      // Make a checkerboard picture so we can see the blur.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);
      canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.srcOver);
      final double sideLength = region.width / 20;
      final int rows = (region.height / sideLength).ceil();

      for (int row = 0; row < rows; row++) {
        for (int column = 0; column < 10; column++) {
          final ui.Rect rect = ui.Rect.fromLTWH(
            row.isEven ? (column * 2) * sideLength : (column * 2 + 1) * sideLength,
            row * sideLength,
            sideLength,
            sideLength,
          );
          canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xffff0000));
        }
      }
      final ui.Picture checkerboard = recorder.endRecording();

      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      builder.addPicture(ui.Offset.zero, checkerboard);
      builder.pushBackdropFilter(ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10));

      // Draw a green rectangle, then an invisible platform view, then a blue
      // rectangle. Both rectangles should not be blurred.
      final ui.PictureRecorder greenRectRecorder = ui.PictureRecorder();
      final ui.Canvas greenRectCanvas = ui.Canvas(greenRectRecorder, region);
      final ui.Paint greenPaint = ui.Paint()..color = const ui.Color(0xff00ff00);
      greenRectCanvas.drawRect(
        ui.Rect.fromCenter(
          center: ui.Offset(region.width / 3, region.height / 2),
          width: region.width / 6,
          height: region.height / 6,
        ),
        greenPaint,
      );
      final ui.Picture greenRectPicture = greenRectRecorder.endRecording();

      final ui.PictureRecorder blueRectRecorder = ui.PictureRecorder();
      final ui.Canvas blueRectCanvas = ui.Canvas(blueRectRecorder, region);
      final ui.Paint bluePaint = ui.Paint()..color = const ui.Color(0xff0000ff);
      blueRectCanvas.drawRect(
        ui.Rect.fromCenter(
          center: ui.Offset(2 * region.width / 3, region.height / 2),
          width: region.width / 6,
          height: region.height / 6,
        ),
        bluePaint,
      );
      final ui.Picture blueRectPicture = blueRectRecorder.endRecording();

      builder.addPicture(ui.Offset.zero, greenRectPicture);
      builder.addPlatformView(0, width: 10, height: 10);
      builder.addPicture(ui.Offset.zero, blueRectPicture);

      // Pop the backdrop filter layer.
      builder.pop();

      await renderScene(builder.build());

      await matchGoldenFile('canvaskit_backdropfilter_with_platformview.png', region: region);
    });
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}
