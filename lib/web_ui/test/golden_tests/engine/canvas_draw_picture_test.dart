// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

final Rect region = Rect.fromLTWH(0, 0, 500, 100);

void main() async {
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

  test('draw growing picture across frames', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTRB(0, 0, 100, 100),
    );

    _drawTestPicture(builder, 100, false);
    builder.pop();

    html.Element elm1 = builder.build().webOnlyRootElement;
    html.document.body.append(elm1);

    // Now draw picture again but at larger size.
    final SurfaceSceneBuilder builder2 = SurfaceSceneBuilder();
    builder2.pushClipRect(
      const Rect.fromLTRB(0, 0, 100, 100),
    );
    // Now draw the picture at original target size, which will use a
    // different code path that should normally not have width/height set
    // on image element.
    _drawTestPicture(builder2, 20, false);
    builder2.pop();

    elm1.remove();
    html.document.body.append(builder2.build().webOnlyRootElement);

    await matchGoldenFile('canvas_draw_picture_acrossframes.png',
        region: region);
  });

  test('draw growing picture across frames clipped', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTRB(0, 0, 100, 100),
    );

    _drawTestPicture(builder, 100, true);
    builder.pop();

    html.Element elm1 = builder.build().webOnlyRootElement;
    html.document.body.append(elm1);

    // Now draw picture again but at larger size.
    final SurfaceSceneBuilder builder2 = SurfaceSceneBuilder();
    builder2.pushClipRect(
      const Rect.fromLTRB(0, 0, 100, 100),
    );
    _drawTestPicture(builder2, 20, true);
    builder2.pop();

    elm1.remove();
    html.document.body.append(builder2.build().webOnlyRootElement);

    await matchGoldenFile('canvas_draw_picture_acrossframes_clipped.png',
        region: region);
  });
}

HtmlImage sharedImage;

void _drawTestPicture(SceneBuilder builder, double targetSize, bool clipped) {
  sharedImage ??= _createRealTestImage();
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas =
      recorder.beginRecording(const Rect.fromLTRB(0, 0, 100, 100));
  canvas.debugEnforceArbitraryPaint();
  if (clipped) {
    canvas.clipRRect(
        RRect.fromLTRBR(0, 0, targetSize, targetSize, Radius.circular(4)));
  }
  canvas.drawImageRect(sharedImage, Rect.fromLTWH(0, 0, 20, 20),
      Rect.fromLTWH(0, 0, targetSize, targetSize), Paint());
  final Picture picture = recorder.endRecording();
  builder.addPicture(
    Offset.zero,
    picture,
  );
}

typedef PaintCallback = void Function(RecordingCanvas canvas);

const String _base64Encoded20x20TestImage =
    'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAAACXBIWXMAAC4jAAAuIwF4pT92AAAA'
    'B3RJTUUH5AMFFBksg4i3gQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAj'
    'SURBVDjLY2TAC/7jlWVioACMah4ZmhnxpyHG0QAb1UyZZgBjWAIm/clP0AAAAABJRU5ErkJggg==';

HtmlImage _createRealTestImage() {
  return HtmlImage(
    html.ImageElement()
      ..src = 'data:text/plain;base64,$_base64Encoded20x20TestImage',
    20,
    20,
  );
}
