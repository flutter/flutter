// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

class FakeEverything implements Canvas, PictureRecorder, Color {
  dynamic noSuchMethod(Invocation invocation) {
    return new FakeEverything();
  }
}

class NegativeSpace implements Canvas, PictureRecorder, Color {
  dynamic noSuchMethod(Invocation invocation) {
    return false;
  }
}

void testCanvas(callback(Canvas canvas)) {
  try {
    callback(new Canvas(new PictureRecorder(), new Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)));
  } catch (error) { }
}

void main() {
  test("canvas APIs should not crash", () {
    dynamic fake = new FakeEverything();
    dynamic no = new NegativeSpace();
    Paint paint = new Paint();
    Rect rect = new Rect.fromLTRB(double.nan, double.nan, double.nan, double.nan);
    List<dynamic> list = <dynamic>[fake, fake];
    Offset offset = new Offset(double.nan, double.nan);
    Path path = new Path();

    try { new Canvas(null, null); } catch (error) { }
    try { new Canvas(null, rect); } catch (error) { }
    try { new Canvas(null, fake); } catch (error) { }
    try { new Canvas(fake, rect); } catch (error) { }
    try { new Canvas(no, rect); } catch (error) { }

    try {
      new PictureRecorder()
        ..endRecording()
        ..endRecording()
        ..endRecording();
    } catch (error) { }

    testCanvas((Canvas canvas) => canvas.clipPath(fake));
    testCanvas((Canvas canvas) => canvas.clipRect(fake));
    testCanvas((Canvas canvas) => canvas.clipRRect(fake));
    testCanvas((Canvas canvas) => canvas.drawArc(fake, 0.0, 0.0, false, paint));
    testCanvas((Canvas canvas) => canvas.drawArc(rect, 0.0, 0.0, false, fake));
    testCanvas((Canvas canvas) => canvas.drawAtlas(fake, list, list, list, fake, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawCircle(offset, double.nan, paint));
    testCanvas((Canvas canvas) => canvas.drawColor(fake, fake));
    testCanvas((Canvas canvas) => canvas.drawDRRect(fake, fake, fake));
    testCanvas((Canvas canvas) => canvas.drawImage(fake, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawImageNine(fake, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawImageRect(fake, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawLine(offset, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawOval(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawPaint(paint));
    testCanvas((Canvas canvas) => canvas.drawPaint(fake));
    testCanvas((Canvas canvas) => canvas.drawPaint(no));
    testCanvas((Canvas canvas) => canvas.drawParagraph(fake, offset));
    testCanvas((Canvas canvas) => canvas.drawPath(fake, paint));
    testCanvas((Canvas canvas) => canvas.drawPicture(fake));
    testCanvas((Canvas canvas) => canvas.drawPoints(fake, list, fake));
    testCanvas((Canvas canvas) => canvas.drawRawAtlas(fake, fake, fake, fake, fake, fake, fake));
    testCanvas((Canvas canvas) => canvas.drawRawPoints(fake, list, paint));
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawRRect(fake, paint));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, null));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, false));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, true));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, no));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, fake));
    testCanvas((Canvas canvas) => canvas.drawVertices(fake, null, paint));
    testCanvas((Canvas canvas) => canvas.getSaveCount());
    testCanvas((Canvas canvas) => canvas.restore());
    testCanvas((Canvas canvas) => canvas.rotate(double.nan));
    testCanvas((Canvas canvas) => canvas.save());
    testCanvas((Canvas canvas) => canvas.saveLayer(rect, paint));
    testCanvas((Canvas canvas) => canvas.saveLayer(fake, fake));
    testCanvas((Canvas canvas) => canvas.saveLayer(null, null));
    testCanvas((Canvas canvas) => canvas.scale(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.skew(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.transform(fake));
    testCanvas((Canvas canvas) => canvas.transform(no));
    testCanvas((Canvas canvas) => canvas.transform(null));
    testCanvas((Canvas canvas) => canvas.translate(double.nan, double.nan));
  });
}
