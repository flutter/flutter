// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable;

import '../base/file_system.dart';
import '../globals.dart';
import 'run.dart';
import 'stop.dart';

typedef Future<int> RunAppFunction();
typedef Future<Null> RunTestsFunction(List<String> testArgs);
typedef Future<int> StopAppFunction();

/// Runs integration (a.k.a. end-to-end) tests.
///
/// An integration test is a program that runs in a separate process from your
/// Flutter application. It connects to the application and acts like a user,
/// performing taps, scrolls, reading out widget properties and verifying their
/// correctness.
///
/// This command takes a target Flutter application that you would like to test
/// as the `--target` option (defaults to `lib/main.dart`). It then looks for a
/// file with the same name but containing the `_test.dart` suffix. The
/// `_test.dart` file is expected to be a program that uses
/// `package:flutter_driver` that exercises your application. Most commonly it
/// is a test written using `package:test`, but you are free to use something
/// else.
///
/// The app and the test are launched simultaneously. Once the test completes
/// the application is stopped and the command exits. If all these steps are
/// successful the exit code will be `0`. Otherwise, you will see a non-zero
/// exit code.
class DriveCommand extends RunCommand {
  final String name = 'drive';
  final String description = 'Runs Flutter Driver tests for the current project.';
  final List<String> aliases = <String>['driver'];

  RunAppFunction _runApp;
  RunTestsFunction _runTests;
  StopAppFunction _stopApp;

  /// Creates a drive command with custom process management functions.
  ///
  /// [runAppFn] starts a Flutter application.
  ///
  /// [runTestsFn] runs tests.
  ///
  /// [stopAppFn] stops the test app after tests are finished.
  DriveCommand.custom({
      RunAppFunction runAppFn,
      RunTestsFunction runTestsFn,
      StopAppFunction stopAppFn
  }) {
    _runApp = runAppFn ?? super.runInProject;
    _runTests = runTestsFn ?? executable.main;
    _stopApp = stopAppFn ?? this.stop;
  }

  DriveCommand() : this.custom();

  @override
  Future<int> runInProject() async {
    String testFile = _getTestFile();

    if (await fs.type(testFile) != FileSystemEntityType.FILE) {
      printError('Test file not found: $testFile');
      return 1;
    }

    int result = await _runApp();
    if (result != 0) {
      printError('Application failed to start. Will not run test. Quitting.');
      return result;
    }

    try {
      return await _runTests([testFile])
        .then((_) => 0)
        .catchError((error, stackTrace) {
          printError('ERROR: $error\n$stackTrace');
          return 1;
        });
    } finally {
      await _stopApp();
    }
  }

  Future<int> stop() async {
    return await stopAll(devices, applicationPackages) ? 0 : 2;
  }

  String _getTestFile() {
    String appFile = argResults['target'];
    String extension = path.extension(appFile);
    String name = path.withoutExtension(appFile);
    return '${name}_test$extension';
  }
}
