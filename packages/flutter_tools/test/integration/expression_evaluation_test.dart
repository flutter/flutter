// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'package:vm_service_lib/vm_service_lib.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('flutter run expression evaluation', () {
    Directory tempDir;
    final BasicProject _project = BasicProject();
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

    Future<Isolate> breakInBuildMethod(FlutterTestDriver flutter) async {
      return _flutter.breakAt(
          _project.buildMethodBreakpointUri,
          _project.buildMethodBreakpointLine);
    }

    Future<Isolate> breakInTopLevelFunction(FlutterTestDriver flutter) async {
      return _flutter.breakAt(
          _project.topLevelFunctionBreakpointUri,
          _project.topLevelFunctionBreakpointLine);
    }

    test('can evaluate trivial expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions(_flutter);
    });

    test('can evaluate trivial expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateTrivialExpressions(_flutter);
    });

    test('can evaluate complex expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexExpressions(_flutter);
    });

    test('can evaluate complex expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexExpressions(_flutter);
    });

    test('can evaluate expressions returning complex objects in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexReturningExpressions(_flutter);
    });

    test('can evaluate expressions returning complex objects in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexReturningExpressions(_flutter);
    });
  }, timeout: const Timeout.factor(6));
}

Future<void> evaluateTrivialExpressions(FlutterTestDriver flutter) async {
  InstanceRef res;

  res = await flutter.evaluateInFrame('"test"');
  expect(res.kind == InstanceKind.kString && res.valueAsString == 'test', isTrue);

  res = await flutter.evaluateInFrame('1');
  expect(res.kind == InstanceKind.kInt && res.valueAsString == 1.toString(), isTrue);

  res = await flutter.evaluateInFrame('true');
  expect(res.kind == InstanceKind.kBool && res.valueAsString == true.toString(), isTrue);
}

Future<void> evaluateComplexExpressions(FlutterTestDriver flutter) async {
  final InstanceRef res = await flutter.evaluateInFrame('new DateTime.now().year');
    expect(res.kind == InstanceKind.kInt && res.valueAsString == DateTime.now().year.toString(), isTrue);
}

Future<void> evaluateComplexReturningExpressions(FlutterTestDriver flutter) async {
  final DateTime now = DateTime.now();
    final InstanceRef resp = await flutter.evaluateInFrame('new DateTime.now()');
    expect(resp.classRef.name, equals('DateTime'));
    // Ensure we got a reasonable approximation. The more accurate we try to
    // make this, the more likely it'll fail due to differences in the time
    // in the remote VM and the local VM at the time the code runs.
    final InstanceRef res = await flutter.evaluate(resp.id, r'"$year-$month-$day"');
    expect(res.valueAsString,
        equals('${now.year}-${now.month}-${now.day}'));
}
