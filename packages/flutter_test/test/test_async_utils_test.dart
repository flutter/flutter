// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test/flutter_test.dart' as flutter_test show expect;

// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as real_test show expect;

// We have to use real_test's expect because the flutter_test expect() goes
// out of its way to check that we're not leaking APIs and the whole point
// of this test is to see how we handle leaking APIs.

class TestAPI {
  Future<Object> testGuard1() {
    return TestAsyncUtils.guard<Object>(() async { return null; });
  }
  Future<Object> testGuard2() {
    return TestAsyncUtils.guard<Object>(() async { return null; });
  }
}

class TestAPISubclass extends TestAPI {
  Future<Object> testGuard3() {
    return TestAsyncUtils.guard<Object>(() async { return null; });
  }
}

Future<Object> _guardedThrower() {
  return TestAsyncUtils.guard<Object>(() async {
    throw 'Hello';
  });
}

void main() {
  test('TestAsyncUtils - one class', () async {
    final TestAPI testAPI = TestAPI();
    Future<Object> f1, f2;
    f1 = testAPI.testGuard1();
    try {
      f2 = testAPI.testGuard2();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Guarded function conflict.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'The guarded method "testGuard1" from class TestAPI was called from .*test_async_utils_test.dart on line [0-9]+\.'));
      real_test.expect(lines[3], matches(r'Then, the "testGuard2" method \(also from class TestAPI\) was called from .*test_async_utils_test.dart on line [0-9]+\.'));
      real_test.expect(lines[4], 'The first method (TestAPI.testGuard1) had not yet finished executing at the time that the second method (TestAPI.testGuard2) was called. Since both are guarded, and the second was not a nested call inside the first, the first must complete its execution before the second can be called. Typically, this is achieved by putting an "await" statement in front of the call to the first.');
      real_test.expect(lines[5], '');
      real_test.expect(lines[6], 'When the first method (TestAPI.testGuard1) was called, this was the stack:');
      real_test.expect(lines.length, greaterThan(6));
    }
    expect(await f1, isNull);
    expect(f2, isNull);
  });

  test('TestAsyncUtils - two classes, all callers in superclass', () async {
    final TestAPI testAPI = TestAPISubclass();
    Future<Object> f1, f2;
    f1 = testAPI.testGuard1();
    try {
      f2 = testAPI.testGuard2();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Guarded function conflict.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "testGuard1" from class TestAPI was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[3], matches(r'^Then, the "testGuard2" method \(also from class TestAPI\) was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[4], 'The first method (TestAPI.testGuard1) had not yet finished executing at the time that the second method (TestAPI.testGuard2) was called. Since both are guarded, and the second was not a nested call inside the first, the first must complete its execution before the second can be called. Typically, this is achieved by putting an "await" statement in front of the call to the first.');
      real_test.expect(lines[5], '');
      real_test.expect(lines[6], 'When the first method (TestAPI.testGuard1) was called, this was the stack:');
      real_test.expect(lines.length, greaterThan(7));
    }
    expect(await f1, isNull);
    expect(f2, isNull);
  });

  test('TestAsyncUtils - two classes, mixed callers', () async {
    final TestAPISubclass testAPI = TestAPISubclass();
    Future<Object> f1, f2;
    f1 = testAPI.testGuard1();
    try {
      f2 = testAPI.testGuard3();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Guarded function conflict.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "testGuard1" from class TestAPI was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[3], matches(r'^Then, the "testGuard3" method from class TestAPISubclass was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[4], 'The first method (TestAPI.testGuard1) had not yet finished executing at the time that the second method (TestAPISubclass.testGuard3) was called. Since both are guarded, and the second was not a nested call inside the first, the first must complete its execution before the second can be called. Typically, this is achieved by putting an "await" statement in front of the call to the first.');
      real_test.expect(lines[5], '');
      real_test.expect(lines[6], 'When the first method (TestAPI.testGuard1) was called, this was the stack:');
      real_test.expect(lines.length, greaterThan(7));
    }
    expect(await f1, isNull);
    expect(f2, isNull);
  });

  test('TestAsyncUtils - expect() catches pending async work', () async {
    final TestAPI testAPI = TestAPISubclass();
    Future<Object> f1;
    f1 = testAPI.testGuard1();
    try {
      flutter_test.expect(0, 0);
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Guarded function conflict.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "testGuard1" from class TestAPI was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[3], matches(r'^Then, the "expect" function was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[4], 'The first method (TestAPI.testGuard1) had not yet finished executing at the time that the second function (expect) was called. Since both are guarded, and the second was not a nested call inside the first, the first must complete its execution before the second can be called. Typically, this is achieved by putting an "await" statement in front of the call to the first.');
      real_test.expect(lines[5], 'If you are confident that all test APIs are being called using "await", and this expect() call is not being called at the top level but is itself being called from some sort of callback registered before the testGuard1 method was called, then consider using expectSync() instead.');
      real_test.expect(lines[6], '');
      real_test.expect(lines[7], 'When the first method (TestAPI.testGuard1) was called, this was the stack:');
      real_test.expect(lines.length, greaterThan(7));
    }
    expect(await f1, isNull);
  });

  testWidgets('TestAsyncUtils - expect() catches pending async work', (WidgetTester tester) async {
    Future<Object> f1, f2;
    try {
      f1 = tester.pump();
      f2 = tester.pump();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Guarded function conflict.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "pump" from class WidgetTester was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[3], matches(r'^Then, it was called from .*test_async_utils_test.dart on line [0-9]+\.$'));
      real_test.expect(lines[4], 'The first method had not yet finished executing at the time that the second method was called. Since both are guarded, and the second was not a nested call inside the first, the first must complete its execution before the second can be called. Typically, this is achieved by putting an "await" statement in front of the call to the first.');
      real_test.expect(lines[5], '');
      real_test.expect(lines[6], 'When the first method was called, this was the stack:');
      real_test.expect(lines.length, greaterThan(7));
      // TODO(jacobr): add more tests like this if they are useful.

      final DiagnosticPropertiesBuilder propertiesBuilder = DiagnosticPropertiesBuilder();
      e.debugFillProperties(propertiesBuilder);
      final List<DiagnosticsNode> information = propertiesBuilder.properties;
      real_test.expect(information.length, 6);
      real_test.expect(information[0].level, DiagnosticLevel.summary);
      real_test.expect(information[1].level, DiagnosticLevel.hint);
      real_test.expect(information[2].level, DiagnosticLevel.info);
      real_test.expect(information[3].level, DiagnosticLevel.info);
      real_test.expect(information[4].level, DiagnosticLevel.info);
      real_test.expect(information[5].level, DiagnosticLevel.info);
      real_test.expect(information[0], isA<DiagnosticsProperty<void>>());
      real_test.expect(information[1], isA<DiagnosticsProperty<void>>());
      real_test.expect(information[2], isA<DiagnosticsProperty<void>>());
      real_test.expect(information[3], isA<DiagnosticsProperty<void>>());
      real_test.expect(information[4], isA<DiagnosticsProperty<void>>());
      real_test.expect(information[5], isA<DiagnosticsStackTrace>());
      final DiagnosticsStackTrace stackTraceProperty = information[5] as DiagnosticsStackTrace;
      real_test.expect(stackTraceProperty.name, '\nWhen the first method was called, this was the stack');
      real_test.expect(stackTraceProperty.value, isA<StackTrace>());
    }
    await f1;
    await f2;
  });

  testWidgets('TestAsyncUtils - expect() catches pending async work', (WidgetTester tester) async {
    Future<Object> f1;
    try {
      f1 = tester.pump();
      TestAsyncUtils.verifyAllScopesClosed();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Asynchronous call to guarded function leaked.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "pump" from class WidgetTester was called from .*test_async_utils_test.dart on line [0-9]+, but never completed before its parent scope closed\.$'));
      real_test.expect(lines[3], matches(r'^The guarded method "pump" from class AutomatedTestWidgetsFlutterBinding was called from [^ ]+ on line [0-9]+, but never completed before its parent scope closed\.'));
      real_test.expect(lines.length, 4);
      final DiagnosticPropertiesBuilder propertiesBuilder = DiagnosticPropertiesBuilder();
      e.debugFillProperties(propertiesBuilder);
      final List<DiagnosticsNode> information = propertiesBuilder.properties;
      real_test.expect(information.length, 4);
      real_test.expect(information[0].level, DiagnosticLevel.summary);
      real_test.expect(information[1].level, DiagnosticLevel.hint);
      real_test.expect(information[2].level, DiagnosticLevel.info);
      real_test.expect(information[3].level, DiagnosticLevel.info);
    }
    await f1;
  });

  testWidgets('TestAsyncUtils - expect() catches pending async work', (WidgetTester tester) async {
    Future<Object> f1;
    try {
      f1 = tester.pump();
      TestAsyncUtils.verifyAllScopesClosed();
      throw 'unexpectedly did not throw';
    } on FlutterError catch (e) {
      final List<String> lines = e.message.split('\n');
      real_test.expect(lines[0], 'Asynchronous call to guarded function leaked.');
      real_test.expect(lines[1], 'You must use "await" with all Future-returning test APIs.');
      real_test.expect(lines[2], matches(r'^The guarded method "pump" from class WidgetTester was called from .*test_async_utils_test.dart on line [0-9]+, but never completed before its parent scope closed\.$'));
      real_test.expect(lines[3], matches(r'^The guarded method "pump" from class AutomatedTestWidgetsFlutterBinding was called from [^ ]+ on line [0-9]+, but never completed before its parent scope closed\.'));
      real_test.expect(lines.length, 4);
      final DiagnosticPropertiesBuilder propertiesBuilder = DiagnosticPropertiesBuilder();
      e.debugFillProperties(propertiesBuilder);
      final List<DiagnosticsNode> information = propertiesBuilder.properties;
      real_test.expect(information.length, 4);
      real_test.expect(information[0].level, DiagnosticLevel.summary);
      real_test.expect(information[1].level, DiagnosticLevel.hint);
      real_test.expect(information[2].level, DiagnosticLevel.info);
      real_test.expect(information[3].level, DiagnosticLevel.info);
    }
    await f1;
  });

  testWidgets('TestAsyncUtils - guard body can throw', (WidgetTester tester) async {
    try {
      await _guardedThrower();
      expect(false, true); // _guardedThrower should throw and we shouldn't reach here
    } on String catch (s) {
      expect(s, 'Hello');
    }
  });

  // see also dev/manual_tests/test_data which contains tests run by the flutter_tools tests for 'flutter test'
}
