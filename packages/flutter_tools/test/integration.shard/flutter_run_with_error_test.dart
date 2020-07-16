// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/project_with_early_error.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final ProjectWithEarlyError _project = ProjectWithEarlyError();
  const String _exceptionStart = '══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞══════════════════';
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test('flutter run reports an early error in an application', () async {
    final StringBuffer stdout = StringBuffer();

    await _flutter.run(startPaused: true, withDebugger: true, structuredErrors: true);
    await _flutter.resume();

    final Completer<void> completer = Completer<void>();
    bool lineFound = false;

    await Future<void>(() async {
      _flutter.stdout.listen((String line) {
        stdout.writeln(line);
        if (line.startsWith('Another exception was thrown') && !lineFound) {
          lineFound = true;
          completer.complete();
        }
      });
      await completer.future;
    }).timeout(const Duration(seconds: 15), onTimeout: () {
      // Complete anyway in case we don't see the 'Another exception' line.
      completer.complete();
    });
    await _flutter.stop();

    expect(stdout.toString(), contains(_exceptionStart));
  });

  test('flutter run for web reports an early error in an application', () async {
    final StringBuffer stdout = StringBuffer();

    await _flutter.run(startPaused: true, withDebugger: true, structuredErrors: true, chrome: true);
    await _flutter.resume();
    final Completer<void> completer = Completer<void>();
    bool lineFound = false;

    await Future<void>(() async {
      _flutter.stdout.listen((String line) {
        stdout.writeln(line);
        if (line.startsWith('Another exception was thrown') && !lineFound) {
          lineFound = true;
          completer.complete();
        }
      });
      await completer.future;
    }).timeout(const Duration(seconds: 15), onTimeout: () {
      // Complete anyway in case we don't see the 'Another exception' line.
      completer.complete();
    });

    expect(stdout.toString(), contains(_exceptionStart));
    await _flutter.stop();
  }, skip: 'Running in cirrus environment causes premature exit');
}
