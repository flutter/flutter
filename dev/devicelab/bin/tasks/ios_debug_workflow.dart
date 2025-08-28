// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// This is a test to validate that Xcode debugging still works now that LLDB is the default.
Future<void> main() async {
  await task(() async {
    deviceOperatingSystem = DeviceOperatingSystem.ios;
    return createIosWorkflowTest()();
  });
}

Future<void> enableLLDBDebugging() async {
  final int configResult = await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
    'config',
    '--enable-lldb-debugging',
  ], canFail: true);
  if (configResult != 0) {
    print('Failed to enable configuration.');
  }
}

TaskFunction createIosWorkflowTest({String? deviceIdOverride}) {
  return () async {
    // Create project
    const String appName = 'ios_workflow_test';
    final Directory tempDirectory = dir(Directory.systemTemp.createTempSync().path);
    await exec(_flutterBin, <String>[
      'create',
      '--no-pub',
      appName,
    ], workingDirectory: tempDirectory.path);

    final Directory appDirectory = dir(path.join(tempDirectory.path, appName));

    // Select device
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }

    // Test LLDB workflow
    await enableLLDBDebugging();
    final TaskResult lldbResult = await _validateWorkflow(
      workflow: IosDebugWorkflow.lldb,
      deviceId: deviceIdOverride!,
      appDirectoryPath: appDirectory.path,
    );
    if (lldbResult.failed) {
      return lldbResult;
    }

    // TODO(vashworth): Also test Xcode workflow once
    // https://github.com/flutter/flutter/issues/173573 is fixed.

    return TaskResult.success(null);
  };
}

Future<TaskResult> _validateWorkflow({
  required IosDebugWorkflow workflow,
  required String deviceId,
  required String appDirectoryPath,
}) async {
  final List<String> options = <String>[
    '--no-android-gradle-daemon',
    '--verbose',
    '--debug',
    '--no-publish-port',
    '-d',
    deviceId,
  ];
  final Process process = await startFlutter(
    'run',
    options: options,
    workingDirectory: appDirectoryPath,
  );

  Pattern expectedLog;
  Pattern unexpectedLog;
  const Pattern xcodeExpectedLog = 'Action result status: not yet started';
  final Pattern lldbExpectedLog = RegExp(r'Process .* resuming');
  switch (workflow) {
    case IosDebugWorkflow.xcode:
      expectedLog = xcodeExpectedLog;
      unexpectedLog = lldbExpectedLog;
    case IosDebugWorkflow.lldb:
      expectedLog = lldbExpectedLog;
      unexpectedLog = xcodeExpectedLog;
  }

  // TODO(vashworth): Update to verify app launched all the way once
  // https://github.com/flutter/flutter/issues/173365 is fixed.
  final Pattern finishPattern = RegExp(
    'Application launched on the device. Waiting for Dart VM Service url.',
  );

  String? foundUnexpectedLog;
  String? foundExpectedLog;

  final StreamSubscription<String> stdoutSubscription = process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('stdout: $line');
        if (line.contains(finishPattern)) {
          process.kill();
        }

        if (line.contains(expectedLog)) {
          foundExpectedLog = line;
        }

        if (line.contains(unexpectedLog)) {
          foundUnexpectedLog = line;
        }
      });

  final StreamSubscription<String> stderrSubscription = process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) => print('stderr: $line'));

  final int runFlutterResult = await process.exitCode.whenComplete(() {
    stdoutSubscription.cancel();
    stderrSubscription.cancel();
  });
  if (runFlutterResult != 0) {
    print('Flutter run returned non-zero exit code: $runFlutterResult.');
    return TaskResult.failure('failed');
  }

  if (foundUnexpectedLog != null) {
    return TaskResult.failure('Unexpected logs found: $foundUnexpectedLog');
  }
  if (foundExpectedLog == null) {
    return TaskResult.failure('Expected logs not found.');
  }

  return TaskResult.success(null);
}

enum IosDebugWorkflow { xcode, lldb }

final String _flutterBin = path.join(flutterDirectory.path, 'bin', 'flutter');
