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

TaskFunction createPlatformInteractionTest() {
  return new DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/platform_interaction',
    'lib/main.dart',
  );
}

TaskFunction createFlavorsTest() {
  return new DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/flavors',
    'lib/main.dart',
    extraOptions: <String>['--flavor', 'paid']
  );
}

TaskFunction createExternalUiIntegrationTest() {
  return new DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/external_ui',
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

  DriverTest(
    this.testDirectory,
    this.testTarget, {
      this.extraOptions = const <String>[],
    }
  );

  final String testDirectory;
  final String testTarget;
  final List<String> extraOptions;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);
      final List<String> options = <String>[
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
      ];
      options.addAll(extraOptions);
      await flutter('drive', options: options);

      return new TaskResult.success(null);
    });
  }
}
