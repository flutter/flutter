// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final Directory integrationTestDir = Directory(
  path.join(flutterDirectory.path, 'dev/integration_tests/ui'));

/// Verifies that track-widget-creation can be enabled and disabled.
class TrackWidgetCreationEnabledTask {
  TrackWidgetCreationEnabledTask([this.deviceIdOverride]);

  String deviceIdOverride;

  Future<TaskResult> task() async {
    bool failed = false;
    String message = '';
    if (deviceIdOverride != null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }
    await inDirectory<void>(integrationTestDir, () async {
      section('Running with track-widget-creation enabled');
      final Process runProcess = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        flutterCommandArgs('run', <String>['--track-widget-creation', '-d', deviceIdOverride]),
        environment: <String, String>{
          'FLUTTER_WEB': 'true',
          'FLUTTER_MACOS': 'true'
        }
      );
      final String runLine = await runProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere(
          (String line) => line.startsWith('SET WIDGETS'),
          orElse: () => null,
        );
      if (runLine == null) {
        failed = true;
        message += 'Test did not report widgets before exiting.';
      } else if (runLine != 'SET WIDGETS: 1') {
        failed = true;
        message += 'Expected 1 widget with track-widget-creation enabled '
          'but found $runLine';
      }
      await runProcess.exitCode
        .timeout(const Duration(minutes: 1));
    });

    await inDirectory<void>(integrationTestDir, () async {
      section('Running with track-widget-creation disabled');
      final Process runProcess = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        flutterCommandArgs('run', <String>['--no-track-widget-creation', '-d', deviceIdOverride]),
        environment: <String, String>{
          'FLUTTER_WEB': 'true',
          'FLUTTER_MACOS': 'true'
        }
      );
      final String runLine = await runProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere(
          (String line) => line.startsWith('SET WIDGETS'),
          orElse: () => null,
        );
      if (runLine == null) {
        failed = true;
        message += 'Test did not report widgets before exiting.';
      } else if (runLine != 'SET WIDGETS: 2') {
        failed = true;
        message += 'Expected 2 widget with track-widget-creation disaabled '
          'but found $runLine';
      }
      await runProcess.exitCode
        .timeout(const Duration(minutes: 1));
    });

    return failed
      ? TaskResult.failure(message)
      : TaskResult.success(null);
  }
}
