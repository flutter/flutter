// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final Directory flutterGalleryDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));
final File runTestSource = File(path.join(
  flutterDirectory.path, 'dev', 'automated_tests', 'flutter_run_test', 'flutter_run_test.dart',
));
const Pattern passedMessageMatch = '+0: example passed';
const Pattern failedMessageMatch = '+1: example failed [E]';
const Pattern skippedMessageMatch = '+1 -1: example skipped';
const Pattern finishedMessageMatch = '+1 ~1 -1: Some tests failed.';
const Pattern printMessageMatch = 'This is print';
const Pattern writelnMessageMatch = 'This is writeln';

Future<void> main() async {
  await task(createFlutterRunTask);
}

// verifies that the messages above are printed as a test script is executed.
Future<TaskResult> createFlutterRunTask() async {
  bool passedTest = false;
  bool failedTest = false;
  bool skippedTest = false;
  bool finishedMessage = false;
  bool printMessage = false;
  bool writelnMessage = false;
  final Device device = await devices.workingDevice;
  await device.unlock();
  final List<String> options = <String>[
    '-t', runTestSource.absolute.path, '-d', device.deviceId, '-v', '--no-publish-port',
  ];
  await inDirectory<void>(flutterGalleryDir, () async {
    final Process run = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      flutterCommandArgs('run', options),
      environment: null,
    );

    final Completer<void> finished = Completer<void>();
    final StreamSubscription<void> subscription = run.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
      print('stdout: $line');
      // tests execute in order.
      if (line.contains(passedMessageMatch)) {
        passedTest = true;
      } else if (line.contains(failedMessageMatch)) {
        failedTest = true;
      } else if (line.contains(skippedMessageMatch)) {
        skippedTest = true;
      } else if (line.contains(printMessageMatch)) {
        printMessage = true;
      } else if (line.contains(writelnMessageMatch)) {
        writelnMessage = true;
      } else if (line.contains(finishedMessageMatch)) {
        finishedMessage = true;
        finished.complete();
      }
    });
    await finished.future.timeout(const Duration(minutes: 1));
    subscription.cancel();
    run.kill();
  });
  return passedTest && failedTest && skippedTest && finishedMessage && printMessage && writelnMessage
    ? TaskResult.success(<String, dynamic>{})
    : TaskResult.failure('Test did not execute as expected.');
}
