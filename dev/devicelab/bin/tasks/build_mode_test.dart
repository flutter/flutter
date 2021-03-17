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

Future<String> runFlutterAndQuit(List<String> args, Device device) async {
  final Completer<void> ready = Completer<void>();
  print('run: starting...');
  final Process run = await startProcess(
    path.join(flutterDirectory.path, 'bin', 'flutter'),
    <String>['run', '--suppress-analytics', '--no-publish-port', ...args],
    isBot: false, // we just want to test the output, not have any debugging info
  );
  final List<String> stdout = <String>[];
  final List<String> stderr = <String>[];
  int runExitCode;
  run.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(
    (String line) {
      print('run:stdout: $line');
      stdout.add(line);
      if (line.contains('>>> FINISHED <<<')) {
        ready.complete();
      }
    },
  );
  run.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(
    (String line) {
      print('run:stderr: $line');
      stderr.add(line);
    },
  );
  run.exitCode.then<void>((int exitCode) {
    runExitCode = exitCode;
  });
  await Future.any<dynamic>(<Future<dynamic>>[ready.future, run.exitCode]);
  if (runExitCode != null) {
    throw 'Failed to run test app; runner unexpected exited, with exit code $runExitCode.';
  }
  run.stdin.write('q');
  await run.exitCode;
  if (stderr.isNotEmpty) {
    throw 'flutter run ${args.join(' ')} had output on standard error:\n${stderr.join('\n')}';
  }
  return stdout.join('\n');
}

void main() {
  task(() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    Future<void> checkMode(String mode, {bool releaseExpected = false, bool dynamic = false}) async {
      await inDirectory(appDir, () async {
        print('run: starting $mode test...');
        final List<String> args = <String>[
          '--$mode',
          if (dynamic) '--dynamic',
          '-d',
          device.deviceId,
          'lib/build_mode.dart',
        ];
        final String stdout = await runFlutterAndQuit(args, device);
        if (!stdout.contains('>>> Release: $releaseExpected <<<')) {
          throw "flutter run --$mode ${dynamic ? '--dynamic ' : ''}didn't set kReleaseMode properly";
        }
      });
    }
    await checkMode('debug', releaseExpected: false);
    await checkMode('profile', releaseExpected: false);
    await checkMode('profile', releaseExpected: false, dynamic: true);
    await checkMode('release', releaseExpected: true);
    await checkMode('release', releaseExpected: true, dynamic: true);
    return TaskResult.success(null);
  });
}
