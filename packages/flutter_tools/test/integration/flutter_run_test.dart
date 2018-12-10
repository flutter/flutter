// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('flutter_run', () {
    Directory tempDir;
    final BasicProject _project = BasicProject();
    FlutterRunTestDriver _flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync();
      await _project.setUpIn(tempDir);
      _flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await _flutter.stop();
      tryToDelete(tempDir);
    });

    test('reports an error if an invalid device is supplied', () async {
      // This test forces flutter to check for all possible devices to catch issues
      // like https://github.com/flutter/flutter/issues/21418 which were skipped
      // over because other integration tesst run using flutter-tester which short-cuts
      // some of the checks for devices.
      final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter');

      const ProcessManager _processManager = LocalProcessManager();
      final ProcessResult _proc = await _processManager.run(
        <String>[flutterBin, 'run', '-d', 'invalid-device-id'],
        workingDirectory: tempDir.path
      );

      expect(_proc.stdout, isNot(contains('flutter has exited unexpectedly')));
      expect(_proc.stderr, isNot(contains('flutter has exited unexpectedly')));
      if (!_proc.stderr.toString().contains('Unable to locate a development')
        && !_proc.stdout.toString().contains('No devices found with name or id matching')) {
          fail("'flutter run -d invalid-device-id' did not produce the expected error");
        }
    });

    test('writes pid-file', () async {
      final File pidFile = tempDir.childFile('test.pid');
      await _flutter.run(pidFile: pidFile);
      expect(pidFile.existsSync(), isTrue);
    });
  }, timeout: const Timeout.factor(6));
}
