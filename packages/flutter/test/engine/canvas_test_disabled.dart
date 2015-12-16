// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:ui' show Rect, Color, Paint;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {

  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));

  test("matrix access should work", () {
    // Matrix equality doesn't work!
    // https://github.com/google/vector_math.dart/issues/147
    expect(canvas.getTotalMatrix(), equals(new Matrix4.identity().storage));
    Matrix4 matrix = new Matrix4.identity();
    // Round-tripping through getTotalMatrix will lose the z value
    // So only scale to 1x in the z direction.
    matrix.scale(2.0, 2.0, 1.0);
    canvas.setMatrix(matrix.storage);
    canvas.drawPaint(new Paint()..color = const Color(0xFF00FF00));
    expect(canvas.getTotalMatrix(), equals(matrix.storage));
  });

}
