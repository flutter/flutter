// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/native_assets_test.dart';

Future<void> main() async {
  await task(() async {
    deviceOperatingSystem = DeviceOperatingSystem.ios;
    String? simulatorDeviceId;
    try {
      await testWithNewIOSSimulator(
        'TestNativeAssetsSim',
        (String deviceId) async {
          simulatorDeviceId = deviceId;
          await createNativeAssetsTest(
            deviceIdOverride: deviceId,
            isIosSimulator: true,
          )();
        },
      );
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }
    return TaskResult.success(null);
  });
}
