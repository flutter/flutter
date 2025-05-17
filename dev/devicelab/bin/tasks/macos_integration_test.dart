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
  deviceOperatingSystem = DeviceOperatingSystem.macos;
  await task(() async {
    final String projectDirectory =
        '${flutterDirectory.path}/dev/integration_tests/macos_integration_test';

    await inDirectory(projectDirectory, () async {
      section('Build clean');

      await flutter('clean');

      section('Configure macOS integration app');

      await flutter('build', options: <String>['macos', '-v', '--config-only', '--release']);
    });

    section('Run integration XCUITests');

    if (!await runXcodeTests(
      platformDirectory: path.join(projectDirectory, 'macos'),
      destination: 'platform=macOS',
      testName: 'integration test macos',
    )) {
      return TaskResult.failure('macOS XCUITests failed');
    }

    return TaskResult.success(null);
  });
}
