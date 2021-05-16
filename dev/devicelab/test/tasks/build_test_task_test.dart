// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/runner.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import '../common.dart';

void main() {
  final Map<String, String> isolateParams = <String, String>{
    'runFlutterConfig': 'false',
    'runProcessCleanup': 'false',
    'timeoutInMinutes': '1',
  };

  test('runs build and test when no args are passed', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.data['benchmark'], 'data');
  });

  test('runs build only when build arg is given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--build'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.message, 'No tests run');
  });

  test('runs test only when test arg is given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--test'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.data['benchmark'], 'data');
  });

  test('throws exception when build and test arg are given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--build', '--test'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.message, 'Task failed: Exception: Both build and test should not be passed. Pass only one.');
  });

  test('throws exception when build and application binary arg are given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--build', '--application-binary-path=test.apk'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.message, 'Task failed: Exception: Application binary path is only used for tests');
  });
}
