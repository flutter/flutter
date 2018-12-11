// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/stepping_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('debugger', () {
    Directory tempDir;
    final SteppingProject _project = SteppingProject();
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

    test('can step over statements', () async {
      await _flutter.run(withDebugger: true);

      // Stop at the initial breakpoint that the expected steps are based on.
      await _flutter.breakAt(_project.breakpointUri, _project.breakpointLine, restart: true);

      // Issue 5 steps, ensuring that we end up on the annotated lines each time.
      for (int i = 1; i <= _project.numberOfSteps; i++) {
        await _flutter.stepOverOrOverAsyncSuspension();
        final SourcePosition location = await _flutter.getSourceLocation();
        final int actualLine = location.line;

        // Get the line we're expected to stop at by searching for the comment
        // within the source code.
        final int expectedLine = _project.lineForStep(i);

        expect(actualLine, equals(expectedLine),
          reason: 'After $i steps, debugger should stop at $expectedLine but stopped at $actualLine');
      }
    });
  }, timeout: const Timeout.factor(3));
}
