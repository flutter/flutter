// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<void> main() async {
  await task(() async {
    try {
      await runProjectTest((FlutterProject flutterProject) async {
        section('APK does contain methods from dev dependency in debug mode');

        // Create dev_dependency plugin to use for test.
        final Directory tempDir = Directory.systemTemp.createTempSync('android_release_builds_exclude_dev_dependencies_test.');
        const String devDependencyPluginOrg = 'com.example.dev_dependency_plugin';
        await FlutterPluginProject.create(tempDir, 'dev_dependency_plugin', options: <String>['--platforms=android', '--org=$devDependencyPluginOrg']);

        // Add devDependencyPlugin as dependency of flutterProject.
        await flutterProject.addPlugin('dev_dependency_plugin', options: <String>['--path', '${tempDir.path}/dev_dependency_plugin']);

        // Build APK in debug mode and check that devDependencyPlugin is represented in the APK.
        await inDirectory(flutterProject.rootPath, () async {
          await flutter('build', options: <String>[
            'apk',
            '--debug',
            '--target-platform=android-arm',
          ]);
          File apk = File('${flutterProject.rootPath}/build/app/outputs/flutter-apk/app-debug.apk');
          if (!apk.existsSync()) {
            throw TaskResult.failure("Expected ${apk.path} to exist, but it doesn't");
          }
          bool apkIncludesDevDependency = await checkApkContainsMethodsFromLibrary(apk, devDependencyPluginOrg);
          if (!apkIncludesDevDependency) {
            return TaskResult.failure('Expected to find dev_dependency_plugin in APK built with debug mode but did not.');
          }

          section('APK does contain methods from dev dependency in release mode');

          // Build APK in release mode and check that devDependencyPlugin is not represented in the APK.
          await flutter('build', options: <String>[
            'apk',
            '--release',
            '--target-platform=android-arm',
          ]);
          apk = File('${flutterProject.rootPath}/build/app/outputs/flutter-apk/app-release.apk');
          if (!apk.existsSync()) {
            throw TaskResult.failure("Expected ${apk.path} to exist, but it doesn't");
          }
          apkIncludesDevDependency = await checkApkContainsMethodsFromLibrary(apk, devDependencyPluginOrg);
          if (apkIncludesDevDependency) {
            return TaskResult.failure('Expected to not find dev_dependency_plugin in APK built with release mode but did.');
          }
        });
      });
      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
          return taskResult;
        } catch (e) {
          return TaskResult.failure(e.toString());
        }
  });
}
