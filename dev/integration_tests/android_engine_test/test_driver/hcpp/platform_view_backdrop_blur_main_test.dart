// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';

/// Verifies `BackdropFilter` blurs over HCPP platform views.
///
/// Native (SurfaceFlinger) blur of the platform view requires API 37 and a
/// device with cross-window blur enabled. CI emulators do not have it, so two
/// golden variants exist:
///
/// - `.native_blur.png`: the platform view and the Flutter content behind the
///   panel are blurred together with no seam.
/// - `.no_native_blur.png`: only the Flutter content is blurred; the platform
///   view shows through sharp. This also guards against regressions where the
///   overlay (the panel's tint and the red button) goes missing.
///
/// For local debugging, a (local) golden-file is required as a baseline:
///
/// ```sh
/// # Checkout HEAD, i.e. *before* changes you want to test.
/// UPDATE_GOLDENS=1 flutter drive lib/hcpp/platform_view_backdrop_blur_main.dart
///
/// # Make your changes.
///
/// # Run the test against baseline.
/// flutter drive lib/hcpp/platform_view_backdrop_blur_main.dart
/// ```
///
/// For a convenient way to deflake a test, see `tool/deflake.dart`.
void main() async {
  const goldenPrefix = 'hybrid_composition_pp_platform_view';

  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;
  late final String variant;

  setUpAll(() async {
    if (isLuci) {
      await enableSkiaGoldComparator(namePrefix: 'android_engine_test$goldenVariant');
    }
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await nativeDriver.configureForScreenshotTesting();
    await flutterDriver.waitUntilFirstFrameRasterized();
    await nativeDriver.waitUntilFirstFrameDisplayed();

    final int sdk = await nativeDriver.sdkVersion;
    final bool blurEnabled = await nativeDriver.isCrossWindowBlurEnabled;
    variant = sdk >= 37 && blurEnabled ? 'native_blur' : 'no_native_blur';
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('verify that HCPP is supported and enabled', () async {
    final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;

    expect(response['supported'], true);
  }, timeout: Timeout.none);

  test('should blur the platform view and Flutter content under the panel', () async {
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.backdrop_blur.$variant.png'),
    );
  }, timeout: Timeout.none);

  test('should remove the blur when the filter is removed, and restore it', () async {
    // The red button sits in the Flutter overlay above the blur; tapping it
    // also verifies that touches reach Flutter through the blur carrier.
    await flutterDriver.tap(find.byValueKey('ToggleBlur'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.backdrop_blur.removed.png'),
    );

    await flutterDriver.tap(find.byValueKey('ToggleBlur'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('$goldenPrefix.backdrop_blur.$variant.png'),
    );
  }, timeout: Timeout.none);
}
