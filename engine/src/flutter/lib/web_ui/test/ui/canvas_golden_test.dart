// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = ui.Rect.fromLTRB(0, 0, 500, 250);

void testMain() {
  group('Canvas', () {
    setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

    setUp(() {
      renderer.fontCollection.debugResetFallbackFonts();
    });

    test('renders using non-recording canvas if weak refs are supported', () async {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, kDefaultRegion);
      expect(canvas, isA<LayerCanvas>());
      await drawTestPicture(canvas as LayerCanvas);
      await drawPictureUsingCurrentRenderer(recorder.endRecording());
      await matchGoldenFile('ui_weakref_picture.png', region: kDefaultRegion);
      // Unskip when Skwasm and CanvasKit are unified:
      // https://github.com/flutter/flutter/issues/172311
    }, skip: isSkwasm);

    test('text style - foreground/background/color do not leak across paragraphs', () async {
      const double testWidth = 440;
      const double middle = testWidth / 2;
      ui.Paragraph createTestParagraph({
        ui.Color? color,
        ui.Paint? foreground,
        ui.Paint? background,
      }) {
        final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle());
        builder.pushStyle(
          ui.TextStyle(fontSize: 16, color: color, foreground: foreground, background: background),
        );
        final StringBuffer text = StringBuffer();
        if (color == null && foreground == null && background == null) {
          text.write('Default');
        } else {
          if (color != null) {
            text.write('Color');
          }
          if (foreground != null) {
            if (text.isNotEmpty) {
              text.write('+');
            }
            text.write('Foreground');
          }
          if (background != null) {
            if (text.isNotEmpty) {
              text.write('+');
            }
            text.write('Background');
          }
        }
        builder.addText(text.toString());
        final ui.Paragraph paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: testWidth));
        return paragraph;
      }

      final List<ParagraphFactory> variations = <ParagraphFactory>[
        () => createTestParagraph(),
        () => createTestParagraph(color: const ui.Color(0xFF009900)),
        () => createTestParagraph(foreground: ui.Paint()..color = const ui.Color(0xFF990000)),
        () => createTestParagraph(background: ui.Paint()..color = const ui.Color(0xFF7777FF)),
        () => createTestParagraph(
          color: const ui.Color(0xFFFF00FF),
          background: ui.Paint()..color = const ui.Color(0xFF0000FF),
        ),
        () => createTestParagraph(
          foreground: ui.Paint()..color = const ui.Color(0xFF00FFFF),
          background: ui.Paint()..color = const ui.Color(0xFF0000FF),
        ),
      ];

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.largest);
      canvas.translate(10, 10);

      for (final ParagraphFactory from in variations) {
        for (final ParagraphFactory to in variations) {
          canvas.save();
          final ui.Paragraph fromParagraph = from();
          canvas.drawParagraph(fromParagraph, ui.Offset.zero);

          final ui.Offset leftEnd = ui.Offset(
            fromParagraph.maxIntrinsicWidth + 10,
            fromParagraph.height / 2,
          );
          final ui.Offset rightEnd = ui.Offset(middle - 10, leftEnd.dy);
          const ui.Offset tipOffset = ui.Offset(-5, -5);
          canvas.drawLine(leftEnd, rightEnd, ui.Paint());
          canvas.drawLine(rightEnd, rightEnd + tipOffset, ui.Paint());
          canvas.drawLine(rightEnd, rightEnd + tipOffset.scale(1, -1), ui.Paint());

          canvas.translate(middle, 0);
          canvas.drawParagraph(to(), ui.Offset.zero);
          canvas.restore();
          canvas.translate(0, 22);
        }
      }

      final ui.Picture picture = recorder.endRecording();
      await drawPictureUsingCurrentRenderer(picture);

      await matchGoldenFile(
        'ui_text_styles_do_not_leak.png',
        region: const ui.Rect.fromLTRB(0, 0, testWidth, 850),
      );
    });

    // Make sure we clear the canvas in between frames.
    test('empty frame after contentful frame', () async {
      // First draw a frame with a red rectangle
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.largest);
      canvas.drawRect(
        const ui.Rect.fromLTRB(20, 20, 100, 100),
        ui.Paint()..color = const ui.Color(0xffff0000),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      builder.addPicture(ui.Offset.zero, picture);
      final ui.Scene scene = builder.build();
      await renderScene(scene);

      // Now draw an empty layer tree and confirm that the red rectangle is
      // no longer drawn.
      final ui.SceneBuilder emptySceneBuilder = ui.SceneBuilder();
      emptySceneBuilder.pushOffset(0, 0);
      final ui.Scene emptyScene = emptySceneBuilder.build();
      await renderScene(emptyScene);

      await matchGoldenFile('ui_empty_scene.png', region: const ui.Rect.fromLTRB(0, 0, 100, 100));
    });

    // Regression test for https://github.com/flutter/flutter/issues/121758
    test(
      'resources used in temporary surfaces for Image.toByteData can cross to rendering overlays',
      () async {
        ui_web.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (int viewId) => createDomHTMLDivElement()..id = 'view-0',
        );
        await createPlatformView(0, 'test-platform-view');

        ui.Picture makeTextPicture(String text, ui.Offset offset) {
          final ui.PictureRecorder recorder = ui.PictureRecorder();
          final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.largest);
          final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle());
          builder.addText(text);
          final ui.Paragraph paragraph = builder.build();
          paragraph.layout(const ui.ParagraphConstraints(width: 100));
          canvas.drawRect(
            ui.Rect.fromLTWH(offset.dx, offset.dy, paragraph.width, paragraph.height).inflate(10),
            ui.Paint()..color = const ui.Color(0xFF00FF00),
          );
          canvas.drawParagraph(paragraph, offset);
          return recorder.endRecording();
        }

        ui.Picture imageToPicture(ui.Image image, ui.Offset offset) {
          final ui.PictureRecorder recorder = ui.PictureRecorder();
          final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.largest);
          canvas.drawImage(image, offset, ui.Paint());
          return recorder.endRecording();
        }

        final ui.Picture helloPicture = makeTextPicture('Hello', ui.Offset.zero);

        final ui.Image helloImage = helloPicture.toImageSync(100, 100);

        // Calling toByteData is essential to hit the bug.
        await helloImage.toByteData(format: ui.ImageByteFormat.png);

        final ui.SceneBuilder sb = ui.SceneBuilder();
        sb.pushOffset(0, 0);
        sb.addPicture(ui.Offset.zero, helloPicture);
        sb.addPlatformView(0, width: 10, height: 10);

        // The image is rendered after the platform view so that it's rendered into
        // a separate surface, which is what triggers the bug. If the bug is present
        // the image will not appear on the UI.
        sb.addPicture(const ui.Offset(0, 50), imageToPicture(helloImage, ui.Offset.zero));
        sb.pop();

        await renderScene(sb.build());

        // The below line should not throw an error.
        await matchGoldenFile(
          'cross_overlay_resources.png',
          region: const ui.Rect.fromLTRB(0, 0, 100, 100),
        );
      },
    );
  });
}

