// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

class NotAColor extends Color {
  const NotAColor(int value) : super(value);
}

void main() {
  test('color accessors should work', () {
    Color foo = const Color(0x12345678);
    expect(foo.alpha, equals(0x12));
    expect(foo.red, equals(0x34));
    expect(foo.green, equals(0x56));
    expect(foo.blue, equals(0x78));
  });

  test('paint set to black', () {
    Color c = const Color(0x00000000);
    Paint p = new Paint();
    p.color = c;
    expect(c.toString(), equals('Color(0x00000000)'));
  });

  test('color created with out of bounds value', () {
    try {
      Color c = const Color(0x100 << 24);
      Paint p = new Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });

  test('color created with wildly out of bounds value', () {
    try {
      Color c = const Color(1 << 1000000);
      Paint p = new Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });

  test('two colors are only == if they have the same runtime type', () {
    expect(const Color(123), equals(const Color(123)));
    expect(const Color(123), equals(new Color(123)));
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

  test('compute gray luminance', () {
    // Each color component is at 20%.
    final Color lightGray = const Color(0xFF333333);
    // Relative luminance's formula is just the linearized color value for gray.
    // ((0.2 + 0.055) / 1.055) ^ 2.4.
    expect(lightGray.computeLuminance(), equals(0.033104766570885055));
  });

  test('compute color luminance', () {
    final Color brightRed = const Color(0xFFFF3B30);
    // 0.2126 * ((1.0 + 0.055) / 1.055) ^ 2.4 +
    // 0.7152 * ((0.23137254902 +0.055) / 1.055) ^ 2.4 +
    // 0.0722 * ((0.18823529411 + 0.055) / 1.055) ^ 2.4
    expect(brightRed.computeLuminance(), equals(0.24601329637099723));
  });
}
