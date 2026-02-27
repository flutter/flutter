// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wide_gamut_test/main.dart' as app;

// See: https://developer.apple.com/documentation/metal/mtlpixelformat/mtlpixelformatbgr10_xr.
double _decodeBGR10(int x) {
  const max = 1.25098;
  const min = -0.752941;
  const intercept = min;
  const double slope = (max - min) / 1024.0;
  return (x * slope) + intercept;
}

double _decodeHalf(int x) {
  if (x == 0x7c00) {
    return double.infinity;
  }
  if (x == 0xfc00) {
    return -double.infinity;
  }
  final sign = x & 0x8000 == 0 ? 1.0 : -1.0;
  final int exponent = (x >> 10) & 0x1f;
  final int fraction = x & 0x3ff;
  if (exponent == 0) {
    return sign * math.pow(2.0, -14) * (fraction / 1024.0);
  } else {
    return sign * math.pow(2.0, exponent - 15) * (1.0 + fraction / 1024.0);
  }
}

bool _isAlmost(double x, double y, double epsilon) {
  return (x - y).abs() < epsilon;
}

double _distanceSquared(double r, double g, double b, List<double> color) {
  return (r - color[0]) * (r - color[0]) +
      (g - color[1]) * (g - color[1]) +
      (b - color[2]) * (b - color[2]);
}

List<double> _deepRed = <double>[1.0931, -0.2268, -0.1501];

(bool, List<double>) _findRGBAF16Color(
  Uint8List bytes,
  int width,
  int height,
  List<double> color, {
  required double epsilon,
}) {
  final byteData = ByteData.sublistView(bytes);
  expect(bytes.lengthInBytes, width * height * 8);
  expect(bytes.lengthInBytes, byteData.lengthInBytes);
  var foundColor = false;
  double minDistance = double.infinity;
  var closestColor = <double>[0, 0, 0];
  for (var i = 0; i < bytes.lengthInBytes; i += 8) {
    final int pixel = byteData.getUint64(i, Endian.host);
    final double blue = _decodeHalf((pixel >> 32) & 0xffff);
    final double green = _decodeHalf((pixel >> 16) & 0xffff);
    final double red = _decodeHalf((pixel >> 0) & 0xffff);
    if (_isAlmost(red, color[0], epsilon) &&
        _isAlmost(green, color[1], epsilon) &&
        _isAlmost(blue, color[2], epsilon)) {
      foundColor = true;
    }
    final double currentDistance = _distanceSquared(red, green, blue, color);
    if (currentDistance < minDistance) {
      minDistance = currentDistance;
      closestColor = <double>[red, green, blue];
    }
  }
  return (foundColor, closestColor);
}

(bool, List<double>) _findBGRA10Color(
  Uint8List bytes,
  int width,
  int height,
  List<double> color, {
  required double epsilon,
}) {
  final byteData = ByteData.sublistView(bytes);
  expect(bytes.lengthInBytes, width * height * 8);
  expect(bytes.lengthInBytes, byteData.lengthInBytes);
  var foundColor = false;
  double minDistance = double.infinity;
  var closestColor = <double>[0, 0, 0];
  for (var i = 0; i < bytes.lengthInBytes; i += 8) {
    final int pixel = byteData.getUint64(i, Endian.host);
    final double blue = _decodeBGR10((pixel >> 6) & 0x3ff);
    final double green = _decodeBGR10((pixel >> 22) & 0x3ff);
    final double red = _decodeBGR10((pixel >> 38) & 0x3ff);
    if (_isAlmost(red, color[0], epsilon) &&
        _isAlmost(green, color[1], epsilon) &&
        _isAlmost(blue, color[2], epsilon)) {
      foundColor = true;
    }
    final double currentDistance = _distanceSquared(red, green, blue, color);
    if (currentDistance < minDistance) {
      minDistance = currentDistance;
      closestColor = <double>[red, green, blue];
    }
  }
  return (foundColor, closestColor);
}

