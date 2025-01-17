// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart' as utils;
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      await runProjectTest((FlutterProject flutterProject) async {
        // Enable plugins being marked as dev dependncies in the .flutter-plugins-dependencies file.
        await utils.flutter('config', options: <String>['--explicit-package-dependencies']);

        // Create dev_dependency plugin to use for test.
        final Directory tempDir = Directory.systemTemp.createTempSync(
          'android_release_builds_exclude_dev_dependencies_test.',
        );
        const String devDependencyPluginOrg = 'com.example.dev_dependency_plugin';
        await FlutterPluginProject.create(
          tempDir,
          'dev_dependency_plugin',
          options: <String>['--platforms=android', '--org=$devDependencyPluginOrg'],
        );

        // Add devDependencyPlugin as dependency of flutterProject.
        await flutterProject.addPlugin(
          'dev:dev_dependency_plugin',
          options: <String>['--path', path.join(tempDir.path, 'dev_dependency_plugin')],
        );

        final List<String> buildModesToTest = <String>['debug', 'profile', 'release'];
        for (final String buildMode in buildModesToTest) {
          utils.section('APK contains methods from dev dependency in $buildMode mode as expected');

          final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
          final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';
          String eval = await utils.eval(gradlewExecutable, <String>['app:dependencies', '--configuration',  '${buildMode}RuntimeClasspath'], workingDirectory: flutterProject.androidPath);

          final bool isTestingReleaseMode = buildMode == 'release';

          // TODO(camsim99): make check more specific so we know it's what we expect.
          // example: [2025-01-17 11:14:54.115037] [STDOUT] \--- project :dev_dependency_plugin
          // [2025-01-17 11:14:54.115043] [STDOUT]      +--- org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22 (*)
          // [2025-01-17 11:14:54.115049] [STDOUT]      \--- io.flutter:flutter_embedding_debug:1.0.0-5517cc9b3b3bcf12431b47f495e342a30b738835 (*)
          final bool buildContainsDevDependency = eval.contains('\--- project :dev_dependency_plugin');
          final bool apkIncludesDevDependencyAsExpected =
              isTestingReleaseMode ? !buildContainsDevDependency : buildContainsDevDependency;
          if (!apkIncludesDevDependencyAsExpected) {
            throw TaskResult.failure(
              'Expected to${isTestingReleaseMode ? ' not' : ''} find dev_dependency_plugin as a dependency of the app built in $buildMode mode but did${isTestingReleaseMode ? '' : ' not'}.',
            );
          }
        }
      });
      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
