// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:matcher/matcher.dart';

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

  Future<void> start({bool expressionEvaluation}) {
    // The non-test project has a loop around its breakpoints.
    // No need to start paused as all breakpoint would be eventually reached.
    return  _flutter.run(
      withDebugger: true, chrome: true,
      expressionEvaluation: expressionEvaluation);
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

  testWithoutContext('flutter run expression evaluation - error if expression evaluation disabled', () async {
    await initProject();
    await start(expressionEvaluation: false);
    await breakInTopLevelFunction(_flutter);
    await failToEvaluateExpression(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

 testWithoutContext('flutter run expression evaluation - no native javascript objects in static scope', () async {
    await initProject();
    await start(expressionEvaluation: true);
    await breakInTopLevelFunction(_flutter);
    await checkStaticScope(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter run expression evaluation - can handle compilation errors', () async {
    await initProject();
    await start(expressionEvaluation: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateErrorExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in top level function', () async {
    await initProject();
    await start(expressionEvaluation: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter run expression evaluation - can evaluate trivial expressions in build method', () async {
    await initProject();
    await start(expressionEvaluation: true);
    await breakInBuildMethod(_flutter);
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in top level function', () async {
    await initProject();
    await start(expressionEvaluation: true);
    await breakInTopLevelFunction(_flutter);
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter run expression evaluation - can evaluate complex expressions in build method', () async {
    await initProject();
    await _flutter.run(withDebugger: true, chrome: true);
    await breakInBuildMethod(_flutter);
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779
}

void batch2() {
  final TestsProject _project = TestsProject();
  Directory tempDir;
  FlutterRunTestDriver _flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('test_expression_eval_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  }

  Future<void> breakInMethod(FlutterTestDriver flutter) async {
    await _flutter.addBreakpoint(
      _project.breakpointAppUri,
      _project.breakpointLine,
    );
    await _flutter.resume();
    await _flutter.waitForPause();
  }

  Future<void> startPaused({bool expressionEvaluation}) {
    // The test project does not have a loop around its breakpoints.
    // Start paused so we can set a breakpoint before passing it
    // in the execution.
    return  _flutter.run(
      withDebugger: true, chrome: true,
      expressionEvaluation: expressionEvaluation,
      startPaused: true, script: _project.testFilePath);
  }

  testWithoutContext('flutter test expression evaluation - error if expression evaluation disabled', () async {
    await initProject();
    await startPaused(expressionEvaluation: false);
    await breakInMethod(_flutter);
    await failToEvaluateExpression(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter test expression evaluation - can evaluate trivial expressions in a test', () async {
    await initProject();
    await startPaused(expressionEvaluation: true);
    await breakInMethod(_flutter);
    await evaluateTrivialExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779

  testWithoutContext('flutter test expression evaluation - can evaluate complex expressions in a test', () async {
    await initProject();
    await startPaused(expressionEvaluation: true);
    await breakInMethod(_flutter);
    await evaluateComplexExpressions(_flutter);
    await cleanProject();
  }, skip: 'CI not setup for web tests'); // https://github.com/flutter/flutter/issues/53779
}

Future<void> failToEvaluateExpression(FlutterTestDriver flutter) async {
  ObjRef res;
  try {
    res = await flutter.evaluateInFrame('"test"');
  } on RPCError catch (e) {
    expect(e.message, contains(
      'UnimplementedError: '
      'Expression evaluation is not supported for this configuration'));
  }
  expect(res, null);
}

Future<void> checkStaticScope(FlutterTestDriver flutter) async {
  final Frame res = await flutter.getTopStackFrame();
  expect(res.vars, equals(<BoundVariable>[]));
}

Future<void> evaluateErrorExpressions(FlutterTestDriver flutter) async {
  final ObjRef res = await flutter.evaluateInFrame('typo');
  expectError(res, 'CompilationError: Getter not found: \'typo\'.\ntypo\n^^^^');
}

Future<void> evaluateTrivialExpressions(FlutterTestDriver flutter) async {
  ObjRef res;

  res = await flutter.evaluateInFrame('"test"');
  expectInstance(res, InstanceKind.kString, 'test');

  res = await flutter.evaluateInFrame('1');
  expectInstance(res, InstanceKind.kDouble, 1.toString());

  res = await flutter.evaluateInFrame('true');
  expectInstance(res, InstanceKind.kBool, true.toString());
}

Future<void> evaluateComplexExpressions(FlutterTestDriver flutter) async {
  final ObjRef res = await flutter.evaluateInFrame('new DateTime.now().year');
  expectInstance(res, InstanceKind.kDouble, DateTime.now().year.toString());
}

void expectInstance(ObjRef result, String kind, String message) {
  expect(result,
    const TypeMatcher<InstanceRef>()
      .having((InstanceRef instance) => instance.kind, 'kind', kind)
      .having((InstanceRef instance) => instance.valueAsString, 'valueAsString', message));
}

void expectError(ObjRef result, String message) {
  expect(result,
    const TypeMatcher<ErrorRef>()
      .having((ErrorRef instance) => instance.message, 'message', message));
}

void main() {
  batch1();
  batch2();
}
