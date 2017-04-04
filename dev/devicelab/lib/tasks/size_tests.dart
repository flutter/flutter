// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';

import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createBasicMaterialAppSizeTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    if (await sampleDir.exists())
      rmTree(sampleDir);

    final Stopwatch watch = new Stopwatch();
    int releaseSizeInBytes;

    await inDirectory(Directory.systemTemp, () async {
      await flutter('create', options: <String>[sampleAppName]);

      if (!(await sampleDir.exists()))
        throw 'Failed to create sample Flutter app in ${sampleDir.path}';

      await inDirectory(sampleDir, () async {
        await flutter('packages', options: <String>['get']);
        await flutter('build', options: <String>['clean']);

        if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
          await prepareProvisioningCertificates(sampleDir.path);
          watch.start();
          await flutter('build', options: <String>['ios', '--release']);
          watch.stop();
          // IPAs are created manually AFAICT
          await exec('tar', <String>['-zcf', 'build/app.ipa', 'build/ios/Release-iphoneos/Runner.app/']);
          releaseSizeInBytes = await file('${sampleDir.path}/build/app.ipa').length();
        } else {
          watch.start();
          await flutter('build', options: <String>['apk', '--release']);
          watch.stop();
          releaseSizeInBytes = await file('${sampleDir.path}/build/app/outputs/apk/app-release.apk').length();
        }
      });
    });

    return new TaskResult.success(
        <String, dynamic>{
          'release_size_in_bytes': releaseSizeInBytes,
          'build_time_millis': watch.elapsedMilliseconds,
        },
        benchmarkScoreKeys: <String>['release_size_in_bytes', 'build_time_millis']);
  };
}
