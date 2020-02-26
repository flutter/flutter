// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final Directory flutterGalleryDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));
final File runTestSource = File(path.join(
  flutterDirectory.path, 'dev', 'automated_tests', 'flutter_run_test', 'flutter_run_test.dart',
));
const Pattern passedMessageMatch = '+0: example passed';
const Pattern failedMessageMatch = '+1: example failed [E]';
const Pattern skippedMessageMatch = '+1 -1: example skipped';
const Pattern finishedMessageMatch = '+1 ~1 -1: Some tests failed.';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(createFlutterRunTask);
}

// verifies that the messages above are printed as a test script is executed.
Future<TaskResult> createFlutterRunTask() async {
  bool passedTest = false;
  bool failedTest = false;
  bool skippedTest = false;
  bool finishedMessage = false;
  final Device device = await devices.workingDevice;
  await device.unlock();
  final List<String> options = <String>[
    '-t', runTestSource.absolute.path, '-d', device.deviceId,
  ];
  await inDirectory<void>(flutterGalleryDir, () async {
    startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      flutterCommandArgs('run', options),
      environment: null,
    );
    final Completer<void> finished = Completer<void>();
    final StreamSubscription<void> subscription = device.logcat.listen((String line) {
      // tests execute in order.
      if (line.contains(passedMessageMatch)) {
        passedTest = true;
      } else if (line.contains(failedMessageMatch)) {
        failedTest = true;
      } else if (line.contains(skippedMessageMatch)) {
        skippedTest = true;
      } else if (line.contains(finishedMessageMatch)) {
        finishedMessage = true;
        finished.complete();
      }
    });
    await finished.future.timeout(const Duration(minutes: 1));
    subscription.cancel();
  });
  return passedTest && failedTest && skippedTest && finishedMessage
    ? TaskResult.success(<String, dynamic>{})
    : TaskResult.failure('Test did not execute as expected.');
}
