// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    final String projectDirectory = '${flutterDirectory.path}/dev/integration_tests/flutter_gallery';

    IOSink? sink;
    deviceOperatingSystem = DeviceOperatingSystem.macos;
    Device? device;
    try {
      device = await devices.workingDevice;
    } on DeviceException {
      device = null;
      print('Could not find device');
    }

    try {
      await inDirectory(projectDirectory, () async {
        if (device != null && device.canStreamLogs && hostAgent.dumpDirectory != null) {
          sink = File(path.join(hostAgent.dumpDirectory!.path, '${device.deviceId}.log')).openWrite();
          await device.startLoggingToSink(sink!);
        }

        section('Build gallery app');

        await flutter(
          'build',
          options: <String>[
            'macos',
            '-v',
            '--debug',
          ],
        );
      });

      section('Run platform unit tests');

      if (!await runXcodeTests(
        platformDirectory: path.join(projectDirectory, 'macos'),
        destination: 'platform=macOS',
        testName: 'native_ui_tests_macos',
        // skipCodesign: true,
      )) {
        return TaskResult.failure('Platform unit tests failed');
      }
    } finally {
      if (device != null && device.canStreamLogs) {
        await device.stopLoggingToSink();
        await sink?.close();
      }
    }

    return TaskResult.success(null);
  });
}
