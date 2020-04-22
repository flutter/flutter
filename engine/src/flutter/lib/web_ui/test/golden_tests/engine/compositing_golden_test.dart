// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import '../../matchers.dart';
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

  test('pushClipRect', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTRB(10, 10, 60, 60),
    );
    _drawTestPicture(builder);
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_shifted_clip_rect.png', region: region);
  });

  test('pushClipRect with offset and transform', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();

    builder.pushOffset(0, 60);
    builder.pushTransform(
      Matrix4.diagonal3Values(1, -1, 1).toFloat64(),
    );
    builder.pushClipRect(
      const Rect.fromLTRB(10, 10, 60, 60),
    );
    _drawTestPicture(builder);
    builder.pop();
    builder.pop();
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_clip_rect_with_offset_and_transform.png',
        region: region);
  });

  test('pushClipRRect', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRRect(
      RRect.fromLTRBR(10, 10, 60, 60, const Radius.circular(5)),
    );
    _drawTestPicture(builder);
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_shifted_clip_rrect.png', region: region);
  });

  test('pushPhysicalShape', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushPhysicalShape(
      path: Path()..addRect(const Rect.fromLTRB(10, 10, 60, 60)),
      clipBehavior: Clip.hardEdge,
      color: const Color.fromRGBO(0, 0, 0, 0.3),
      elevation: 0,
    );
    _drawTestPicture(builder);
    builder.pop();

    builder.pushOffset(70, 0);
    builder.pushPhysicalShape(
      path: Path()
        ..addRRect(RRect.fromLTRBR(10, 10, 60, 60, const Radius.circular(5))),
      clipBehavior: Clip.hardEdge,
      color: const Color.fromRGBO(0, 0, 0, 0.3),
      elevation: 0,
    );
    _drawTestPicture(builder);
    builder.pop();
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_shifted_physical_shape_clip.png',
        region: region);
  });

  test('pushImageFilter', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushImageFilter(
      ImageFilter.blur(sigmaX: 1, sigmaY: 3),
    );
    _drawTestPicture(builder);
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_image_filter.png', region: region);
  });

  group('Cull rect computation', () {
    _testCullRectComputation();
  });
}

