// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_data/integration_tests_project.dart';
import 'test_data/tests_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void batch1() {
  final BasicProject project = BasicProject();
  late Directory tempDir;
  late FlutterRunTestDriver flutter;

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

void batch2() {
  final TestsProject project = TestsProject();
  late Directory tempDir;
  late FlutterTestTestDriver flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('test_expression_eval_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterTestTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await flutter.waitForCompletion();
    tryToDelete(tempDir);
  }

  testWithoutContext('flutter test expression evaluation - can evaluate trivial expressions in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(project.breakpointUri, project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateTrivialExpressions(flutter);

    // Ensure we did not leave a dill file alongside the test.
    // https://github.com/Dart-Code/Dart-Code/issues/4243.
    final String dillFilename = '${project.testFilePath}.dill';
    expect(fileSystem.file(dillFilename).existsSync(), isFalse);

    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate complex expressions in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(project.breakpointUri, project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateComplexExpressions(flutter);
    await cleanProject();
  });

  testWithoutContext('flutter test expression evaluation - can evaluate expressions returning complex objects in a test', () async {
    await initProject();
    await flutter.test(
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(project.breakpointUri, project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateComplexReturningExpressions(flutter);
    await cleanProject();
  });
}

void batch3() {
  final IntegrationTestsProject project = IntegrationTestsProject();
  late Directory tempDir;
  late FlutterTestTestDriver flutter;

  Future<void> initProject() async {
    tempDir = createResolvedTempDirectorySync('integration_test_expression_eval_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterTestTestDriver(tempDir);
  }

  Future<void> cleanProject() async {
    await flutter.waitForCompletion();
    tryToDelete(tempDir);
  }

  testWithoutContext('flutter integration test expression evaluation - can evaluate expressions in a test', () async {
    await initProject();
    await flutter.test(
      deviceId: 'flutter-tester',
      testFile: project.testFilePath,
      withDebugger: true,
      beforeStart: () => flutter.addBreakpoint(project.breakpointUri, project.breakpointLine),
    );
    await flutter.waitForPause();
    await evaluateTrivialExpressions(flutter);

    // Ensure we did not leave a dill file alongside the test.
    // https://github.com/Dart-Code/Dart-Code/issues/4243.
    final String dillFilename = '${project.testFilePath}.dill';
    expect(fileSystem.file(dillFilename).existsSync(), isFalse);

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
  final ObjRef res = await flutter.evaluateInFrame('new DateTime(2000).year');
  expectValueOfType(res, InstanceKind.kInt, '2000');
}

Future<void> evaluateComplexReturningExpressions(FlutterTestDriver flutter) async {
  final DateTime date = DateTime(2000);
  final ObjRef resp = await flutter.evaluateInFrame('new DateTime(2000)');
  expectInstanceOfClass(resp, 'DateTime');
  final ObjRef res = await flutter.evaluate(resp.id!, r'"$year-$month-$day"');
  expectValue(res, '${date.year}-${date.month}-${date.day}');
}

void expectInstanceOfClass(ObjRef result, String name) {
  expect(result,
    const TypeMatcher<InstanceRef>()
      .having((InstanceRef instance) => instance.classRef!.name, 'resp.classRef.name', name));
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
  batch3();
}
