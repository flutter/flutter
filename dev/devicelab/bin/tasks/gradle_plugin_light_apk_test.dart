// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<void> main() async {
  await task(() async {
    try {
      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleDebug with target platform = android-arm');
        await pluginProject.runGradleTask('assembleDebug',
            options: <String>['-Ptarget-platform=android-arm']);

        final Iterable<String> apkFiles = await getFilesInApk(pluginProject.debugApkPath);

        checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
          'lib/armeabi-v7a/libflutter.so',
          // Debug mode intentionally includes `x86` and `x86_64`.
          'lib/x86/libflutter.so',
          'lib/x86_64/libflutter.so',
        ], apkFiles);

        checkItDoesNotContain<String>(<String>[
          'lib/armeabi-v7a/libapp.so',
          'lib/x86/libapp.so',
          'lib/x86_64/libapp.so',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with target platform = android-arm');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm']);

        final Iterable<String> apkFiles = await getFilesInApk(pluginProject.releaseApkPath);

        checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
        ], apkFiles);

        checkItDoesNotContain<String>(<String>[
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with target platform = android-arm64');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm64']);

        final Iterable<String> apkFiles = await getFilesInApk(pluginProject.releaseApkPath);

        checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
        ], apkFiles);

        checkItDoesNotContain<String>(<String>[
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleDebug');
        await project.runGradleTask('assembleDebug');
        final String errorMessage = validateSnapshotDependency(project, 'build/app.dill');
        if (errorMessage != null) {
          throw TaskResult.failure(errorMessage);
        }
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleProfile');
        await project.runGradleTask('assembleProfile');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleLocal (custom debug build)');
        await project.addCustomBuildType('local', initWith: 'debug');
        await project.runGradleTask('assembleLocal');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleLocal (plugin with custom build type)');
        await project.addCustomBuildType('local', initWith: 'debug');
        await project.addGlobalBuildType('local', initWith: 'debug');
        section('Add plugin');
        await project.addPlugin('path_provider');
        await project.getPackages();

        await project.runGradleTask('assembleLocal');
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('gradlew assembleDebug on plugin example');
        await pluginProject.runGradleTask('assembleDebug');
        if (!File(pluginProject.debugApkPath).existsSync())
          throw TaskResult.failure(
              'Gradle did not produce an apk file at the expected place');
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
