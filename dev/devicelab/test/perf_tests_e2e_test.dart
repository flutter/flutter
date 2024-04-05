// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('mac-os')
library;

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

void main() {

  late Directory testOutputDirectory;

  setUp(() async {
    testOutputDirectory = Directory.systemTemp.createTempSync('output_dir');
  });

  test('runs perf tests, no callback', () async {
    const FakeDevice physicalDevice = FakeDevice(deviceId: 'macOS');
    final PerfTest perfTest = PerfTest(
      path.join(flutterDirectory.absolute.path, 'dev/benchmarks/macrobenchmarks'),
      'test_driver/animated_image.dart',
      'animated_image',
      device: physicalDevice,
      testOuputDirectory: testOutputDirectory.absolute.path,
      timeoutSeconds: 50,
      saveTraceFile: true,
    );
    final TaskResult result = await perfTest.run();
    expect(result.succeeded, isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}