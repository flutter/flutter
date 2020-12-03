// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:web_engine_tester/golden_tester.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect region = const ui.Rect.fromLTRB(0, 0, 500, 250);

Future<void> matchPictureGolden(String goldenFile, CkPicture picture, { bool write = false }) async {
  final EnginePlatformDispatcher dispatcher = ui.window.platformDispatcher as EnginePlatformDispatcher;
  final LayerSceneBuilder sb = LayerSceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(ui.Offset.zero, picture);
  dispatcher.rasterizer!.draw(sb.build().layerTree);
  await matchGoldenFile(goldenFile, region: region, write: write);
}

void testMain() {
  group('CkCanvas', () {
    setUpCanvasKitTest();

    test('renders using non-recording canvas if weak refs are supported', () async {
      expect(browserSupportsFinalizationRegistry, isTrue,
          reason: 'This test specifically tests non-recording canvas, which '
                  'only works if FinalizationRegistry is available.');
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(region);
      expect(canvas.runtimeType, CkCanvas);
      drawTestPicture(canvas);
      await matchPictureGolden('canvaskit_picture_original.png', recorder.endRecording());
    });

    test('renders using a recording canvas if weak refs are not supported', () async {
      browserSupportsFinalizationRegistry = false;
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(region);
      expect(canvas, isA<RecordingCkCanvas>());
      drawTestPicture(canvas);

      final CkPicture originalPicture = recorder.endRecording();
      await matchPictureGolden('canvaskit_picture_original.png', originalPicture);

      final ByteData originalPixels = await (await originalPicture.toImage(50, 50)).toByteData() as ByteData;

      // Test that a picture restored from a snapshot looks the same.
      final CkPictureSnapshot? snapshot = canvas.pictureSnapshot;
      expect(snapshot, isNotNull);
      final SkPicture restoredSkPicture = snapshot!.toPicture();
      expect(restoredSkPicture, isNotNull);
      final CkPicture restoredPicture = CkPicture(restoredSkPicture, ui.Rect.fromLTRB(0, 0, 50, 50), snapshot);
      final ByteData restoredPixels = await (await restoredPicture.toImage(50, 50)).toByteData() as ByteData;

      await matchPictureGolden('canvaskit_picture_restored.png', restoredPicture);
      expect(restoredPixels.buffer.asUint8List(), originalPixels.buffer.asUint8List());
    });
  // TODO: https://github.com/flutter/flutter/issues/60040
  // TODO: https://github.com/flutter/flutter/issues/71520
  }, skip: isIosSafari || isFirefox);
}

