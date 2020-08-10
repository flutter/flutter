// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:js_util' as js_util;

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

import 'scuba.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
        double maxDiffRatePercent = 0.0}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png',
          region: region, maxDiffRatePercent: maxDiffRatePercent);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
  });

  setUpStableTestFonts();

  test('Paints image', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.drawImage(createTestImage(), Offset(0, 0), new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image');
  });

  test('Paints image with transform', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    rc.drawImage(createTestImage(), Offset(0, 0), new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_with_transform');
  });

  test('Paints image with transform and offset', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    rc.drawImage(createTestImage(), Offset(30, 20), new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_with_transform_and_offset');
  });

  test('Paints image with transform using destination', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 4.0);
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_rect_with_transform');
  });

  test('Paints image with source and destination', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(
        testImage,
        Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight),
        new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_rect_with_source');
  });

  test('Paints image with source and destination and round clip', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.save();
    rc.clipRRect(RRect.fromLTRBR(
        100, 30, 2 * testWidth, 2 * testHeight, Radius.circular(16)));
    rc.drawImageRect(
        testImage,
        Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight),
        new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_rect_with_source_and_clip');
  });

  test('Paints image with transform using source and destination', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    rc.translate(50.0, 100.0);
    rc.rotate(math.pi / 6.0);
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(
        testImage,
        Rect.fromLTRB(testWidth / 2, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight),
        new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_image_rect_with_transform_source');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image not below.
  test('Paints on top of image', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should below image not on top.
  test('Paints below image', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_below_image');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image with clip rect.
  test('Paints on top of image with clip rect', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.clipRect(Rect.fromLTRB(75, 75, 160, 160));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image_clip_rect');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image with clip rect and transform.
  test('Paints on top of image with clip rect with transform', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    // Rotate around center of circle.
    rc.translate(100, 100);
    rc.rotate(math.pi / 4.0);
    rc.translate(-100, -100);
    rc.clipRect(Rect.fromLTRB(75, 75, 160, 160));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image_clip_rect_with_transform');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image with stack of clip rect and transforms.
  test('Paints on top of image with clip rect with stack', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    // Rotate around center of circle.
    rc.translate(100, 100);
    rc.rotate(-math.pi / 4.0);
    rc.save();
    rc.translate(-100, -100);
    rc.clipRect(Rect.fromLTRB(75, 75, 160, 160));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), new Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image_clip_rect_with_stack');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image with clip rrect.
  test('Paints on top of image with clip rrect', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    rc.clipRRect(RRect.fromLTRBR(75, 75, 160, 160, Radius.circular(5)));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image_clip_rrect');
  });

  // Regression test for https://github.com/flutter/flutter/issues/44845
  // Circle should draw on top of image with clip rrect.
  test('Paints on top of image with clip path', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    final Path path = Path();
    // Triangle.
    path.moveTo(118, 57);
    path.lineTo(75, 160);
    path.lineTo(160, 160);
    rc.clipPath(path);
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 30, 2 * testWidth, 2 * testHeight), Paint());
    rc.drawCircle(
        Offset(100, 100),
        50.0,
        Paint()
          ..strokeWidth = 3
          ..color = Color.fromARGB(128, 0, 0, 0));
    rc.restore();
    await _checkScreenshot(rc, 'draw_circle_on_image_clip_path');
  });

  // Regression test for https://github.com/flutter/flutter/issues/53078
  // Verified that Text+Image+Text+Rect+Text composites correctly.
  // Yellow text should be behind image and rectangle.
  // Cyan text should be above everything.
  test('Paints text above and below image', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    rc.save();
    Image testImage = createTestImage();
    double testWidth = testImage.width.toDouble();
    double testHeight = testImage.height.toDouble();
    final Paragraph paragraph1 = createTestParagraph(
        'should be below...............',
        color: Color(0xFFFFFF40));
    paragraph1.layout(const ParagraphConstraints(width: 400.0));
    rc.drawParagraph(paragraph1, const Offset(20, 100));
    rc.drawImageRect(testImage, Rect.fromLTRB(0, 0, testWidth, testHeight),
        Rect.fromLTRB(100, 100, 200, 200), Paint());
    rc.drawRect(
        Rect.fromLTWH(50, 50, 100, 200),
        Paint()
          ..strokeWidth = 3
          ..color = Color(0xA0000000));
    final Paragraph paragraph2 = createTestParagraph(
        'Should be above...............',
        color: Color(0xFF00FFFF));
    paragraph2.layout(const ParagraphConstraints(width: 400.0));
    rc.drawParagraph(paragraph2, const Offset(20, 150));
    rc.restore();
    await _checkScreenshot(rc, 'draw_text_composite_order_below',
        maxDiffRatePercent: 1.0);
  });

  // Creates a picture
  test('Paints nine slice image', () async {
    Rect region = const Rect.fromLTWH(0, 0, 500, 500);
    EnginePictureRecorder recorder = EnginePictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    Image testImage = createNineSliceImage();
    canvas.clipRect(Rect.fromLTWH(0, 0,420, 200));
    canvas.drawImageNine(testImage, Rect.fromLTWH(20, 20, 20, 20),
        Rect.fromLTWH(20, 20, 400, 400), Paint());
    Picture picture = recorder.endRecording();

    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    builder.addPicture(Offset(0, 0), picture);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(builder.build().webOnlyRootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('draw_nine_slice.png',
          region: region, maxDiffRatePercent: 0);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/61691
  //
  // The bug in bitmap_canvas.dart was that when we transformed and clipped
  // the image we did not apply `transform-origin: 0 0 0` to the clipping
  // element which resulted in an undesirable offset.
  test('Paints clipped and transformed image', () async {
    final Rect region = const Rect.fromLTRB(0, 0, 60, 70);
    final RecordingCanvas canvas = RecordingCanvas(region);
    canvas.translate(10, 10);
    canvas.transform(Matrix4.rotationZ(0.4).storage);
    canvas.clipPath(Path()
      ..moveTo(10, 10)
      ..lineTo(50, 10)
      ..lineTo(50, 30)
      ..lineTo(10, 30)
      ..close()
    );
    canvas.drawImage(createNineSliceImage(), Offset.zero, Paint());
    await _checkScreenshot(canvas, 'draw_clipped_and_transformed_image', region: region,
        maxDiffRatePercent: 1.0);
  });
}

// 9 slice test image that has a shiny/glass look.
const String base64ImageData = 'data:image/png;base64,iVBORw0KGgoAAAANSUh'
    'EUgAAADwAAAA8CAYAAAA6/NlyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPo'
    'AAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAApGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQA'
    'AARoABQAAAAEAAABKARsABQAAAAEAAABSATEAAgAAACAAAABah2kABAAAAAEAAAB6AAAAAAAA'
    'AEgAAAABAAAASAAAAAFBZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpAAADoAEAAwAA'
    'AAEAAQAAoAIABAAAAAEAAAA8oAMABAAAAAEAAAA8AAAAAKgRPeEAAAAJcEhZcwAACxMAAAs'
    'TAQCanBgAAATqaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOn'
    'g9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA1LjQuMCI+CiAgIDxyZGY6Uk'
    'RGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW'
    '5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAg'
    'IHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgICA'
    'gICAgICB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1J'
    'lc291cmNlUmVmIyIKICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlL'
    'mNvbS9leGlmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2'
    'JlLmNvbS94YXAvMS4wLyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmF'
    'kb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8eG1wTU06SW5zdGFuY2VJRD54bXAua'
    'WlkOjMxRTc0MTc5ODQwQTExRUE5OEU4QUI4OTRCMjhDRUE3PC94bXBNTTpJbnN0YW5jZUl'
    'EPgogICAgICAgICA8eG1wTU06RG9jdW1lbnRJRD54bXAuZGlkOjMxRTc0MTdBODQwQTExR'
    'UE5OEU4QUI4OTRCMjhDRUE3PC94bXBNTTpEb2N1bWVudElEPgogICAgICAgICA8eG1wTU0'
    '6RGVyaXZlZEZyb20gcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICA8c'
    '3RSZWY6aW5zdGFuY2VJRD54bXAuZGlkOjAxODAxMTc0MDcyMDY4MTE4MjJBQUI1NDhBQTA'
    'zMDNBPC9zdFJlZjppbnN0YW5jZUlEPgogICAgICAgICAgICA8c3RSZWY6ZG9jdW1lbnRJR'
    'D54bXAuZGlkOjAxODAxMTc0MDcyMDY4MTE4MjJBQUI1NDhBQTAzMDNBPC9zdFJlZjpkb2N'
    '1bWVudElEPgogICAgICAgICA8L3htcE1NOkRlcml2ZWRGcm9tPgogICAgICAgICA8ZXhpZ'
    'jpQaXhlbFlEaW1lbnNpb24+NjA8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICAgICA8'
    'ZXhpZjpDb2xvclNwYWNlPjE8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl'
    '4ZWxYRGltZW5zaW9uPjYwPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPHhtcD'
    'pDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3Jl'
    'YXRvclRvb2w+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YX'
    'Rpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZ'
    'XRhPgpq1fpCAAAUDUlEQVRoBd1beYxd11n/3fvu2+fNm9VbPB6PHS+ldt0kNKWJk0YkaVJS'
    'UtRQhFCqSggRCVWgSKUKEgi1FNSKlvIH/1dVoWqatBKkUYqgAVRaNSTN0jg2buIkE4/XmbF'
    'ne/O2u/D7ffedN2/GM9hJCRAf+76z3LN8+/nuOd94jUYjwRWmJFnp6nkeVI+jCJ7vw+Mc9l'
    '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'
    '7T81zbIITGpJk9OwtIVbZ'
    '/dNp0M3036d0iP91QvNopo9Ukg3P8v2wWAv6CuXaIz4TR9OMoaaXtXYZx7EjusY7FIYRJkI'
    'Z/XBQJV1qYuwsZsvyuU+9FWXMRBuw+77fwuvV4ex8O1vGY4Bg1kUkp8wfkLy7dH39hW84hE'
    'KKrhCfB2atgDFz074VaFYbpgkMcJI/V1im7Z4kyb9rQPjtuRTh5QoT1sMjVDCLTVcpN/w2qt'
    'kvI+df/QQdrz/RnJ2AGXaozIZmMsytkvi3Jm3i7omli6X+PU0PDBkccnJNWMIPn4fzk3swpn'
    'vfRf1I0eM4hokAvtFXqLn6aRkeDhGZ0VzWFwIraVO/HVzJ7ETB21AZ9G1meGr+WR9mDS3mC'
    'pLpQhbyi2LJDJvDqKFOkMw0vsw9VaYUumee3HNbb/M6NkJDPDIapB/DzHAs7oU2RWZ05Tda'
    'Fr3nRuRS8u8YJtnZMDsLAPReJ1aUxzI1CnMv/o65l9/A0tnX0Vy/gKi4ycMOIePANAjgJ'
    'cu8pO9VTWe0dxV1/bpnb10TjldirDPO4roHDttciMbEFpxziqu8YxvHMC5aFhcpTMoqEaH'
    'BxEf9+KsZLBcqmLsBqEtE4JZN6XGZi2xNjKixcY9sNQgTrDl5o892rTMLQajHHk+5CE8di'
    'fDKCVVXgvDwLptJiOcT7N5XTXglLdqmtQ1l+h6EqTYmFjJR0KZc5QlBWhY5F5BjP70bgqnD'
    'nPHSVH9zHPrbNEH6LET0HZn37+xUu5xG8DSqp0V7D0ItwVacEikdSjjjJgoqwuGvXNXGOg'
    'Z2x0yEXi0PeqFO87AiFGCkemvOKYkSF/6yS1vnLOWTaHN/VcmnSWt0eHThELBHBiCGisGra'
    'SI5l6R3qD0q05ZR4TNVHES7bnltEgcg6JF3uVlyFsBpdB+lzgdRTMHeejneZR0H1BrnKECH'
    '7GyVy1BAmcsr17WxYs78QNqQF4bppFXqX9BBqIrzmcExwueASjAFzlaWncpqEpJCXVc7wv'
    'Nj7eT/BbztCaofk+k0AAAAAElFTkSuQmCC';

HtmlImage createNineSliceImage() {
  return HtmlImage(
    html.ImageElement()
      ..src = base64ImageData,
    60,
    60,
  );
}


HtmlImage createTestImage({int width = 100, int height = 50}) {
  html.CanvasElement canvas =
      new html.CanvasElement(width: width, height: height);
  html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#E04040';
  ctx.fillRect(0, 0, 33, 50);
  ctx.fill();
  ctx.fillStyle = '#40E080';
  ctx.fillRect(33, 0, 33, 50);
  ctx.fill();
  ctx.fillStyle = '#2040E0';
  ctx.fillRect(66, 0, 33, 50);
  ctx.fill();
  html.ImageElement imageElement = html.ImageElement();
  imageElement.src = js_util.callMethod(canvas, 'toDataURL', <dynamic>[]);
  return HtmlImage(imageElement, width, height);
}

Paragraph createTestParagraph(String text,
    {Color color = const Color(0xFF000000)}) {
  final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
    fontFamily: 'Ahem',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  ));
  builder.pushStyle(TextStyle(color: color));
  builder.addText(text);
  return builder.build();
}
