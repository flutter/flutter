// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wide_gamut_test/main.dart' as app;

// See: https://developer.apple.com/documentation/metal/mtlpixelformat/mtlpixelformatbgr10_xr.
double _decodeBGR10(int x) {
  const double max = 1.25098;
  const double min = -0.752941;
  const double intercept = min;
  const double slope = (max - min) / 1024.0;
  return (x * slope) + intercept;
}

bool _isAlmost(double x, double y, double epsilon) {
  return (x - y).abs() < epsilon;
}

List<double> _deepRed = <double>[1.0931, -0.2268, -0.1501];

bool _findBGRA10Color(
    Uint8List bytes, int width, int height, List<double> color) {
  final ByteData byteData = ByteData.sublistView(bytes);
  expect(bytes.lengthInBytes, width * height * 8);
  expect(bytes.lengthInBytes, byteData.lengthInBytes);
  bool foundDeepRed = false;
  for (int i = 0; i < bytes.lengthInBytes; i += 8) {
    final int pixel = byteData.getUint64(i, Endian.host);
    final double blue = _decodeBGR10((pixel >> 6) & 0x3ff);
    final double green = _decodeBGR10((pixel >> 22) & 0x3ff);
    final double red = _decodeBGR10((pixel >> 38) & 0x3ff);
    if (_isAlmost(red, color[0], 0.01) &&
        _isAlmost(green, color[1], 0.01) &&
        _isAlmost(blue, color[2], 0.01)) {
      foundDeepRed = true;
    }
  }
  return foundDeepRed;
}

bool _findBGR10Color(
    Uint8List bytes, int width, int height, List<double> color) {
  final ByteData byteData = ByteData.sublistView(bytes);
  expect(bytes.lengthInBytes, width * height * 4);
  expect(bytes.lengthInBytes, byteData.lengthInBytes);
  bool foundDeepRed = false;
  for (int i = 0; i < bytes.lengthInBytes; i += 4) {
    final int pixel = byteData.getUint32(i, Endian.host);
    final double blue = _decodeBGR10(pixel & 0x3ff);
    final double green = _decodeBGR10((pixel >> 10) & 0x3ff);
    final double red = _decodeBGR10((pixel >> 20) & 0x3ff);
    if (_isAlmost(red, color[0], 0.01) &&
        _isAlmost(green, color[1], 0.01) &&
        _isAlmost(blue, color[2], 0.01)) {
      foundDeepRed = true;
    }
  }
  return foundDeepRed;
}

bool _findColor(List<Object?> result, List<double> color) {
  expect(result, isNotNull);
  expect(result.length, 4);
  final int width = (result[0] as int?)!;
  final int height = (result[1] as int?)!;
  final String format = (result[2] as String?)!;
  if (format == 'MTLPixelFormatBGR10_XR') {
    return _findBGR10Color((result[3] as Uint8List?)!, width, height, color);
  } else if (format == 'MTLPixelFormatBGRA10_XR') {
    return _findBGRA10Color((result[3] as Uint8List?)!, width, height, color);
  } else {
    fail('Unsupported pixel format: $format');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('look for display p3 deepest red', (WidgetTester tester) async {
      app.run(app.Setup.image);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const MethodChannel channel = MethodChannel('flutter/screenshot');
      final List<Object?> result =
          await channel.invokeMethod('test') as List<Object?>;
      expect(_findColor(result, _deepRed), isTrue);
    });
    testWidgets('look for display p3 deepest red', (WidgetTester tester) async {
      app.run(app.Setup.canvasSaveLayer);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const MethodChannel channel = MethodChannel('flutter/screenshot');
      final List<Object?> result =
          await channel.invokeMethod('test') as List<Object?>;
      expect(_findColor(result, _deepRed), isTrue);
    });
    testWidgets('no p3 deepest red without image', (WidgetTester tester) async {
      app.run(app.Setup.none);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const MethodChannel channel = MethodChannel('flutter/screenshot');
      final List<Object?> result =
          await channel.invokeMethod('test') as List<Object?>;
      expect(_findColor(result, _deepRed), isFalse);
      expect(_findColor(result, <double>[0.0, 1.0, 0.0]), isFalse);
    });
    testWidgets('p3 deepest red with blur', (WidgetTester tester) async {
      app.run(app.Setup.blur);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      const MethodChannel channel = MethodChannel('flutter/screenshot');
      final List<Object?> result =
          await channel.invokeMethod('test') as List<Object?>;
      expect(_findColor(result, _deepRed), isTrue);
      expect(_findColor(result, <double>[0.0, 1.0, 0.0]), isTrue);
    });
  });
}
