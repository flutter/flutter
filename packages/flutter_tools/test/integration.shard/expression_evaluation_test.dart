// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  final BasicProjectWithSecondary project = BasicProjectWithSecondary();
  Directory tempDir;
  FlutterRunTestDriver flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('run_expression_eval_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await flutter.stop();
    tryToDelete(tempDir);
  }

  Future<void> breakInBuildMethod(FlutterTestDriver flutter) async {
    await flutter.breakAt(
      project.buildMethodBreakpointUri,
      project.buildMethodBreakpointLine,
    );
  }

  Future<void> breakInTopLevelFunction(FlutterTestDriver flutter) async {
    await flutter.breakAt(
      project.topLevelFunctionBreakpointUri,
      project.topLevelFunctionBreakpointLine,
    );
  }

  testWithoutContext('flutter run expression evaluation - can evaluate method from dependent library after hot reload', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInTopLevelFunction(flutter);

    await evaluateHotReloadedExpresison(flutter, 12);
    project.updateSecondaryReturnValue(24);
    await flutter.hotReload();

    await evaluateHotReloadedExpresison(flutter, 24);
  }, skip: 'Adding one more test puts this shard over the limit');

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in top level function', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInTopLevelFunction(flutter);
    await evaluateTrivialExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in build method', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInBuildMethod(flutter);
    await evaluateTrivialExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in top level function', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInTopLevelFunction(flutter);
    await evaluateComplexExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in build method', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInBuildMethod(flutter);
    await evaluateComplexExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate expressions returning complex objects in top level function', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInTopLevelFunction(flutter);
    await evaluateComplexReturningExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate expressions returning complex objects in build method', () async {
    await initProject();
    await flutter.run(withDebugger: true);
    await breakInBuildMethod(flutter);
    await evaluateComplexReturningExpressions(flutter);
    await cleanProject();
  });
}
