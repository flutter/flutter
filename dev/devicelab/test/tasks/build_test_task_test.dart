// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/build_test_task.dart';

import '../common.dart';

void main() {
  Device device;

  setUp(() {
    FakeDevice.resetLog();
    device = const FakeDevice(deviceId: 'abc');
  });

  test('runs build and test when no args are passed', () async {
    final TaskResult result = await FakeBuildTestTask(<String>[]).call();
    expect(result.data['benchmark'], 'data');
  });

  test('runs build only when build arg is given', () async {
    final TaskResult result = await FakeBuildTestTask(<String>['--build']).call();
    expect(result.data['benchmark'], 'data');
  });

  test('runs test only when test arg is given', () async {
    final TaskResult result = await FakeBuildTestTask(<String>['--test']).call();
    expect(result.data['benchmark'], 'data');
  });

  test('throws exception when build and test arg are given', () async {
    expect(() => FakeBuildTestTask(<String>['--build', '--test']).call(), throwsException);
  });
}

class FakeBuildTestTask extends BuildTestTask {
  FakeBuildTestTask(List<String> args) : super(args);
  
  /// Args passed to flutter build to build the application under test.
  @override
  List<String> getBuildArgs(DeviceOperatingSystem deviceOperatingSystem) => <String>[];

  /// Args passed to flutter drive to test the built application.
  @override
  List<String> getTestArgs(DeviceOperatingSystem deviceOperatingSystem, String deviceId) => <String>[];

  /// Logic to construct [TaskResult] from this test's results.
  @override
  Future<TaskResult> parseTaskResult() async => TaskResult.success(<String, String>{'benchmark': 'data'});
}