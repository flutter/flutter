// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library playfair.test;

import 'package:test/test.dart';

import 'package:playfair/playfair.dart';
import 'test_painting_canvas.dart';

void main() {
  test('test_chart', () {
    ChartData data = new ChartData(
      startX: 0.0,
      startY: 0.0,
      endX: 10.0,
      endY: 1.0,
      dataSet: [
        const Point(0.0, 0.0),
        const Point(2.0, 0.5),
        const Point(5.0, 0.2),
        const Point(10.0, 0.9),
      ]
    );

    StringBuffer buffer = new StringBuffer();
    PaintingCanvas canvas = new TestPaintingCanvas(
      new PictureRecorder(),
      const Size(100.0, 100.0),
      buffer.write
    );

    new ChartPainter(data).paint(canvas, new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));

    // TODO(jackson): Update this to the correct value once Sky packages can test
    // See https://github.com/domokit/sky_engine/issues/580
    expect(buffer.toString(), equals(""));
  });
}
