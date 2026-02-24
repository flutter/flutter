// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('ImageFilter.blur with TileMode.clamp', () async {
    const region = ui.Rect.fromLTRB(0, 0, 300, 300);

    // Create a picture with a white background
    final backgroundRecorder = ui.PictureRecorder();
    final backgroundCanvas = ui.Canvas(backgroundRecorder, region);
    backgroundCanvas.drawPaint(ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    final ui.Picture backgroundPicture = backgroundRecorder.endRecording();

    // Create a picture with a red square
    final redSquareRecorder = ui.PictureRecorder();
    final redSquareCanvas = ui.Canvas(redSquareRecorder, region);
    redSquareCanvas.drawRect(
      const ui.Rect.fromLTRB(100, 100, 200, 200),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );
    final ui.Picture redSquarePicture = redSquareRecorder.endRecording();

    final builder = ui.SceneBuilder();
    builder.pushOffset(0, 0);

    // Add white background
    builder.addPicture(ui.Offset.zero, backgroundPicture);

    // Push blur image filter with TileMode.clamp
    builder.pushImageFilter(
      ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0, tileMode: ui.TileMode.clamp),
    );

    // Add red square
    builder.addPicture(ui.Offset.zero, redSquarePicture);

    builder.pop(); // Pop image filter

    await renderScene(builder.build());

    await matchGoldenFile('ui_image_filter_blur_clamp.png', region: region);
  });
}
