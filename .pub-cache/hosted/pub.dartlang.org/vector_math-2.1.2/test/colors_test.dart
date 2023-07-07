// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testToGrayscale() {
  final input = Vector4(0.0, 1.0, 0.5, 1.0);
  final output = input.clone();

  Colors.toGrayscale(output, output);

  relativeTest(output.r, 0.745);
  relativeTest(output.g, 0.745);
  relativeTest(output.b, 0.745);
  expect(output.a, equals(1.0));
}

void testHexString() {
  final color = Vector4.zero();

  Colors.fromHexString('#6495ED', color);

  relativeTest(color.r, 0.3921);
  relativeTest(color.g, 0.5843);
  relativeTest(color.b, 0.9294);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color), equals('6495ed'));

  Colors.fromHexString('#6495eD', color);

  relativeTest(color.r, 0.3921);
  relativeTest(color.g, 0.5843);
  relativeTest(color.b, 0.9294);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color), equals('6495ed'));

  Colors.fromHexString('6495eD', color);

  relativeTest(color.r, 0.3921);
  relativeTest(color.g, 0.5843);
  relativeTest(color.b, 0.9294);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color), equals('6495ed'));

  Colors.fromHexString('#F0F', color);

  relativeTest(color.r, 1.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 1.0);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color), equals('ff00ff'));

  Colors.fromHexString('#88FF00fF', color);

  relativeTest(color.r, 1.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 1.0);
  relativeTest(color.a, 0.5333);

  expect(Colors.toHexString(color, alpha: true), equals('88ff00ff'));

  Colors.fromHexString('#8F0f', color);

  relativeTest(color.r, 1.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 1.0);
  relativeTest(color.a, 0.5333);

  expect(Colors.toHexString(color, alpha: true), equals('88ff00ff'));

  Colors.fromHexString('#8F0f', color);

  relativeTest(color.r, 1.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 1.0);
  relativeTest(color.a, 0.5333);

  expect(Colors.toHexString(color, alpha: true), equals('88ff00ff'));

  Colors.fromHexString('#8F0f', color);

  relativeTest(color.r, 1.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 1.0);
  relativeTest(color.a, 0.5333);

  expect(Colors.toHexString(color, alpha: true, short: true), equals('8f0f'));

  Colors.fromHexString('#00FF00', color);

  relativeTest(color.r, 0.0);
  relativeTest(color.g, 1.0);
  relativeTest(color.b, 0.0);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color, short: true), equals('0f0'));

  Colors.fromHexString('#00FF00', color);

  relativeTest(color.r, 0.0);
  relativeTest(color.g, 1.0);
  relativeTest(color.b, 0.0);
  relativeTest(color.a, 1.0);

  expect(Colors.toHexString(color), equals('00ff00'));

  Colors.fromHexString('#00000000', color);

  relativeTest(color.r, 0.0);
  relativeTest(color.g, 0.0);
  relativeTest(color.b, 0.0);
  relativeTest(color.a, 0.0);

  expect(Colors.toHexString(color, alpha: true), equals('00000000'));

  expect(() => Colors.fromHexString('vector_math rules!', color),
      throwsA(isA<FormatException>()));
}

void testFromRgba() {
  final output = Vector4.zero();

  Colors.fromRgba(100, 149, 237, 255, output);

  relativeTest(output.r, 0.3921);
  relativeTest(output.g, 0.5843);
  relativeTest(output.b, 0.9294);
  expect(output.a, equals(1.0));
}

void testAlphaBlend() {
  final output = Vector4.zero();
  final foreground1 = Vector4(0.3921, 0.5843, 0.9294, 1.0);
  final foreground2 = Vector4(0.3921, 0.5843, 0.9294, 0.5);
  final background1 = Vector4(1.0, 0.0, 0.0, 1.0);
  final background2 = Vector4(1.0, 0.5, 0.0, 0.5);

  output.setFrom(foreground1);
  Colors.alphaBlend(output, background1, output);

  relativeTest(output.r, 0.3921);
  relativeTest(output.g, 0.5843);
  relativeTest(output.b, 0.9294);
  expect(output.a, equals(1.0));

  output.setFrom(background2);
  Colors.alphaBlend(foreground1, output, output);

  relativeTest(output.r, 0.3921);
  relativeTest(output.g, 0.5843);
  relativeTest(output.b, 0.9294);
  expect(output.a, equals(1.0));

  Colors.alphaBlend(foreground2, background1, output);

  relativeTest(output.r, 0.6960);
  relativeTest(output.g, 0.2921);
  relativeTest(output.b, 0.4647);
  expect(output.a, equals(1.0));

  Colors.alphaBlend(foreground2, background2, output);

  relativeTest(output.r, 0.5947);
  relativeTest(output.g, 0.5561);
  relativeTest(output.b, 0.6195);
  expect(output.a, equals(0.75));
}

