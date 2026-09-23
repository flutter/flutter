// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    TaskResult? result;
    String? simulatorDeviceId;
    try {
      await testWithNewIOSSimulator('native_platform_view_ui_tests_ios', (String deviceId) async {
        simulatorDeviceId = deviceId;
        final projectDirectory =
            '${flutterDirectory.path}/dev/integration_tests/ios_platform_view_tests';

        await inDirectory(projectDirectory, () async {
          // To address "Failed to terminate" failure.
          section('Uninstall previously installed app');

          await flutter('install', options: <String>['--uninstall-only', '-d', deviceId]);

          section('Build clean');

          await flutter('clean');

          section('Build platform view app');

          await flutter('build', options: <String>['ios', '-v', '--simulator', '--config-only']);
        });

        section('Run platform view XCUITests');

        if (!await runXcodeTests(
          platformDirectory: path.join(projectDirectory, 'ios'),
          destination: 'id=$deviceId',
          testName: 'native_platform_view_ui_tests_ios',
          configuration: 'Debug',
          skipCodesign: true,
        )) {
          result = TaskResult.failure('Platform view XCUITests failed');
        } else {
          result = TaskResult.success(null);
        }
      });
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }
    return result ?? TaskResult.failure('Simulator creation failed');
  });
}
