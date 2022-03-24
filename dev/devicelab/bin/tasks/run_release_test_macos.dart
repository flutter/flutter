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

/// Basic launch test for desktop operating systems.
void main() {
  task(() async {
    deviceOperatingSystem = DeviceOperatingSystem.macos;
    final Device device = await devices.workingDevice;
    // TODO(cbracken): https://github.com/flutter/flutter/issues/87508#issuecomment-1043753201
    // Switch to dev/integration_tests/ui once we have CocoaPods working on M1 Macs.
    final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));
    await inDirectory(appDir, () async {
      final Completer<void> ready = Completer<void>();
      final List<String> stdout = <String>[];
      final List<String> stderr = <String>[];

      print('run: starting...');
      final List<String> options = <String>[
        '--release',
        '-d',
        device.deviceId,
      ];
      final Process run = await startFlutter(
        'run',
        options: options,
        isBot: false,
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

      _findNextMatcherInList(
        stdout,
        (String line) => line.startsWith('Launching lib/main.dart on ') && line.endsWith(' in release mode...'),
        'Launching lib/main.dart on',
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