void _testCullRectComputation() {
  // Draw a picture larger that screen. Verify that cull rect is equal to screen
  // bounds.
  test('fills screen bounds', () async {
    final SceneBuilder builder = SceneBuilder();
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          Offset.zero, 10000, Paint()..style = PaintingStyle.fill);
    });
    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(0, 0, 500, 100));
  }, skip: '''TODO(https://github.com/flutter/flutter/issues/40395)
  Needs ability to set iframe to 500,100 size. Current screen seems to be 500,500''');

  // Draw a picture that overflows the screen. Verify that cull rect is the
  // intersection of screen bounds and paint bounds.
  test('intersects with screen bounds', () async {
    final SceneBuilder builder = SceneBuilder();
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(Offset.zero, 20, Paint()..style = PaintingStyle.fill);
    });
    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(0, 0, 20, 20));
  });

  // Draw a picture that's fully outside the screen bounds. Verify the cull rect
  // is zero.
  test('fully outside screen bounds', () async {
    final SceneBuilder builder = SceneBuilder();
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          const Offset(-100, -100), 20, Paint()..style = PaintingStyle.fill);
    });
    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, Rect.zero);
    expect(picture.debugExactGlobalCullRect, Rect.zero);
  });

  // Draw a picture that's fully inside the screen. Verify that cull rect is
  // equal to the paint bounds.
  test('limits to paint bounds if no clip layers', () async {
    final SceneBuilder builder = SceneBuilder();
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          const Offset(50, 50), 10, Paint()..style = PaintingStyle.fill);
    });
    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(40, 40, 60, 60));
  });

  // Draw a picture smaller than the screen. Offset it such that it remains
  // fully inside the screen bounds. Verify that cull rect is still just the
  // paint bounds.
  test('offset does not affect paint bounds', () async {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(10, 10);
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          const Offset(50, 50), 10, Paint()..style = PaintingStyle.fill);
    });
    builder.pop();

    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(40, 40, 60, 60));
  });

  // Draw a picture smaller than the screen. Offset it such that the picture
  // overflows screen bounds. Verify that the cull rect is the intersection
  // between screen bounds and paint bounds.
  test('offset overflows paint bounds', () async {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 90);
    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(Offset.zero, 20, Paint()..style = PaintingStyle.fill);
    });
    builder.pop();

    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(
        picture.debugExactGlobalCullRect, const Rect.fromLTRB(0, 70, 20, 100));
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(0, -20, 20, 10));
  }, skip: '''TODO(https://github.com/flutter/flutter/issues/40395)
  Needs ability to set iframe to 500,100 size. Current screen seems to be 500,500''');

  // Draw a picture inside a layer clip but fill all available space inside it.
  // Verify that the cull rect is equal to the layer clip.
  test('fills layer clip rect', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTWH(10, 10, 60, 60),
    );

    builder.pushClipRect(
      const Rect.fromLTWH(40, 40, 60, 60),
    );

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          Offset.zero, 10000, Paint()..style = PaintingStyle.fill);
    });

    builder.pop(); // pushClipRect
    builder.pop(); // pushClipRect
    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_cull_rect_fills_layer_clip.png',
        region: region);

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(40, 40, 70, 70));
  });

  // Draw a picture inside a layer clip but position the picture such that its
  // paint bounds overflow the layer clip. Verify that the cull rect is the
  // intersection between the layer clip and paint bounds.
  test('intersects layer clip rect and paint bounds', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTWH(10, 10, 60, 60),
    );

    builder.pushClipRect(
      const Rect.fromLTWH(40, 40, 60, 60),
    );

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(
          const Offset(80, 55), 30, Paint()..style = PaintingStyle.fill);
    });

    builder.pop(); // pushClipRect
    builder.pop(); // pushClipRect
    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile(
        'compositing_cull_rect_intersects_clip_and_paint_bounds.png',
        region: region);

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, const Rect.fromLTRB(50, 40, 70, 70));
  });

  // Draw a picture inside a layer clip that's positioned inside the clip using
  // an offset layer. Verify that the cull rect is the intersection between the
  // layer clip and the offset paint bounds.
  test('offsets picture inside layer clip rect', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTWH(10, 10, 60, 60),
    );

    builder.pushClipRect(
      const Rect.fromLTWH(40, 40, 60, 60),
    );

    builder.pushOffset(55, 70);

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(Offset.zero, 20, Paint()..style = PaintingStyle.fill);
    });

    builder.pop(); // pushOffset
    builder.pop(); // pushClipRect
    builder.pop(); // pushClipRect
    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_cull_rect_offset_inside_layer_clip.png',
        region: region);

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect,
        const Rect.fromLTRB(-15.0, -20.0, 15.0, 0.0));
  });

  // Draw a picture inside a layer clip that's positioned an offset layer such
  // that the picture is push completely outside the clip area. Verify that the
  // cull rect is zero.
  test('zero intersection with clip', () async {
    final SceneBuilder builder = SceneBuilder();
    builder.pushClipRect(
      const Rect.fromLTWH(10, 10, 60, 60),
    );

    builder.pushClipRect(
      const Rect.fromLTWH(40, 40, 60, 60),
    );

    builder.pushOffset(100, 50);

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawCircle(Offset.zero, 20, Paint()..style = PaintingStyle.fill);
    });

    builder.pop(); // pushOffset
    builder.pop(); // pushClipRect
    builder.pop(); // pushClipRect

    builder.build();

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(picture.optimalLocalCullRect, Rect.zero);
    expect(picture.debugExactGlobalCullRect, Rect.zero);
  });

  // Draw a picture inside a rotated clip. Verify that the cull rect is big
  // enough to fit the rotated clip.
  test('rotates clip and the picture', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.pushOffset(80, 50);

    builder.pushTransform(
      Matrix4.rotationZ(-math.pi / 4).toFloat64(),
    );

    builder.pushClipRect(
      const Rect.fromLTRB(-10, -10, 10, 10),
    );

    builder.pushTransform(
      Matrix4.rotationZ(math.pi / 4).toFloat64(),
    );

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawPaint(Paint()
        ..color = const Color.fromRGBO(0, 0, 255, 0.6)
        ..style = PaintingStyle.fill);
      canvas.drawRect(
        const Rect.fromLTRB(-5, -5, 5, 5),
        Paint()
          ..color = const Color.fromRGBO(0, 255, 0, 1.0)
          ..style = PaintingStyle.fill,
      );
    });

    builder.pop(); // pushTransform
    builder.pop(); // pushClipRect
    builder.pop(); // pushTransform
    builder.pop(); // pushOffset
    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_cull_rect_rotated.png', region: region);

    final PersistedStandardPicture picture = enumeratePictures().single;
    expect(
      picture.optimalLocalCullRect,
      within(
          distance: 0.05, from: const Rect.fromLTRB(-14.1, -14.1, 14.1, 14.1)),
    );
  });

  test('pushClipPath', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Path path = Path();
    path..addRect(const Rect.fromLTRB(10, 10, 60, 60));
    builder.pushClipPath(
      path,
    );
    _drawTestPicture(builder);
    builder.pop();

    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_clip_path.png', region: region);
  });

  // Draw a picture inside a rotated clip. Verify that the cull rect is big
  // enough to fit the rotated clip.
  test('clips correctly when using 3d transforms', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();

    builder.pushTransform(Matrix4.diagonal3Values(
        EngineWindow.browserDevicePixelRatio,
        EngineWindow.browserDevicePixelRatio, 1.0).toFloat64());

    // TODO(yjbanov): see the TODO below.
    // final double screenWidth = html.window.innerWidth.toDouble();
    // final double screenHeight = html.window.innerHeight.toDouble();

    final Matrix4 scaleTransform = Matrix4.identity().scaled(0.5, 0.2);
    builder.pushTransform(
      scaleTransform.toFloat64(),
    );

    builder.pushOffset(400, 200);

    builder.pushClipRect(
      const Rect.fromLTRB(-200, -200, 200, 200),
    );

    builder.pushTransform(
      Matrix4.rotationY(45.0 * math.pi / 180.0).toFloat64()
    );

    builder.pushClipRect(
      const Rect.fromLTRB(-140, -140, 140, 140),
    );

    builder.pushTransform(Matrix4.translationValues(0, 0, -50).toFloat64());

    drawWithBitmapCanvas(builder, (RecordingCanvas canvas) {
      canvas.drawPaint(Paint()
        ..color = const Color.fromRGBO(0, 0, 255, 0.6)
        ..style = PaintingStyle.fill);
      // Rect will be clipped.
      canvas.drawRect(
        const Rect.fromLTRB(-150, -150, 150, 150),
        Paint()
          ..color = const Color.fromRGBO(0, 255, 0, 1.0)
          ..style = PaintingStyle.fill,
      );
      // Should be outside the clip range.
      canvas.drawRect(
        const Rect.fromLTRB(-150, -150, -140, -140),
        Paint()
          ..color = const Color.fromARGB(0xE0, 255, 0, 0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(140, -150, 150, -140),
        Paint()
          ..color = const Color.fromARGB(0xE0, 255, 0, 0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(-150, 140, -140, 150),
        Paint()
          ..color = const Color.fromARGB(0xE0, 255, 0, 0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(140, 140, 150, 150),
        Paint()
          ..color = const Color.fromARGB(0xE0, 255, 0, 0)
          ..style = PaintingStyle.fill,
      );
      // Should be inside clip range
      canvas.drawRect(
        const Rect.fromLTRB(-100, -100, -90, -90),
        Paint()
          ..color = const Color.fromARGB(0xE0, 0, 0, 0x80)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(90, -100, 100, -90),
        Paint()
          ..color = const Color.fromARGB(0xE0, 0, 0, 0x80)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(-100, 90, -90, 100),
        Paint()
          ..color = const Color.fromARGB(0xE0, 0, 0, 0x80)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTRB(90, 90, 100, 100),
        Paint()
          ..color = const Color.fromARGB(0xE0, 0, 0, 0x80)
          ..style = PaintingStyle.fill,
      );
    });

    builder.pop(); // pushTransform Z-50
    builder.pop(); // pushClipRect
    builder.pop(); // pushTransform 3D rotate
    builder.pop(); // pushClipRect
    builder.pop(); // pushOffset
    builder.pop(); // pushTransform scale
    builder.pop(); // pushTransform scale devicepixelratio
    html.document.body.append(builder.build().webOnlyRootElement);

    await matchGoldenFile('compositing_3d_rotate1.png', region: region);

    // ignore: unused_local_variable
    final PersistedStandardPicture picture = enumeratePictures().single;
    // TODO(https://github.com/flutter/flutter/issues/40395):
    //   Needs ability to set iframe to 500,100 size. Current screen seems to be 500,500.
    // expect(
    //   picture.optimalLocalCullRect,
    //   within(
    //       distance: 0.05,
    //       from: Rect.fromLTRB(
    //           -140, -140, screenWidth - 360.0, screenHeight + 40.0)),
    // );
  });

  // This test reproduces text blurriness when two pieces of text appear inside
  // two nested clips:
  //
  //   ┌───────────────────────┐
  //   │   text in outer clip  │
  //   │ ┌────────────────────┐│
  //   │ │ text in inner clip ││
  //   │ └────────────────────┘│
  //   └───────────────────────┘
  //
  // This test clips using layers. See a similar test in `canvas_golden_test.dart`,
  // which clips using canvas.
  //
  // More details: https://github.com/flutter/flutter/issues/32274
  test(
    'renders clipped text with high quality',
    () async {
      // To reproduce blurriness we need real clipping.
      debugShowClipLayers = false;
      final Paragraph paragraph =
          (ParagraphBuilder(ParagraphStyle(fontFamily: 'Roboto'))..addText('Am I blurry?')).build();
      paragraph.layout(const ParagraphConstraints(width: 1000));

      final Rect canvasSize = Rect.fromLTRB(
        0,
        0,
        paragraph.maxIntrinsicWidth + 16,
        2 * paragraph.height + 32,
      );
      final Rect outerClip =
          Rect.fromLTRB(0.5, 0.5, canvasSize.right, canvasSize.bottom);
      final Rect innerClip = Rect.fromLTRB(0.5, canvasSize.bottom / 2 + 0.5,
          canvasSize.right, canvasSize.bottom);
      final SurfaceSceneBuilder builder = SurfaceSceneBuilder();

      builder.pushClipRect(outerClip);

      {
        final EnginePictureRecorder recorder = PictureRecorder();
        final RecordingCanvas canvas = recorder.beginRecording(outerClip);
        canvas.drawParagraph(paragraph, const Offset(8.5, 8.5));
        final Picture picture = recorder.endRecording();
        expect(canvas.hasArbitraryPaint, false);

        builder.addPicture(
          Offset.zero,
          picture,
        );
      }

      builder.pushClipRect(innerClip);
      {
        final EnginePictureRecorder recorder = PictureRecorder();
        final RecordingCanvas canvas = recorder.beginRecording(innerClip);
        canvas.drawParagraph(paragraph, Offset(8.5, 8.5 + innerClip.top));
        final Picture picture = recorder.endRecording();
        expect(canvas.hasArbitraryPaint, false);

        builder.addPicture(
          Offset.zero,
          picture,
        );
      }
      builder.pop(); // inner clip
      builder.pop(); // outer clip

      final html.Element sceneElement = builder.build().webOnlyRootElement;
      expect(
        sceneElement.querySelectorAll('p').map<String>((e) => e.innerText).toList(),
        <String>['Am I blurry?', 'Am I blurry?'],
        reason: 'Expected to render text using HTML',
      );
      html.document.body.append(sceneElement);

      await matchGoldenFile(
        'compositing_draw_high_quality_text.png',
        region: canvasSize,
        maxDiffRatePercent: 0.0,
        pixelComparison: PixelComparison.precise,
      );
    },
    testOn: 'chrome',
  );
}

void _drawTestPicture(SceneBuilder builder) {
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas =
      recorder.beginRecording(const Rect.fromLTRB(0, 0, 100, 100));
  canvas.drawCircle(
      const Offset(10, 10), 10, Paint()..style = PaintingStyle.fill);
  canvas.drawCircle(
      const Offset(60, 10),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(255, 0, 0, 1));
  canvas.drawCircle(
      const Offset(10, 60),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 255, 0, 1));
  canvas.drawCircle(
      const Offset(60, 60),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 255, 1));
  final Picture picture = recorder.endRecording();

  builder.addPicture(
    Offset.zero,
    picture,
  );
}

typedef PaintCallback = void Function(RecordingCanvas canvas);

void drawWithBitmapCanvas(SceneBuilder builder, PaintCallback callback,
    {Rect bounds = Rect.largest}) {
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas = recorder.beginRecording(bounds);

  canvas.debugEnforceArbitraryPaint();
  callback(canvas);
  final Picture picture = recorder.endRecording();

  builder.addPicture(
    Offset.zero,
    picture,
  );
}
