// Copyright 2014 The Flutter Authors. All rights reserved.
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
  final Completer<void> listening = Completer<void>();
  final Completer<void> ready = Completer<void>();
  final Completer<void> reloaded = Completer<void>();
  final Completer<void> restarted = Completer<void>();
  final Completer<void> finished = Completer<void>();
  final List<String> stdout = <String>[];
  final List<String> stderr = <String>[];

  if (onListening == null)
    listening.complete();

  int exitCode;
  process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
    print('attach:stdout: $line');
    stdout.add(line);
    if (line.contains('Waiting') && onListening != null)
      listening.complete(onListening());
    if (line.contains('Quit (terminate the application on the device)'))
      ready.complete();
    if (line.contains('Reloaded '))
      reloaded.complete();
    if (line.contains('Restarted application in '))
      restarted.complete();
    if (line.contains('Application finished'))
      finished.complete();
  });
  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
    print('run:stderr: $line');
    stdout.add(line);
  });

  process.exitCode.then<void>((int processExitCode) { exitCode = processExitCode; });

  Future<dynamic> eventOrExit(Future<void> event) {
    return Future.any<dynamic>(<Future<dynamic>>[
      event,
      process.exitCode,
      // Keep the test from running for 15 minutes if it gets stuck.
      Future<void>.delayed(const Duration(seconds: 10)).then<void>((void _) {
        throw StateError('eventOrExit timed out');
      }),
    ]);
  }

  await eventOrExit(listening.future);
  await eventOrExit(ready.future);

  if (exitCode != null)
    throw TaskResult.failure('Failed to attach to test app; command unexpected exited, with exit code $exitCode.');

  process.stdin.write('r');
  print('run:stdin: r');
  await process.stdin.flush();
  await eventOrExit(reloaded.future);

  process.stdin.write('R');
  print('run:stdin: R');
  await process.stdin.flush();
  await eventOrExit(restarted.future);

  process.stdin.write('q');
  print('run:stdin: q');
  await process.stdin.flush();
  await eventOrExit(finished.future);

  await process.exitCode;

  if (stderr.isNotEmpty)
    throw TaskResult.failure('flutter attach had output on standard error.');

  if (exitCode != 0)
    throw TaskResult.failure('exit code was not 0');
}

void main() {
  const String kAppId = 'com.yourcompany.integration_ui';
  const String kActivityId = '$kAppId/com.yourcompany.integration_ui.MainActivity';

  task(() async {
    final AndroidDevice device = await devices.workingDevice as AndroidDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      section('Building');
      final String buildStdout = await eval(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['--suppress-analytics', 'build', 'apk', '--debug', 'lib/main.dart'],
      );
      final String lastLine = buildStdout.split('\n').last;
      final RegExp builtRegExp = RegExp(r'Built (.+)( \(|\.$)');
      final String apkPath = builtRegExp.firstMatch(lastLine)[1];

      section('Installing $apkPath');

      await device.adb(<String>['install', '-r', apkPath]);

      try {
        section('Launching `flutter attach`');
        Process attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['-v', '--suppress-analytics', 'attach', '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );

        await testReload(attachProcess, onListening: () async {
          await device.shellExec('am', <String>['start', '-n', kActivityId]);
        });

        // Give the device the time to really shut down the app.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // After the delay, force-stopping it shouldn't do anything, but doesn't hurt.
        await device.shellExec('am', <String>['force-stop', kAppId]);

        String currentTime = (await device.shellEval('date', <String>['"+%F %R:%S.000"'])).trim();
        print('Start time on device: $currentTime');
        section('Relaunching application');
        await device.shellExec('am', <String>['start', '-n', kActivityId]);

        // If the next line fails, your device may not support regexp search.
        final String observatoryLine = await device.adb(<String>['logcat', '-e', 'Observatory listening on http:', '-m', '1', '-T', currentTime]);
        print('Found observatory line: $observatoryLine');
        final String observatoryUri = RegExp(r'Observatory listening on ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)').firstMatch(observatoryLine)[1];
        print('Extracted observatory port: $observatoryUri');

        section('Launching attach with given port');
        attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['-v', '--suppress-analytics', 'attach', '--debug-uri',
          observatoryUri, '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );
        await testReload(attachProcess);

        // Give the device the time to really shut down the app.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // After the delay, force-stopping it shouldn't do anything, but doesn't hurt.
        await device.shellExec('am', <String>['force-stop', kAppId]);

        section('Attaching after relaunching application');
        await device.shellExec('am', <String>['start', '-n', kActivityId]);

        // Let the application launch. Sync to the next time an observatory is ready.
        currentTime = (await device.shellEval('date', <String>['"+%F %R:%S.000"'])).trim();
        await device.adb(<String>['logcat', '-e', 'Observatory listening on http:', '-m', '1', '-T', currentTime]);

        // Attach again now that the VM is already running.
        attachProcess = await startProcess(
          path.join(flutterDirectory.path, 'bin', 'flutter'),
          <String>['-v', '--suppress-analytics', 'attach', '-d', device.deviceId],
          isBot: false, // we just want to test the output, not have any debugging info
        );
        // Verify that it can discover the observatory port from past logs.
        await testReload(attachProcess);
      } catch (err, st) {
        print('Uncaught exception: $err\n$st');
        rethrow;
      } finally {
        section('Uninstalling');
        await device.adb(<String>['uninstall', kAppId]);
      }
    });
    return TaskResult.success(null);
  });
}
