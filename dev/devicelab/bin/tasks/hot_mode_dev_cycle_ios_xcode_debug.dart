// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/hot_mode_tests.dart';
import 'package:path/path.dart' as path;

/// This is a test to validate that Xcode debugging still works now that LLDB is the default.
Future<void> main() async {
  await task(() async {
    deviceOperatingSystem = DeviceOperatingSystem.ios;
    try {
      await disableLLDBDebugging();
      // This isn't actually a benchmark test, so do not use the returned `benchmarkScoreKeys` result.
      await createHotModeTest()();
      return TaskResult.success(null);
    } finally {
      await enableLLDBDebugging();
    }
  });
}

Future<void> disableLLDBDebugging() async {
  final int configResult = await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
    'config',
    '--no-enable-lldb-debugging',
  ]);
  if (configResult != 0) {
    print('Failed to disable configuration, tasks may not run.');
  }
}

Future<void> enableLLDBDebugging() async {
  final int configResult = await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
    'config',
    '--enable-lldb-debugging',
  ], canFail: true);
  if (configResult != 0) {
    print('Failed to enable configuration.');
  }
}
