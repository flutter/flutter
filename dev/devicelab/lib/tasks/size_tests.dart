// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../framework/framework.dart';
import '../framework/utils.dart';

import 'package:flutter_devicelab/framework/adb.dart';

TaskFunction createBasicMaterialAppSizeTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    if (await sampleDir.exists())
      rmTree(sampleDir);

    int releaseSizeInBytes;

    await inDirectory(Directory.systemTemp, () async {
      await flutter('create', options: <String>[sampleAppName]);

      if (!(await sampleDir.exists()))
        throw 'Failed to create sample Flutter app in ${sampleDir.path}';

      await inDirectory(sampleDir, () async {
        await flutter('packages', options: <String>['get']);
        await flutter('build', options: <String>['clean']);

        if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
          await flutter('build', options: <String>['ios', '--release']);
          // IPAs are created manually AFAICT
          await exec('tar', <String>['-zcf', 'build/app.ipa', 'build/ios/Release-iphoneos/Runner.app/']);
          releaseSizeInBytes = await file('${sampleDir.path}/build/app.ipa').length();
        } else {
          await flutter('build', options: <String>['apk', '--release']);
          releaseSizeInBytes = await file('${sampleDir.path}/build/app.apk').length();
        }
      });
    });

    return new TaskResult.success(
        <String, dynamic>{'release_size_in_bytes': releaseSizeInBytes},
        benchmarkScoreKeys: <String>['release_size_in_bytes']);
  };
}
