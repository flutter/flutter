// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createSampleCatalogGenerator() {
  return new SampleCatalogGenerator();
}

class SampleCatalogGenerator {

  Future<TaskResult> call() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String deviceId = device.deviceId;

    final Directory catalogDirectory = dir('${flutterDirectory.path}/examples/catalog');
    await inDirectory(catalogDirectory, () async {
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
        await prepareProvisioningCertificates(catalogDirectory.path);
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('drive', options: <String>[
        'test_driver/screenshot.dart',
        '-d',
        deviceId,
      ]);
    });

    return new TaskResult.success(null);
  }
}
