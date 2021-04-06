// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/build_test_task.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

/// Smoke test of a successful task.
Future<void> main(List<String> args) async {
  deviceOperatingSystem = DeviceOperatingSystem.fake;
  await task(FakeBuildTestTask(args));
}

class FakeBuildTestTask extends BuildTestTask {
  FakeBuildTestTask(List<String> args) : super(args, runFlutterClean: false);

  @override
  // In prod, tasks always run some unit of work and the test framework assumes
  // there will be some work done when managing the isolate. To fake this, add a delay.
  Future<void> build() async {
    if (targetPlatform != DeviceOperatingSystem.fake) {
      throw Exception('Only DeviceOperatingSystem.fake is supported');
    }
  }

  @override
  Future<TaskResult> test() async {
    if (targetPlatform != DeviceOperatingSystem.fake) {
      throw Exception('Only DeviceOperatingSystem.fake is supported');
    }

    return TaskResult.success(<String, String>{'benchmark': 'data'});
  }
}
