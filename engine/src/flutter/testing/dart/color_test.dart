// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:ui';

import 'package:test/test.dart';

class NotAColor extends Color {
  const NotAColor(int value) : super(value);
}

void main() {
  test('color accessors should work', () {
    const Color foo = Color(0x12345678);
    expect(foo.alpha, equals(0x12));
    expect(foo.red, equals(0x34));
    expect(foo.green, equals(0x56));
    expect(foo.blue, equals(0x78));
  });

  test('paint set to black', () {
    const Color c = Color(0x00000000);
    final Paint p = Paint();
    p.color = c;
    expect(c.toString(), equals('Color(0x00000000)'));
  });

  test('color created with out of bounds value', () {
    try {
      const Color c = Color(0x100 << 24);
      final Paint p = Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });

  test('color created with wildly out of bounds value', () {
    try {
      const Color c = Color(1 << 1000000);
      final Paint p = Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });

  test('two colors are only == if they have the same runtime type', () {
    expect(const Color(123), equals(const Color(123)));
    expect(const Color(123), equals(Color(123))); // ignore: prefer_const_constructors
    expect(const Color(123), isNot(equals(const Color(321))));
    expect(const Color(123), isNot(equals(const NotAColor(123))));
    expect(const NotAColor(123), isNot(equals(const Color(123))));
    expect(const NotAColor(123), equals(const NotAColor(123)));
  });

  test('Color.lerp', () {
    expect(
      Color.lerp(const Color(0x00000000), const Color(0xFFFFFFFF), 0.0),
      const Color(0x00000000),
    );
    expect(
      Color.lerp(const Color(0x00000000), const Color(0xFFFFFFFF), 0.5),
      const Color(0x7F7F7F7F),
    );
    expect(
      Color.lerp(const Color(0x00000000), const Color(0xFFFFFFFF), 1.0),
      const Color(0xFFFFFFFF),
    );
    expect(
      Color.lerp(const Color(0x00000000), const Color(0xFFFFFFFF), -0.1),
      const Color(0x00000000),
    );
    expect(
      Color.lerp(const Color(0x00000000), const Color(0xFFFFFFFF), 1.1),
      const Color(0xFFFFFFFF),
    );
  });

  test('Color.alphaBlend', () {
    expect(
      Color.alphaBlend(const Color(0x00000000), const Color(0x00000000)),
      const Color(0x00000000),
    );
    expect(
      Color.alphaBlend(const Color(0x00000000), const Color(0xFFFFFFFF)),
      const Color(0xFFFFFFFF),
    );
    expect(
      Color.alphaBlend(const Color(0xFFFFFFFF), const Color(0x00000000)),
      const Color(0xFFFFFFFF),
    );
    expect(
      Color.alphaBlend(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
      const Color(0xFFFFFFFF),
    );
    expect(
      Color.alphaBlend(const Color(0x80FFFFFF), const Color(0xFF000000)),
      const Color(0xFF808080),
    );
    expect(
      Color.alphaBlend(const Color(0x80808080), const Color(0xFFFFFFFF)),
      const Color(0xFFBFBFBF),
    );
    expect(
      Color.alphaBlend(const Color(0x80808080), const Color(0xFF000000)),
      const Color(0xFF404040),
    );
    expect(
      Color.alphaBlend(const Color(0x01020304), const Color(0xFF000000)),
      const Color(0xFF000000),
    );
    expect(
      Color.alphaBlend(const Color(0x11223344), const Color(0xFF000000)),
      const Color(0xFF020304),
    );
    expect(
      Color.alphaBlend(const Color(0x11223344), const Color(0x80000000)),
      const Color(0x88040608),
    );
  });

  test('compute gray luminance', () {
    // Each color component is at 20%.
    const Color lightGray = Color(0xFF333333);
    // Relative luminance's formula is just the linearized color value for gray.
    // ((0.2 + 0.055) / 1.055) ^ 2.4.
    expect(lightGray.computeLuminance(), equals(0.033104766570885055));
  });

  test('compute color luminance', () {
    const Color brightRed = Color(0xFFFF3B30);
    // 0.2126 * ((1.0 + 0.055) / 1.055) ^ 2.4 +
    // 0.7152 * ((0.23137254902 +0.055) / 1.055) ^ 2.4 +
    // 0.0722 * ((0.18823529411 + 0.055) / 1.055) ^ 2.4
    expect(brightRed.computeLuminance(), equals(0.24601329637099723));
  });
}