(bool, List<double>) _findBGR10Color(
  Uint8List bytes,
  int width,
  int height,
  List<double> color, {
  required double epsilon,
}) {
  final byteData = ByteData.sublistView(bytes);
  expect(bytes.lengthInBytes, width * height * 4);
  expect(bytes.lengthInBytes, byteData.lengthInBytes);
  var foundColor = false;
  double minDistance = double.infinity;
  var closestColor = <double>[0, 0, 0];
  for (var i = 0; i < bytes.lengthInBytes; i += 4) {
    final int pixel = byteData.getUint32(i, Endian.host);
    final double blue = _decodeBGR10(pixel & 0x3ff);
    final double green = _decodeBGR10((pixel >> 10) & 0x3ff);
    final double red = _decodeBGR10((pixel >> 20) & 0x3ff);
    if (_isAlmost(red, color[0], epsilon) &&
        _isAlmost(green, color[1], epsilon) &&
        _isAlmost(blue, color[2], epsilon)) {
      foundColor = true;
    }
    final double currentDistance = _distanceSquared(red, green, blue, color);
    if (currentDistance < minDistance) {
      minDistance = currentDistance;
      closestColor = <double>[red, green, blue];
    }
  }
  return (foundColor, closestColor);
}

(bool, List<double>) _findColor(List<dynamic> result, List<double> color, {double epsilon = 0.01}) {
  expect(result, isNotNull);
  expect(result.length, 4);
  final [int width, int height, String format, Uint8List bytes] = result;
  return switch (format) {
    'MTLPixelFormatBGR10_XR' => _findBGR10Color(bytes, width, height, color, epsilon: epsilon),
    'MTLPixelFormatBGRA10_XR' => _findBGRA10Color(bytes, width, height, color, epsilon: epsilon),
    'MTLPixelFormatRGBA16Float' => _findRGBAF16Color(bytes, width, height, color, epsilon: epsilon),
    _ => fail('Unsupported pixel format: $format'),
  };
}

class _HasColor extends Matcher {
  const _HasColor(this.color, {this.epsilon = 0.01});

  final List<double> color;
  final double epsilon;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final (bool found, List<double> closest) = _findColor(
      item as List<dynamic>,
      color,
      epsilon: epsilon,
    );
    matchState['closest'] = closest;
    return found;
  }

  @override
  Description describe(Description description) {
    return description.add('contains color $color');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final closest = matchState['closest'] as List<double>;
    return mismatchDescription.add('closest color to $color was $closest');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('look for display p3 deepest red', (WidgetTester tester) async {
      app.run(app.Setup.image);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
    });
    testWidgets('look for display p3 deepest red', (WidgetTester tester) async {
      app.run(app.Setup.canvasSaveLayer);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
    });
    testWidgets('no p3 deepest red without image', (WidgetTester tester) async {
      app.run(app.Setup.none);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, isNot(_HasColor(_deepRed)));
      expect(result, isNot(const _HasColor(<double>[0.0, 1.0, 0.0])));
    });
    testWidgets('p3 deepest red with blur', (WidgetTester tester) async {
      app.run(app.Setup.blur);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
      expect(result, const _HasColor(<double>[0.0, 1.0, 0.0]));
    });
    testWidgets('draw image with wide gamut works', (WidgetTester tester) async {
      app.run(app.Setup.drawnImage);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, const _HasColor(<double>[0.0, 1.0, 0.0]));
    });
    testWidgets('draw container with wide gamut works', (WidgetTester tester) async {
      app.run(app.Setup.container);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
    });

    testWidgets('draw wide gamut linear gradient works', (WidgetTester tester) async {
      app.run(app.Setup.linearGradient);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
    });

    testWidgets('draw wide gamut radial gradient works', (WidgetTester tester) async {
      app.run(app.Setup.radialGradient);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed, epsilon: 0.05));
    });

    testWidgets('draw wide gamut conical gradient works', (WidgetTester tester) async {
      app.run(app.Setup.conicalGradient);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed, epsilon: 0.05));
    });

    testWidgets('draw wide gamut sweep gradient works', (WidgetTester tester) async {
      app.run(app.Setup.sweepGradient);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const channel = MethodChannel('flutter/screenshot');
      final result = await channel.invokeMethod('test') as List<Object?>;
      expect(result, _HasColor(_deepRed));
    });
  });
}
