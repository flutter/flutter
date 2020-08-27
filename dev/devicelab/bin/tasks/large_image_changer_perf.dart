// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

const String kPackageName = 'com.example.macrobenchmarks';
const String kActivityName = 'com.example.macrobenchmarks.MainActivity';

class LargeImageChangerPerfTest extends MemoryTest {
  LargeImageChangerPerfTest()
      : super(
          '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
          'test_memory/large_image_changer.dart', kPackageName,
        );

  @override
  AndroidDevice get device => super.device as AndroidDevice;

  @override
  int get iterationCount => 5;

  @override
  Future<void> useMemory() async {
    await launchApp();
    await recordStart();
    await Future<void>.delayed(const Duration(seconds: 30));
    await recordEnd();
  }
}

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(LargeImageChangerPerfTest().run);
}
