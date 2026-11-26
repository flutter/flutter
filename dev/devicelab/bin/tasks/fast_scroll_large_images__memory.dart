// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

const String kPackageName = 'com.example.macrobenchmarks';

class FastScrollLargeImagesMemoryTest extends MemoryTest {
  FastScrollLargeImagesMemoryTest()
    : super(
        '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
        'test_memory/large_images.dart',
        kPackageName,
        requiresTapToStart: true,
      );

  @override
  int get iterationCount => 5;
}

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(FastScrollLargeImagesMemoryTest().run);
}
