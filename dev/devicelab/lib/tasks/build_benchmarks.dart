// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final Directory helloWorldDir = dir(path.join(flutterDirectory.path, 'examples', 'hello_world'));

/// Creates a device lab build benchmark.
TaskFunction createBuildbenchmarkTask() {
  return () async {
    return inDirectory<TaskResult>(helloWorldDir, () async {
      final Stopwatch stopwatch = Stopwatch()
        ..start();
      final Process initialBuild = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['build', 'apk', '--debug'],
        environment: null,
      );
      int exitCode = await initialBuild.exitCode;
      if (exitCode != 0) {
        return TaskResult.failure('Failed to build debug APK');
      }
      final int initialBuildMilliseconds = stopwatch.elapsedMilliseconds;
      stopwatch
        ..reset()
        ..start();
      final Process secondBuild = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['build', 'apk', '--debug'],
        environment: null,
      );
      exitCode = await secondBuild.exitCode;
      if (exitCode != 0) {
        return TaskResult.failure('Failed to build debug APK');
      }
      final int secondBuildMilliseconds = stopwatch.elapsedMilliseconds;
      final Process newBuildConfig = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['build', 'apk', '--profile'],
        environment: null,
      );
      exitCode = await newBuildConfig.exitCode;
      if (exitCode != 0) {
        return TaskResult.failure('Failed to build profile APK');
      }
      stopwatch
        ..reset()
        ..start();
      final Process thirdBuild = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['build', 'apk', '--debug'],
        environment: null,
      );
      exitCode = await thirdBuild.exitCode;
      if (exitCode != 0) {
        return TaskResult.failure('Failed to build debug APK');
      }
      final int thirdBuildMilliseconds = stopwatch.elapsedMilliseconds;
      stopwatch.stop();
      final Map<String, double> allResults = <String, double>{};
      allResults['first_build_debug_millis'] = initialBuildMilliseconds.toDouble();
      allResults['second_build_debug_millis'] = secondBuildMilliseconds.toDouble();
      allResults['after_config_change_build_debug_millis'] = thirdBuildMilliseconds.toDouble();
      return TaskResult.success(allResults, benchmarkScoreKeys: allResults.keys.toList());
    });
  };
}
