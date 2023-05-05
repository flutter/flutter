// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/hot_mode_tests.dart';

Future<void> main() async {
  await task(() async {
    deviceOperatingSystem = DeviceOperatingSystem.ios;
    String? simulatorDeviceId;
    try {
      await testWithNewIOSSimulator('TestHotReloadSim', (String deviceId) async {
        simulatorDeviceId = deviceId;
        // This isn't actually a benchmark test, so do not use the returned `benchmarkScoreKeys` result.
        await createHotModeTest(deviceIdOverride: deviceId, checkAppRunningOnLocalDevice: true)();
      });
    } finally {
      await removeIOSimulator(simulatorDeviceId);
    }

    return TaskResult.success(null);
  });
}
