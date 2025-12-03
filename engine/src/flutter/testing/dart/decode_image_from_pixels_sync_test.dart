// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('decodeImageFromPixelsSync decodes RGBA8888', () async {
    const int width = 2;
    const int height = 2;
    // 2x2 red image
    final Uint8List pixels = Uint8List.fromList(<int>[
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      255,
    ]);

    final Image image = decodeImageFromPixelsSync(pixels, width, height, PixelFormat.rgba8888);

    expect(image.width, width);
    expect(image.height, height);

    final ByteData? data = await image.toByteData(format: ImageByteFormat.rawRgba);
    expect(data, isNotNull);
    final Uint8List resultPixels = data!.buffer.asUint8List();
    expect(resultPixels, pixels);

    image.dispose();
  });

  test('decodeImageFromPixelsSync resizes image', () {
    const int width = 2;
    const int height = 2;
    final Uint8List pixels = Uint8List(width * height * 4);

    final Image image = decodeImageFromPixelsSync(
      pixels,
      width,
      height,
      PixelFormat.rgba8888,
      targetWidth: 4,
      targetHeight: 4,
    );

    expect(image.width, 4);
    expect(image.height, 4);
    image.dispose();
  });

  test('decodeImageFromPixelsSync throws on invalid dimensions', () {
    final Uint8List pixels = Uint8List(4);
    expect(
      () => decodeImageFromPixelsSync(pixels, 0, 1, PixelFormat.rgba8888),
      throwsA(isA<String>()), // Throws string error from C++
    );
  });
}
