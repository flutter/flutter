// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_data/tests_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void batch1() {
  final BasicProject _project = BasicProject();
  Directory tempDir;
  FlutterRunTestDriver _flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('run_expression_eval_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  }

  Future<void> breakInBuildMethod(FlutterTestDriver flutter) async {
    await _flutter.breakAt(
      _project.buildMethodBreakpointUri,
      _project.buildMethodBreakpointLine,
    );
  }

  Future<void> breakInTopLevelFunction(FlutterTestDriver flutter) async {
    await _flutter.breakAt(
      _project.topLevelFunctionBreakpointUri,
      _project.topLevelFunctionBreakpointLine,
    );
  }

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in top level function', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in build method', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInBuildMethod(_flutter);
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in top level function', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in build method', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInBuildMethod(_flutter);
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate expressions returning complex objects in top level function', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateComplexReturningExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter run expression evaluation - can evaluate expressions returning complex objects in build method', () async {
    await initProject();
    await _flutter.run(withDebugger: true);
    await breakInBuildMethod(_flutter);
    await evaluateComplexReturningExpressions(_flutter);
    await cleanProject();
  });
}

void batch2() {
  final TestsProject _project = TestsProject();
  Directory tempDir;
  FlutterTestTestDriver _flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('test_expression_eval_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterTestTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await _flutter?.waitForCompletion();
    tryToDelete(tempDir);
  }

  testWithoutContext('flutter test expression evaluation - can evaluate trivial expressions in a test', () async {
    await initProject();
    await _flutter.test(
      withDebugger: true,
      beforeStart: () => _flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await _flutter.waitForPause();
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate complex expressions in a test', () async {
    await initProject();
    await _flutter.test(
      withDebugger: true,
      beforeStart: () => _flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await _flutter.waitForPause();
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate expressions returning complex objects in a test', () async {
    await initProject();
    await _flutter.test(
      withDebugger: true,
      beforeStart: () => _flutter.addBreakpoint(_project.breakpointUri, _project.breakpointLine),
    );
    await _flutter.waitForPause();
    await evaluateComplexReturningExpressions(_flutter);
    await cleanProject();
  });
}

Future<void> evaluateTrivialExpressions(FlutterTestDriver flutter) async {
  ObjRef res;

  res = await flutter.evaluateInFrame('"test"');
  expectValueOfType(res, InstanceKind.kString, 'test');

  res = await flutter.evaluateInFrame('1');
  expectValueOfType(res, InstanceKind.kInt, 1.toString());

  res = await flutter.evaluateInFrame('true');
  expectValueOfType(res, InstanceKind.kBool, true.toString());
}

Future<void> evaluateComplexExpressions(FlutterTestDriver flutter) async {
  final ObjRef res = await flutter.evaluateInFrame('new DateTime.now().year');
  expectValueOfType(res, InstanceKind.kInt, DateTime.now().year.toString());
}

Future<void> evaluateComplexReturningExpressions(FlutterTestDriver flutter) async {
  final DateTime now = DateTime.now();
  final ObjRef resp = await flutter.evaluateInFrame('new DateTime.now()');
  expectInstanceOfClass(resp, 'DateTime');
  // Ensure we got a reasonable approximation. The more accurate we try to
  // make this, the more likely it'll fail due to differences in the time
  // in the remote VM and the local VM at the time the code runs.
  final InstanceRef res = await flutter.evaluate(resp.id, r'"$year-$month-$day"');
  expectValue(res, '${now.year}-${now.month}-${now.day}');
}

void expectInstanceOfClass(ObjRef result, String name) {
  expect(result,
    const TypeMatcher<InstanceRef>()
      .having((InstanceRef instance) => instance.classRef.name, 'resp.classRef.name', name));
}

void expectValueOfType(ObjRef result, String kind, String message) {
  expect(result,
    const TypeMatcher<InstanceRef>()
      .having((InstanceRef instance) => instance.kind, 'kind', kind)
      .having((InstanceRef instance) => instance.valueAsString, 'valueAsString', message));
}

void expectValue(ObjRef result, String message) {
  expect(result,
    const TypeMatcher<InstanceRef>()
      .having((InstanceRef instance) => instance.valueAsString, 'valueAsString', message));
}

void main() {
  batch1();
  batch2();
}
