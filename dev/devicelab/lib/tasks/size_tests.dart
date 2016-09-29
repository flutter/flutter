// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createBasicMaterialAppSizeTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    if (await sampleDir.exists())
      rmTree(sampleDir);

    int apkSizeInBytes;

    await inDirectory(Directory.systemTemp, () async {
      await flutter('create', options: <String>[sampleAppName]);

      if (!(await sampleDir.exists()))
        throw 'Failed to create sample Flutter app in ${sampleDir.path}';

      await inDirectory(sampleDir, () async {
        await flutter('packages', options: <String>['get']);
        await flutter('build', options: <String>['clean']);
        await flutter('build', options: <String>['apk', '--release']);
        apkSizeInBytes = await file('${sampleDir.path}/build/app.apk').length();
      });
    });

    return new TaskResult.success(
        <String, dynamic>{'release_size_in_bytes': apkSizeInBytes},
        benchmarkScoreKeys: <String>['release_size_in_bytes']);
  };
}
