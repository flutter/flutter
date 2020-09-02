// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  final Rect region = Rect.fromLTWH(0, 0, 500, 500);

  setUp(() async {
    debugShowClipLayers = true;
    SurfaceSceneBuilder.debugForgetFrameScene();
    for (html.Node scene in html.document.querySelectorAll('flt-scene')) {
      scene.remove();
    }

    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  test('Convert Canvas to Picture', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture testPicture = await _drawTestPictureWithCircle(region);
    builder.addPicture(Offset.zero, testPicture);

    html.document.body.append(builder
        .build()
        .webOnlyRootElement);

    //await matchGoldenFile('canvas_to_picture.png', region: region, write: true);
  });
}

Picture _drawTestPictureWithCircle(Rect region) {
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas = recorder.beginRecording(region);
  canvas.drawOval(
      region,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Color(0xFF00FF00));
  return recorder.endRecording();
}
