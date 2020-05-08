// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final Directory integrationTestDir = Directory(
  path.join(flutterDirectory.path, 'dev/integration_tests/ui'),
);

/// Verifies that track-widget-creation can be enabled and disabled.
class TrackWidgetCreationEnabledTask {
  TrackWidgetCreationEnabledTask([
    this.deviceIdOverride,
    this.additionalArgs = const <String>[],
  ]);

  String deviceIdOverride;
  final List<String> additionalArgs;

  Future<TaskResult> task() async {
    final File file = File(path.join(integrationTestDir.path, 'info'));
    if (file.existsSync()) {
      file.deleteSync();
    }
    bool failed = false;
    String message = '';
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }
    await inDirectory<void>(integrationTestDir, () async {
      section('Running with track-widget-creation enabled');
      final Process runProcess = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        flutterCommandArgs('run', <String>[
          ...?additionalArgs,
          '--vmservice-out-file=info',
          '--track-widget-creation',
          '-v',
          '-d',
          deviceIdOverride,
          path.join('lib/track_widget_creation.dart'),
        ]),
      );
      runProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(print);
      final File file = await waitForFile(path.join(integrationTestDir.path, 'info'));
      final VmService vmService = await vmServiceConnectUri(file.readAsStringSync());
      final VM vm = await vmService.getVM();
      final Response result = await vmService.callMethod(
        'ext.devicelab.test',
        isolateId: vm.isolates.single.id,
       );
      if (result.json['result'] != 2) {
        message += result.json.toString();
        failed = true;
      }
      runProcess.stdin.write('q');
      vmService.dispose();
      file.deleteSync();
      await runProcess.exitCode;
    });

    await inDirectory<void>(integrationTestDir, () async {
      section('Running with track-widget-creation disabled');
      final Process runProcess = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        flutterCommandArgs('run', <String>[
           ...?additionalArgs,
           '--vmservice-out-file=info',
          '--no-track-widget-creation',
          '-v',
          '-d',
          deviceIdOverride,
          path.join('lib/track_widget_creation.dart'),
        ]),
      );
      runProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(print);
      final File file = await waitForFile(path.join(integrationTestDir.path, 'info'));
      final VmService vmService = await vmServiceConnectUri(file.readAsStringSync());
      final VM vm = await vmService.getVM();
      final Response result = await vmService.callMethod(
        'ext.devicelab.test',
        isolateId: vm.isolates.single.id,
       );
      if (result.json['result'] != 1) {
        message += result.json.toString();
        failed = true;
      }
      runProcess.stdin.write('q');
      vmService.dispose();
      file.deleteSync();
      await runProcess.exitCode;
    });

    return failed
      ? TaskResult.failure(message)
      : TaskResult.success(null);
  }
}

/// Wait for up to 400 seconds for the file to appear.
Future<File> waitForFile(String path) async {
  for (int i = 0; i < 20; i += 1) {
    final File file = File(path);
    print('looking for ${file.path}');
    if (file.existsSync()) {
      return file;
    }
    await Future<void>.delayed(const Duration(seconds: 20));
  }
  throw StateError('Did not find vmservice out file after 400 seconds');
}
