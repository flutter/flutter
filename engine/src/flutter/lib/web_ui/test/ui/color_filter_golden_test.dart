// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect region = ui.Rect.fromLTRB(0, 0, 500, 250);

void testMain() {
  group('ColorFilter', () {
    setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

    test('ColorFilter.matrix applies a color filter', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();

      builder.pushOffset(0, 0);

      // Draw a red circle and apply it to the scene.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle = recorder.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle);

      // Apply a "greyscale" color filter.
      builder.pushColorFilter(
        const ui.ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
      );

      // Draw another red circle and apply it to the scene.
      // This one should be grey since we have the color filter.
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);

      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture greyCircle = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, greyCircle);

      await renderScene(builder.build());

      await matchGoldenFile('ui_colorfilter.png', region: region);
    });

    test('invertColors inverts the colors', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();

      builder.pushOffset(0, 0);

      // Draw a red circle and apply it to the scene.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle = recorder.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle);

      // Draw another red circle with invertColors.
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);

      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()
          ..color = const ui.Color.fromARGB(255, 255, 0, 0)
          ..invertColors = true,
      );
      final ui.Picture invertedCircle = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, invertedCircle);

      await renderScene(builder.build());

      await matchGoldenFile('ui_invertcolors.png', region: region);
    });

    test('ColorFilter.matrix works for inverse matrix', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();

      builder.pushOffset(0, 0);

      // Draw a red, green, and blue square with the inverted color matrix.
      builder.pushColorFilter(
        const ui.ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255, //
          0, -1, 0, 0, 255, //
          0, 0, -1, 0, 255, //
          0, 0, 0, 1, 0, //
        ]),
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);
      canvas.drawRect(
        const ui.Rect.fromLTWH(50, 50, 100, 100),
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(200, 50, 100, 100),
        ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(350, 50, 100, 100),
        ui.Paint()..color = const ui.Color.fromARGB(255, 0, 0, 255),
      );
      final ui.Picture invertedSquares = recorder.endRecording();

      builder.addPicture(ui.Offset.zero, invertedSquares);

      await renderScene(builder.build());

      await matchGoldenFile('ui_inverse_colormatrix.png', region: region);
    });

    test('ColorFilter color with 0 opacity', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle1 = recorder.endRecording();
      builder.addPicture(ui.Offset.zero, redCircle1);

      builder.pushColorFilter(
        ui.ColorFilter.mode(const ui.Color(0x00000000).withOpacity(0), ui.BlendMode.srcOver),
      );

      // Draw another red circle and apply it to the scene.
      // This one should also be red with the color filter doing nothing
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);
      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle2 = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle2);

      await renderScene(builder.build());

      await matchGoldenFile('ui_transparent_colorfilter.png', region: region);
    });

    test('ColorFilter with dst blend mode', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle1 = recorder.endRecording();
      builder.addPicture(ui.Offset.zero, redCircle1);

      // Push dst color filter
      builder.pushColorFilter(const ui.ColorFilter.mode(ui.Color(0xffff0000), ui.BlendMode.dst));

      // Draw another red circle and apply it to the scene.
      // This one should also be red with the color filter doing nothing
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);
      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle2 = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle2);

      await renderScene(builder.build());

      await matchGoldenFile('ui_dst_colorfilter.png', region: region);
    });

    test('ColorFilter only applies to child bounds', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();

      builder.pushOffset(0, 0);

      // Draw a red circle and add it to the scene.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle = recorder.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle);

      // Apply a green color filter.
      builder.pushColorFilter(const ui.ColorFilter.mode(ui.Color(0xff00ff00), ui.BlendMode.color));
      // Draw another red circle and apply it to the scene.
      // This one should be green since we have the color filter.
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);

      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture greenCircle = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, greenCircle);

      await renderScene(builder.build());

      await matchGoldenFile('ui_colorfilter_bounds.png', region: region);
    });

    test('ColorFilter works as an ImageFilter', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();

      builder.pushOffset(0, 0);

      // Draw a red circle and add it to the scene.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle = recorder.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle);

      // Apply a green color filter as an ImageFilter.
      builder.pushImageFilter(const ui.ColorFilter.mode(ui.Color(0xff00ff00), ui.BlendMode.color));
      // Draw another red circle and apply it to the scene.
      // This one should be green since we have the color filter.
      final ui.PictureRecorder recorder2 = ui.PictureRecorder();
      final ui.Canvas canvas2 = ui.Canvas(recorder2, region);

      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture greenCircle = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, greenCircle);

      await renderScene(builder.build());

      await matchGoldenFile('ui_colorfilter_as_imagefilter.png', region: region);
    });
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
  }, skip: isSafari || isFirefox);
}
