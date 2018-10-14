// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      final Completer<void> ready = Completer<void>();
      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['--suppress-analytics', 'run', '--release', '-d', device.deviceId, 'lib/main.dart'],
        isBot: false, // we just want to test the output, not have any debugging info
      );
      final List<String> stdout = <String>[];
      final List<String> stderr = <String>[];
      int runExitCode;
      run.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('run:stdout: $line');
          stdout.add(line);
          if (line.contains('To quit, press "q".'))
            ready.complete();
        });
      run.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('run:stderr: $line');
          stdout.add(line);
        });
      run.exitCode.then<void>((int exitCode) { runExitCode = exitCode; });
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);
      if (runExitCode != null)
        throw 'Failed to run test app; runner unexpected exited, with exit code $runExitCode.';
      run.stdin.write('q');
      await run.exitCode;
      if (stderr.isNotEmpty)
        throw 'flutter run --release had output on standard error.';
      if (stdout.first.startsWith('Building flutter tool...'))
        stdout.removeAt(0);
      if (stdout.first.startsWith('Running "flutter packages get" in ui...'))
        stdout.removeAt(0);
      if (stdout.first.startsWith('Initializing gradle...'))
        stdout.removeAt(0);
      if (stdout.first.startsWith('Resolving dependencies...'))
        stdout.removeAt(0);
      if (!(stdout.first.startsWith('Launching lib/main.dart on ') && stdout.first.endsWith(' in release mode...')))
        throw 'flutter run --release had unexpected first line: ${stdout.first}';
      stdout.removeAt(0);
      if (!stdout.first.startsWith('Gradle task \'assembleRelease\'...'))
        throw 'flutter run --release had unexpected second line: ${stdout.first}';
      stdout.removeAt(0);
      if (!(stdout.first.startsWith('Built build/app/outputs/apk/release/app-release.apk (') && stdout.first.endsWith('MB).')))
        throw 'flutter run --release had unexpected third line: ${stdout.first}';
      stdout.removeAt(0);
      if (stdout.first.startsWith('Installing build/app/outputs/apk/app.apk...'))
        stdout.removeAt(0);
      if (stdout.join('\n') != '\nTo quit, press "q".\n\nApplication finished.') {
        throw 'flutter run --release had unexpected output after third line:\n'
            '${stdout.join('\n')}';
      }
    });
    return TaskResult.success(null);
  });
}
