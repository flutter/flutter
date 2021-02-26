// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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
  FakeBuildTestTask(List<String> args) : super(args, workingDirectory: Directory.current, runFlutterClean: false) {
    deviceOperatingSystem = DeviceOperatingSystem.fake;
  }

  @override
  Future<void> build() async {}

  @override
  Future<TaskResult> test() async => TaskResult.success(<String, String>{'benchmark': 'data'});
}
