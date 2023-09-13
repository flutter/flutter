// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show StreamSubscription;
import 'dart:io' show Directory, Process;

import 'package:flutter_devicelab/framework/devices.dart'
    show Device, DeviceOperatingSystem, deviceOperatingSystem, devices;
import 'package:flutter_devicelab/framework/framework.dart' show task;
import 'package:flutter_devicelab/framework/task_result.dart' show TaskResult;
import 'package:flutter_devicelab/framework/utils.dart'
    show dir, flutter, flutterDirectory, inDirectory, startFlutter;
import 'package:path/path.dart' as path;

Future<TaskResult> run() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  final Device device = await devices.workingDevice;
  await device.unlock();
  final Directory appDir =
      dir(path.join(flutterDirectory.path, 'examples/hello_world'));

  bool isUsingValidationLayers = false;
  bool hasValidationErrors = false;
  int impellerBackendCount = 0;

  await inDirectory(appDir, () async {
    await flutter('packages', options: <String>['get']);

    final StreamSubscription<String> adb = device.logcat.listen(
      (String data) {
        if (data.contains('Using the Impeller rendering backend')) {
          // Sometimes more than one of these will be printed out if there is a
          // fallback.
          impellerBackendCount += 1;
        }
        if (data.contains(
            'Using the Impeller rendering backend (Vulkan with Validation Layers)')) {
          isUsingValidationLayers = true;
        }
        if (data.contains('ImpellerValidationBreak')) {
          hasValidationErrors = true;
        }
        print('something: $data');
      },
    );

    final Process process = await startFlutter(
      'run',
      options: <String>[
        '--enable-impeller',
        '-d',
        device.deviceId,
      ],
    );

    // Since we are waiting for the lack of errors, there is no determinate
    // amount of time we can wait.
    await Future<void>.delayed(const Duration(seconds: 10));
    process.stdin.write('q');
    await adb.cancel();
  });

  if (!isUsingValidationLayers || impellerBackendCount != 1) {
    return TaskResult.failure('Not using Vulkan validation layers.');
  } 
  if (hasValidationErrors){
    return TaskResult.failure('Impeller validation errors detected.');
  }
  return TaskResult.success(null);
}

Future<void> main() async {
  await task(run);
}
