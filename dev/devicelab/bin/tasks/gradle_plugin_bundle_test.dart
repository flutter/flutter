// Copyright (c) 2016 The Chromium Authors. All rights reserved.
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
        section('App bundle content for task bundleRelease without explicit target platform');
        await pluginProject.runGradleTask('bundleRelease');

        if (!pluginProject.hasReleaseBundle)
          throw TaskResult.failure(
              'Gradle did not produce a release aab file at: ${pluginProject.releaseBundlePath}');

        final Iterable<String> bundleFiles = await pluginProject.getFilesInAppBundle(pluginProject.releaseBundlePath);

        checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('App bundle content for task bundleRelease with target platform = android-arm');
        await pluginProject.runGradleTask('bundleRelease',
            options: <String>['-Ptarget-platform=android-arm']);

        if (!pluginProject.hasReleaseBundle)
          throw TaskResult.failure(
              'Gradle did not produce a release aab file at: ${pluginProject.releaseBundlePath}');

        final Iterable<String> bundleFiles = await pluginProject.getFilesInAppBundle(pluginProject.releaseBundlePath);

        checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);

        checkItDoesNotContain<String>(<String>[
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
        ], bundleFiles);
      });
      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
