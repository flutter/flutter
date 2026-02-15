// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _doubleColorPrecision = 0.01;

void main() {
  test('HSVColor control test', () {
    const color = HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.6);

    expect(color, hasOneLineDescription);
    expect(color.hashCode, equals(const HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.6).hashCode));

    expect(color.withAlpha(0.8), const HSVColor.fromAHSV(0.8, 28.0, 0.3, 0.6));
    expect(color.withHue(123.0), const HSVColor.fromAHSV(0.7, 123.0, 0.3, 0.6));
    expect(color.withSaturation(0.9), const HSVColor.fromAHSV(0.7, 28.0, 0.9, 0.6));
    expect(color.withValue(0.1), const HSVColor.fromAHSV(0.7, 28.0, 0.3, 0.1));

    expect(color.toColor(), const Color(0xb399816b));

    final HSVColor result = HSVColor.lerp(
      color,
      const HSVColor.fromAHSV(0.3, 128.0, 0.7, 0.2),
      0.25,
    )!;
    expect(result.alpha, moreOrLessEquals(0.6));
    expect(result.hue, moreOrLessEquals(53.0));
    expect(result.saturation, greaterThan(0.3999));
    expect(result.saturation, lessThan(0.4001));
    expect(result.value, moreOrLessEquals(0.5));
  });

  test('HSVColor hue sweep test', () {
    final output = <Color>[];
    for (var hue = 0.0; hue <= 360.0; hue += 36.0) {
      final hsvColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0);
      final Color color = hsvColor.toColor();
      output.add(color);
      if (hue != 360.0) {
        // Check that it's reversible.
        expect(
          HSVColor.fromColor(color),
          within<HSVColor>(distance: _doubleColorPrecision, from: hsvColor),
        );
      }
    }
    final expectedColors = <Color>[
      const Color(0xffff0000),
      const Color(0xffff9900),
      const Color(0xffccff00),
      const Color(0xff33ff00),
      const Color(0xff00ff66),
      const Color(0xff00ffff),
      const Color(0xff0066ff),
      const Color(0xff3300ff),
      const Color(0xffcc00ff),
      const Color(0xffff0099),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSVColor saturation sweep test', () {
    final output = <Color>[];
    for (var saturation = 0.0; saturation < 1.0; saturation += 0.1) {
      final hslColor = HSVColor.fromAHSV(1.0, 0.0, saturation, 1.0);
      final Color color = hslColor.toColor();
      output.add(color);
      // Check that it's reversible.
      expect(
        HSVColor.fromColor(color),
        within<HSVColor>(distance: _doubleColorPrecision, from: hslColor),
      );
    }
    final expectedColors = <Color>[
      const Color(0xffffffff),
      const Color(0xffffe6e6),
      const Color(0xffffcccc),
      const Color(0xffffb3b3),
      const Color(0xffff9999),
      const Color(0xffff8080),
      const Color(0xffff6666),
      const Color(0xffff4d4d),
      const Color(0xffff3333),
      const Color(0xffff1a1a),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSVColor value sweep test', () {
    final output = <Color>[];
    for (var value = 0.0; value < 1.0; value += 0.1) {
      final hsvColor = HSVColor.fromAHSV(1.0, 0.0, 1.0, value);
      final Color color = hsvColor.toColor();
      output.add(color);
      // Check that it's reversible. Discontinuities at the ends for saturation,
      // so we skip those.
      if (value >= _doubleColorPrecision && value <= (1.0 - _doubleColorPrecision)) {
        expect(
          HSVColor.fromColor(color),
          within<HSVColor>(distance: _doubleColorPrecision, from: hsvColor),
        );
      }
      // output.add(HSVColor.fromAHSV(1.0, 0.0, 1.0, value).toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff000000),
      const Color(0xff1a0000),
      const Color(0xff330000),
      const Color(0xff4d0000),
      const Color(0xff660000),
      const Color(0xff800000),
      const Color(0xff990000),
      const Color(0xffb30000),
      const Color(0xffcc0000),
      const Color(0xffe50000),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSVColor.lerp identical a,b', () {
    expect(HSVColor.lerp(null, null, 0), null);
    const color = HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);
    expect(identical(HSVColor.lerp(color, color, 0.5), color), true);
  });

  test('HSVColor lerps hue correctly.', () {
    final output = <Color>[];
    const startColor = HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);
    const endColor = HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0);

    for (var t = -0.5; t < 1.5; t += 0.1) {
      output.add(HSVColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff00ffff),
      const Color(0xff0066ff),
      const Color(0xff3300ff),
      const Color(0xffcc00ff),
      const Color(0xffff0099),
      const Color(0xffff0000),
      const Color(0xffff9900),
      const Color(0xffccff00),
      const Color(0xff33ff00),
      const Color(0xff00ff66),
      const Color(0xff00ffff),
      const Color(0xff0066ff),
      const Color(0xff3300ff),
      const Color(0xffcc00ff),
      const Color(0xffff0099),
      const Color(0xffff0000),
      const Color(0xffff9900),
      const Color(0xffccff00),
      const Color(0xff33ff00),
      const Color(0xff00ff66),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSVColor lerps saturation correctly.', () {
    final output = <Color>[];
    const startColor = HSVColor.fromAHSV(1.0, 0.0, 0.0, 1.0);
    const endColor = HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);

    for (var t = -0.1; t < 1.1; t += 0.1) {
      output.add(HSVColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xffffffff),
      const Color(0xffffffff),
      const Color(0xffffe6e6),
      const Color(0xffffcccc),
      const Color(0xffffb3b3),
      const Color(0xffff9999),
      const Color(0xffff8080),
      const Color(0xffff6666),
      const Color(0xffff4d4d),
      const Color(0xffff3333),
      const Color(0xffff1a1a),
      const Color(0xffff0000),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSVColor lerps value correctly.', () {
    final output = <Color>[];
    const startColor = HSVColor.fromAHSV(1.0, 0.0, 1.0, 0.0);
    const endColor = HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);

    for (var t = -0.1; t < 1.1; t += 0.1) {
      output.add(HSVColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff000000),
      const Color(0xff000000),
      const Color(0xff1a0000),
      const Color(0xff330000),
      const Color(0xff4d0000),
      const Color(0xff660000),
      const Color(0xff800000),
      const Color(0xff990000),
      const Color(0xffb30000),
      const Color(0xffcc0000),
      const Color(0xffe50000),
      const Color(0xffff0000),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSLColor control test', () {
    const color = HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.6);

    expect(color, hasOneLineDescription);
    expect(color.hashCode, equals(const HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.6).hashCode));

    expect(color.withAlpha(0.8), const HSLColor.fromAHSL(0.8, 28.0, 0.3, 0.6));
    expect(color.withHue(123.0), const HSLColor.fromAHSL(0.7, 123.0, 0.3, 0.6));
    expect(color.withSaturation(0.9), const HSLColor.fromAHSL(0.7, 28.0, 0.9, 0.6));
    expect(color.withLightness(0.1), const HSLColor.fromAHSL(0.7, 28.0, 0.3, 0.1));

    expect(color.toColor(), const Color(0xb3b8977a));

    final HSLColor result = HSLColor.lerp(
      color,
      const HSLColor.fromAHSL(0.3, 128.0, 0.7, 0.2),
      0.25,
    )!;
    expect(result.alpha, moreOrLessEquals(0.6));
    expect(result.hue, moreOrLessEquals(53.0));
    expect(result.saturation, greaterThan(0.3999));
    expect(result.saturation, lessThan(0.4001));
    expect(result.lightness, moreOrLessEquals(0.5));
  });

  test('HSLColor hue sweep test', () {
    final output = <Color>[];
    for (var hue = 0.0; hue <= 360.0; hue += 36.0) {
      final hslColor = HSLColor.fromAHSL(1.0, hue, 0.5, 0.5);
      final Color color = hslColor.toColor();
      output.add(color);
      if (hue != 360.0) {
        // Check that it's reversible.
        expect(
          HSLColor.fromColor(color),
          within<HSLColor>(distance: _doubleColorPrecision, from: hslColor),
        );
      }
    }
    final expectedColors = <Color>[
      const Color(0xffbf4040),
      const Color(0xffbf8c40),
      const Color(0xffa6bf40),
      const Color(0xff59bf40),
      const Color(0xff40bf73),
      const Color(0xff40bfbf),
      const Color(0xff4073bf),
      const Color(0xff5940bf),
      const Color(0xffa640bf),
      const Color(0xffbf408c),
      const Color(0xffbf4040),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSLColor saturation sweep test', () {
    final output = <Color>[];
    for (var saturation = 0.0; saturation < 1.0; saturation += 0.1) {
      final hslColor = HSLColor.fromAHSL(1.0, 0.0, saturation, 0.5);
      final Color color = hslColor.toColor();
      output.add(color);
      // Check that it's reversible.
      expect(
        HSLColor.fromColor(color),
        within<HSLColor>(distance: _doubleColorPrecision, from: hslColor),
      );
    }
    final expectedColors = <Color>[
      const Color(0xff808080),
      const Color(0xff8c7373),
      const Color(0xff996666),
      const Color(0xffa65959),
      const Color(0xffb34d4d),
      const Color(0xffbf4040),
      const Color(0xffcc3333),
      const Color(0xffd92626),
      const Color(0xffe51a1a),
      const Color(0xfff20d0d),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSLColor lightness sweep test', () {
    final output = <Color>[];
    for (var lightness = 0.0; lightness < 1.0; lightness += 0.1) {
      final hslColor = HSLColor.fromAHSL(1.0, 0.0, 0.5, lightness);
      final Color color = hslColor.toColor();
      output.add(color);
      // Check that it's reversible. Discontinuities at the ends for saturation,
      // so we skip those.
      if (lightness >= _doubleColorPrecision && lightness <= (1.0 - _doubleColorPrecision)) {
        expect(
          HSLColor.fromColor(color),
          within<HSLColor>(distance: _doubleColorPrecision, from: hslColor),
        );
      }
    }
    final expectedColors = <Color>[
      const Color(0xff000000),
      const Color(0xff260d0d),
      const Color(0xff4d1a1a),
      const Color(0xff732626),
      const Color(0xff993333),
      const Color(0xffbf4040),
      const Color(0xffcc6666),
      const Color(0xffd98c8c),
      const Color(0xffe6b3b3),
      const Color(0xfff2d9d9),
      const Color(0xffffffff),
    ];
    expect(output, equals(expectedColors));
  });

  group('HSLColor.fromColor tests', () {
    test('Pink', () {
      const color = Color.fromARGB(255, 255, 51, 152);
      final hslColor = HSLColor.fromColor(color);
      expect(hslColor.alpha, 1.0);
      expect(hslColor.hue, within<double>(distance: .3, from: 330));
      expect(hslColor.saturation, 1.0);
      expect(hslColor.lightness, within<double>(distance: _doubleColorPrecision, from: 0.6));
    });

    test('White', () {
      const color = Color(0xffffffff);
      final hslColor = HSLColor.fromColor(color);
      expect(hslColor.alpha, 1.0);
      expect(hslColor.hue, 0.0);
      expect(hslColor.saturation, 0.0);
      expect(hslColor.lightness, 1.0);
    });

    test('Black', () {
      const color = Color(0xff000000);
      final hslColor = HSLColor.fromColor(color);
      expect(hslColor.alpha, 1.0);
      expect(hslColor.hue, 0.0);
      expect(hslColor.saturation, 0.0);
      expect(hslColor.lightness, 0.0);
    });

    test('Gray', () {
      const color = Color(0xff808080);
      final hslColor = HSLColor.fromColor(color);
      expect(hslColor.alpha, 1.0);
      expect(hslColor.hue, 0.0);
      expect(hslColor.saturation, 0.0);
      expect(hslColor.lightness, within<double>(distance: _doubleColorPrecision, from: 0.5));
    });
  });

  test('HSLColor.lerp identical a,b', () {
    expect(HSLColor.lerp(null, null, 0), null);
    const color = HSLColor.fromAHSL(1.0, 0.0, 0.5, 0.5);
    expect(identical(HSLColor.lerp(color, color, 0.5), color), true);
  });

  test('HSLColor lerps hue correctly.', () {
    final output = <Color>[];
    const startColor = HSLColor.fromAHSL(1.0, 0.0, 0.5, 0.5);
    const endColor = HSLColor.fromAHSL(1.0, 360.0, 0.5, 0.5);

    for (var t = -0.5; t < 1.5; t += 0.1) {
      output.add(HSLColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff40bfbf),
      const Color(0xff4073bf),
      const Color(0xff5940bf),
      const Color(0xffa640bf),
      const Color(0xffbf408c),
      const Color(0xffbf4040),
      const Color(0xffbf8c40),
      const Color(0xffa6bf40),
      const Color(0xff59bf40),
      const Color(0xff40bf73),
      const Color(0xff40bfbf),
      const Color(0xff4073bf),
      const Color(0xff5940bf),
      const Color(0xffa640bf),
      const Color(0xffbf408c),
      const Color(0xffbf4040),
      const Color(0xffbf8c40),
      const Color(0xffa6bf40),
      const Color(0xff59bf40),
      const Color(0xff40bf73),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSLColor lerps saturation correctly.', () {
    final output = <Color>[];
    const startColor = HSLColor.fromAHSL(1.0, 0.0, 0.0, 0.5);
    const endColor = HSLColor.fromAHSL(1.0, 0.0, 1.0, 0.5);

    for (var t = -0.1; t < 1.1; t += 0.1) {
      output.add(HSLColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff808080),
      const Color(0xff808080),
      const Color(0xff8c7373),
      const Color(0xff996666),
      const Color(0xffa65959),
      const Color(0xffb34d4d),
      const Color(0xffbf4040),
      const Color(0xffcc3333),
      const Color(0xffd92626),
      const Color(0xffe51a1a),
      const Color(0xfff20d0d),
      const Color(0xffff0000),
      const Color(0xffff0000),
    ];
    expect(output, equals(expectedColors));
  });

  test('HSLColor lerps lightness correctly.', () {
    final output = <Color>[];
    const startColor = HSLColor.fromAHSL(1.0, 0.0, 0.5, 0.0);
    const endColor = HSLColor.fromAHSL(1.0, 0.0, 0.5, 1.0);

    for (var t = -0.1; t < 1.1; t += 0.1) {
      output.add(HSLColor.lerp(startColor, endColor, t)!.toColor());
    }
    final expectedColors = <Color>[
      const Color(0xff000000),
      const Color(0xff000000),
      const Color(0xff260d0d),
      const Color(0xff4d1a1a),
      const Color(0xff732626),
      const Color(0xff993333),
      const Color(0xffbf4040),
      const Color(0xffcc6666),
      const Color(0xffd98c8c),
      const Color(0xffe6b3b3),
      const Color(0xfff2d9d9),
      const Color(0xffffffff),
      const Color(0xffffffff),
    ];
    expect(output, equals(expectedColors));
  });

  // Tests the implementation against these colors from Wikipedia
  // https://en.wikipedia.org/wiki/HSL_and_HSV#Examples
  test('Wikipedia Examples Table test', () {
    // ignore: always_specify_types
    final colors = <(int, double, double, double, double, double, double, double, double, String)>[
      // RGB,        r,   g,   b, hue,   v,   l,s(hsv),s(hsl)
      (0xFFFFFFFF, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 'white'),
      (0xFF808080, 0.5, 0.5, 0.5, 0.0, 0.5, 0.5, 0.0, 0.0, 'gray'),
      (0xFF000000, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 'black'),
      (0xFFFF0000, 1.0, 0.0, 0.0, 0.0, 1.0, 0.5, 1.0, 1.0, 'red'),
      (0xFFBFBF00, .75, .75, 0.0, 60, .75, .375, 1.0, 1.0, 'lime'),
      (0xFF008000, 0.0, 0.5, 0.0, 120, 0.5, .25, 1.0, 1.0, 'green'),
      (0xFF80FFFF, 0.5, 1.0, 1.0, 180, 1.0, 0.75, 0.5, 1, 'cyan'),
      (0xFF8080FF, 0.5, 0.5, 1.0, 240, 1.0, 0.75, 0.5, 1, 'light purple'),
      (0xFFBF40BF, 0.75, 0.25, 0.75, 300, .75, .5, 2.0 / 3, .5, 'mute magenta'),
    ];

    for (final (
          int rgb,
          double r,
          double g,
          double b,
          double hue,
          double v,
          double l,
          double sHSV,
          double sHSL,
          String name,
        )
        in colors) {
      final color = Color.from(alpha: 1.0, red: r, green: g, blue: b);
      final debugColorConstructor = 'Color.from(alpha: 1.0, red: $r, green: $g, blue: $b)';
      final intColor = Color(rgb);
      expect(
        intColor.r,
        within<double>(distance: _doubleColorPrecision, from: r),
        reason: '$name: Color($rgb).r should be $r',
      );
      expect(
        intColor.g,
        within<double>(distance: _doubleColorPrecision, from: g),
        reason: '$name: Color($rgb).g should be $g',
      );
      expect(
        intColor.b,
        within<double>(distance: _doubleColorPrecision, from: b),
        reason: '$name: Color($rgb).b should be $b',
      );
      final hsv = HSVColor.fromAHSV(1.0, hue, sHSV, v);
      final hsl = HSLColor.fromAHSL(1.0, hue, sHSL, l);
      expect(
        color,
        within<Color>(distance: _doubleColorPrecision, from: intColor),
        reason: '$name: $debugColorConstructor should be close to Color($rgb)',
      );
      expect(
        hsv.toColor(),
        within<Color>(distance: _doubleColorPrecision, from: color),
        reason:
            '$name: HSVColor.fromAHSV(1.0, $hue, $sHSV, $v).hsv should be close to $debugColorConstructor',
      );
      expect(
        hsl.toColor(),
        within<Color>(distance: _doubleColorPrecision, from: color),
        reason:
            '$name: HSLColor.fromAHSL(1.0, $hue, $sHSL, $l).hsl should be close to $debugColorConstructor',
      );
      expect(
        HSVColor.fromColor(color),
        within<HSVColor>(distance: _doubleColorPrecision, from: hsv),
        reason:
            '$name: HSVColor.fromColor($debugColorConstructor) should be close to HSVColor.fromAHSV(1.0, $hue, $sHSV, $v)',
      );
      expect(
        HSLColor.fromColor(color),
        within<HSLColor>(distance: _doubleColorPrecision, from: hsl),
        reason:
            '$name: HSLColor.fromColor($debugColorConstructor) should be close to HSLColor.fromAHSL(1.0, $hue, $sHSL, $l)',
      );
    }
  });

  test('ColorSwatch test', () {
    final int color = nonconst(0xFF027223);
    final greens1 = ColorSwatch<String>(color, const <String, Color>{
      '2259 C': Color(0xFF027223),
      '2273 C': Color(0xFF257226),
      '2426 XGC': Color(0xFF00932F),
      '7732 XGC': Color(0xFF007940),
    });
    final greens2 = ColorSwatch<String>(color, const <String, Color>{
      '2259 C': Color(0xFF027223),
      '2273 C': Color(0xFF257226),
      '2426 XGC': Color(0xFF00932F),
      '7732 XGC': Color(0xFF007940),
    });
    expect(greens1, greens2);
    expect(greens1.hashCode, greens2.hashCode);
    expect(greens1['2259 C'], const Color(0xFF027223));
    expect(greens1.value, 0xFF027223);
    expect(listEquals(greens1.keys.toList(), greens2.keys.toList()), isTrue);
  });

  test('ColorSwatch.lerp', () {
    const swatchA = ColorSwatch<int>(0x00000000, <int, Color>{1: Color(0x00000000)});
    const swatchB = ColorSwatch<int>(0xFFFFFFFF, <int, Color>{1: Color(0xFFFFFFFF)});
    expect(
      ColorSwatch.lerp(swatchA, swatchB, 0.0),
      isSameColorAs(const ColorSwatch<int>(0x00000000, <int, Color>{1: Color(0x00000000)})),
    );
    expect(
      ColorSwatch.lerp(swatchA, swatchB, 0.5),
      isSameColorAs(const ColorSwatch<int>(0x7F7F7F7F, <int, Color>{1: Color(0x7F7F7F7F)})),
    );
    expect(
      ColorSwatch.lerp(swatchA, swatchB, 1.0),
      isSameColorAs(const ColorSwatch<int>(0xFFFFFFFF, <int, Color>{1: Color(0xFFFFFFFF)})),
    );
    expect(
      ColorSwatch.lerp(swatchA, swatchB, -0.1),
      isSameColorAs(const ColorSwatch<int>(0x00000000, <int, Color>{1: Color(0x00000000)})),
    );
    expect(
      ColorSwatch.lerp(swatchA, swatchB, 1.1),
      isSameColorAs(const ColorSwatch<int>(0xFFFFFFFF, <int, Color>{1: Color(0xFFFFFFFF)})),
    );
  });

  test('ColorSwatch.lerp identical a,b', () {
    expect(ColorSwatch.lerp<Object?>(null, null, 0), null);
    const color = ColorSwatch<int>(0x00000000, <int, Color>{1: Color(0x00000000)});
    expect(identical(ColorSwatch.lerp(color, color, 0.5), color), true);
  });

  test('ColorDiagnosticsProperty includes valueProperties in JSON', () {
    var property = ColorProperty('foo', const Color.fromARGB(10, 20, 30, 40));
    final valueProperties =
        property.toJsonMap(const DiagnosticsSerializationDelegate())['valueProperties']!
            as Map<String, Object>;
    expect(valueProperties['alpha'], 10);
    expect(valueProperties['red'], 20);
    expect(valueProperties['green'], 30);
    expect(valueProperties['blue'], 40);

    property = ColorProperty('foo', null);
    final Map<String, Object?> json = property.toJsonMap(const DiagnosticsSerializationDelegate());
    expect(json.containsKey('valueProperties'), isFalse);
  });

  test('MaterialColor swatch comparison', () {
    const sampleMap = <int, MaterialColor>{
      0: Colors.lightBlue,
      1: Colors.deepOrange,
      2: Colors.blueGrey,
    };
    const first = MaterialColor(0, sampleMap);
    const second = MaterialColor(0, sampleMap);
    const third = MaterialColor(0, <int, MaterialColor>{
      0: Colors.lightBlue,
      1: Colors.deepOrange,
      2: Colors.blueGrey,
    });
    expect(first == second, true);
    expect(first == third, true);
  });
}
