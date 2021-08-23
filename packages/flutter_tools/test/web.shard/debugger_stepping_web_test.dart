// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../integration.shard/test_data/stepping_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  Directory tempDirectory;
  FlutterRunTestDriver flutter;

  setUp(() {
    tempDirectory = createResolvedTempDirectorySync('debugger_stepping_test.');
  });

  testWithoutContext('Web debugger can step over statements', () async {
    final WebSteppingProject _project = WebSteppingProject();
    await _project.setUpIn(tempDirectory);

    flutter = FlutterRunTestDriver(tempDirectory);

    await flutter.run(
      withDebugger: true, startPaused: true, chrome: true,
      additionalCommandArgs: <String>['--verbose', '--web-renderer=html']);
    await flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine);
    await flutter.resume(waitForNextPause: true); // Now we should be on the breakpoint.
    expect((await flutter.getSourceLocation()).line, equals(_project.breakpointLine));

    // Issue 5 steps, ensuring that we end up on the annotated lines each time.
    for (int i = 1; i <= _project.numberOfSteps; i += 1) {
      await flutter.stepOverOrOverAsyncSuspension();
      final SourcePosition location = await flutter.getSourceLocation();
      final int actualLine = location.line;

      // Get the line we're expected to stop at by searching for the comment
      // within the source code.
      final int expectedLine = _project.lineForStep(i);

      expect(actualLine, equals(expectedLine),
        reason: 'After $i steps, debugger should stop at $expectedLine but stopped at $actualLine'
      );
    }
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDirectory);
  });
}
