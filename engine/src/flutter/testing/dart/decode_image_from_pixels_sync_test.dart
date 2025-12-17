// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'impeller_enabled.dart';

void main() {
  test('decodeImageFromPixelsSync decodes RGBA8888', () async {
    const width = 2;
    const height = 2;
    // 2x2 red image
    final pixels = Uint8List.fromList(<int>[
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

    final ByteData? data = await image.toByteData();
    expect(data, isNotNull);
    final Uint8List resultPixels = data!.buffer.asUint8List();
    expect(resultPixels, pixels);

    image.dispose();
  }, skip: !impellerEnabled);

  test('decodeImageFromPixelsSync throws on invalid dimensions', () {
    final pixels = Uint8List(4);
    expect(
      () => decodeImageFromPixelsSync(pixels, 0, 1, PixelFormat.rgba8888),
      throwsA(isA<String>()), // Throws string error from C++
    );
  }, skip: !impellerEnabled);

  test('decodeImageFromPixelsSync throws if not Impeller', () {
    final pixels = Uint8List(4);
    expect(
      () => decodeImageFromPixelsSync(pixels, 1, 1, PixelFormat.rgba8888),
      throwsA(isA<String>()),
    );
  }, skip: impellerEnabled);
}
