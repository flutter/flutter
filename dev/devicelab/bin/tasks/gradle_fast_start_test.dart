// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<void> main() async {
  await task(() async {
    try {
      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleDebug with --fast-start');
        await pluginProject.runGradleTask('assembleDebug',
            options: <String>['-Pfast-start=true']);

        final Iterable<String> apkFiles = await getFilesInApk(pluginProject.debugApkPath);

        checkCollectionContains<String>(<String>[
          ...debugAssets,
          ...baseApkFiles,
          'lib/x86/libflutter.so',
          'lib/x86_64/libflutter.so',
          'lib/armeabi-v7a/libflutter.so',
          'lib/arm64-v8a/libflutter.so',
        ], apkFiles);

        checkCollectionDoesNotContain<String>(<String>[
          ...flutterAssets,
        ], apkFiles);
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
