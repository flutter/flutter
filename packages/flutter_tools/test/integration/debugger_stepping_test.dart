// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Integration tests which invoke flutter instead of unit testing the code
// will not produce meaningful coverage information - we can measure coverage
// from the isolate running the test, but not from the isolate started via
// the command line process.
@Tags(<String>['no_coverage'])
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
      tempDir = createResolvedTempDirectorySync('debugger_stepping_test.');
      await _project.setUpIn(tempDir);
      _flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await _flutter.stop();
      tryToDelete(tempDir);
    });

    test('can step over statements', () async {
      await _flutter.run(withDebugger: true, startPaused: true);
      await _flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine);
      await _flutter.resume();
      await _flutter.waitForPause(); // Now we should be on the breakpoint.

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
          reason: 'After $i steps, debugger should stop at $expectedLine but stopped at $actualLine');
      }
    });
  }, timeout: const Timeout.factor(10), tags: <String>['integration']); // The DevFS sync takes a really long time, so these tests can be slow.
}
