// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:high_bitrate_images/main.dart' as app;
import 'package:integration_test/integration_test.dart';

// See: https://developer.apple.com/documentation/metal/mtlpixelformat/mtlpixelformatbgr10_xr.
double _decodeBGR10(int x) {
  const max = 1.25098;
  const min = -0.752941;
  const intercept = min;
  const double slope = (max - min) / 1024.0;
  return (x * slope) + intercept;
}

Uint8List _convertBGRA10XRToBGRA8888(Uint8List bgra10xr) {
  final inputByteData = ByteData.sublistView(bgra10xr);
  final bgra8888 = Uint8List(bgra10xr.lengthInBytes ~/ 2); // 8 bytes per pixel -> 4 bytes per pixel
  final outputByteData = ByteData.view(bgra8888.buffer);

  for (var i = 0, j = 0; i < bgra10xr.lengthInBytes; i += 8, j += 4) {
    final int pixel = inputByteData.getUint64(i, Endian.host);

    final double blue10 = _decodeBGR10((pixel >> 6) & 0x3ff);
    final double green10 = _decodeBGR10((pixel >> 22) & 0x3ff);
    final double red10 = _decodeBGR10((pixel >> 38) & 0x3ff);

    final int blue8 = (blue10.clamp(0.0, 1.0) * 255).round();
    final int green8 = (green10.clamp(0.0, 1.0) * 255).round();
    final int red8 = (red10.clamp(0.0, 1.0) * 255).round();
    const alpha8 = 255; // Assuming opaque for BGRA8888

    final int bgra8888Pixel = (alpha8 << 24) | (red8 << 16) | (green8 << 8) | blue8;
    outputByteData.setUint32(j, bgra8888Pixel, Endian.host);
  }
  return bgra8888;
}

Future<ui.Image> _getScreenshot() async {
  const channel = MethodChannel('flutter/screenshot');
  final result = await channel.invokeMethod('test') as List<Object?>;

  expect(result, isNotNull);
  expect(result.length, 4);
  final [int width, int height, String format, Uint8List bytes] = result as List<dynamic>;

  expect(format, equals('MTLPixelFormatBGRA10_XR'));

  final completer = Completer<ui.Image>();
  final Uint8List pixels = _convertBGRA10XRToBGRA8888(bytes);
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.bgra8888,
    (ui.Image image) => completer.complete(image),
  );

  return completer.future;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('renders sdfs with rgba32f', (WidgetTester tester) async {
      app.gTargetPixelFormat = ui.TargetPixelFormat.rgbaFloat32;
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _getScreenshot();
      // TODO(gaaclarke): Turn this into a golden test. This turned out to be
      // quite involved so it's deferred.
      // expect(
      //   screenshot,
      //   matchesGoldenFile('high_bitrate_images.rbga32f'),
      // );
    });

    testWidgets('renders sdfs with r32f', (WidgetTester tester) async {
      app.gTargetPixelFormat = ui.TargetPixelFormat.rFloat32;
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _getScreenshot();
      // TODO(gaaclarke): Turn this into a golden test. This turned out to be
      // quite involved so it's deferred.
      // expect(
      //   screenshot,
      //   matchesGoldenFile('high_bitrate_images.rbga32f'),
      // );
    });
  });
}
