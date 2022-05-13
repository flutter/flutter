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
    final String projectDirectory = '${flutterDirectory.path}/dev/integration_tests/flutter_gallery';

    await inDirectory(projectDirectory, () async {
      section('Build clean');

      await flutter('clean');

      section('Build gallery app');

      await flutter(
        'build',
        options: <String>[
          'ios',
          '-v',
          '--release',
          '--config-only',
        ],
      );
    });

    section('Run platform unit tests');

    final Device device = await devices.workingDevice;
    if (!await runXcodeTests(
      platformDirectory: path.join(projectDirectory, 'ios'),
      destination: 'id=${device.deviceId}',
      testName: 'native_ui_tests_ios',
    )) {
      return TaskResult.failure('Platform unit tests failed');
    }

    return TaskResult.success(null);
  });
}
