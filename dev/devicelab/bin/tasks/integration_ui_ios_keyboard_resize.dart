// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    String? simulatorDeviceId;
    var result = TaskResult.success(null);
    try {
      await testWithNewIOSSimulator('integration_ui_ios_keyboard_resize', (String deviceId) async {
        simulatorDeviceId = deviceId;
        result = await createEndToEndKeyboardTest(deviceIdOverride: deviceId).call();
      });
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }
    return result;
  });
}
