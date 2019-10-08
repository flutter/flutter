// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import '../../matchers.dart';
import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);
  final Paint testPaint = Paint()..color = const Color(0xFFFF0000);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      { Rect region = const Rect.fromLTWH(0, 0, 500, 500) }) async {

    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);

    // Draws the estimated bounds so we can spot the bug in Scuba.
    engineCanvas
      ..save()
      ..drawRect(
        rc.computePaintBounds(),
        PaintData()
          ..color = const Color.fromRGBO(0, 0, 255, 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      )
      ..restore();

    rc.apply(engineCanvas);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('paint_bounds_for_$fileName.png', region: region);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  test('Empty canvas reports correct paint bounds', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTWH(1, 2, 300, 400));
    expect(rc.computePaintBounds(), Rect.zero);
    await _checkScreenshot(rc, 'empty_canvas');
  });

  test('Computes paint bounds for draw line', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawLine(const Offset(50, 100), const Offset(120, 140), testPaint);
    // The off by one is due to the minimum stroke width of 1.
    expect(rc.computePaintBounds(), const Rect.fromLTRB(49, 99, 121, 141));
    await _checkScreenshot(rc, 'draw_line');
  });

  test('Computes paint bounds for draw line when line exceeds limits',
      () async {
    // Uses max bounds when computing paint bounds
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawLine(const Offset(50, 100), const Offset(screenWidth + 100.0, 140),
        testPaint);
    // The off by one is due to the minimum stroke width of 1.
    expect(rc.computePaintBounds(),
        const Rect.fromLTRB(49.0, 99.0, screenWidth, 141.0));
    await _checkScreenshot(rc, 'draw_line_exceeding_limits');
  });

  test('Computes paint bounds for draw rect', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(10, 20, 30, 40));
    await _checkScreenshot(rc, 'draw_rect');
  });

  test('Computes paint bounds for draw rect when exceeds limits', () async {
    // Uses max bounds when computing paint bounds
    RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawRect(
        const Rect.fromLTRB(10, 20, 30 + screenWidth, 40 + screenHeight),
        testPaint);
    expect(rc.computePaintBounds(),
        const Rect.fromLTRB(10, 20, screenWidth, screenHeight));

    rc = RecordingCanvas(screenRect);
    rc.drawRect(const Rect.fromLTRB(-200, -100, 30, 40), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(0, 0, 30, 40));
    await _checkScreenshot(rc, 'draw_rect_exceeding_limits');
  });

  test('Computes paint bounds for translate', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.translate(5, 7);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(15, 27, 35, 47));
    await _checkScreenshot(rc, 'translate');
  });

  test('Computes paint bounds for scale', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.scale(2, 2);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(20, 40, 60, 80));
    await _checkScreenshot(rc, 'scale');
  });

  test('Computes paint bounds for rotate', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.rotate(math.pi / 4.0);
    rc.drawLine(
        const Offset(1, 0), Offset(50 * math.sqrt(2) - 1, 0), testPaint);
    // The extra 0.7 is due to stroke width of 1 rotated by 45 degrees.
    expect(rc.computePaintBounds(),
        within(distance: 0.1, from: const Rect.fromLTRB(0, 0, 50.7, 50.7)));
    await _checkScreenshot(rc, 'rotate');
  });

  test('Computes paint bounds for horizontal skew', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.skew(1.0, 0.0);
    rc.drawRect(const Rect.fromLTRB(20, 20, 40, 40), testPaint);
    expect(
        rc.computePaintBounds(),
        within(
            distance: 0.1, from: const Rect.fromLTRB(40.0, 20.0, 80.0, 40.0)));
    await _checkScreenshot(rc, 'skew_horizontally');
  });

  test('Computes paint bounds for vertical skew', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.skew(0.0, 1.0);
    rc.drawRect(const Rect.fromLTRB(20, 20, 40, 40), testPaint);
    expect(
        rc.computePaintBounds(),
        within(
            distance: 0.1, from: const Rect.fromLTRB(20.0, 40.0, 40.0, 80.0)));
    await _checkScreenshot(rc, 'skew_vertically');
  });

  test('Computes paint bounds for a complex transform', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    final Float64List matrix = Float64List(16);
    // translate(210, 220) , scale(2, 3), rotate(math.pi / 4.0)
    matrix[0] = 1.4;
    matrix[1] = 2.12;
    matrix[2] = 0.0;
    matrix[3] = 0.0;
    matrix[4] = -1.4;
    matrix[5] = 2.12;
    matrix[6] = 0.0;
    matrix[7] = 0.0;
    matrix[8] = 0.0;
    matrix[9] = 0.0;
    matrix[10] = 2.0;
    matrix[11] = 0.0;
    matrix[12] = 210.0;
    matrix[13] = 220.0;
    matrix[14] = 0.0;
    matrix[15] = 1.0;
    rc.transform(matrix);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(),
        const Rect.fromLTRB(168.0, 283.6, 224.0, 368.4));
    await _checkScreenshot(rc, 'complex_transform');
  });

  test('drawPaint should cover full size', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawPaint(testPaint);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), screenRect);
    await _checkScreenshot(rc, 'draw_paint');
  });

  test('drawColor should cover full size', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawColor(const Color(0xFFFF0000), BlendMode.multiply);
    rc.drawRect(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), screenRect);
    await _checkScreenshot(rc, 'draw_color');
  });

  test('Computes paint bounds for draw oval', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawOval(const Rect.fromLTRB(10, 20, 30, 40), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(10, 20, 30, 40));
    await _checkScreenshot(rc, 'draw_oval');
  });

  test('Computes paint bounds for draw round rect', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTRB(10, 20, 30, 40), const Radius.circular(5.0)),
        testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(10, 20, 30, 40));
    await _checkScreenshot(rc, 'draw_round_rect');
  });

  test(
      'Computes empty paint bounds when inner rect outside of outer rect for '
      'drawDRRect', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawDRRect(RRect.fromRectAndCorners(const Rect.fromLTRB(10, 20, 30, 40)),
        RRect.fromRectAndCorners(const Rect.fromLTRB(1, 2, 3, 4)), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(0, 0, 0, 0));
    await _checkScreenshot(rc, 'draw_drrect_empty');
  });

  test('Computes paint bounds using outer rect for drawDRRect', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawDRRect(
        RRect.fromRectAndCorners(const Rect.fromLTRB(10, 20, 30, 40)),
        RRect.fromRectAndCorners(const Rect.fromLTRB(12, 22, 28, 38)),
        testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(10, 20, 30, 40));
    await _checkScreenshot(rc, 'draw_drrect');
  });

  test('Computes paint bounds for draw circle', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawCircle(const Offset(20, 20), 10.0, testPaint);
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(10.0, 10.0, 30.0, 30.0));
    rc.drawCircle(const Offset(200, 300), 100.0, testPaint);
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(10.0, 10.0, 300.0, 400.0));
    await _checkScreenshot(rc, 'draw_circle');
  });

  test('Computes paint bounds for draw image', () {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawImage(TestImage(), const Offset(50, 100), Paint());
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(50.0, 100.0, 70.0, 110.0));
  });

  test('Computes paint bounds for draw image rect', () {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.drawImageRect(TestImage(), const Rect.fromLTRB(1, 1, 20, 10),
        const Rect.fromLTRB(5, 6, 400, 500), Paint());
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(5.0, 6.0, 400.0, 500.0));
  });

  test('Computes paint bounds for single-line draw paragraph', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    final Paragraph paragraph = createTestParagraph();
    const double textLeft = 5.0;
    const double textTop = 7.0;
    const double widthConstraint = 300.0;
    paragraph.layout(const ParagraphConstraints(width: widthConstraint));
    rc.drawParagraph(paragraph, const Offset(textLeft, textTop));
    expect(
      rc.computePaintBounds(),
      const Rect.fromLTRB(textLeft, textTop, textLeft + widthConstraint, 21.0),
    );
    await _checkScreenshot(rc, 'draw_paragraph');
  });

  test('Computes paint bounds for multi-line draw paragraph', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    final Paragraph paragraph = createTestParagraph();
    const double textLeft = 5.0;
    const double textTop = 7.0;
    const double widthConstraint =
        130.0; // do not go lower than the shortest word.
    paragraph.layout(const ParagraphConstraints(width: widthConstraint));
    rc.drawParagraph(paragraph, const Offset(textLeft, textTop));
    expect(
      rc.computePaintBounds(),
      const Rect.fromLTRB(textLeft, textTop, textLeft + widthConstraint, 35.0),
    );
    await _checkScreenshot(rc, 'draw_paragraph_multi_line');
  });

  test('Should exclude painting outside simple clipRect', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.clipRect(const Rect.fromLTRB(50, 50, 100, 100));
    rc.drawLine(const Offset(10, 11), const Offset(20, 21), testPaint);

    expect(rc.computePaintBounds(), Rect.zero);
    rc.drawLine(const Offset(52, 53), const Offset(55, 56), testPaint);

    // Extra pixel due to default line length
    expect(rc.computePaintBounds(), const Rect.fromLTRB(51, 52, 56, 57));
    await _checkScreenshot(rc, 'clip_rect_simple');
  });

  test('Should include intersection of clipRect and painting', () async {
    RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.clipRect(const Rect.fromLTRB(50, 50, 100, 100));
    rc.drawRect(const Rect.fromLTRB(20, 60, 120, 70), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(50, 60, 100, 70));
    await _checkScreenshot(rc, 'clip_rect_intersects_paint_left_to_right');

    rc = RecordingCanvas(screenRect);
    rc.clipRect(const Rect.fromLTRB(50, 50, 100, 100));
    rc.drawRect(const Rect.fromLTRB(60, 20, 70, 200), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(60, 50, 70, 100));
    await _checkScreenshot(rc, 'clip_rect_intersects_paint_top_to_bottom');
  });

  test('Should intersect rects for multiple clipRect calls', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    rc.clipRect(const Rect.fromLTRB(50, 50, 100, 100));
    rc.scale(2.0, 2.0);
    rc.clipRect(const Rect.fromLTRB(30, 30, 45, 45));
    rc.drawRect(const Rect.fromLTRB(10, 30, 60, 35), testPaint);
    expect(rc.computePaintBounds(), const Rect.fromLTRB(60, 60, 90, 70));
    await _checkScreenshot(rc, 'clip_rects_intersect');
  });

  // drawShadow
  test('Computes paint bounds for drawShadow', () async {
    final RecordingCanvas rc = RecordingCanvas(screenRect);
    final Path path = Path();
    path.addRect(const Rect.fromLTRB(20, 30, 100, 110));
    rc.drawShadow(path, const Color(0xFFFF0000), 2.0, true);
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(15.0, 27.0, 106.0, 117.0));
    await _checkScreenshot(rc, 'path_with_shadow');
  });

  test('Clip with negative scale reports correct paint bounds', () async {
    // The following draws a filled rectangle that occupies the bottom half of
    // the canvas. Notice that both the clip and the rectangle are drawn
    // forward. What makes them appear at the bottom is the translation and a
    // vertical flip via a negative scale. This replicates the Material
    // overscroll glow effect at the bottom of a list, where it is drawn upside
    // down.
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 100, 100));
    rc
      ..translate(0, 100)
      ..scale(1, -1)
      ..clipRect(const Rect.fromLTRB(0, 0, 100, 50))
      ..drawRect(const Rect.fromLTRB(0, 0, 100, 100), Paint());
    expect(
        rc.computePaintBounds(), const Rect.fromLTRB(0.0, 50.0, 100.0, 100.0));
    await _checkScreenshot(rc, 'scale_negative');
  });

  test('Clip with a rotation reports correct paint bounds', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 100, 100));
    rc
      ..translate(50, 50)
      ..rotate(math.pi / 4.0)
      ..clipRect(const Rect.fromLTWH(-20, -20, 40, 40))
      ..drawRect(const Rect.fromLTWH(-80, -80, 160, 160), Paint());
    expect(
      rc.computePaintBounds(),
      Rect.fromCircle(center: const Offset(50, 50), radius: 20 * math.sqrt(2)),
    );
    await _checkScreenshot(rc, 'clip_rect_rotated');
  });

  test('Rotated line reports correct paint bounds', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 100, 100));
    rc
      ..translate(50, 50)
      ..rotate(math.pi / 4.0)
      ..drawLine(const Offset(0, 0), const Offset(20, 20), Paint());
    expect(
      rc.computePaintBounds(),
      within(distance: 0.1, from: const Rect.fromLTRB(34.4, 48.6, 65.6, 79.7)),
    );
    await _checkScreenshot(rc, 'line_rotated');
  });

  test('Should support reusing path and reset when drawing into canvas.',
      () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 100, 100));

    final Path path = Path();
    path.moveTo(3, 0);
    path.lineTo(100, 97);
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFFFF0000));
    path.reset();
    path.moveTo(0, 3);
    path.lineTo(97, 100);
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF00FF00));
    await _checkScreenshot(rc, 'reuse_path');
  });

  test('Should draw RRect after line when beginning new path.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 200, 400));
    rc.save();
    rc.translate(50.0, 100.0);
    final Path path = Path();
    // Draw a vertical small line (caret).
    path.moveTo(8, 4);
    path.lineTo(8, 24);
    // Draw round rect below caret.
    path.addRRect(
        RRect.fromLTRBR(0.5, 100.5, 80.7, 150.7, const Radius.circular(10)));
    rc.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF404000));
    await _checkScreenshot(rc, 'path_with_line_and_roundrect');
  });
}

class TestImage implements Image {
  @override
  int get width => 20;

  @override
  int get height => 10;

  @override
  Future<ByteData> toByteData(
      {ImageByteFormat format = ImageByteFormat.rawRgba}) async {
    throw UnsupportedError('Cannot encode test image');
  }

  @override
  String toString() => '[$width\u00D7$height]';

  @override
  void dispose() {}
}

Paragraph createTestParagraph() {
  final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
    fontFamily: 'Ahem',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  ));
  builder.addText('A short sentence.');
  return builder.build();
}
