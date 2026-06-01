// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Whether the current environment is LUCI.
bool get isLuci => io.Platform.environment['LUCI_CI'] == 'True';

void main() async {
  late final FlutterDriver flutterDriver;
  late final String activeGoldenVariant;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();

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

    // Compare the bytes to a golden file on the host filesystem using the cached variant
    final imageBase64 = reply['imageBytes']! as String;
    final Uint8List imageBytes = base64.decode(imageBase64);
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
}
