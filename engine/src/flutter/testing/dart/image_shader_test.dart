// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'canvas_test.dart' show createImage, testCanvas;

void main() {
  test('Construct an ImageShader', () async {
    final Image image = await createImage(50, 50);
    final ImageShader shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16));
    final Paint paint = Paint()..shader=shader;
    final Rect rect = Rect.fromLTRB(0, 0, 100, 100);
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));
  });
}
