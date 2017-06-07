// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

Future<TaskResult> samplePageCatalogGenerator(String authorizationToken) async {
  final Device device = await devices.workingDevice;
  await device.unlock();
  final String deviceId = device.deviceId;

  final Directory catalogDirectory = dir('${flutterDirectory.path}/examples/catalog');
  await inDirectory(catalogDirectory, () async {
    await flutter('packages', options: <String>['get']);

    if (deviceOperatingSystem == DeviceOperatingSystem.ios)
      await prepareProvisioningCertificates(catalogDirectory.path);

    await dart(<String>['bin/sample_page.dart']);

    await flutter('drive', options: <String>[
      '--target',
      'test_driver/screenshot.dart',
      '--device-id',
      deviceId,
    ]);

    await dart(<String>[
      'bin/save_screenshots.dart',
      await getCurrentFlutterRepoCommit(),
      authorizationToken,
    ]);
  });

  return new TaskResult.success(null);
}
