// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/project_with_immediate_exit.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('immediate exit', () {
    Directory tempDir;
    final ProjectWithImmediateExit _project = ProjectWithImmediateExit();
    FlutterRunTestDriver _flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('run_test.');
      await _project.setUpIn(tempDir);
      _flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      tryToDelete(tempDir);
    });

    testWithoutContext('flutter_tools gracefully handles quick app shutdown', () async {
      try {
        await _flutter.run();
      } on Exception {
        expect(_flutter.lastErrorInfo, contains('Error connecting to the service protocol:'));
        expect(
            _flutter.lastErrorInfo.contains(
              // Looks for stack trace entry of the form:
              //   test/integration.shard/test_driver.dart 379:18  FlutterTestDriver._waitFor.<fn>
                RegExp(r'^(.+)\/([^\/]+)\.dart \d*:\d*\s*.*\$')
            ),
            isFalse
        );
      }
    });
  }, skip: true, // Flaky: https://github.com/flutter/flutter/issues/74052
  );
}
