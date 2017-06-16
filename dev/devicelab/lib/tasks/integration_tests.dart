// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createChannelsIntegrationTest() {
  return new DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/channels',
    'lib/main.dart',
  );
}

TaskFunction createPlatformChannelSampleTest() {
  return new DriverTest(
    '${flutterDirectory.path}/examples/platform_channel',
    'test_driver/button_tap.dart',
  );
}

class DriverTest {

  DriverTest(this.testDirectory, this.testTarget);

  final String testDirectory;
  final String testTarget;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);

      await flutter('drive', options: <String>[
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);

      return new TaskResult.success(null);
    });
  }
}
