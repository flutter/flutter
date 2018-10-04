// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';
import 'save_catalog_screenshots.dart' show saveCatalogScreenshots;


Future<TaskResult> samplePageCatalogGenerator(String authorizationToken) async {
  final Device device = await devices.workingDevice;
  await device.unlock();
  final String deviceId = device.deviceId;

  final Directory catalogDirectory = dir('${flutterDirectory.path}/examples/catalog');
  await inDirectory<void>(catalogDirectory, () async {
    await flutter('packages', options: <String>['get']);

    final bool isIosDevice = deviceOperatingSystem == DeviceOperatingSystem.ios;
    if (isIosDevice)
      await prepareProvisioningCertificates(catalogDirectory.path);

    final String commit = await getCurrentFlutterRepoCommit();

    await dart(<String>['bin/sample_page.dart', commit]);

    await flutter('drive', options: <String>[
      '--target',
      'test_driver/screenshot.dart',
      '--device-id',
      deviceId,
    ]);

    await saveCatalogScreenshots(
      directory: dir('${flutterDirectory.path}/examples/catalog/.generated'),
      commit: commit,
      token: authorizationToken,
      prefix: isIosDevice ? 'ios_' : '',
    );
  });

  return TaskResult.success(null);
}
