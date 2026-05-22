// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';

/// Runs the Android Hardware Smoke Test golden suite in CI.
Future<void> runAndroidHardwareSmokeTests() async {
  printProgress('Running Android Hardware Smoke Tests Shard');

  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');

  await runCommand('flutter', <String>[
    'drive',
    '--driver=test_driver/driver_test.dart',
    '--target=integration_test/integration_test_wrapper.dart',
    '--no-dds',
    '--no-enable-dart-profiling',
  ], workingDirectory: testDir);
}
