// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart'
    hide ClipRectEngineLayer, BackdropFilterEngineLayer;

import 'package:web_engine_tester/golden_tester.dart';

/// To debug compositing failures on browsers, set this flag to true and run
/// flutter run -d chrome --web-renderer=html
///        test/golden_tests/engine/shader_mask_golden_test.dart --profile
const bool debugTest = false;

void main() async {
  if (!debugTest) {
    internalBootstrapBrowserTest(() => testMain);
  } else {
    _renderScene(BlendMode.color);
  }
}

/// TODO: unskip webkit tests once flakiness is resolved. See
/// https://github.com/flutter/flutter/issues/76713
bool get isWebkit => browserEngine == BrowserEngine.webkit;

void testMain() async {
  setUp(() async {
    debugShowClipLayers = true;
    SurfaceSceneBuilder.debugForgetFrameScene();
    for (html.Node scene in html.document.querySelectorAll('flt-scene')) {
      scene.remove();
    }
    initWebGl();
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  /// Should render the picture unmodified.
  test('Renders shader mask with linear gradient BlendMode dst', () async {
    _renderScene(BlendMode.dst);
    await matchGoldenFile('shadermask_linear_dst.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  /// Should render the gradient only where circles have alpha channel.
  test('Renders shader mask with linear gradient BlendMode srcIn', () async {
    _renderScene(BlendMode.srcIn);
    await matchGoldenFile('shadermask_linear_srcin.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  test('Renders shader mask with linear gradient BlendMode color', () async {
    _renderScene(BlendMode.color);
    await matchGoldenFile('shadermask_linear_color.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  test('Renders shader mask with linear gradient BlendMode xor', () async {
    _renderScene(BlendMode.xor);
    await matchGoldenFile('shadermask_linear_xor.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  test('Renders shader mask with linear gradient BlendMode plus', () async {
    _renderScene(BlendMode.plus);
    await matchGoldenFile('shadermask_linear_plus.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  test('Renders shader mask with linear gradient BlendMode modulate', () async {
    _renderScene(BlendMode.modulate);
    await matchGoldenFile('shadermask_linear_modulate.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  test('Renders shader mask with linear gradient BlendMode overlay', () async {
    _renderScene(BlendMode.overlay);
    await matchGoldenFile('shadermask_linear_overlay.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);

  /// Should render the gradient opaque on top of content.
  test('Renders shader mask with linear gradient BlendMode src', () async {
    _renderScene(BlendMode.src);
    await matchGoldenFile('shadermask_linear_src.png',
        region: Rect.fromLTWH(0, 0, 360, 200));
  }, skip: isWebkit);
}

Picture _drawTestPictureWithCircles(
    Rect region, double offsetX, double offsetY) {
  final EnginePictureRecorder recorder = EnginePictureRecorder();
  final RecordingCanvas canvas = recorder.beginRecording(region);
  canvas.drawCircle(Offset(offsetX + 30, offsetY + 30), 30,
      SurfacePaint()..style = PaintingStyle.fill);
  canvas.drawCircle(
      Offset(offsetX + 110, offsetY + 30),
      30,
      SurfacePaint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF0000));
  canvas.drawCircle(
      Offset(offsetX + 30, offsetY + 110),
      30,
      SurfacePaint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF00FF00));
  canvas.drawCircle(
      Offset(offsetX + 110, offsetY + 110),
      30,
      SurfacePaint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0000FF));
  return recorder.endRecording();
}

void _renderScene(BlendMode blendMode) {
  final Rect region = Rect.fromLTWH(0, 0, 400, 400);

  final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
  final Picture circles1 = _drawTestPictureWithCircles(region, 10, 10);
  builder.addPicture(Offset.zero, circles1);

  List<Color> colors = <Color>[
    Color(0xFF000000),
    Color(0xFFFF3C38),
    Color(0xFFFF8C42),
    Color(0xFFFFF275),
    Color(0xFF6699CC),
    Color(0xFF656D78),
  ];
  List<double> stops = <double>[0.0, 0.05, 0.4, 0.6, 0.9, 1.0];

  EngineGradient shader = GradientLinear(Offset(200, 30), Offset(320, 150),
      colors, stops, TileMode.clamp, Matrix4.identity().storage);

  builder.pushShaderMask(shader, Rect.fromLTWH(180, 10, 140, 140), blendMode,
      oldLayer: null);
  final Picture circles2 = _drawTestPictureWithCircles(region, 180, 10);
  builder.addPicture(Offset.zero, circles2);
  builder.pop();

  html.document.body!.append(builder.build().webOnlyRootElement!);
}
