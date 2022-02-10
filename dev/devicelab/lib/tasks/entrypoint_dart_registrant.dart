// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Process, ProcessSignal;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

/// Asserts that the custom entrypoint works in the presence of the dart plugin
/// registrant.
TaskFunction entrypointDartRegistrant() {
  return () async {
    const String testDirName = 'entrypoint_dart_registrant';
    final String integrationTestsPath =
        '${flutterDirectory.path}/dev/integration_tests';
    final String testPath = '$integrationTestsPath/$testDirName';
    await inDirectory(integrationTestsPath, () async {
      await flutter('create', options: <String>[
        '--platforms',
        'android',
        testDirName,
      ]);
    });
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String entrypoint = await inDirectory(testPath, () async {
      // The problem only manifested when the dart plugin registrant was used
      // (which path_provider has).
      await flutter('pub', options: <String>[
        'get',
      ]);
      // The problem only manifested on release builds, so we test release.
      final Process process =
          await startFlutter('run', options: <String>['--release']);
      final Completer<String> completer = Completer<String>();
      final StreamSubscription<String> stdoutSub = process.stdout
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) async {
        print(line);
        if (line.contains('entrypoint:')) {
          completer.complete(line);
        }
      });
      final String entrypoint = await completer.future;
      await stdoutSub.cancel();
      process.stdin.write('q');
      await process.stdin.flush();
      process.kill(ProcessSignal.sigint);
      return entrypoint;
    });
    if (entrypoint.contains('entrypoint: entrypoint')) {
      return TaskResult.success(null);
    } else {
      return TaskResult.failure(entrypoint);
    }
  };
}
