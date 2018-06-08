// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const double _doubleColorPrecision = 0.005;

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

  test('HSVColor converts RGB colors correctly.', () {
    void testColor(Color color, double alpha, double hue, double saturation, double value) {
      final HSVColor fromRGB = new HSVColor.fromColor(color);
      expect(fromRGB.alpha, closeTo(alpha, _doubleColorPrecision));
      expect(fromRGB.hue, closeTo(hue, _doubleColorPrecision));
      expect(fromRGB.saturation, closeTo(saturation, _doubleColorPrecision));
      expect(fromRGB.value, closeTo(value, _doubleColorPrecision));
      expect(fromRGB.toColor(), equals(color));

      final HSVColor fromHSV = new HSVColor.fromAHSV(alpha, hue, saturation, value);
      expect(fromHSV.toColor(), equals(color));
    }

    testColor(const Color(0xffffffff), 1.0, 0.0, 0.0, 1.0); // White
    testColor(const Color(0xff000000), 1.0, 0.0, 0.0, 0.0); // Black
    testColor(const Color(0xff808080), 1.0, 0.0, 0.0, 0.5); // Middle grey
    testColor(const Color(0xffff0000), 1.0, 0.0, 1.0, 1.0); // Red primary
    testColor(const Color(0xff00ff00), 1.0, 120.0, 1.0, 1.0); // Green primary
    testColor(const Color(0xff0000ff), 1.0, 240.0, 1.0, 1.0); // Blue primary
    testColor(const Color(0xffffffff).withAlpha(0x40), 0.25, 0.0, 0.0, 1.0); // With transparency.
    testColor(const Color(0xff000000).withAlpha(0xbf), 0.75, 0.0, 0.0, 0.0); // With transparency.
  });

  test('HSLColor control test', () {
    const HSLColor color = const HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.6);

    expect(color, hasOneLineDescription);
    expect(color.hashCode, equals(const HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.6).hashCode));

    expect(color.withAlpha(0.8), const HSLColor.fromAHSL(0.8, 28.0, 0.3, 0.6));
    expect(color.withHue(123.0), const HSLColor.fromAHSL(0.7, 123.0, 0.3, 0.6));
    expect(color.withSaturation(0.9), const HSLColor.fromAHSL(0.7, 28.0, 0.9, 0.6));
    expect(color.withValue(0.1), const HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.1));

    expect(color.toColor(), const Color(0xb3b8977a));

    final HSLColor result = HSLColor.lerp(color, const HSLColor.fromAHSL(0.3, 128.0, 0.7, 0.2), 0.25);
    expect(result.alpha, 0.6);
    expect(result.hue, 53.0);
    expect(result.saturation, greaterThan(0.3999));
    expect(result.saturation, lessThan(0.4001));
    expect(result.lightness, 0.5);
  });

  test('HSLColor converts RGB colors correctly.', () {
    void testColor(Color color, double alpha, double hue, double saturation, double lightness) {
      final HSLColor fromRGB = new HSLColor.fromColor(color);
      expect(fromRGB.alpha, closeTo(alpha, _doubleColorPrecision));
      expect(fromRGB.hue, closeTo(hue, _doubleColorPrecision));
      expect(fromRGB.saturation, closeTo(saturation, _doubleColorPrecision));
      expect(fromRGB.lightness, closeTo(lightness, _doubleColorPrecision));
      expect(fromRGB.toColor(), equals(color));

      final HSLColor fromHSL = new HSLColor.fromAHSL(alpha, hue, saturation, lightness);
      expect(fromHSL.toColor(), equals(color));
    }

    testColor(const Color(0xffffffff), 1.0, 0.0, 0.0, 1.0);
    testColor(const Color(0xff000000), 1.0, 0.0, 0.0, 0.0);
    testColor(const Color(0xff808080), 1.0, 0.0, 0.0, 0.5); // Middle grey
    testColor(const Color(0xffff0000), 1.0, 0.0, 1.0, 0.5); // Red primary
    testColor(const Color(0xff00ff00), 1.0, 120.0, 1.0, 0.5); // Green primary
    testColor(const Color(0xff0000ff), 1.0, 240.0, 1.0, 0.5); // Blue primary
    testColor(const Color(0xffffffff).withAlpha(0x40), 0.25, 0.0, 0.0, 1.0); // With transparency.
    testColor(const Color(0xff000000).withAlpha(0xbf), 0.75, 0.0, 0.0, 0.0); // With transparency.
  });

  test('ColorSwatch test', () {
    final int color = nonconst(0xFF027223);
    final ColorSwatch<String> greens1 = new ColorSwatch<String>(
      color, const <String, Color>{
        '2259 C': const Color(0xFF027223),
        '2273 C': const Color(0xFF257226),
        '2426 XGC': const Color(0xFF00932F),
        '7732 XGC': const Color(0xFF007940),
      },
    );
    final ColorSwatch<String> greens2 = new ColorSwatch<String>(
      color, const <String, Color>{
        '2259 C': const Color(0xFF027223),
        '2273 C': const Color(0xFF257226),
        '2426 XGC': const Color(0xFF00932F),
        '7732 XGC': const Color(0xFF007940),
      },
    );
    expect(greens1, greens2);
    expect(greens1.hashCode, greens2.hashCode);
    expect(greens1['2259 C'], const Color(0xFF027223));
    expect(greens1.value, 0xFF027223);
  });

  test('HSVColor lerps correctly.', () {
    final HSVColor white = HSVColor.fromColor(const Color(0xffffffff));
    final HSVColor black = HSVColor.fromColor(const Color(0xff000000));
    final HSVColor quarterGrey = HSVColor.fromColor(const Color(0xff404040));
    final HSVColor middleGrey = HSVColor.fromColor(const Color(0xff808080));
    final HSVColor threeQuarterGrey = HSVColor.fromColor(const Color(0xffbfbfbf));
    final HSVColor redPrimary = HSVColor.fromColor(const Color(0xffff0000));
    final HSVColor greenPrimary = HSVColor.fromColor(const Color(0xff00ff00));
    final HSVColor bluePrimary = HSVColor.fromColor(const Color(0xff0000ff));
    final HSVColor yellow = HSVColor.fromColor(const Color(0xffffff00));
    final HSVColor cyan = HSVColor.fromColor(const Color(0xff00ffff));
    expect(HSVColor.lerp(white, black, 0.25), within<HSVColor>(distance: _doubleColorPrecision, from: threeQuarterGrey));
    expect(HSVColor.lerp(white, black, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: middleGrey));
    expect(HSVColor.lerp(white, black, 0.75), within<HSVColor>(distance: _doubleColorPrecision, from: quarterGrey));
    expect(HSVColor.lerp(white.withAlpha(0.0), black, 0.25), within<HSVColor>(distance: _doubleColorPrecision, from: threeQuarterGrey.withAlpha(0.25)));
    expect(HSVColor.lerp(white.withAlpha(0.0), black, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: middleGrey.withAlpha(0.5)));
    expect(HSVColor.lerp(white.withAlpha(0.0), black, 0.75), within<HSVColor>(distance: _doubleColorPrecision, from: quarterGrey.withAlpha(0.75)));
    expect(HSVColor.lerp(redPrimary, greenPrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: yellow));
    expect(HSVColor.lerp(redPrimary, bluePrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: greenPrimary));
    expect(HSVColor.lerp(greenPrimary, bluePrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: cyan));
    expect(HSVColor.lerp(greenPrimary, redPrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: yellow));
    expect(HSVColor.lerp(bluePrimary, greenPrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: cyan));
    expect(HSVColor.lerp(bluePrimary, redPrimary, 0.5), within<HSVColor>(distance: _doubleColorPrecision, from: greenPrimary));
  });

  test('HSLColor lerps correctly.', () {
    final HSLColor white = HSLColor.fromColor(const Color(0xffffffff));
    final HSLColor black = HSLColor.fromColor(const Color(0xff000000));
    final HSLColor quarterGrey = HSLColor.fromColor(const Color(0xff404040));
    final HSLColor middleGrey = HSLColor.fromColor(const Color(0xff808080));
    final HSLColor threeQuarterGrey = HSLColor.fromColor(const Color(0xffbfbfbf));
    final HSLColor redPrimary = HSLColor.fromColor(const Color(0xffff0000));
    final HSLColor greenPrimary = HSLColor.fromColor(const Color(0xff00ff00));
    final HSLColor bluePrimary = HSLColor.fromColor(const Color(0xff0000ff));
    final HSLColor yellow = HSLColor.fromColor(const Color(0xffffff00));
    final HSLColor cyan = HSLColor.fromColor(const Color(0xff00ffff));
    expect(HSLColor.lerp(white, black, 0.25), within<HSLColor>(distance: _doubleColorPrecision, from: threeQuarterGrey));
    expect(HSLColor.lerp(white, black, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: middleGrey));
    expect(HSLColor.lerp(white, black, 0.75), within<HSLColor>(distance: _doubleColorPrecision, from: quarterGrey));
    expect(HSLColor.lerp(white.withAlpha(0.0), black, 0.25), within<HSLColor>(distance: _doubleColorPrecision, from: threeQuarterGrey.withAlpha(0.25)));
    expect(HSLColor.lerp(white.withAlpha(0.0), black, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: middleGrey.withAlpha(0.5)));
    expect(HSLColor.lerp(white.withAlpha(0.0), black, 0.75), within<HSLColor>(distance: _doubleColorPrecision, from: quarterGrey.withAlpha(0.75)));
    expect(HSLColor.lerp(redPrimary, greenPrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: yellow));
    expect(HSLColor.lerp(redPrimary, bluePrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: greenPrimary));
    expect(HSLColor.lerp(greenPrimary, bluePrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: cyan));
    expect(HSLColor.lerp(greenPrimary, redPrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: yellow));
    expect(HSLColor.lerp(bluePrimary, greenPrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: cyan));
    expect(HSLColor.lerp(bluePrimary, redPrimary, 0.5), within<HSLColor>(distance: _doubleColorPrecision, from: greenPrimary));
  });
}
