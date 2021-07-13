// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/common.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

void main() {
  task(() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      final Completer<void> ready = Completer<void>();
      final List<String> stdout = <String>[];
      final List<String> stderr = <String>[];

      // Uninstall if the app is already installed on the device to get to a clean state.
      print('uninstalling...');
      final Process uninstall = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['--suppress-analytics', 'install', '--uninstall-only', '-d', device.deviceId],
      )..stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
        print('uninstall:stdout: $line');
      })..stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
        print('uninstall:stderr: $line');
        stderr.add(line);
      });
      if (await uninstall.exitCode != 0) {
        throw 'flutter install --uninstall-only failed.';
      }

      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['--suppress-analytics', 'run', '--release', '-d', device.deviceId, 'lib/main.dart'],
        isBot: false, // we just want to test the output, not have any debugging info
      );
      int? runExitCode;
      run.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('run:stdout: $line');
          if (
            !line.startsWith('Building flutter tool...') &&
            !line.startsWith('Running "flutter pub get" in ui...') &&
            !line.startsWith('Initializing gradle...') &&
            !line.contains('settings_aar.gradle') &&
            !line.startsWith('Resolving dependencies...') &&
            // Catch engine piped output from unrelated concurrent Flutter apps
            !line.contains(RegExp(r'[A-Z]\/flutter \([0-9]+\):')) &&
            // Empty lines could be due to the progress spinner breaking up.
            line.length > 1
          ) {
            stdout.add(line);
          }
          if (line.contains('Quit (terminate the application on the device).')) {
            ready.complete();
          }
        });
      run.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('run:stderr: $line');
          stderr.add(line);
        });
      unawaited(run.exitCode.then<void>((int exitCode) { runExitCode = exitCode; }));
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);
      if (runExitCode != null) {
        throw 'Failed to run test app; runner unexpected exited, with exit code $runExitCode.';
      }
      run.stdin.write('q');

      await run.exitCode;

      if (stderr.isNotEmpty) {
        throw 'flutter run --release had output on standard error.';
      }

      _findNextMatcherInList(
        stdout,
        (String line) => line.startsWith('Launching lib/main.dart on ') && line.endsWith(' in release mode...'),
        'Launching lib/main.dart on',
      );

      _findNextMatcherInList(
        stdout,
        (String line) => line.startsWith("Running Gradle task 'assembleRelease'..."),
        "Running Gradle task 'assembleRelease'...",
      );

      _findNextMatcherInList(
        stdout,
        (String line) => line.contains('Built build/app/outputs/flutter-apk/app-release.apk (') && line.contains('MB).'),
        'Built build/app/outputs/flutter-apk/app-release.apk',
      );

      _findNextMatcherInList(
        stdout,
        (String line) => line.startsWith('Installing build/app/outputs/flutter-apk/app.apk...'),
        'Installing build/app/outputs/flutter-apk/app.apk...',
      );

      _findNextMatcherInList(
        stdout,
        (String line) => line.contains('Quit (terminate the application on the device).'),
        'q Quit (terminate the application on the device)',
      );

      _findNextMatcherInList(
        stdout,
        (String line) => line == 'Application finished.',
        'Application finished.',
      );
    });
    return TaskResult.success(null);
  });
}

void _findNextMatcherInList(
  List<String> list,
  bool Function(String testLine) matcher,
  String errorMessageExpectedLine
) {
  final List<String> copyOfListForErrorMessage = List<String>.from(list);

  while (list.isNotEmpty) {
    final String nextLine = list.first;
    list.removeAt(0);

    if (matcher(nextLine)) {
      return;
    }
  }

  throw '''
Did not find expected line

$errorMessageExpectedLine

in flutter run --release stdout

$copyOfListForErrorMessage
  ''';
}
