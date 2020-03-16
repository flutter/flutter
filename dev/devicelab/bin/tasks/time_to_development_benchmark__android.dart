// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(createTimeToDevelopmentCommand);
}

final Directory flutterGalleryDir =
    dir(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'flutter_gallery'));
final Directory editedFlutterGalleryDir =
    dir(path.join(Directory.systemTemp.path, 'edited_flutter_gallery'));

Future<TaskResult> createTimeToDevelopmentCommand() async {
  final Map<String, double> allResults = <String, double>{};
  bool failed = false;
  await inDirectory<void>(flutterDirectory, () async {
    rmTree(editedFlutterGalleryDir);
    mkdirs(editedFlutterGalleryDir);
    recursiveCopy(flutterGalleryDir, editedFlutterGalleryDir);
    await inDirectory<void>(editedFlutterGalleryDir, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final Stopwatch stopwatch = Stopwatch()..start();
      final Process initialBuild = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', '--debug', '-d', device.deviceId, '--no-resident',],
      );
      int exitCode = await initialBuild.exitCode;
      if (exitCode != 0) {
        failed = true;
        return;
      }
      final int initialBuildMilliseconds = stopwatch.elapsedMilliseconds;
      stopwatch
        ..reset()
        ..start();
      // Update a source file.
      final File appDartSource = file(path.join(
        editedFlutterGalleryDir.path,
        'lib/gallery/app.dart',
      ));
      appDartSource.writeAsStringSync(
        appDartSource.readAsStringSync().replaceFirst(
          "'Flutter Gallery'",
          "'Updated Flutter Gallery'",
        ),
      );

      final Process secondBuild = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', '--debug', '-d', device.deviceId, '--no-resident'],
        environment: null,
      );
      exitCode = await secondBuild.exitCode;
      if (exitCode != 0) {
        failed = true;
        return;
      }
      stopwatch.stop();
      allResults['time_to_development'] = initialBuildMilliseconds.toDouble();
      allResults['time_to_development_incremental'] =
          stopwatch.elapsedMilliseconds.toDouble();
    });
  });
  if (failed) {
    return TaskResult.failure('Failed to build debug app');
  }

  return TaskResult.success(allResults,
      benchmarkScoreKeys: allResults.keys.toList());
}
