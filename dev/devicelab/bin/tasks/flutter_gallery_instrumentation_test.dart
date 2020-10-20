// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

// This test runs "//dev/integration_tests/flutter_gallery/test/live_smoketest.dart", which communicates
// with the Java code to report its status. If this test fails due to a problem on the Dart
// side, you can debug that by just running that file directly using `flutter run`.

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;

  await task(() async {
    final Directory galleryDirectory =
      dir('${flutterDirectory.path}/dev/integration_tests/flutter_gallery');
    await inDirectory(galleryDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);
      await flutter('clean');
      await flutter('build', options: <String>['apk', '--target', 'test/live_smoketest.dart']);
      await exec('./tool/run_instrumentation_test.sh', <String>[], environment: <String, String>{
        'JAVA_HOME': await findJavaHome(),
      });
    });

    return TaskResult.success(null);
  });
}
