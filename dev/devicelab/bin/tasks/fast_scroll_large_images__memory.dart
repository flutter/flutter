// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Measure application memory usage after pausing and resuming the app
/// with the Android back button.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

const String kPackageName = 'com.example.macrobenchmarks';
const String kActivityName = 'com.example.macrobenchmarks.MainActivity';

class FastScrollLargeImagesMemoryTest extends MemoryTest {
  FastScrollLargeImagesMemoryTest()
      : super(
          '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
          'test_memory/large_images.dart', kPackageName,
        );

  @override
  AndroidDevice get device => super.device;

  @override
  int get iterationCount => 5;

  /// Perform a series of back button suspend and resume cycles.
  @override
  Future<void> useMemory() async {
    await launchApp();
    await recordStart();
    for (int i = 0; i < 3; i += 1) {
      await device.shellExec('input', <String>['swipe', '0 1500 0 0 50']);
      await Future<void>.delayed(const Duration(milliseconds: 3000));
    }
    await recordEnd();
  }
}

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(FastScrollLargeImagesMemoryTest().run);
}
