// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// Whether the current environment is LUCI.
bool get isLuci => io.Platform.environment['LUCI_CI'] == 'True';

const String platformViewTestName = 'platformViewTest';

void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;
  late final String activeGoldenVariant;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await nativeDriver.configureForScreenshotTesting();

    final String response = await flutterDriver.requestData(
      json.encode(<String, Object?>{'command': 'get_golden_variant'}),
    );
    final Map<String, Object?> reply =
        (json.decode(response) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final replyVariant = reply['goldenVariant'] as String?;
    activeGoldenVariant = (replyVariant != null && replyVariant.isNotEmpty)
        ? '.$replyVariant'
        : '';

    if (isLuci) {
      await enableSkiaGoldComparator(
        namePrefix: 'android_hardware_smoke_test$activeGoldenVariant',
      );
    }
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  Future<void> templateTest(String testName) async {
    // Ask the app to render the test and return the rendered image bytes
    final String response = await flutterDriver.requestData(
      json.encode(<String, Object?>{
        'testName': testName,
        'performAppSideGoldenCompare': false,
      }),
    );

    // Expect a successful reply
    final Map<String, Object?> reply =
        (json.decode(response) as Map<Object?, Object?>)
            .cast<String, Object?>();
    expect(reply['message'], equals('Rendered $testName'));

    final Uint8List imageBytes;
    if (testName == platformViewTestName) {
      final int x = reply['x']! as int;
      final int y = reply['y']! as int;
      final int w = reply['width']! as int;
      final int h = reply['height']! as int;

      final NativeScreenshot fullScreenshot = await nativeDriver.screenshot();
      final Uint8List fullBytes = await fullScreenshot.readAsBytes();

      final img.Image? decoded = img.decodePng(fullBytes);
      if (decoded == null) {
        throw StateError(
          'Failed to decode full screen screenshot for $testName',
        );
      }
      if (x < 0 ||
          y < 0 ||
          w <= 0 ||
          h <= 0 ||
          x + w > decoded.width ||
          y + h > decoded.height) {
        throw StateError(
          'Crop bounds out of range for $testName: x=$x, y=$y, w=$w, h=$h, image.width=${decoded.width}, image.height=${decoded.height}',
        );
      }
      final img.Image cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: w,
        height: h,
      );
      imageBytes = Uint8List.fromList(img.encodePng(cropped));
    } else {
      final imageBase64 = reply['imageBytes']! as String;
      imageBytes = base64.decode(imageBase64);
    }

    // Compare the bytes to a golden file on the host filesystem using the cached variant
    await expectLater(
      imageBytes,
      matchesGoldenFile('goldens/$testName$activeGoldenVariant.png'),
    );
  }

  test('should render and match blueRectangleTest golden', () async {
    await templateTest('blueRectangleTest');
  }, timeout: Timeout.none);

  test('should render and match trianglePathTest golden', () async {
    await templateTest('trianglePathTest');
  }, timeout: Timeout.none);

  test('should render and match textTest golden', () async {
    await templateTest('textTest');
  }, timeout: Timeout.none);

  test('should render and match imageTest golden', () async {
    await templateTest('imageTest');
  }, timeout: Timeout.none);

  test('should render and match advancedBlendTest golden', () async {
    await templateTest('advancedBlendTest');
  }, timeout: Timeout.none);

  test('should render and match backdropFilterBlurTest golden', () async {
    await templateTest('backdropFilterBlurTest');
  }, timeout: Timeout.none);

  test('should render and match $platformViewTestName golden', () async {
    await templateTest(platformViewTestName);
  }, timeout: Timeout.none);
}
