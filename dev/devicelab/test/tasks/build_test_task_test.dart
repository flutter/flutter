// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/runner.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import '../common.dart';

void main() {
  final isolateParams = <String, String>{'runFlutterConfig': 'false', 'timeoutInMinutes': '1'};

  test('runs build and test when no args are passed', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.data!['benchmark'], 'data');
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
    expect(result.data!['benchmark'], 'data');
  });

  test('sets environment', () async {
    final capturedPrintLines = StringBuffer();
    await runZoned<Future<void>>(
      () async {
        await runTask(
          'smoke_test_build_test',
          taskArgs: <String>['--test'],
          deviceId: 'FAKE_SUCCESS',
          isolateParams: isolateParams,
        );
      },
      zoneSpecification: ZoneSpecification(
        // Intercept printing from the task.
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) async {
          capturedPrintLines.writeln(line);
        },
      ),
    );
    final capturedPrint = capturedPrintLines.toString();
    expect(
      capturedPrint,
      allOf(
        contains('with environment {'),
        contains('FLUTTER_DEVICELAB_DEVICEID: FAKE_SUCCESS'),
        contains('BOT: true'),
      ),
    );
    expect(capturedPrint, contains('Process terminated with exit code 0.'));
  });

  test('throws exception when build and test arg are given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--build', '--test'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(
      result.message,
      'Task failed: Exception: Both build and test should not be passed. Pass only one.',
    );
  });

  test('copies artifacts when build and application binary arg are given', () async {
    final TaskResult result = await runTask(
      'smoke_test_build_test',
      taskArgs: <String>['--build', '--application-binary-path=test'],
      deviceId: 'FAKE_SUCCESS',
      isolateParams: isolateParams,
    );
    expect(result.message, 'No tests run');
  });
}