typedef ParagraphFactory = ui.Paragraph Function();

Future<void> drawTestPicture(LayerCanvas canvas) async {
  canvas.clear(const ui.Color(0xFFFFFFF));

  canvas.translate(10, 10);

  // Row 1
  canvas.save();

  canvas.save();
  canvas.clipRect(const ui.Rect.fromLTRB(0, 0, 45, 45));
  canvas.clipRRect(ui.RRect.fromLTRBR(5, 5, 50, 50, const ui.Radius.circular(8)));
  canvas.clipPath(
    ui.Path()
      ..moveTo(5, 5)
      ..lineTo(25, 5)
      ..lineTo(45, 45)
      ..lineTo(5, 45)
      ..close(),
  );
  canvas.drawColor(const ui.Color.fromARGB(255, 100, 100, 0), ui.BlendMode.srcOver);
  canvas.restore(); // remove clips

  canvas.translate(60, 0);
  canvas.drawCircle(const ui.Offset(30, 25), 15, ui.Paint()..color = const ui.Color(0xFF0000AA));

  canvas.translate(60, 0);
  canvas.drawArc(
    const ui.Rect.fromLTRB(10, 20, 50, 40),
    math.pi / 4,
    3 * math.pi / 2,
    true,
    ui.Paint()..color = const ui.Color(0xFF00AA00),
  );

  canvas.translate(60, 0);
  canvas.drawImage(await generateTestImage(), const ui.Offset(20, 20), ui.Paint());

  canvas.translate(60, 0);
  final ui.RSTransform transform = ui.RSTransform.fromComponents(
    rotation: 0,
    scale: 1,
    anchorX: 0,
    anchorY: 0,
    translateX: 0,
    translateY: 0,
  );
  canvas.drawRawAtlas(
    await generateTestImage(),
    Float32List(4)
      ..[0] = transform.scos
      ..[1] = transform.ssin
      ..[2] = transform.tx + 20
      ..[3] = transform.ty + 20,
    Float32List(4)
      ..[0] = 0
      ..[1] = 0
      ..[2] = 15
      ..[3] = 15,
    Int32List.fromList(<int>[0x00000000]),
    ui.BlendMode.srcOver,
    null,
    ui.Paint(),
  );

  canvas.translate(60, 0);
  canvas.drawDRRect(
    ui.RRect.fromLTRBR(0, 0, 40, 30, const ui.Radius.elliptical(16, 8)),
    ui.RRect.fromLTRBR(10, 10, 30, 20, const ui.Radius.elliptical(4, 8)),
    ui.Paint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageRect(
    await generateTestImage(),
    const ui.Rect.fromLTRB(0, 0, 15, 15),
    const ui.Rect.fromLTRB(10, 10, 40, 40),
    ui.Paint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageNine(
    await generateTestImage(),
    const ui.Rect.fromLTRB(5, 5, 15, 15),
    const ui.Rect.fromLTRB(10, 10, 50, 40),
    ui.Paint(),
  );

  canvas.restore();

  // Row 2
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawLine(ui.Offset.zero, const ui.Offset(40, 30), ui.Paint());

  canvas.translate(60, 0);
  canvas.drawOval(const ui.Rect.fromLTRB(0, 0, 40, 30), ui.Paint());

  canvas.translate(60, 0);
  canvas.save();
  canvas.clipRect(const ui.Rect.fromLTRB(0, 0, 50, 30));
  canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFF6688AA));
  canvas.restore();

  canvas.translate(60, 0);
  {
    final ui.PictureRecorder otherRecorder = ui.PictureRecorder();
    final ui.Canvas otherCanvas = ui.Canvas(otherRecorder, const ui.Rect.fromLTRB(0, 0, 40, 20));
    otherCanvas.drawCircle(
      const ui.Offset(30, 15),
      10,
      ui.Paint()..color = const ui.Color(0xFFAABBCC),
    );
    canvas.drawPicture(otherRecorder.endRecording());
  }

  canvas.translate(60, 0);
  canvas.drawPoints(
    ui.PointMode.polygon,
    const <ui.Offset>[ui.Offset(10, 10), ui.Offset(20, 10), ui.Offset(30, 20), ui.Offset(40, 20)],
    ui.Paint()
      ..color = const ui.Color(0xFF0000FF)
      ..strokeWidth = 5
      ..strokeCap = ui.StrokeCap.round,
  );

  canvas.translate(60, 0);
  canvas.drawRRect(ui.RRect.fromLTRBR(0, 0, 40, 30, const ui.Radius.circular(10)), ui.Paint());

  canvas.translate(60, 0);
  canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 40, 30), ui.Paint());

  canvas.translate(60, 0);
  canvas.drawShadow(
    ui.Path()..addRect(const ui.Rect.fromLTRB(0, 0, 40, 30)),
    const ui.Color(0xFF00FF00),
    4,
    true,
  );

  canvas.restore();

  // Row 3
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawVertices(
    ui.Vertices(ui.VertexMode.triangleFan, const <ui.Offset>[
      ui.Offset(10, 30),
      ui.Offset(30, 50),
      ui.Offset(10, 60),
    ]),
    ui.BlendMode.srcOver,
    ui.Paint(),
  );

  canvas.translate(60, 0);
  final int restorePoint = canvas.getSaveCount();
  for (int i = 0; i < 5; i++) {
    canvas.save();
    canvas.translate(10, 10);
    canvas.drawCircle(ui.Offset.zero, 5, ui.Paint());
  }
  canvas.restoreToCount(restorePoint);
  canvas.drawCircle(ui.Offset.zero, 7, ui.Paint()..color = const ui.Color(0xFFFF0000));

  canvas.translate(60, 0);
  canvas.drawLine(ui.Offset.zero, const ui.Offset(30, 30), ui.Paint());
  canvas.save();
  canvas.rotate(-math.pi / 8);
  canvas.drawLine(ui.Offset.zero, const ui.Offset(30, 30), ui.Paint());
  canvas.drawCircle(const ui.Offset(30, 30), 7, ui.Paint()..color = const ui.Color(0xFF00AA00));
  canvas.restore();

  canvas.translate(60, 0);
  final ui.Paint thickStroke = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 20;
  final ui.Paint semitransparent = ui.Paint()..color = const ui.Color(0x66000000);

  canvas.saveLayer(kDefaultRegion, semitransparent);
  canvas.drawLine(const ui.Offset(10, 10), const ui.Offset(50, 50), thickStroke);
  canvas.drawLine(const ui.Offset(50, 10), const ui.Offset(10, 50), thickStroke);
  canvas.restore();

  canvas.translate(60, 0);
  canvas.saveLayer(null, semitransparent);
  canvas.drawLine(const ui.Offset(10, 10), const ui.Offset(50, 50), thickStroke);
  canvas.drawLine(const ui.Offset(50, 10), const ui.Offset(10, 50), thickStroke);
  canvas.restore();

  // To test saveLayerWithFilter we draw three circles with only the middle one
  // blurred using the layer image filter.
  canvas.translate(60, 0);
  canvas.saveLayer(kDefaultRegion, ui.Paint());
  canvas.drawCircle(const ui.Offset(30, 30), 10, ui.Paint());
  {
    canvas.saveLayerWithFilter(
      kDefaultRegion,
      ui.Paint(),
      ui.ImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp),
    );
    canvas.drawCircle(const ui.Offset(10, 10), 10, ui.Paint());
    canvas.drawCircle(const ui.Offset(50, 50), 10, ui.Paint());
    canvas.restore();
  }
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.scale(2, 1.5);
  canvas.drawCircle(ui.Offset.zero, 10, ui.Paint());
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.skew(2, 1.5);
  canvas.drawRect(const ui.Rect.fromLTRB(-10, -10, 10, 10), ui.Paint());
  canvas.restore();

  canvas.restore();

  // Row 4
  canvas.translate(0, 60);
  canvas.save();

  canvas.save();
  final Matrix4 matrix = Matrix4.identity();
  matrix.translate(30, 30);
  matrix.scale(2, 1.5);
  canvas.transform(matrix.toFloat64());
  canvas.drawCircle(ui.Offset.zero, 10, ui.Paint());
  canvas.restore();

  canvas.translate(60, 0);
  final ui.Paragraph p = makeSimpleText('Hello', fontSize: 18, color: const ui.Color(0xFF0000AA));
  canvas.drawParagraph(p, const ui.Offset(10, 20));

  canvas.translate(60, 0);
  canvas.drawPath(
    ui.Path()
      ..moveTo(30, 20)
      ..lineTo(50, 50)
      ..lineTo(10, 50)
      ..close(),
    ui.Paint()..color = const ui.Color(0xFF0000AA),
  );

  canvas.restore();
}

