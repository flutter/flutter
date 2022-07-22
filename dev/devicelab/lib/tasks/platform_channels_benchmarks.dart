// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory, Process;

import 'package:path/path.dart' as path;

import '../framework/devices.dart' as adb;
import '../framework/framework.dart' show TaskFunction;
import '../framework/task_result.dart' show TaskResult;
import '../framework/utils.dart' as utils;
import '../microbenchmarks.dart' as microbenchmarks;

TaskFunction runTask(adb.DeviceOperatingSystem operatingSystem) {
  return () async {
    adb.deviceOperatingSystem = operatingSystem;
    final adb.Device device = await adb.devices.workingDevice;
    await device.unlock();

    final Directory appDir = utils.dir(path.join(utils.flutterDirectory.path,
        'dev/benchmarks/platform_channels_benchmarks'));
    final Process flutterProcess = await utils.inDirectory(appDir, () async {
      final String flutterExe =
          path.join(utils.flutterDirectory.path, 'bin', 'flutter');
      final List<String> createArgs = <String>[
        'create',
        '--platforms',
        'ios,android',
        '--no-overwrite',
        '-v',
        '.',
      ];
      print('\nExecuting: $flutterExe $createArgs $appDir');
      await utils.eval(flutterExe, createArgs);

      final List<String> options = <String>[
        '-v',
        // --release doesn't work on iOS due to code signing issues
        '--profile',
        '--no-publish-port',
        '-d',
        device.deviceId,
      ];
      return utils.startFlutter(
        'run',
        options: options,
      );
    });

    final Map<String, double> results =
        await microbenchmarks.readJsonResults(flutterProcess);
    return TaskResult.success(results,
        benchmarkScoreKeys: results.keys.toList());
  };
}
