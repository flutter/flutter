// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:test/test.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group_entry.dart';
import 'package:test_api/src/backend/live_test.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_core/src/runner/engine.dart';
import 'package:test_core/src/runner/plugin/environment.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/suite.dart';

/// A dummy suite platform to use for testing suites.
final suitePlatform =
    SuitePlatform(Runtime.vm, compiler: Runtime.vm.defaultCompiler);

// The last state change detected via [expectStates].
State? lastState;

/// Asserts that exactly [states] will be emitted via [liveTest.onStateChange].
///
/// The most recent emitted state is stored in [_lastState].
void expectStates(LiveTest liveTest, Iterable<State> statesIter) {
  var states = Queue.from(statesIter);
  liveTest.onStateChange.listen(expectAsync1((state) {
    lastState = state;
    expect(state, equals(states.removeFirst()));
  }, count: states.length, max: states.length));
}

/// Asserts that errors will be emitted via [liveTest.onError] that match
/// [validators], in order.
void expectErrors(LiveTest liveTest, Iterable<Function> validatorsIter) {
  var validators = Queue.from(validatorsIter);
  liveTest.onError.listen(expectAsync1((error) {
    validators.removeFirst()(error.error);
  }, count: validators.length, max: validators.length));
}

/// Asserts that [liveTest] will have a single failure with message `"oh no"`.
void expectSingleFailure(LiveTest liveTest) {
  expectStates(liveTest, [
    const State(Status.running, Result.success),
    const State(Status.complete, Result.failure)
  ]);

  expectErrors(liveTest, [
    (error) {
      expect(lastState?.status, equals(Status.complete));
      expect(error, isTestFailure('oh no'));
    }
  ]);
}

/// Asserts that [liveTest] will have a single error, the string `"oh no"`.
void expectSingleError(LiveTest liveTest) {
  expectStates(liveTest, [
    const State(Status.running, Result.success),
    const State(Status.complete, Result.error)
  ]);

  expectErrors(liveTest, [
    (error) {
      expect(lastState?.status, equals(Status.complete));
      expect(error, equals('oh no'));
    }
  ]);
}

/// Returns a matcher that matches a [TestFailure] with the given [message].
///
/// [message] can be a string or a [Matcher].
Matcher isTestFailure(message) => const TypeMatcher<TestFailure>()
    .having((e) => e.message, 'message', message);

/// Asserts that [liveTest] has completed and passed.
///
/// If the test had any errors, they're surfaced nicely into the outer test.
void expectTestPassed(LiveTest liveTest) {
  // Since the test is expected to pass, we forward any current or future errors
  // to the outer test, because they're definitely unexpected.
  for (var error in liveTest.errors) {
    registerException(error.error, error.stackTrace);
  }
  liveTest.onError.listen((error) {
    registerException(error.error, error.stackTrace);
  });

  expect(liveTest.state.status, equals(Status.complete));
  expect(liveTest.state.result, equals(Result.success));
}

/// Asserts that [liveTest] failed with a single [TestFailure] whose message
/// matches [message].
void expectTestFailed(LiveTest liveTest, message) {
  expect(liveTest.state.status, equals(Status.complete));
  expect(liveTest.state.result, equals(Result.failure));
  expect(liveTest.errors, hasLength(1));
  expect(liveTest.errors.first.error, isTestFailure(message));
}

/// Runs [body] with a declarer, runs all the declared tests, and asserts that
/// they pass.
///
/// This is typically used to run multiple tests where later tests make
/// assertions about the results of previous ones.
Future expectTestsPass(void Function() body) async {
  var engine = declareEngine(body);
  var success = await engine.run();

  for (var test in engine.liveTests) {
    expectTestPassed(test);
  }

  expect(success, isTrue);
}

/// Runs [body] with a declarer and returns the declared entries.
List<GroupEntry> declare(
  void Function() body, {
  // TODO: Change the default https://github.com/dart-lang/test/issues/1571
  bool allowDuplicateTestNames = true,
}) {
  var declarer = Declarer(allowDuplicateTestNames: allowDuplicateTestNames)
    ..declare(body);
  return declarer.build().entries;
}

/// Runs [body] with a declarer and returns an engine that runs those tests.
Engine declareEngine(void Function() body, {bool runSkipped = false}) {
  var declarer = Declarer()..declare(body);
  return Engine.withSuites([
    RunnerSuite(
        const PluginEnvironment(),
        SuiteConfiguration.runSkipped(runSkipped),
        declarer.build(),
        suitePlatform)
  ]);
}
