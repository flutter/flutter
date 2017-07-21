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
      final Completer<Null> ready = new Completer<Null>();
      bool ok;
      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', '--verbose', '--observatory-port=8888', '-d', device.deviceId, 'lib/commands.dart'],
      );
      run.stdout
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          print('run:stdout: $line');
          if (line.contains(new RegExp(r'^\[\s+\] For a more detailed help message, press "h"\. To quit, press "q"\.'))) {
            print('run: ready!');
            ready.complete();
            ok ??= true;
          }
        });
      run.stderr
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          stderr.writeln('run:stderr: $line');
        });
      run.exitCode.then((int exitCode) { ok = false; });
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);
      if (!ok)
        throw 'Failed to run test app.';
      await drive('none');
      print('test: pressing "p" to enable debugPaintSize...');
      run.stdin.write('p');
      await drive('debug_paint');
      print('test: pressing "p" again...');
      run.stdin.write('p');
      await drive('none');
      print('test: pressing "P" to enable performance overlay...');
      run.stdin.write('P');
      await drive('performance_overlay');
      print('test: pressing "P" again...');
      run.stdin.write('P');
      await drive('none');
      run.stdin.write('q');
      final int result = await run.exitCode;
      if (result != 0)
        throw 'Received unexpected exit code $result from run process.';
    });
    return new TaskResult.success(null);
  });
}

Future<Null> drive(String name) async {
  print('drive: running commands_$name check...');
  final Process drive = await startProcess(
    path.join(flutterDirectory.path, 'bin', 'flutter'),
    <String>['drive', '--use-existing-app', 'http://127.0.0.1:8888/', '--keep-app-running', '--driver', 'test_driver/commands_${name}_test.dart'],
  );
  drive.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen((String line) {
      print('drive:stdout: $line');
    });
  drive.stderr
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen((String line) {
      stderr.writeln('drive:stderr: $line');
    });
  final int result = await drive.exitCode;
  if (result != 0)
    throw 'Failed to drive test app (exit code $result).';
  print('drive: finished commands_$name check successfully.');
}