void testLinearGamma() {
  final gamma = Vector4.zero();
  final linear = Vector4.zero();
  final foreground = Vector4(0.3921, 0.5843, 0.9294, 1.0);

  gamma.setFrom(foreground);
  Colors.linearToGamma(gamma, gamma);

  relativeTest(gamma.r, 0.6534);
  relativeTest(gamma.g, 0.7832);
  relativeTest(gamma.b, 0.9672);
  expect(gamma.a, equals(foreground.a));

  linear.setFrom(gamma);
  Colors.gammaToLinear(linear, linear);

  relativeTest(linear.r, foreground.r);
  relativeTest(linear.g, foreground.g);
  relativeTest(linear.b, foreground.b);
  expect(linear.a, equals(foreground.a));
}

void testRgbHsl() {
  final hsl = Vector4.zero();
  final rgb = Vector4.zero();
  final input = Vector4(0.3921, 0.5843, 0.9294, 1.0);

  hsl.setFrom(input);
  Colors.rgbToHsl(hsl, hsl);

  relativeTest(hsl.x, 0.6070);
  relativeTest(hsl.y, 0.7920);
  relativeTest(hsl.z, 0.6607);
  expect(hsl.a, equals(input.a));

  rgb.setFrom(hsl);
  Colors.hslToRgb(rgb, rgb);

  relativeTest(rgb.r, input.r);
  relativeTest(rgb.g, input.g);
  relativeTest(rgb.b, input.b);
  expect(rgb.a, equals(input.a));

  void testRoundtrip(Vector4 input) {
    final result = input.clone();

    Colors.rgbToHsl(result, result);
    Colors.hslToRgb(result, result);

    absoluteTest(result.r, input.r);
    absoluteTest(result.g, input.g);
    absoluteTest(result.b, input.b);
    expect(result.a, equals(input.a));
  }

  testRoundtrip(Colors.red);
  testRoundtrip(Colors.green);
  testRoundtrip(Colors.blue);
  testRoundtrip(Colors.black);
  testRoundtrip(Colors.white);
  testRoundtrip(Colors.gray);
  testRoundtrip(Colors.yellow);
  testRoundtrip(Colors.fuchsia);
}

void testRgbHsv() {
  final hsv = Vector4.zero();
  final rgb = Vector4.zero();
  final input = Vector4(0.3921, 0.5843, 0.9294, 1.0);

  hsv.setFrom(input);
  Colors.rgbToHsv(hsv, hsv);

  relativeTest(hsv.x, 0.6070);
  relativeTest(hsv.y, 0.5781);
  relativeTest(hsv.z, 0.9294);
  expect(hsv.a, equals(input.a));

  rgb.setFrom(hsv);
  Colors.hsvToRgb(rgb, rgb);

  relativeTest(rgb.r, input.r);
  relativeTest(rgb.g, input.g);
  relativeTest(rgb.b, input.b);
  expect(rgb.a, equals(input.a));

  void testRoundtrip(Vector4 input) {
    final result = input.clone();

    Colors.rgbToHsv(result, result);
    Colors.hsvToRgb(result, result);

    absoluteTest(result.r, input.r);
    absoluteTest(result.g, input.g);
    absoluteTest(result.b, input.b);
    expect(result.a, equals(input.a));
  }

  testRoundtrip(Colors.red);
  testRoundtrip(Colors.green);
  testRoundtrip(Colors.blue);
  testRoundtrip(Colors.black);
  testRoundtrip(Colors.white);
  testRoundtrip(Colors.gray);
  testRoundtrip(Colors.yellow);
  testRoundtrip(Colors.fuchsia);
}

void main() {
  group('Colors', () {
    test('From RGBA', testFromRgba);
    test('Hex String', testHexString);
    test('To Grayscale', testToGrayscale);
    test('Alpha Blend', testAlphaBlend);
    test('Linear/Gamma', testLinearGamma);
    test('RGB/HSL', testRgbHsl);
    test('RGB/HSV', testRgbHsv);
  });
}
