// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';

void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    if (isLuci) {
      await enableSkiaGoldComparator(namePrefix: 'android_engine_test$goldenVariant');
    }
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await nativeDriver.configureForScreenshotTesting();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('Should be able to hide and show platform view multiple times', () async {
    const hideText = 'Hide Platform View';
    const showText = 'Show Platform View';

    expect(await flutterDriver.getText(find.byValueKey('ToggleButtonText')), hideText);
    // hide platform view
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));

    expect(await flutterDriver.getText(find.byValueKey('ToggleButtonText')), showText);
    // show platform view
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    await flutterDriver.waitFor(find.byValueKey('PlatformView'));

    // hide platform view
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    expect(await flutterDriver.getText(find.byValueKey('ToggleButtonText')), showText);

    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('hide_show_hide_platform_view.png'),
    );
  }, timeout: Timeout.none);
}
