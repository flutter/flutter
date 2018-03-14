// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    int vmServicePort;

    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      final Completer<Null> ready = new Completer<Null>();
      bool ok;
      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', '--verbose', '-d', device.deviceId, 'lib/commands.dart'],
      );
      final StreamController<String> stdout = new StreamController<String>.broadcast();
      run.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          print('run:stdout: $line');
          stdout.add(line);
          if (lineContainsServicePort(line)) {
            vmServicePort = parseServicePort(line);
            print('service protocol connection available at port $vmServicePort');
            print('run: ready!');
            ready.complete();
            ok ??= true;
          }
        });
      run.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          stderr.writeln('run:stderr: $line');
        });
      run.exitCode.then((int exitCode) { ok = false; });
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);
      if (!ok)
        throw 'Failed to run test app.';

      final VMServiceClient client = new VMServiceClient.connect('ws://localhost:$vmServicePort/ws');

      final DriveHelper driver = new DriveHelper(vmServicePort);

      await driver.drive('none');
      print('test: pressing "p" to enable debugPaintSize...');
      run.stdin.write('p');
      await driver.drive('debug_paint');
      print('test: pressing "p" again...');
      run.stdin.write('p');
      await driver.drive('none');
      print('test: pressing "P" to enable performance overlay...');
      run.stdin.write('P');
      await driver.drive('performance_overlay');
      print('test: pressing "P" again...');
      run.stdin.write('P');
      await driver.drive('none');
      final Future<String> reloadStartingText =
        stdout.stream.firstWhere((String line) => line.endsWith('hot reload...'));
      final Future<String> reloadEndingText =
        stdout.stream.firstWhere((String line) => line.contains('Hot reload performed in '));
      print('test: pressing "r" to perform a hot reload...');
      run.stdin.write('r');
      await reloadStartingText;
      await reloadEndingText;
      await driver.drive('none');
      final Future<String> restartStartingText =
        stdout.stream.firstWhere((String line) => line.endsWith('full restart...'));
      final Future<String> restartEndingText =
        stdout.stream.firstWhere((String line) => line.contains('Restart performed in '));
      print('test: pressing "R" to perform a full reload...');
      run.stdin.write('R');
      await restartStartingText;
      await restartEndingText;
      await driver.drive('none');
      run.stdin.write('q');
      final int result = await run.exitCode;
      if (result != 0)
        throw 'Received unexpected exit code $result from run process.';
      print('test: validating that the app has in fact closed...');
      await client.done.timeout(const Duration(seconds: 5));
    });
    return new TaskResult.success(null);
  });
}

class DriveHelper {
  DriveHelper(this.vmServicePort);

  final int vmServicePort;

  Future<Null> drive(String name) async {
    print('drive: running commands_$name check...');
    final Process drive = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['drive', '--use-existing-app', 'http://127.0.0.1:$vmServicePort/', '--keep-app-running', '--driver', 'test_driver/commands_${name}_test.dart'],
    );
    drive.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      print('drive:stdout: $line');
    });
    drive.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      stderr.writeln('drive:stderr: $line');
    });
    final int result = await drive.exitCode;
    if (result != 0)
      throw 'Failed to drive test app (exit code $result).';
    print('drive: finished commands_$name check successfully.');
  }
}