void drawTestPicture(CkCanvas canvas) {
  canvas.clear(ui.Color(0xFFFFFFF));

  canvas.translate(10, 10);

  // Row 1
  canvas.save();

  canvas.save();
  canvas.clipRect(
    ui.Rect.fromLTRB(0, 0, 45, 45),
    ui.ClipOp.intersect,
    true,
  );
  canvas.clipRRect(
    ui.RRect.fromLTRBR(5, 5, 50, 50, ui.Radius.circular(8)),
    true,
  );
  canvas.clipPath(
    CkPath()
      ..moveTo(5, 5)
      ..lineTo(25, 5)
      ..lineTo(45, 45)
      ..lineTo(5, 45)
      ..close(),
    true,
  );
  canvas.drawColor(ui.Color.fromARGB(255, 100, 100, 0), ui.BlendMode.srcOver);
  canvas.restore(); // remove clips

  canvas.translate(60, 0);
  canvas.drawCircle(
    const ui.Offset(30, 25),
    15,
    CkPaint()..color = ui.Color(0xFF0000AA),
  );

  canvas.translate(60, 0);
  canvas.drawArc(
    ui.Rect.fromLTRB(10, 20, 50, 40),
    math.pi / 4,
    3 * math.pi / 2,
    true,
    CkPaint()..color = ui.Color(0xFF00AA00),
  );

  canvas.translate(60, 0);
  canvas.drawImage(
    generateTestImage(),
    const ui.Offset(20, 20),
    CkPaint(),
  );

  canvas.translate(60, 0);
  final ui.RSTransform transform = ui.RSTransform.fromComponents(
    rotation: 0,
    scale: 1,
    anchorX: 0,
    anchorY: 0,
    translateX: 0,
    translateY: 0,
  );
  canvas.drawAtlasRaw(
    CkPaint(),
    generateTestImage(),
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
    [Float32List(4)],
    ui.BlendMode.srcOver,
  );

  canvas.translate(60, 0);
  canvas.drawDRRect(
    ui.RRect.fromLTRBR(0, 0, 40, 30, ui.Radius.elliptical(16, 8)),
    ui.RRect.fromLTRBR(10, 10, 30, 20, ui.Radius.elliptical(4, 8)),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageRect(
    generateTestImage(),
    ui.Rect.fromLTRB(0, 0, 15, 15),
    ui.Rect.fromLTRB(10, 10, 40, 40),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageNine(
    generateTestImage(),
    ui.Rect.fromLTRB(5, 5, 15, 15),
    ui.Rect.fromLTRB(10, 10, 50, 40),
    CkPaint(),
  );

  canvas.restore();

  // Row 2
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawLine(ui.Offset(0, 0), ui.Offset(40, 30), CkPaint());

  canvas.translate(60, 0);
  canvas.drawOval(
    ui.Rect.fromLTRB(0, 0, 40, 30),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.save();
  canvas.clipRect(ui.Rect.fromLTRB(0, 0, 50, 30), ui.ClipOp.intersect, true);
  canvas.drawPaint(CkPaint()..color = ui.Color(0xFF6688AA));
  canvas.restore();

  canvas.translate(60, 0);
  {
    final CkPictureRecorder otherRecorder = CkPictureRecorder();
    final CkCanvas otherCanvas =
        otherRecorder.beginRecording(ui.Rect.fromLTRB(0, 0, 40, 20));
    otherCanvas.drawCircle(
      ui.Offset(30, 15),
      10,
      CkPaint()..color = ui.Color(0xFFAABBCC),
    );
    canvas.drawPicture(otherRecorder.endRecording());
  }

  canvas.translate(60, 0);
  // TODO(yjbanov): CanvasKit.drawPoints is currently broken
  //                https://github.com/flutter/flutter/issues/71489
  //                But keeping this anyway as it's a good test-case that
  //                will ensure it's fixed when we have the fix.
  canvas.drawPoints(
    CkPaint()
      ..color = ui.Color(0xFF0000FF)
      ..strokeWidth = 5
      ..strokeCap = ui.StrokeCap.round,
    ui.PointMode.polygon,
    offsetListToFloat32List(<ui.Offset>[
      ui.Offset(10, 10),
      ui.Offset(20, 10),
      ui.Offset(30, 20),
      ui.Offset(40, 20)
    ]),
  );

  canvas.translate(60, 0);
  canvas.drawRRect(
    ui.RRect.fromLTRBR(0, 0, 40, 30, ui.Radius.circular(10)),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawRect(
    ui.Rect.fromLTRB(0, 0, 40, 30),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawShadow(
    CkPath()
      ..addRect(ui.Rect.fromLTRB(0, 0, 40, 30)),
    ui.Color(0xFF00FF00),
    4,
    true,
  );

  canvas.restore();

  // Row 3
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawVertices(
    CkVertices(
      ui.VertexMode.triangleFan,
      <ui.Offset>[
        ui.Offset(10, 30),
        ui.Offset(30, 50),
        ui.Offset(10, 60),
      ],
    ),
    ui.BlendMode.srcOver,
    CkPaint(),
  );

  canvas.translate(60, 0);
  final int restorePoint = canvas.save();
  for (int i = 0; i < 5; i++) {
    canvas.save();
    canvas.translate(10, 10);
    canvas.drawCircle(ui.Offset.zero, 5, CkPaint());
  }
  canvas.restoreToCount(restorePoint);
  canvas.drawCircle(ui.Offset.zero, 7, CkPaint()..color = ui.Color(0xFFFF0000));

  canvas.translate(60, 0);
  canvas.drawLine(ui.Offset.zero, ui.Offset(30, 30), CkPaint());
  canvas.save();
  canvas.rotate(-math.pi / 8);
  canvas.drawLine(ui.Offset.zero, ui.Offset(30, 30), CkPaint());
  canvas.drawCircle(ui.Offset(30, 30), 7, CkPaint()..color = ui.Color(0xFF00AA00));
  canvas.restore();

  canvas.translate(60, 0);
  final CkPaint thickStroke = CkPaint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 20;
  final CkPaint semitransparent = CkPaint()..color = ui.Color(0x66000000);

  canvas.saveLayer(region, semitransparent);
  canvas.drawLine(ui.Offset(10, 10), ui.Offset(50, 50), thickStroke);
  canvas.drawLine(ui.Offset(50, 10), ui.Offset(10, 50), thickStroke);
  canvas.restore();

  canvas.translate(60, 0);
  canvas.saveLayerWithoutBounds(semitransparent);
  canvas.drawLine(ui.Offset(10, 10), ui.Offset(50, 50), thickStroke);
  canvas.drawLine(ui.Offset(50, 10), ui.Offset(10, 50), thickStroke);
  canvas.restore();

  // To test saveLayerWithFilter we draw three circles with only the middle one
  // blurred using the layer image filter.
  canvas.translate(60, 0);
  canvas.saveLayer(region, CkPaint());
  canvas.drawCircle(ui.Offset(30, 30), 10, CkPaint());
  {
    canvas.saveLayerWithFilter(region, ui.ImageFilter.blur(sigmaX: 5, sigmaY: 10));
    canvas.drawCircle(ui.Offset(10, 10), 10, CkPaint());
    canvas.drawCircle(ui.Offset(50, 50), 10, CkPaint());
    canvas.restore();
  }
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.scale(2, 1.5);
  canvas.drawCircle(ui.Offset.zero, 10, CkPaint());
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.skew(2, 1.5);
  canvas.drawRect(ui.Rect.fromLTRB(-10, -10, 10, 10), CkPaint());
  canvas.restore();

  canvas.restore();

  // Row 4
  canvas.translate(0, 60);
  canvas.save();

  canvas.save();
  final Matrix4 matrix = Matrix4.identity();
  matrix.translate(30, 30);
  matrix.scale(2, 1.5);
  canvas.transform(matrix.storage);
  canvas.drawCircle(ui.Offset.zero, 10, CkPaint());
  canvas.restore();

  canvas.translate(60, 0);
  final CkParagraphBuilder pb = CkParagraphBuilder(CkParagraphStyle(
    fontFamily: 'Roboto',
    fontStyle: ui.FontStyle.normal,
    fontWeight: ui.FontWeight.normal,
    fontSize: 18,
  ));
  pb.pushStyle(CkTextStyle(
    color: ui.Color(0xFF0000AA),
  ));
  pb.addText('Hello');
  pb.pop();
  final CkParagraph p = pb.build();
  p.layout(ui.ParagraphConstraints(width: 1000));
  canvas.drawParagraph(
    p,
    ui.Offset(10, 20),
  );

  canvas.translate(60, 0);
  canvas.drawPath(
    CkPath()
      ..moveTo(30, 20)
      ..lineTo(50, 50)
      ..lineTo(10, 50)
      ..close(),
    CkPaint()..color = ui.Color(0xFF0000AA),
  );

  canvas.restore();
}

CkImage generateTestImage() {
  final html.CanvasElement canvas = html.CanvasElement()
    ..width = 20
    ..height = 20;
  final html.CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#FF0000';
  ctx.fillRect(0, 0, 10, 10);
  ctx.fillStyle = '#00FF00';
  ctx.fillRect(0, 10, 10, 10);
  ctx.fillStyle = '#0000FF';
  ctx.fillRect(10, 0, 10, 10);
  ctx.fillStyle = '#FF00FF';
  ctx.fillRect(10, 10, 10, 10);
  final Uint8List imageData = ctx.getImageData(0, 0, 20, 20).data.buffer.asUint8List();
  final SkImage skImage = canvasKit.MakeImage(
    imageData,
    20,
    20,
    canvasKit.AlphaType.Premul,
    canvasKit.ColorType.RGBA_8888,
    SkColorSpaceSRGB,
  );
  return CkImage(skImage);
}
