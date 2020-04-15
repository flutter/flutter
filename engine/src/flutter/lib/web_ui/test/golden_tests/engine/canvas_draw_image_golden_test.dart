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
