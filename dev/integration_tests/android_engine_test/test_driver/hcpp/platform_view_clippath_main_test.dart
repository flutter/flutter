// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';

/// For local debugging, a (local) golden-file is required as a baseline:
///
/// ```sh
/// # Checkout HEAD, i.e. *before* changes you want to test.
/// UPDATE_GOLDENS=1 flutter drive lib/hcpp/platform_view_clippath_main.dart
///
/// # Make your changes.
///
/// # Run the test against baseline.
/// flutter drive lib/hcpp/platform_view_clippath_main.dart
/// ```
///
/// For a convenient way to deflake a test, see `tool/deflake.dart`.
void main() async {
  const goldenPrefix = 'hybrid_composition_pp_platform_view';

  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    if (isLuci) {
      await enableSkiaGoldComparator(namePrefix: 'android_engine_test$goldenVariant');
    }
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await nativeDriver.configureForScreenshotTesting();
    await flutterDriver.waitUntilFirstFrameRasterized();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('verify that HCPP is supported and enabled', () async {
    final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;

    expect(response['supported'], true);
  }, timeout: Timeout.none);

  test('should screenshot a platform view with no path clipping', () async {
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_path_clipping.png'),
    );
  }, timeout: Timeout.none);

  test(
    'should start with triangle cutoff on left, and toggle to no triangle cutoff on left',
    () async {
      await flutterDriver.tap(find.byValueKey('clipper_button_triangle'));
      await expectLater(
        nativeDriver.screenshot(),
        matchesGoldenFile('$goldenPrefix.only_triangle.png'),
      );
      await flutterDriver.tap(find.byValueKey('clipper_button_triangle'));
      await expectLater(
        nativeDriver.screenshot(),
        matchesGoldenFile('$goldenPrefix.no_path_clipping.png'),
      );
    },
    timeout: Timeout.none,
  );

  test(
    'should start with wave cutoff on bottom, and toggle to no wave cutoff on bottom',
    () async {
      await flutterDriver.tap(find.byValueKey('clipper_button_cubicWave'));
      await expectLater(
        nativeDriver.screenshot(),
        matchesGoldenFile('$goldenPrefix.only_cubicWave.png'),
      );
      await flutterDriver.tap(find.byValueKey('clipper_button_cubicWave'));
      await expectLater(
        nativeDriver.screenshot(),
        matchesGoldenFile('$goldenPrefix.no_path_clipping.png'),
      );
    },
    timeout: Timeout.none,
  );

  test('should start with box cutout (nonZero), and toggle to no box cutout', () async {
    await flutterDriver.tap(find.byValueKey('clipper_button_overlappingNonZero'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.only_overlappingNonZero.png'),
    );
    await flutterDriver.tap(find.byValueKey('clipper_button_overlappingNonZero'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_path_clipping.png'),
    );
  }, timeout: Timeout.none);

  test('should start with box cutout (evenOdd), and toggle to no box cutout', () async {
    await flutterDriver.tap(find.byValueKey('clipper_button_overlappingEvenOdd'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.only_overlappingEvenOdd.png'),
    );
    await flutterDriver.tap(find.byValueKey('clipper_button_overlappingEvenOdd'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_path_clipping.png'),
    );
  }, timeout: Timeout.none);

  test('should apply all except evenOdd box clipper', () async {
    await flutterDriver.tap(find.byValueKey('clipper_button_overlappingNonZero'));
    await flutterDriver.tap(find.byValueKey('clipper_button_cubicWave'));
    await flutterDriver.tap(find.byValueKey('clipper_button_triangle'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.complex_clippath.png'),
    );
  }, timeout: Timeout.none);
}
