// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

typedef CanvasCallback = void Function(Canvas canvas);

void testCanvas(CanvasCallback callback) {
  try {
    callback(Canvas(PictureRecorder(), Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)));
  } catch (error) { } // ignore: empty_catches
}

void main() {
  test('canvas APIs should not crash', () {
    final Paint paint = Paint();
    final Rect rect = Rect.fromLTRB(double.nan, double.nan, double.nan, double.nan);
    final RRect rrect = RRect.fromRectAndCorners(rect);
    const Offset offset = Offset(double.nan, double.nan);
    final Path path = Path();
    const Color color = Color(0);
    final Paragraph paragraph = ParagraphBuilder(ParagraphStyle()).build();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.scale(1.0, 1.0);
    final Picture picture = recorder.endRecording();
    final Image image = picture.toImage(1, 1);

    try { Canvas(null, null); } catch (error) { } // ignore: empty_catches
    try { Canvas(null, rect); } catch (error) { } // ignore: empty_catches
    try { Canvas(PictureRecorder(), null); } catch (error) { } // ignore: empty_catches
    try { Canvas(PictureRecorder(), rect); } catch (error) { } // ignore: empty_catches

    try {
      PictureRecorder()
        ..endRecording()
        ..endRecording()
        ..endRecording();
    } catch (error) { } // ignore: empty_catches

    testCanvas((Canvas canvas) => canvas.clipPath(path));
    testCanvas((Canvas canvas) => canvas.clipRect(rect));
    testCanvas((Canvas canvas) => canvas.clipRRect(rrect));
    testCanvas((Canvas canvas) => canvas.drawArc(rect, 0.0, 0.0, false, paint));
    testCanvas((Canvas canvas) => canvas.drawAtlas(image, <RSTransform>[], <Rect>[], <Color>[], BlendMode.src, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawCircle(offset, double.nan, paint));
    testCanvas((Canvas canvas) => canvas.drawColor(color, BlendMode.src));
    testCanvas((Canvas canvas) => canvas.drawDRRect(rrect, rrect, paint));
    testCanvas((Canvas canvas) => canvas.drawImage(image, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawImageNine(image, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawImageRect(image, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawLine(offset, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawOval(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawPaint(paint));
    testCanvas((Canvas canvas) => canvas.drawParagraph(paragraph, offset));
    testCanvas((Canvas canvas) => canvas.drawPath(path, paint));
    testCanvas((Canvas canvas) => canvas.drawPicture(picture));
    testCanvas((Canvas canvas) => canvas.drawPoints(PointMode.points, <Offset>[], paint));
    testCanvas((Canvas canvas) => canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawRawPoints(PointMode.points, Float32List(0), paint));
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawRRect(rrect, paint));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, null));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, false));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, true));
    testCanvas((Canvas canvas) => canvas.drawVertices(Vertices(VertexMode.triangles, <Offset>[]), null, paint));
    testCanvas((Canvas canvas) => canvas.getSaveCount());
    testCanvas((Canvas canvas) => canvas.restore());
    testCanvas((Canvas canvas) => canvas.rotate(double.nan));
    testCanvas((Canvas canvas) => canvas.save());
    testCanvas((Canvas canvas) => canvas.saveLayer(rect, paint));
    testCanvas((Canvas canvas) => canvas.saveLayer(null, null));
    testCanvas((Canvas canvas) => canvas.scale(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.skew(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.transform(null));
    testCanvas((Canvas canvas) => canvas.translate(double.nan, double.nan));
  });
}
