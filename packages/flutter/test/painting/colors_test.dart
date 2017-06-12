// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HSVColor control test', () {
    const HSVColor color = const HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.6);

    expect(color, hasOneLineDescription);
    expect(color.hashCode, equals(const HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.6).hashCode));

    expect(color.withAlpha(0.8), const HSVColor.fromAHSV(0.8, 28.0, 0.3, 0.6));
    expect(color.withHue(123.0), const HSVColor.fromAHSV(0.7, 123.0, 0.3, 0.6));
    expect(color.withSaturation(0.9), const HSVColor.fromAHSV(0.7, 28.0, 0.9, 0.6));
    expect(color.withValue(0.1), const HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.1));

    expect(color.toColor(), const Color(0xb399816b));

    final HSVColor result = HSVColor.lerp(color, const HSVColor.fromAHSV(0.3, 128.0, 0.7, 0.2), 0.25);
    expect(result.alpha, 0.6);
    expect(result.hue, 53.0);
    expect(result.saturation, greaterThan(0.3999));
    expect(result.saturation, lessThan(0.4001));
    expect(result.value, 0.5);
  });

  test('HSVColor.fromColor test', () {
    final HSVColor black = new HSVColor.fromColor(const Color.fromARGB(0xFF, 0x00, 0x00, 0x00));
    final HSVColor red = new HSVColor.fromColor(const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00));
    final HSVColor green = new HSVColor.fromColor(const Color.fromARGB(0xFF, 0x00, 0xFF, 0x00));
    final HSVColor blue = new HSVColor.fromColor(const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF));

    expect(black.toColor(), equals(const Color.fromARGB(0xFF, 0x00, 0x00, 0x00)));
    expect(red.toColor(), equals(const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00)));
    expect(green.toColor(), equals(const Color.fromARGB(0xFF, 0x00, 0xFF, 0x00)));
    expect(blue.toColor(), equals(const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF)));
  });
}
