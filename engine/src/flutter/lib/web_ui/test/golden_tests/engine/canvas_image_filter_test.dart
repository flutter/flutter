// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';

import 'screenshot.dart';
import 'testimage.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 100.0;
  const double screenHeight = 100.0;
  const Rect region = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Regression test for https://github.com/flutter/flutter/issues/76966
  test('Draws image with dstATop color filter', () async {
    final RecordingCanvas canvas = RecordingCanvas(region);
    canvas.drawImage(createFlutterLogoTestImage(), Offset(10, 10),
      Paint()
        ..colorFilter = EngineColorFilter.mode(Color(0x40000000),
            BlendMode.dstATop));
    await canvasScreenshot(canvas, 'image_color_fiter_dstatop',
        region: region);
  });
}
