// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/stepping_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

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

    await flutter.run(withDebugger: true, startPaused: true, chrome: true);
    await flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine);
    await flutter.resume();
    await flutter.waitForPause(); // Now we should be on the breakpoint.

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
  }, skip: true); // https://github.com/flutter/flutter/issues/62889

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDirectory);
  });
}
