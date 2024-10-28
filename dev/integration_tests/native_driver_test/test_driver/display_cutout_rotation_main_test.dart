// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:native_driver/native_driver.dart';
import 'package:test/test.dart';

const String _tallCutout = 'com.android.internal.display.cutout.emulation.tall';

void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await flutterDriver.waitUntilFirstFrameRasterized();
    // Enable developer settings in order to simulate a cutout.
    await Process.run('adb', <String>[
      'shell',
      'settings',
      'put',
      'global',
      'development_settings_enabled',
      '1'
    ]);
    // Simulate the tall cutout. A singular cutout that aligns to the "top" of the display.
    await Process.run(
        'adb', <String>['shell', 'cmd', 'overlay', 'enable', _tallCutout]);
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
