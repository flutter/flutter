// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:web_engine_tester/golden_tester.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect region = ui.Rect.fromLTRB(0, 0, 500, 500);

void testMain() {
  group('BackdropFilter', () {
    setUpCanvasKitTest();
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

    test('blur renders to the edges', () async {
      // Make a checkerboard picture so we can see the blur.
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(region);
      canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.srcOver);
      final double sideLength = region.width / 20;
      final int rows = (region.height / sideLength).ceil();

      for (int row = 0; row < rows; row++) {
        for (int column = 0; column < 10; column++) {
          final ui.Rect rect = ui.Rect.fromLTWH(
            row.isEven
                ? (column * 2) * sideLength
                : (column * 2 + 1) * sideLength,
            row * sideLength,
            sideLength,
            sideLength,
          );
          canvas.drawRect(rect, CkPaint()..color = const ui.Color(0xffff0000));
        }
      }
      final CkPicture checkerboard = recorder.endRecording();

      final LayerSceneBuilder builder = LayerSceneBuilder();
      builder.pushOffset(0, 0);
      builder.addPicture(ui.Offset.zero, checkerboard);
      builder.pushBackdropFilter(ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10));
      CanvasKitRenderer.instance.rasterizer.draw(builder.build().layerTree);
      await matchGoldenFile('canvaskit_backdropfilter_blur_edges.png',
          region: region);
    });
    test('ImageFilter with ColorFilter as child', () async {
      final LayerSceneBuilder builder = LayerSceneBuilder();
      const ui.Rect region = ui.Rect.fromLTRB(0, 0, 500, 250);

      builder.pushOffset(0, 0);

      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(region);
      final ui.ColorFilter colorFilter = ui.ColorFilter.mode(
        const ui.Color(0XFF00FF00).withOpacity(0.55),
        ui.BlendMode.darken
      );

      // using a colorFilter as an imageFilter for backDrop filter
      builder.pushBackdropFilter(colorFilter);
      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        CkPaint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final CkPicture redCircle1 = recorder.endRecording();
      builder.addPicture(ui.Offset.zero, redCircle1);
      await matchSceneGolden('canvaskit_red_circle_green_backdrop_colorFilter.png', builder.build(), region: region);
    });
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}
