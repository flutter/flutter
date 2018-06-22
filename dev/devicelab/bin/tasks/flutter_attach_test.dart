// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<void> testReload(Process process, { Future<void> Function() onListening }) async {
  print('Testing hot reload, restart and quit');
  final Completer<Null> listening = new Completer<Null>();
  final Completer<Null> ready = new Completer<Null>();
  final Completer<Null> reloaded = new Completer<Null>();
  final Completer<Null> restarted = new Completer<Null>();
  final List<String> stdout = <String>[];
  final List<String> stderr = <String>[];

  if (onListening == null)
    listening.complete();

  int exitCode;
  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    print('attach:stdout: $line');
    stdout.add(line);
    if (line.contains('Listening') && onListening != null) {
      listening.complete(onListening());
    }
    if (line.contains('To quit, press "q".'))
      ready.complete();
    if (line.contains('Reloaded '))
      reloaded.complete();
    if (line.contains('Restarted app in '))
      restarted.complete();
  });
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    print('run:stderr: $line');
    stdout.add(line);
  });

  process.exitCode.then((int processExitCode) { exitCode = processExitCode; });

  await Future.any<dynamic>(<Future<dynamic>>[ listening.future, process.exitCode ]);
  await Future.any<dynamic>(<Future<dynamic>>[ ready.future, process.exitCode ]);

  if (exitCode != null)
    throw 'Failed to attach to test app; command unexpected exited, with exit code $exitCode.';

  process.stdin.write('r');
  process.stdin.flush();
  await reloaded.future;
  process.stdin.write('R');
  process.stdin.flush();
  await restarted.future;
  process.stdin.write('q');
  process.stdin.flush();

  await process.exitCode;

  if (stderr.isNotEmpty)
    throw 'flutter attach had output on standard error.';

  if (exitCode != 0)
    throw 'exit code was not 0';

  const List<String> expectedLinePrefixes = const <String>[
    'Initializing hot reload...',
    'Reloaded ',
    'Performing hot restart...',
    'Restarted app in ',
    'Application finished',
  ];

  int expectedIndex = 0;
  for (int i = 0; i < stdout.length; i++) {
    if (stdout[i].startsWith(expectedLinePrefixes[expectedIndex])) {
      expectedIndex++;
      if (expectedIndex >= expectedLinePrefixes.length)
        break;
    }
  }

  if (expectedIndex != expectedLinePrefixes.length)
    throw 'not all expected lines were found';
}

void main() {
  task(() async {
    final AndroidDevice device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      print('Build: starting...');
      final String buildStdout = await eval(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'build', 'apk', '--debug', 'lib/main.dart'],
      );
      final String lastLine = buildStdout.split('\n').last;
      final RegExp builtRegExp = new RegExp(r'Built (.+)( \(|\.$)');
      final String apkPath = builtRegExp.firstMatch(lastLine)[1];

      print('Installing $apkPath');

      await device.adb(<String>['install', apkPath]);

      try {
        print('Launching attach.');
        Process attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'attach', '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );

        await testReload(attachProcess, onListening: () async {
          print('Launching app.');
          await device.shellExec('am', <String>['start', '-n', 'com.yourcompany.integration_ui/com.yourcompany.integration_ui.MainActivity']);
        });

        final String currentTime = (await device.shellEval('date', <String>['"+%F %R:%S.000"'])).trim();
        print('Start time on device: $currentTime');
        print('Launching app');
        await device.shellExec('am', <String>['start', '-n', 'com.yourcompany.integration_ui/com.yourcompany.integration_ui.MainActivity']);

        final String observatoryLine = await device.adb(<String>['logcat', '-e', 'Observatory listening on http:', '-m', '1', '-T', currentTime]);
        print('Found observatory line: $observatoryLine');
        final String observatoryPort = new RegExp(r'Observatory listening on http://.*:([0-9]+)').firstMatch(observatoryLine)[1];
        print('Extracted observatory port: $observatoryPort');

        print('Launching attach with given port.');
        attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'attach', '--debug-port', observatoryPort, '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );
        await testReload(attachProcess);

      } finally {
        print('Uninstalling');
        await device.adb(<String>['uninstall', 'com.yourcompany.integration_ui']);
      }
    });
    return new TaskResult.success(null);
  });
}
