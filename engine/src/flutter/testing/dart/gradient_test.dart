// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('Gradient.radial with no focal point', () {
    expect(
      Gradient.radial(
        Offset.zero,
        0.0,
        <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
        <double>[0.0, 1.0],
        TileMode.mirror,
      ),
      isNotNull,
    );
  });

  // this is just a radial gradient, focal point is discarded.
  test('radial center and focal == Offset.zero and focalRadius == 0.0 is ok', () {
    expect(
      () => Gradient.radial(
        Offset.zero,
        0.0,
        <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
        <double>[0.0, 1.0],
        TileMode.mirror,
        null,
        Offset.zero,
      ),
      isNotNull,
    );
  });

  test('radial center != focal and focalRadius == 0.0 is ok', () {
    expect(
      () => Gradient.radial(
        Offset.zero,
        0.0,
        <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
        <double>[0.0, 1.0],
        TileMode.mirror,
        null,
        const Offset(2.0, 2.0),
      ),
      isNotNull,
    );
  });

  // this would result in div/0 on skia side.
  test('radial center and focal == Offset.zero and focalRadius != 0.0 assert', () {
    expect(
      () => Gradient.radial(
        Offset.zero,
        0.0,
        <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
        <double>[0.0, 1.0],
        TileMode.mirror,
        null,
        Offset.zero,
        1.0,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('gradients with no colors draw with the paint color', () async {
    final shaders = <Shader>[
      Gradient.linear(Offset.zero, const Offset(10.0, 10.0), const <Color>[], const <double>[]),
      Gradient.radial(Offset.zero, 10.0, const <Color>[], const <double>[]),
      Gradient.sweep(Offset.zero, const <Color>[], const <double>[]),
    ];
    for (final Shader shader in shaders) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0.0, 0.0, 10.0, 10.0),
        Paint()
          ..color = const Color(0xFF00FF00)
          ..shader = shader,
      );
      final Picture picture = recorder.endRecording();
      final Image image = await picture.toImage(10, 10);
      final ByteData? pixels = await image.toByteData();
      expect(pixels!.getUint32(0), 0x00FF00FF);
      image.dispose();
      picture.dispose();
    }
  });
}
