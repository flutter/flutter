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
/// corresponding test file within the `test_driver` directory. The test file is
/// expected to have the same name but contain the `_test.dart` suffix. The
/// `_test.dart` file would generall be a Dart program that uses
/// `package:flutter_driver` and exercises your application. Most commonly it
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

    argParser.addFlag(
      'keep-app-running',
      negatable: true,
      defaultsTo: false,
      help:
        'Will keep the Flutter application running when done testing. By '
        'default Flutter Driver stops the application after tests are finished.'
    );

    argParser.addFlag(
      'use-existing-app',
      negatable: true,
      defaultsTo: false,
      help:
        'Will not start a new Flutter application but connect to an '
        'already running instance. This will also cause the driver to keep '
        'the application running after tests are done.'
    );
  }

  DriveCommand() : this.custom();

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    String testFile = _getTestFile();
    if (testFile == null) {
      return 1;
    }

    if (await fs.type(testFile) != FileSystemEntityType.FILE) {
      printError('Test file not found: $testFile');
      return 1;
    }

    if (!argResults['use-existing-app']) {
      printStatus('Starting application: ${argResults["target"]}');
      int result = await _runApp();
      if (result != 0) {
        printError('Application failed to start. Will not run test. Quitting.');
        return result;
      }
    } else {
      printStatus('Will connect to already running application instance');
    }

    try {
      return await _runTests([testFile])
        .then((_) => 0)
        .catchError((error, stackTrace) {
          printError('CAUGHT EXCEPTION: $error\n$stackTrace');
          return 1;
        });
    } finally {
      if (!argResults['keep-app-running'] && !argResults['use-existing-app']) {
        printStatus('Stopping application instance');
        await _stopApp();
      } else {
        printStatus('Leaving the application running');
      }
    }
  }

  Future<int> stop() async {
    return await stopAll(devices, applicationPackages) ? 0 : 2;
  }

  String _getTestFile() {
    String appFile = path.normalize(argResults['target']);

    // This command extends `flutter start` and therefore CWD == package dir
    String packageDir = getCurrentDirectory();

    // Make appFile path relative to package directory because we are looking
    // for the corresponding test file relative to it.
    if (!path.isRelative(appFile)) {
      if (!path.isWithin(packageDir, appFile)) {
        printError(
          'Application file $appFile is outside the package directory $packageDir'
        );
        return null;
      }

      appFile = path.relative(appFile, from: packageDir);
    }

    List<String> parts = path.split(appFile);

    if (parts.length < 2) {
      printError(
        'Application file $appFile must reside in one of the sub-directories '
        'of the package structure, not in the root directory.'
      );
      return null;
    }

    // Look for the test file inside `test_driver/` matching the sub-path, e.g.
    // if the application is `lib/foo/bar.dart`, the test file is expected to
    // be `test_driver/foo/bar_test.dart`.
    String pathWithNoExtension = path.withoutExtension(path.joinAll(
      [packageDir, 'test_driver']..addAll(parts.skip(1))));
    return '${pathWithNoExtension}_test${path.extension(appFile)}';
  }
}
