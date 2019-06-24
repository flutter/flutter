// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      await runProjectTest((FlutterProject project) async {
        section('App bundle content for task bundleRelease without explicit target platform');
        await project.runGradleTask('bundleRelease');

        final String releaseBundle = path.join(
            project.rootPath,
            'build',
            'app',
            'outputs',
            'bundle',
            'release',
            'app.aab',
          );

        final Iterable<String> bundleFiles = await getFilesInAppBundle(releaseBundle);

        checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);
      });

      await runProjectTest((FlutterProject project) async {
        section('App bundle content using flavors without explicit target platform');
        // Add a few flavors.
        await project.addProductFlavors(<String> ['production', 'staging', 'development']);
        // Build the production flavor in release mode.
        await project.runGradleTask('bundleProductionRelease');

        final String bundlePath = path.join(
            project.rootPath,
            'build',
            'app',
            'outputs',
            'bundle',
            'productionRelease',
            'app.aab',
          );

        final Iterable<String> bundleFiles = await getFilesInAppBundle(bundlePath);

        checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);
      });

      await runProjectTest((FlutterProject project) async {
        section('App bundle content for task bundleRelease with target platform = android-arm');
        await project.runGradleTask('bundleRelease',
            options: <String>['-Ptarget-platform=android-arm']);

        final String releaseBundle = path.join(
            project.rootPath,
            'build',
            'app',
            'outputs',
            'bundle',
            'release',
            'app.aab',
          );

        final Iterable<String> bundleFiles = await getFilesInAppBundle(releaseBundle);

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
