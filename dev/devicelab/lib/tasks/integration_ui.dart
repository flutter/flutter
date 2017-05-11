// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

Future<TaskResult> runEndToEndTests() async {
  final Device device = await devices.workingDevice;
  await device.unlock();
  final String deviceId = device.deviceId;
  final Directory testDirectory = dir('${flutterDirectory.path}/dev/integration_tests/ui');
  await inDirectory(testDirectory, () async {
    await flutter('packages', options: <String>['get']);

    if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
      await prepareProvisioningCertificates(testDirectory.path);
      // This causes an Xcode project to be created.
      await flutter('build', options: <String>['ios']);
    }

    await flutter('drive', options: <String>['-d', deviceId, 'lib/keyboard_resize.dart']);
  });

  return new TaskResult.success(<String, dynamic>{});
}
