// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';

/// Regression test for https://github.com/flutter/flutter/issues/189834.
///
/// A platform view whose bounds do not land on whole physical pixels used to be
/// *truncated* onto the pixel grid, both when sizing the view itself and when
/// pushing clip rects onto the mutator stack. That shrinks the view by up to a
/// pixel, uncovering a thin line of the Flutter content behind it along the
/// right and bottom edges. These goldens should show a blue box over a red
/// background with no red line between the box and its own edges.
///
/// For local debugging, a (local) golden-file is required as a baseline:
///
/// ```sh
/// # Checkout HEAD, i.e. *before* changes you want to test.
/// UPDATE_GOLDENS=1 flutter drive lib/hcpp/platform_view_fractional_size_main.dart
///
/// # Make your changes.
///
/// # Run the test against baseline.
/// flutter drive lib/hcpp/platform_view_fractional_size_main.dart
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

  test('should not leave a background-colored line along the edges of the view', () async {
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.fractional_size.png'),
    );
  }, timeout: Timeout.none);

  test('should not leave a background-colored line along the edges of the clip', () async {
    await flutterDriver.tap(find.byValueKey('toggle_clip_button'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.fractional_size_clipped.png'),
    );
  }, timeout: Timeout.none);
}
