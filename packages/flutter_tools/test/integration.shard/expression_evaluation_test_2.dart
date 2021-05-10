// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/tests_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  final TestsProject _project = TestsProject();
  Directory tempDir;
  FlutterTestTestDriver flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('test_expression_eval_test.');
    await _project.setUpIn(tempDir);
    flutter = FlutterTestTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await flutter?.waitForCompletion();
    tryToDelete(tempDir);
  }

  testWithoutContext('flutter test expression evaluation - can evaluate trivial expressions in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateTrivialExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate complex expressions in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateComplexExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate expressions returning complex objects in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateComplexReturningExpressions(flutter);
    await cleanProject();
  });
}
