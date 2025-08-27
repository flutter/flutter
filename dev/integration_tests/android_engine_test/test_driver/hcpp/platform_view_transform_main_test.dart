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
/// UPDATE_GOLDENS=1 flutter drive lib/hcpp/platform_view_transform_main.dart
///
/// # Make your changes.
///
/// # Run the test against baseline.
/// flutter drive lib/hcpp/platform_view_transform_main.dart
/// ```
///
/// For a convenient way to deflake a test, see `tool/deflake.dart`.
void main() async {
  const String goldenPrefix = 'hybrid_composition_pp_platform_view';

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
    final Map<String, Object?> response =
        json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;

    expect(response['supported'], true);
  }, timeout: Timeout.none);

  test('should rotate in a circle', () async {
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_transform.png'),
    );
    await flutterDriver.tap(find.byValueKey('Rotate'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.half_pi_radians.png'),
    );
    await flutterDriver.tap(find.byValueKey('Rotate'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.one_pi_radians.png'),
    );
    await flutterDriver.tap(find.byValueKey('Rotate'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.one_and_a_half_pi_radians.png'),
    );
    await flutterDriver.tap(find.byValueKey('Rotate'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_transform.png'),
    );
  }, timeout: Timeout.none);

  test('should scale down and then back up', () async {
    await flutterDriver.tap(find.byValueKey('Scale Down'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.scaled_down.png'),
    );
    await flutterDriver.tap(find.byValueKey('Scale Up'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_transform.png'),
    );
  }, timeout: Timeout.none);

  test('should flip and then flip back', () async {
    await flutterDriver.tap(find.byValueKey('Flip X'));
    await expectLater(nativeDriver.screenshot(), matchesGoldenFile('$goldenPrefix.flipped_x.png'));
    await flutterDriver.tap(find.byValueKey('Flip X'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_transform.png'),
    );
  }, timeout: Timeout.none);

  test('should translate and then translate back', () async {
    await flutterDriver.tap(find.byValueKey('Translate Left'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.translated_left.png'),
    );
    await flutterDriver.tap(find.byValueKey('Translate Right'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.no_transform.png'),
    );
  }, timeout: Timeout.none);

  test('should match all applied', () async {
    await flutterDriver.tap(find.byValueKey('Flip X'));
    await flutterDriver.tap(find.byValueKey('Translate Right'));
    await flutterDriver.tap(find.byValueKey('Scale Down'));
    await flutterDriver.tap(find.byValueKey('Rotate'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.all_applied.png'),
    );
  }, timeout: Timeout.none);
}
