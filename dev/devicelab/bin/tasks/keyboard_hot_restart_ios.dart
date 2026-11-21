// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/keyboard_hot_restart_test.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    TaskResult? result;
    String? simulatorDeviceId;
    try {
      await testWithNewIOSSimulator('keyboard_hot_restart_ios', (String deviceId) async {
        simulatorDeviceId = deviceId;
        result = await createKeyboardHotRestartTest(deviceIdOverride: deviceId).call();
      });
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }
    return result ?? TaskResult.failure('Simulator creation failed');
  });
}
