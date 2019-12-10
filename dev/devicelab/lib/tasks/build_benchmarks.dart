// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final Directory helloWorldDir = dir(path.join(flutterDirectory.path, 'examples', 'hello_world'));

/// Creates a devicelab build benchmark for Android.
TaskFunction createAndroidBuildBenchmarkTask() {
  return () async {
    return createBuildCommand('apk');
  };
}

/// Creates a devicelab build benchmark for iOS.
TaskFunction createIosBuildBenchmarkTask() {
  return () async {
    return createBuildCommand('ios');
  };
}

Future<TaskResult> createBuildCommand(String buildKind) {
  return inDirectory<TaskResult>(helloWorldDir, () async {
    final Stopwatch stopwatch = Stopwatch()
      ..start();
    final Process initialBuild = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['build', buildKind, '--debug'],
      environment: null,
    );
    int exitCode = await initialBuild.exitCode;
    if (exitCode != 0) {
      return TaskResult.failure('Failed to build debug app');
    }
    final int initialBuildMilliseconds = stopwatch.elapsedMilliseconds;
    stopwatch
      ..reset()
      ..start();
    final Process secondBuild = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['build', buildKind, '--debug'],
      environment: null,
    );
    exitCode = await secondBuild.exitCode;
    if (exitCode != 0) {
      return TaskResult.failure('Failed to build debug app');
    }
    final int secondBuildMilliseconds = stopwatch.elapsedMilliseconds;
    final Process newBuildConfig = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['build', buildKind, '--profile'],
      environment: null,
    );
    exitCode = await newBuildConfig.exitCode;
    if (exitCode != 0) {
      return TaskResult.failure('Failed to build profile app');
    }
    stopwatch
      ..reset()
      ..start();
    final Process thirdBuild = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['build', buildKind, '--debug'],
      environment: null,
    );
    exitCode = await thirdBuild.exitCode;
    if (exitCode != 0) {
      return TaskResult.failure('Failed to build debug app');
    }
    final int thirdBuildMilliseconds = stopwatch.elapsedMilliseconds;
    stopwatch.stop();
    final Map<String, double> allResults = <String, double>{};
    allResults['first_build_debug_millis'] = initialBuildMilliseconds.toDouble();
    allResults['second_build_debug_millis'] = secondBuildMilliseconds.toDouble();
    allResults['after_config_change_build_debug_millis'] = thirdBuildMilliseconds.toDouble();
    return TaskResult.success(allResults, benchmarkScoreKeys: allResults.keys.toList());
  });
}
