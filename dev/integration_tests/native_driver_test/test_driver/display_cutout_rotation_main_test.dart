// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:native_driver/native_driver.dart';
import 'package:test/test.dart';

// These tests require that the device running them have a single cutout at the
// top of the display. A simulated cutout setting suffices; however, enabling
// one via adb must take place before `flutter drive` starts. Therefore, this
// setup is executed in run_flutter_driver_android_tests.dart, rather than in
// the below setupAll block.
void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await flutterDriver.waitUntilFirstFrameRasterized();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('cutout should be on top in portrait mode', () async {
    await nativeDriver.rotateResetDefault();
    await flutterDriver.waitFor(find.byValueKey('CutoutTop'),
        timeout: const Duration(seconds: 5));
  }, timeout: Timeout.none);

  test('cutout should be on left in landscape mode', () async {
    await nativeDriver.rotateToLandscape();
    await flutterDriver.waitFor(find.byValueKey('CutoutLeft'),
        timeout: const Duration(seconds: 5));
  }, timeout: Timeout.none);

  test('cutout should update on screen rotation', () async {
    await nativeDriver.rotateResetDefault();
    await flutterDriver.waitFor(find.byValueKey('CutoutTop'),
        timeout: const Duration(seconds: 5));
    await nativeDriver.rotateToLandscape();
    await flutterDriver.waitFor(find.byValueKey('CutoutLeft'),
        timeout: const Duration(seconds: 5));
  }, timeout: Timeout.none);
}