Future<ui.Image> generateTestImage() {
  final DomHTMLCanvasElement canvas = createDomCanvasElement(width: 20, height: 20);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#FF0000';
  ctx.fillRect(0, 0, 10, 10);
  ctx.fillStyle = '#00FF00';
  ctx.fillRect(0, 10, 10, 10);
  ctx.fillStyle = '#0000FF';
  ctx.fillRect(10, 0, 10, 10);
  ctx.fillStyle = '#FF00FF';
  ctx.fillRect(10, 10, 10, 10);
  final Uint8List imageData = ctx.getImageData(0, 0, 20, 20).data.buffer.asUint8List();
  final Completer<ui.Image> completer = Completer<ui.Image>();
  renderer.decodeImageFromPixels(imageData, 20, 20, ui.PixelFormat.rgba8888, (ui.Image result) {
    completer.complete(result);
  });
  return completer.future;
}

ui.Paragraph makeSimpleText(
  String text, {
  String? fontFamily,
  double? fontSize,
  ui.FontStyle? fontStyle,
  ui.FontWeight? fontWeight,
  ui.Color? color,
}) {
  final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: fontFamily ?? 'Roboto',
      fontSize: fontSize ?? 14,
      fontStyle: fontStyle ?? ui.FontStyle.normal,
      fontWeight: fontWeight ?? ui.FontWeight.normal,
    ),
  );
  builder.pushStyle(ui.TextStyle(color: color ?? const ui.Color(0xFF000000)));
  builder.addText(text);
  builder.pop();
  final ui.Paragraph paragraph = builder.build();
  paragraph.layout(const ui.ParagraphConstraints(width: 10000));
  return paragraph;
}
