// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import '../framework/adb.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

/// [Task] for defining build-test separation.
///
/// Using this [Task] allows DeviceLab capacity to only be spent on the [test].
abstract class BuildTestTask {
  BuildTestTask(this.args, {this.workingDirectory}) {
    final ArgResults argResults = argParser.parse(args);
    applicationBinaryPath = argResults[kBinaryPathOption] as String;
  }

  static const String kBinaryPathOption = 'binary-path';
  static const String kBuildOnlyOption = 'build-only';

  final ArgParser argParser = ArgParser()
    ..addOption(kBinaryPathOption)
    ..addFlag(kBuildOnlyOption);

  final List<String> args;

  /// If passed, `build` is skipped and `test` is run. If null, only `build` is run.
  String applicationBinaryPath;

  /// If true, skip [test].
  bool buildOnly = false;

  /// Where the test artifacts are stored, such as performance results.
  final Directory workingDirectory;

  /// Run Flutter build to create [applicationBinaryPath].
  Future<void> build() async {
    await inDirectory<void>(workingDirectory, () async {
      section('BUILDING APPLICATION');
      await flutter('build', options: getBuildArgs(deviceOperatingSystem));
    });

  }

  /// Run Flutter drive test from [getTestArgs] against the application under test on the device.
  ///
  /// This assumes that [build()] was called or [applicationBinaryPath] exists.
  Future<TaskResult> test() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    await inDirectory<void>(workingDirectory, () async {
      section('DRIVE START');
      await flutter('drive', options: getTestArgs(deviceOperatingSystem, device.deviceId));
    });

    return parseTaskResult();
  }

  /// Args passed to flutter build to build the application under test.
  List<String> getBuildArgs(DeviceOperatingSystem deviceOperatingSystem) => throw UnimplementedError('getBuildArgs is not implemented');

  /// Args passed to flutter drive to test the built application.
  List<String> getTestArgs(DeviceOperatingSystem deviceOperatingSystem, String deviceId) => throw UnimplementedError('getTestArgs is not implemented');

  /// Logic to construct [TaskResult] from this test's results.
  Future<TaskResult> parseTaskResult() => throw UnimplementedError('parseTaskResult is not implemented');

  /// Run this task.
  Future<TaskResult> call() async {
    if (applicationBinaryPath.isEmpty) {
      build();
    }

    if (buildOnly) {
      return TaskResult.empty();
    }

    return test();
  }
}
