// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

// This test verifies that hot restart hides the keyboard if it is visible.
//
// Steps:
//
// 1. Launch an app that focuses a text field at startup.
//    This makes the keyboard visible.
// 2. Wait until the keyboard is visible.
// 3. Update the app's source code to no longer focus a text field at startup.
// 4. Hot restart the app
// 5. Wait until the keyboard is no longer visible.
//
// See: //dev/integration_tests/keyboard_hot_restart/lib/main.dart
TaskFunction createKeyboardHotRestartTest({
  String? deviceIdOverride,
  bool checkAppRunningOnLocalDevice = false,
  List<String>? additionalOptions,
}) {
  final Directory appDir = dir(
    path.join(flutterDirectory.path, 'dev/integration_tests/keyboard_hot_restart'),
  );

  // This file is modified during the test and needs to be restored at the end.
  final File mainFile = file(path.join(appDir.path, 'lib/main.dart'));
  final String oldContents = mainFile.readAsStringSync();

  // When the test starts, the app forces the keyboard to be visible.
  // The test turns off this behavior by mutating the app's source code from
  // `forceKeyboardOn` to `forceKeyboardOff`.
  // See: //dev/integration_tests/keyboard_hot_restart/lib/main.dart
  const String forceKeyboardOn = 'const bool forceKeyboard = true;';
  const String forceKeyboardOff = 'const bool forceKeyboard = false;';

  return () async {
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }

    return inDirectory<TaskResult>(appDir, () async {
      try {
        section('Create app');
        await createAppProject();

        // Ensure the app forces the keyboard to be visible.
        final String newContents = oldContents.replaceFirst(forceKeyboardOff, forceKeyboardOn);
        mainFile.writeAsStringSync(newContents);

        section('Launch app and wait for keyboard to be visible');

        TestState state = TestState.waitUntilKeyboardOpen;

        final int exitCode = await runApp(
          options: <String>['-d', deviceIdOverride!],
          onLine: (String line, Process process) {
            if (state == TestState.waitUntilKeyboardOpen) {
              if (!stdoutLineIndicatesKeyboardIsOpen(line)) {
                return;
              }

              section('Update the app to no longer force the keyboard to be visible');
              final String newContents = oldContents.replaceFirst(
                forceKeyboardOn,
                forceKeyboardOff,
              );
              mainFile.writeAsStringSync(newContents);

              section('Hot restart the app');
              process.stdin.writeln('R');

              section('Wait until the keyboard is no longer visible');
              state = TestState.waitUntilKeyboardClosed;
            } else if (state == TestState.waitUntilKeyboardClosed) {
              if (!stdoutLineIndicatesKeyboardIsOpen(line)) {
                return;
              }

              // Quit the app. This makes the 'flutter run' process exit.
              process.stdin.writeln('q');
            }
          },
        );

        if (exitCode != 0) {
          return TaskResult.failure('flutter run exited with non-zero exit code: $exitCode');
        }
      } finally {
        mainFile.writeAsStringSync(oldContents);
      }

      return TaskResult.success(null);
    });
  };
}

enum TestState { waitUntilKeyboardOpen, waitUntilKeyboardClosed }

Future<void> createAppProject() async {
  await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
    'create',
    '--platforms=android,ios',
    '.',
  ]);
}

Future<int> runApp({
  required List<String> options,
  required void Function(String, Process) onLine,
}) async {
  final Process process = await startFlutter('run', options: options);

  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();

  void onStdout(String line) {
    onLine(line, process);
    print('stdout: $line');
  }

  process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(onStdout, onDone: stdoutDone.complete);

  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) => print('stderr: $line'), onDone: stderrDone.complete);

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  return process.exitCode;
}

// Check if the keyboard_hot_restart app's stdout indicates the keyboard is open.
// See: //dev/integration_tests/keyboard_hot_restart/lib/main.dart
bool stdoutLineIndicatesKeyboardIsOpen(String line) {
  final RegExp regExp = RegExp(
    r'flutter: viewInsets: EdgeInsets\(\d+\.\d+, \d+\.\d+, \d+\.\d+, (\d+\.\d+)\)',
  );
  final Match? match = regExp.firstMatch(line);
  if (match == null) {
    return false;
  }

  final double keyboardHeight = double.parse(match.group(1)!);

  return keyboardHeight > 0;
}

// Check if the keyboard_hot_restart app's stdout indicates the keyboard is closed.
// See: //dev/integration_tests/keyboard_hot_restart/lib/main.dart
bool stdoutLineIndicatesKeyboardIsClosed(String line) {
  return line.contains('flutter: viewInsets: EdgeInsets.zero');
}
