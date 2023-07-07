// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:test/test.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/test.dart';
import 'package:test_core/src/runner/load_exception.dart';
import 'package:test_core/src/runner/load_suite.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/suite.dart';

import '../utils.dart';

void main() {
  late RunnerSuite innerSuite;
  setUp(() {
    innerSuite = runnerSuite(Group.root([]));
  });

  test('running a load test causes LoadSuite.suite to emit a suite', () async {
    var suite = LoadSuite('name', SuiteConfiguration.empty, suitePlatform,
        () => Future.value(innerSuite));
    expect(suite.group.entries, hasLength(1));

    expect(suite.suite, completion(equals(innerSuite)));
    var liveTest = (suite.group.entries.single as Test).load(suite);
    await liveTest.run();
    expectTestPassed(liveTest);
  });

  test("running a load suite's body may be synchronous", () async {
    var suite = LoadSuite(
        'name', SuiteConfiguration.empty, suitePlatform, () => innerSuite);
    expect(suite.group.entries, hasLength(1));

    expect(suite.suite, completion(equals(innerSuite)));
    var liveTest = (suite.group.entries.single as Test).load(suite);
    await liveTest.run();
    expectTestPassed(liveTest);
  });

  test("a load test doesn't complete until the body returns", () async {
    var completer = Completer<RunnerSuite>();
    var suite = LoadSuite('name', SuiteConfiguration.empty, suitePlatform,
        () => completer.future);
    expect(suite.group.entries, hasLength(1));

    var liveTest = (suite.group.entries.single as Test).load(suite);
    expect(liveTest.run(), completes);
    await Future.delayed(Duration.zero);
    expect(liveTest.state.status, equals(Status.running));

    completer.complete(innerSuite);
    await Future.delayed(Duration.zero);
    expectTestPassed(liveTest);
  });

  test('a load test forwards errors and completes LoadSuite.suite to null',
      () async {
    var suite = LoadSuite('name', SuiteConfiguration.empty, suitePlatform, () {
      return fail('error');
    });
    expect(suite.group.entries, hasLength(1));

    expect(suite.suite, completion(isNull));

    var liveTest = (suite.group.entries.single as Test).load(suite);
    await liveTest.run();
    expectTestFailed(liveTest, 'error');
  });

  test("a load test completes early if it's closed", () async {
    var suite = LoadSuite('name', SuiteConfiguration.empty, suitePlatform,
        () => Completer<RunnerSuite>().future);
    expect(suite.group.entries, hasLength(1));

    var liveTest = (suite.group.entries.single as Test).load(suite);
    expect(liveTest.run(), completes);
    await Future.delayed(Duration.zero);
    expect(liveTest.state.status, equals(Status.running));

    expect(liveTest.close(), completes);
  });

  test('forLoadException() creates a suite that completes to a LoadException',
      () async {
    var exception = LoadException('path', 'error');
    var suite = LoadSuite.forLoadException(exception, SuiteConfiguration.empty);
    expect(suite.group.entries, hasLength(1));

    expect(suite.suite, completion(isNull));

    var liveTest = (suite.group.entries.single as Test).load(suite);
    await liveTest.run();
    expect(liveTest.state.status, equals(Status.complete));
    expect(liveTest.state.result, equals(Result.error));
    expect(liveTest.errors, hasLength(1));
    expect(liveTest.errors.first.error, equals(exception));
  });

  test('forSuite() creates a load suite that completes to a test suite',
      () async {
    var suite = LoadSuite.forSuite(innerSuite);
    expect(suite.group.entries, hasLength(1));

    expect(suite.suite, completion(equals(innerSuite)));
    var liveTest = (suite.group.entries.single as Test).load(suite);
    await liveTest.run();
    expectTestPassed(liveTest);
  });

  group('changeSuite()', () {
    test('returns a new load suite with the same properties', () {
      var suite = LoadSuite(
          'name', SuiteConfiguration.empty, suitePlatform, () => innerSuite);
      expect(suite.group.entries, hasLength(1));

      var newSuite = suite.changeSuite((suite) => suite);
      expect(newSuite.platform.runtime, equals(Runtime.vm));
      expect(newSuite.group.entries.single.name,
          equals(suite.group.entries.single.name));
    });

    test('changes the inner suite', () async {
      var suite = LoadSuite(
          'name', SuiteConfiguration.empty, suitePlatform, () => innerSuite);
      expect(suite.group.entries, hasLength(1));

      var newInnerSuite = runnerSuite(Group.root([]));
      var newSuite = suite.changeSuite((suite) => newInnerSuite);
      expect(newSuite.suite, completion(equals(newInnerSuite)));

      var liveTest = (suite.group.entries.single as Test).load(suite);
      await liveTest.run();
      expectTestPassed(liveTest);
    });

    test("doesn't run change() if the suite is null", () async {
      var suite = LoadSuite(
          'name', SuiteConfiguration.empty, suitePlatform, () => null);
      expect(suite.group.entries, hasLength(1));

      var newSuite = suite.changeSuite(expectAsync1((_) {
        return null;
      }, count: 0));
      expect(newSuite.suite, completion(isNull));

      var liveTest = (suite.group.entries.single as Test).load(suite);
      await liveTest.run();
      expectTestPassed(liveTest);
    });
  });

  group('getSuite()', () {
    test('runs the test and returns the suite', () {
      var suite = LoadSuite.forSuite(innerSuite);
      expect(suite.group.entries, hasLength(1));

      expect(suite.getSuite(), completion(equals(innerSuite)));
    });

    test('forwards errors to the future', () {
      var suite = LoadSuite(
          'name', SuiteConfiguration.empty, suitePlatform, () => throw 'error');
      expect(suite.group.entries, hasLength(1));

      expect(suite.getSuite(), throwsA('error'));
    });
  });
}
