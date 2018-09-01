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
  section('Testing hot reload, restart and quit');
  final Completer<Null> listening = new Completer<Null>();
  final Completer<Null> ready = new Completer<Null>();
  final Completer<Null> reloaded = new Completer<Null>();
  final Completer<Null> restarted = new Completer<Null>();
  final Completer<Null> finished = new Completer<Null>();
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
    if (line.contains('Waiting') && onListening != null)
      listening.complete(onListening());
    if (line.contains('To quit, press "q".'))
      ready.complete();
    if (line.contains('Reloaded '))
      reloaded.complete();
    if (line.contains('Restarted application in '))
      restarted.complete();
    if (line.contains('Application finished'))
      finished.complete();
  });
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    print('run:stderr: $line');
    stdout.add(line);
  });

  process.exitCode.then((int processExitCode) { exitCode = processExitCode; });

  Future<dynamic> eventOrExit(Future<Null> event) {
    return Future.any<dynamic>(<Future<dynamic>>[ event, process.exitCode ]);
  }

  await eventOrExit(listening.future);
  await eventOrExit(ready.future);

  if (exitCode != null)
    throw 'Failed to attach to test app; command unexpected exited, with exit code $exitCode.';

  process.stdin.write('r');
  process.stdin.flush();
  await eventOrExit(reloaded.future);
  process.stdin.write('R');
  process.stdin.flush();
  await eventOrExit(restarted.future);
  process.stdin.write('q');
  process.stdin.flush();
  await eventOrExit(finished.future);

  await process.exitCode;

  if (stderr.isNotEmpty)
    throw 'flutter attach had output on standard error.';

  if (exitCode != 0)
    throw 'exit code was not 0';
}

void main() {
  const String kAppId = 'com.yourcompany.integration_ui';
  const String kActivityId = '$kAppId/com.yourcompany.integration_ui.MainActivity';

  task(() async {
    final AndroidDevice device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      section('Building');
      final String buildStdout = await eval(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'build', 'apk', '--debug', 'lib/main.dart'],
      );
      final String lastLine = buildStdout.split('\n').last;
      final RegExp builtRegExp = new RegExp(r'Built (.+)( \(|\.$)');
      final String apkPath = builtRegExp.firstMatch(lastLine)[1];

      section('Installing $apkPath');

      await device.adb(<String>['install', '-r', apkPath]);

      try {
        section('Launching `flutter attach`');
        Process attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'attach', '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );

        await testReload(attachProcess, onListening: () async {
          await device.shellExec('am', <String>['start', '-n', kActivityId]);
        });

        // Give the device the time to really shut down the app.
        await new Future<Null>.delayed(const Duration(milliseconds: 200));
        // After the delay, force-stopping it shouldn't do anything, but doesn't hurt.
        await device.shellExec('am', <String>['force-stop', kAppId]);

        final String currentTime = (await device.shellEval('date', <String>['"+%F %R:%S.000"'])).trim();
        print('Start time on device: $currentTime');
        section('Relaunching application');
        await device.shellExec('am', <String>['start', '-n', kActivityId]);

        // If the next line fails, your device may not support regexp search.
        final String observatoryLine = await device.adb(<String>['logcat', '-e', 'Observatory listening on http:', '-m', '1', '-T', currentTime]);
        print('Found observatory line: $observatoryLine');
        final String observatoryPort = new RegExp(r'Observatory listening on http://.*:([0-9]+)').firstMatch(observatoryLine)[1];
        print('Extracted observatory port: $observatoryPort');

        section('Launching attach with given port');
        attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'attach', '--debug-port', observatoryPort, '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );
        await testReload(attachProcess);

      } finally {
        section('Uninstalling');
        await device.adb(<String>['uninstall', kAppId]);
      }
    });
    return new TaskResult.success(null);
  });
}
