// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' hide PhysicalShapeEngineLayer;
import 'package:ui/ui.dart';

import 'package:web_engine_tester/golden_tester.dart';

const Rect region = Rect.fromLTWH(0, 0, 500, 500);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpAll(() async {
    await webOnlyInitializePlatform();
    fontCollection.debugRegisterTestFonts();
    await fontCollection.ensureFontsLoaded();
  });

  setUp(() async {
    debugShowClipLayers = true;
    SurfaceSceneBuilder.debugForgetFrameScene();
    for (final DomNode scene in domDocument.querySelectorAll('flt-scene')) {
      scene.remove();
    }
  });

  test('Should apply color filter to image', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture backgroundPicture = _drawBackground();
    builder.addPicture(Offset.zero, backgroundPicture);
    builder.pushColorFilter(
        const EngineColorFilter.mode(Color(0xF0000080), BlendMode.color));
    final Picture circles1 = _drawTestPictureWithCircles(30, 30);
    builder.addPicture(Offset.zero, circles1);
    builder.pop();
    domDocument.body!.append(builder.build().webOnlyRootElement!);

    // TODO(ferhat): update golden for this test after canvas sandwich detection is
    // added to RecordingCanvas.
    await matchGoldenFile('color_filter_blendMode_color.png', region: region,
        maxDiffRatePercent: 12.0);
  });

  test('Should apply matrix color filter to image', () async {
    final List<double> colorMatrix = <double>[
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture backgroundPicture = _drawBackground();
    builder.addPicture(Offset.zero, backgroundPicture);
    builder.pushColorFilter(
        EngineColorFilter.matrix(colorMatrix));
    final Picture circles1 = _drawTestPictureWithCircles(30, 30);
    builder.addPicture(Offset.zero, circles1);
    builder.pop();
    domDocument.body!.append(builder.build().webOnlyRootElement!);
    await matchGoldenFile('color_filter_matrix.png', region: region,
        maxDiffRatePercent: 12.0);
  });

  /// Regression test for https://github.com/flutter/flutter/issues/85733
  test('Should apply mode color filter to circles', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture backgroundPicture = _drawBackground();
    builder.addPicture(Offset.zero, backgroundPicture);
    builder.pushColorFilter(
        const ColorFilter.mode(
          Color(0xFFFF0000),
          BlendMode.srcIn,
        ));
    final Picture circles1 = _drawTestPictureWithCircles(30, 30);
    builder.addPicture(Offset.zero, circles1);
    builder.pop();
    domDocument.body!.append(builder.build().webOnlyRootElement!);
    await matchGoldenFile('color_filter_mode.png', region: region,
        maxDiffRatePercent: 12.0);
  });

  /// Regression test for https://github.com/flutter/flutter/issues/59451.
  ///
  /// Picture with overlay blend inside a physical shape. Should show image
  /// at 0,0. In the filed issue it was leaving a gap on top.
  test('Should render image with color filter without gap', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0, 0, 400, 400), const Radius.circular(2)));
    final PhysicalShapeEngineLayer oldLayer = builder.pushPhysicalShape(
        path: path, color: const Color(0xFFFFFFFF), elevation: 0);
    final Picture circles1 = _drawTestPictureWithImage(
        const ColorFilter.mode(Color(0x3C4043), BlendMode.overlay));
    builder.addPicture(const Offset(10, 0), circles1);
    builder.pop();
    builder.build();

    final SurfaceSceneBuilder builder2 = SurfaceSceneBuilder();
    builder2.pushPhysicalShape(
        path: path, color: const Color(0xFFFFFFFF), elevation: 0, oldLayer: oldLayer);
    builder2.addPicture(const Offset(10, 0), circles1);
    builder2.pop();

    domDocument.body!.append(builder2.build().webOnlyRootElement!);

    await matchGoldenFile('color_filter_blendMode_overlay.png',
        region: region,
        maxDiffRatePercent: 12.0);
  });
}

Picture _drawTestPictureWithCircles(double offsetX, double offsetY) {
  final EnginePictureRecorder recorder =
      PictureRecorder() as EnginePictureRecorder;
  final RecordingCanvas canvas =
      recorder.beginRecording(const Rect.fromLTRB(0, 0, 400, 400));
  canvas.drawCircle(Offset(offsetX + 10, offsetY + 10), 10,
      (Paint()..style = PaintingStyle.fill) as SurfacePaint);
  canvas.drawCircle(
      Offset(offsetX + 60, offsetY + 10),
      10,
      (Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(255, 0, 0, 1)) as SurfacePaint);
  canvas.drawCircle(
      Offset(offsetX + 10, offsetY + 60),
      10,
      (Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 255, 0, 1)) as SurfacePaint);
  canvas.drawCircle(
      Offset(offsetX + 60, offsetY + 60),
      10,
      (Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 255, 1)) as SurfacePaint);
  return recorder.endRecording();
}

Picture _drawTestPictureWithImage(ColorFilter filter) {
  final EnginePictureRecorder recorder =
      PictureRecorder() as EnginePictureRecorder;
  final RecordingCanvas canvas =
      recorder.beginRecording(const Rect.fromLTRB(0, 0, 400, 400));
  final Image testImage = createTestImage();
  canvas.drawImageRect(
      testImage,
      const Rect.fromLTWH(0, 0, 200, 150),
      const Rect.fromLTWH(0, 0, 300, 300),
      (Paint()
        ..style = PaintingStyle.fill
        ..colorFilter = filter
        ..color = const Color.fromRGBO(0, 0, 255, 1)) as SurfacePaint);
  return recorder.endRecording();
}

Picture _drawBackground() {
  final EnginePictureRecorder recorder =
      PictureRecorder() as EnginePictureRecorder;
  final RecordingCanvas canvas =
      recorder.beginRecording(const Rect.fromLTRB(0, 0, 400, 400));
  canvas.drawRect(
      const Rect.fromLTWH(8, 8, 400.0 - 16, 400.0 - 16),
      (Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE0FFE0)) as SurfacePaint);
  return recorder.endRecording();
}

HtmlImage createTestImage({int width = 200, int height = 150}) {
  final DomCanvasElement canvas =
      createDomCanvasElement(width: width, height: height);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(width / 3, 0, width / 3, height);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(2 * width / 3, 0, width / 3, height);
  ctx.fill();
  final DomHTMLImageElement imageElement = createDomHTMLImageElement();
  imageElement.src = js_util.callMethod<String>(canvas, 'toDataURL', <dynamic>[]);
  return HtmlImage(imageElement, width, height);
}
