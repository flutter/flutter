// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

/// This duration is arbitrary but is ideally:
/// a) Long enough to ensure that if the app is crashing at startup, we notice.
/// b) As short as possible, to avoid inflating build times.
const Duration requiredLifespan = Duration(seconds: 5);

void main() {
  final BasicProject _project = BasicProject();
  FlutterRunTestDriver _flutter;
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('lifetime_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter run does not terminate when a debugger is attached', () async {
    await _flutter.run(withDebugger: true);
    await Future<void>.delayed(requiredLifespan);
    expect(_flutter.hasExited, equals(false));
  });

  testWithoutContext('fluter run does not terminate when a debugger is attached and pause-on-exceptions', () async {
    await _flutter.run(withDebugger: true, pauseOnExceptions: true);
    await Future<void>.delayed(requiredLifespan);
    expect(_flutter.hasExited, equals(false));
  });
}
