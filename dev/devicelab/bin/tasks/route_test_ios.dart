// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

void main() {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  task(() async {
    String? simulatorDeviceId;
    TaskResult? result;
    try {
      await testWithNewIOSSimulator('route_test_ios', (String deviceId) async {
        simulatorDeviceId = deviceId;
        final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
        section('TEST WHETHER `flutter drive --route` WORKS on IOS');
        await inDirectory(appDir, () async {
          final int exitCode = await flutter(
            'drive',
            options: <String>['-d', deviceId, '--route', '/smuggle-it', 'lib/route.dart'],
          );
          if (exitCode != 0) {
            result = TaskResult.failure('Flutter drive failed with exit code $exitCode');
          } else {
            result = TaskResult.success(null);
          }
        });
      });
    } finally {
      if (simulatorDeviceId != null) {
        await removeIOSSimulator(simulatorDeviceId);
      }
    }
    return result ?? TaskResult.failure('Simulator creation failed');
  });
}
