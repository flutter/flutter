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

// Verifies that hot restart hides the keyboard if it is visible:
//
// 1. Launches an app that forces the keyboard to be visible
// 2. Updates the app to no longer force the keyboard to be visible
// 3. Hot reloads
// 4. Checks that the keyboard is no longer visible
TaskFunction createKeyboardHotRestartTest({
  String? deviceIdOverride,
  bool checkAppRunningOnLocalDevice = false,
  List<String>? additionalOptions,
}) {
  final Directory appDir = dir(
    path.join(flutterDirectory.path, 'dev/integration_tests/keyboard_hot_restart'),
  );
  final File mainFile = file(path.join(appDir.path, 'lib/main.dart'));

  // This file is modified during the test and needs to be restored at the end.
  final String oldContents = mainFile.readAsStringSync();
  const String forceKeyboardOn = 'const bool forceKeyboard = true;';
  const String forceKeyboardOff = 'const bool forceKeyboard = false;';

  return () async {
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }

    await inDirectory<void>(appDir, () async {
      try {
        section('Create app');
        await createAppProject();

        // Ensure the app forces the keyboard to be visible.
        final String newContents = oldContents.replaceFirst(forceKeyboardOff, forceKeyboardOn);
        mainFile.writeAsStringSync(newContents);

        section('Launch app and wait for keyboard to be visible');

        TestState state = TestState.waitUntilKeyboardOpen;

        await runApp(
          options: <String>['-d', deviceIdOverride!],
          onLine: (String line, Process process) {
            if (state == TestState.waitUntilKeyboardOpen) {
              if (!lineIndicatesKeyboardIsOpen(line)) {
                return;
              }

              section('Update the app to no longer force the keyboard to be visible');
              final String newContents = oldContents.replaceFirst(
                forceKeyboardOn,
                forceKeyboardOff,
              );
              mainFile.writeAsStringSync(newContents);

              section('Hot reload app');
              process.stdin.writeln('R');

              section('Wait until the keyboard is no longer visible');
              state = TestState.waitUntilKeyboardClosed;
            } else if (state == TestState.waitUntilKeyboardClosed) {
              if (!lineIndicatesKeyboardIsClosed(line)) {
                return;
              }

              process.stdin.writeln('q');
            }
          },
        );
      } finally {
        mainFile.writeAsStringSync(oldContents);
      }
    });

    return TaskResult.success(null);
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

Future<void> runApp({
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
  await process.exitCode;
}

bool lineIndicatesKeyboardIsOpen(String line) {
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

bool lineIndicatesKeyboardIsClosed(String line) {
  return line.contains('flutter: viewInsets: EdgeInsets.zero');
}
