// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';

import 'package:vm_service_client/vm_service_client.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';

void main() {
  group('expression evaluation', () {
    Directory tempDir;
    final BasicProject _project = new BasicProject();
    FlutterTestDriver _flutter;

    setUp(() async {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_expression_test.');
      await _project.setUpIn(tempDir);
      _flutter = new FlutterTestDriver(tempDir);
    });

    tearDown(() async {
      await _flutter.stop();
      tryToDelete(tempDir);
    });

    Future<VMIsolate> breakInBuildMethod(FlutterTestDriver flutter) async {
      return _flutter.breakAt(
          _project.buildMethodBreakpointFile,
          _project.buildMethodBreakpointLine);
    }

    Future<VMIsolate> breakInTopLevelFunction(FlutterTestDriver flutter) async {
      return _flutter.breakAt(
          _project.topLevelFunctionBreakpointFile,
          _project.topLevelFunctionBreakpointLine);
    }

    Future<void> evaluateTrivialExpressions() async {
      VMInstanceRef res;

      res = await _flutter.evaluateExpression('"test"');
      expect(res is VMStringInstanceRef && res.value == 'test', isTrue);

      res = await _flutter.evaluateExpression('1');
      expect(res is VMIntInstanceRef && res.value == 1, isTrue);

      res = await _flutter.evaluateExpression('true');
      expect(res is VMBoolInstanceRef && res.value == true, isTrue);
    }

    Future<void> evaluateComplexExpressions() async {
      final VMInstanceRef res = await _flutter.evaluateExpression('new DateTime.now().year');
      expect(res is VMIntInstanceRef && res.value == new DateTime.now().year, isTrue);
    }

    Future<void> evaluateComplexReturningExpressions() async {
      final DateTime now = new DateTime.now();
      final VMInstanceRef resp = await _flutter.evaluateExpression('new DateTime.now()');
      expect(resp.klass.name, equals('DateTime'));
      // Ensure we got a reasonable approximation. The more accurate we try to
      // make this, the more likely it'll fail due to differences in the time
      // in the remote VM and the local VM at the time the code runs.
      final VMStringInstanceRef res = await resp.evaluate(r'"$year-$month-$day"');
      expect(res.value,
          equals('${now.year}-${now.month}-${now.day}'));
    }

    test('can evaluate trivial expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions();
    });

    test('can evaluate trivial expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateTrivialExpressions();
    });

    test('can evaluate complex expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexExpressions();
    });

    test('can evaluate complex expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexExpressions();
    });

    test('can evaluate expressions returning complex objects in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexReturningExpressions();
    });

    test('can evaluate expressions returning complex objects in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexReturningExpressions();
    });
    // TODO(dantup): Unskip after flutter-tester is fixed on Windows:
    // https://github.com/flutter/flutter/issues/17833.
  }, timeout: const Timeout.factor(6), skip: platform.isWindows);
}
