// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createRunWithoutLeakTest(dynamic dir) {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final List<String> options = <String>[
      '-d', device.deviceId, '--verbose',
    ];
    int exitCode;
    await inDirectory<void>(dir, () async {
      final Process process = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          flutterCommandArgs('run', options),
          environment: null,
      );
      final Completer<void> stdoutDone = Completer<void>();
      final Completer<void> stderrDone = Completer<void>();
      process.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
        if (line.contains('] For a more detailed help message, press "h". To detach, press "d"; to quit, press "q"')) {
          process.stdin.writeln('q');
        }
        print('stdout: $line');
      }, onDone: () {
        stdoutDone.complete();
      });
      process.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
        print('stderr: $line');
      }, onDone: () {
        stderrDone.complete();
      });

      await Future.wait<void>(
          <Future<void>>[stdoutDone.future, stderrDone.future]);
      exitCode = await process.exitCode;
    });

    return exitCode == 0
        ? TaskResultCheckProcesses()
        : TaskResult.failure('Failed to run $dir');
  };
}
