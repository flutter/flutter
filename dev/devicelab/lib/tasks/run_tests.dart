// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/host_agent.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction createAndroidRunDebugTest() {
  return AndroidRunOutputTest(release: false);
}

TaskFunction createAndroidRunReleaseTest() {
  return AndroidRunOutputTest(release: true);
}

TaskFunction createMacOSRunDebugTest() {
  return DesktopRunOutputTest(
    // TODO(cbracken): https://github.com/flutter/flutter/issues/87508#issuecomment-1043753201
    // Switch to dev/integration_tests/ui once we have CocoaPods working on M1 Macs.
    '${flutterDirectory.path}/examples/hello_world',
    'lib/main.dart',
    release: false,
    allowStderr: true,
  );
}

TaskFunction createMacOSRunReleaseTest() {
  return DesktopRunOutputTest(
    // TODO(cbracken): https://github.com/flutter/flutter/issues/87508#issuecomment-1043753201
    // Switch to dev/integration_tests/ui once we have CocoaPods working on M1 Macs.
    '${flutterDirectory.path}/examples/hello_world',
    'lib/main.dart',
    release: true,
    allowStderr: true,
  );
}

TaskFunction createWindowsRunDebugTest() {
  return DesktopRunOutputTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/empty.dart',
    release: false,
  );
}

TaskFunction createWindowsRunReleaseTest() {
  return DesktopRunOutputTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/empty.dart',
    release: true,
  );
}

class AndroidRunOutputTest extends RunOutputTask {
  AndroidRunOutputTest({required super.release}) : super(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/main.dart',
  );

  @override
  Future<void> prepare(String deviceId) async {
    // Uninstall if the app is already installed on the device to get to a clean state.
    final List<String> stderr = <String>[];
    print('uninstalling...');
    final Process uninstall = await startFlutter(
      'install',
      options:  <String>['--suppress-analytics', '--uninstall-only', '-d', deviceId],
      isBot: false,
    );
    uninstall.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('uninstall:stdout: $line');
      });
    uninstall.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('uninstall:stderr: $line');
        stderr.add(line);
      });
    if (await uninstall.exitCode != 0) {
      throw 'flutter install --uninstall-only failed.';
    }
    if (stderr.isNotEmpty) {
      throw 'flutter install --uninstall-only had output on standard error.';
    }
  }

  @override
  bool isExpectedStderr(String line) {
    // TODO(egarciad): Remove once https://github.com/flutter/flutter/issues/95131 is fixed.
    return line.contains('Mapping new ns');
  }

  @override
  TaskResult verify(List<String> stdout, List<String> stderr) {
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
      (String line) => line.startsWith('Installing build/app/outputs/flutter-apk/app-release.apk...'),
      'Installing build/app/outputs/flutter-apk/app-release.apk...',
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

class DesktopRunOutputTest extends RunOutputTask {
  DesktopRunOutputTest(
    super.testDirectory,
    super.testTarget, {
      required super.release,
      this.allowStderr = false,
    }
  );

  /// Whether `flutter run` is expected to produce output on stderr.
  final bool allowStderr;

  @override
  bool isExpectedStderr(String line) => allowStderr;

  @override
  TaskResult verify(List<String> stdout, List<String> stderr) {
    _findNextMatcherInList(
      stdout,
      (String line) => line.startsWith('Launching $testTarget on ') &&
        line.endsWith(' in ${release ? 'release' : 'debug'} mode...'),
      'Launching $testTarget on',
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

  static final RegExp _engineLogRegex = RegExp(
    r'\[(VERBOSE|INFO|WARNING|ERROR|FATAL):.+\(\d+\)\]',
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

      await prepare(deviceId);

      final List<String> options = <String>[
        testTarget,
        '-d',
        deviceId,
        if (release) '--release',
        '--verbose',
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
          if (!isExpectedStderr(line)) {
            stderr.add(line);
          }
        });
      unawaited(run.exitCode.then<void>((int exitCode) { runExitCode = exitCode; }));
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);

      final String? dumpDir = hostAgent.dumpDirectory?.path;
      print('RunOutputTask.call: Dumping files to "$dumpDir"...');
      if (dumpDir != null) {
        Future<void> copyFiles(Directory directory) async {
          print('RunOutputTask.call: Copying files from ${directory.path}...');

          try
          {
            final List<FileSystemEntity> entities = await directory.list().toList();
            final Iterable<File> files = entities.whereType<File>();

            for (final File file in files) {
              if (file.path.contains('hello_world')) {
                print('RunOutputTask.call: Copying "${file.path}"...');
                file.copySync('$dumpDir/${basename(file.path)}');
              } else {
                print('RunOutputTask.call: Ignoring file "${file.path}"');
              }
            }
          } catch (e) {
            print('RunOutputTask.call: Copying files resulted in exception: $e');
          }

          print('RunOutputTask.call: Copied files from ${directory.path}');
        }

        await copyFiles(Directory('/Users/swarming/Library/Logs/DiagnosticReports'));
        await copyFiles(Directory('/Users/swarming/Library/Logs/CrashReporter'));
      }
      print('RunOutputTask.call: Dumped files');

      if (runExitCode != null) {
        throw 'Failed to run test app; runner unexpected exited, with exit code $runExitCode.';
      }
      run.stdin.write('q');

      await run.exitCode;

      if (stderr.isNotEmpty) {
        throw 'flutter run ${release ? '--release' : ''} had unexpected output on standard error.';
      }

      final List<String> engineLogs = List<String>.from(
        stdout.where(_engineLogRegex.hasMatch),
      );
      if (engineLogs.isNotEmpty) {
        throw 'flutter run had unexpected Flutter engine logs $engineLogs';
      }

      return verify(stdout, stderr);
    });
  }

  /// Prepare the device for running the test app.
  Future<void> prepare(String deviceId) => Future<void>.value();

  /// Returns true if this stderr output line is expected.
  bool isExpectedStderr(String line) => false;

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
