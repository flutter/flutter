// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/stepping_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('debugger_stepping_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('can step over statements', () async {
    final SteppingProject _project = SteppingProject();
    await _project.setUpIn(tempDir);

    final FlutterRunTestDriver _flutter = FlutterRunTestDriver(tempDir);

    await _flutter.run(withDebugger: true, startPaused: true);
    await _flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine);
    await _flutter.resume(waitForNextPause: true); // Now we should be on the breakpoint.

    expect((await _flutter.getSourceLocation()).line, equals(_project.breakpointLine));

    // Issue 5 steps, ensuring that we end up on the annotated lines each time.
    for (int i = 1; i <= _project.numberOfSteps; i += 1) {
      await _flutter.stepOverOrOverAsyncSuspension();
      final SourcePosition location = await _flutter.getSourceLocation();
      final int actualLine = location.line;

      // Get the line we're expected to stop at by searching for the comment
      // within the source code.
      final int expectedLine = _project.lineForStep(i);

      expect(actualLine, equals(expectedLine),
        reason: 'After $i steps, debugger should stop at $expectedLine but stopped at $actualLine'
      );
    }

    await _flutter.stop();
  });
}
