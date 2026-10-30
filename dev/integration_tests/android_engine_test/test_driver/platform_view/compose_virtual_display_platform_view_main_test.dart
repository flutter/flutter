// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';
import '../_unstable_gold_retry.dart';

/// For local debugging, a (local) golden-file is required as a baseline:
///
/// ```sh
/// # Checkout HEAD, i.e. *before* changes you want to test.
/// UPDATE_GOLDENS=1 flutter drive lib/platform_view/compose_virtual_display_platform_view_main.dart
///
/// # Make your changes.
///
/// # Run the test against baseline.
/// flutter drive lib/platform_view/compose_virtual_display_platform_view_main.dart
/// ```
///
/// For a convenient way to deflake a test, see `tool/deflake.dart`.
void main() async {
  const goldenPrefix = 'compose_virtual_display_platform_view';

  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  late final bool isEmulator;
  late final bool isVulkan;

  setUpAll(() async {
    if (isLuci) {
      await enableSkiaGoldComparator(namePrefix: 'android_engine_test$goldenVariant');
    }
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await nativeDriver.configureForScreenshotTesting();
    await flutterDriver.waitUntilFirstFrameRasterized();
    await nativeDriver.waitUntilFirstFrameDisplayed();

    if (await nativeDriver.sdkVersion case final int version when version < 23) {
      fail('Requires SDK >= 23, got $version');
    }

    isEmulator = await nativeDriver.isEmulator;
    isVulkan = goldenVariant.contains('vulkan');
    if (isEmulator && isVulkan) {
      print('Detected running on a vulkan emulator. Will retry certain failures');
    }
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('should screenshot a Compose layout and recompose on tap', () async {
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFileWithRetries(
        '$goldenPrefix.initial.png',
        retries: isEmulator && isVulkan ? 2 : 0,
      ),
    );

    await nativeDriver.tap(const ByNativeAccessibilityLabel('Change color'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFileWithRetries(
        '$goldenPrefix.tapped.png',
        retries: isEmulator && isVulkan ? 2 : 0,
      ),
    );
  }, timeout: Timeout.none);
}
