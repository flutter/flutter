// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'canvas_test.dart' show createImage, testCanvas;

void main() {
  bool assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());

  test('Construct an ImageShader', () async {
    final Image image = await createImage(50, 50);
    final ImageShader shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16));
    final Paint paint = Paint()..shader = shader;
    const Rect rect = Rect.fromLTRB(0, 0, 100, 100);
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));

    if (assertsEnabled) {
      expect(shader.debugDisposed, false);
    }
    shader.dispose();
    if (assertsEnabled) {
      expect(shader.debugDisposed, true);
    }

    image.dispose();
  });

  test('ImageShader with disposed image', () async {
    final Image image = await createImage(50, 50);
    image.dispose();

    if (assertsEnabled) {
      expectAssertion(() => ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16)));
    } else {
      throwsException(() => ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16)));
    }
  });

  test('Disposed image shader in a paint', () async {
    final Image image = await createImage(50, 50);
    final ImageShader shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16));
    shader.dispose();

    if (assertsEnabled) {
      expectAssertion(() => Paint()..shader = shader);
      return;
    }
    final Paint paint = Paint()..shader = shader;
    const Rect rect = Rect.fromLTRB(0, 0, 100, 100);
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));
    image.dispose();

  });

  test('Construct an ImageShader - GPU image', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawPaint(Paint()..color = const Color(0xFFABCDEF));
    final Picture picture = recorder.endRecording();
    final Image image = picture.toImageSync(50, 50);
    picture.dispose();

    final ImageShader shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Float64List(16));
    final Paint paint = Paint()..shader=shader;
    const Rect rect = Rect.fromLTRB(0, 0, 100, 100);
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));

    if (assertsEnabled) {
      expect(shader.debugDisposed, false);
    }
    shader.dispose();
    if (assertsEnabled) {
      expect(shader.debugDisposed, true);
    }

    image.dispose();
  });
}
