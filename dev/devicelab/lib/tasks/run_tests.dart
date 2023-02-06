// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction createMacOSRunReleaseTest() {
  return DesktopRunOutputTest(
    // TODO(cbracken): https://github.com/flutter/flutter/issues/87508#issuecomment-1043753201
    // Switch to dev/integration_tests/ui once we have CocoaPods working on M1 Macs.
    '${flutterDirectory.path}/examples/hello_world',
    'lib/main.dart',
    release: true,
  );
}

class DesktopRunOutputTest extends RunOutputTask {
  DesktopRunOutputTest(
    super.testDirectory,
    super.testTarget, {
      required super.release,
    }
  );

  @override
  TaskResult verify(List<String> stdout, List<String> stderr) {
    _findNextMatcherInList(
      stdout,
      (String line) => line.startsWith('Launching lib/main.dart on ') &&
        line.endsWith(' in ${release ? 'release' : 'debug'} mode...'),
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

    return TaskResult.success(null);
  }
}

/// Test that the output of `flutter run` is expected.
abstract class RunOutputTask {
  RunOutputTask(
    this.testDirectory,
    this.testTarget, {
      required this.release,
    }
  );

  /// The directory where the app under test is defined.
  final String testDirectory;
  /// The main entry-point file of the application, as run on the device.
  final String testTarget;
  /// Whether to run the app in release mode.
  final bool release;

  Future<TaskResult> call() {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;

      final Completer<void> ready = Completer<void>();
      final List<String> stdout = <String>[];
      final List<String> stderr = <String>[];

      final List<String> options = <String>[
        testTarget,
        '-d',
        deviceId,
        if (release) '--release',
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
          stdout.add(line);
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

      return verify(stdout, stderr);
    });
  }

  /// Verify the output of `flutter run`.
  TaskResult verify(List<String> stdout, List<String> stderr) => throw UnimplementedError('verify is not implemented');

  /// Helper that verifies a line in [list] matches [matcher].
  /// The [list] is updated to contain the lines remaining after the match.
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

in flutter run ${release ? '--release' : ''} stdout

$copyOfListForErrorMessage
''';
  }
}
