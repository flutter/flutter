// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest;

import 'dart:async';
import 'dart:collection';

import '../matcher/matcher.dart' show TestFailure, wrapAsync;

import 'src/configuration.dart';
import 'src/expected_function.dart';
import 'src/group_context.dart';
import 'src/internal_test_case.dart';
import 'src/test_case.dart';
import 'src/test_environment.dart';

export '../matcher/matcher.dart';

export 'src/configuration.dart';
export 'src/simple_configuration.dart';
export 'src/test_case.dart';

/// The signature for a function passed to [test].
typedef dynamic TestFunction();

/// [Configuration] used by the unittest library.
///
/// Note that if a configuration has not been set, calling this getter will
/// create a default configuration.
Configuration get unittestConfiguration {
  if (config == null) environment.config = new Configuration();
  return config;
}

/// If `true`, stack traces are reformatted to be more readable.
bool formatStacks = true;

/// If `true`, irrelevant frames are filtered from the stack trace.
///
/// This does nothing if [formatStacks] is false.
bool filterStacks = true;

/// Separator used between group names and test names.
String groupSep = ' ';

/// Sets the [Configuration] used by the unittest library.
///
/// Throws a [StateError] if there is an existing, incompatible value.
void set unittestConfiguration(Configuration value) {
  if (identical(config, value)) return;
  if (config != null) {
    logMessage('Warning: The unittestConfiguration has already been set. New '
        'unittestConfiguration ignored.');
  } else {
    environment.config = value;
  }
}

/// Logs [message] associated with the current test case.
///
/// Tests should use this instead of [print].
void logMessage(String message) =>
    config.onLogMessage(currentTestCase, message);

/// The test cases that have been defined so far.
List<TestCase> get testCases =>
    new UnmodifiableListView<TestCase>(environment.testCases);

/// The interval (in milliseconds) after which a non-microtask asynchronous
/// delay will be scheduled between tests.
///
/// This is used to avoid starving the DOM or other non-microtask events.
const int BREATH_INTERVAL = 200;

/// The [TestCase] currently being executed.
TestCase get currentTestCase => (environment.currentTestCaseIndex >= 0 &&
        environment.currentTestCaseIndex < testCases.length)
    ? testCases[environment.currentTestCaseIndex]
    : null;

/// The same as [currentTestCase], but typed as an [InternalTestCase].
InternalTestCase get _currentTestCase => currentTestCase as InternalTestCase;

/// The result string for a passing test case.
const PASS = 'pass';

/// The result string for a failing test case.
const FAIL = 'fail';

/// The result string for an test case with an error.
const ERROR = 'error';

/// Creates a new test case with the given description and body.
///
/// The description will be added to the descriptions of any surrounding
/// [group]s.
void test(String description, TestFunction body) {
  _requireNotRunning();
  ensureInitialized();

  if (environment.soloTestSeen && environment.soloNestingLevel == 0) return;
  var testCase = new InternalTestCase(
      testCases.length + 1, _fullDescription(description), body);
  environment.testCases.add(testCase);
}

/// Returns [description] with all of its group prefixes prepended.
String _fullDescription(String description) {
  var group = environment.currentContext.fullName;
  if (description == null) return group;
  return group != '' ? '$group$groupSep$description' : description;
}

/// A convenience function for skipping a test.
void skip_test(String spec, TestFunction body) {}

/// Creates a new test case with the given description and body.
///
/// If [solo_test] is used instead of [test], then all non-solo tests will be
/// disabled. Note that if [solo_group] is used as well, all tests in the group
/// will be enabled, regardless of whether they use [test] or [solo_test], or
/// whether they are in a nested [group] versus [solo_group]. Put another way,
/// if there are any calls to [solo_test] or [solo_group] in a test file, all
/// tests that are not inside a [solo_group] will be disabled unless they are
/// [solo_test]s.
void solo_test(String spec, TestFunction body) {
  _requireNotRunning();
  ensureInitialized();
  if (!environment.soloTestSeen) {
    environment.soloTestSeen = true;
    // This is the first solo-ed test. Discard all tests up to now.
    environment.testCases.clear();
  }
  environment.soloNestingLevel++;
  try {
    test(spec, body);
  } finally {
    environment.soloNestingLevel--;
  }
}

/// Indicate that [callback] is expected to be called [count] number of times
/// (by default 1).
///
/// The unittest framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete. Using [expectAsync]
/// will also ensure that errors that occur within [callback] are tracked and
/// reported. [callback] may take up to six optional or required positional
/// arguments; named arguments are not supported.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
Function expectAsync(Function callback,
    {int count: 1, int max: 0, String id, String reason}) =>
        new ExpectedFunction(callback, count, max, id: id, reason: reason).func;

/// Indicate that [callback] is expected to be called until [isDone] returns
/// true.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete. Using [expectAsyncUntil] will
/// also ensure that errors that occur within [callback] are tracked and
/// reported. [callback] may take up to six optional or required positional
/// arguments; named arguments are not supported.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
Function expectAsyncUntil(Function callback, bool isDone(),
    {String id, String reason}) => new ExpectedFunction(callback, 0, -1,
        id: id, reason: reason, isDone: isDone).func;

/// Creates a group of tests.
///
/// A group's description is included in the descriptions of any tests or
/// sub-groups it contains. [setUp] and [tearDown] are also scoped to the
/// containing group.
void group(String description, void body()) {
  ensureInitialized();
  _requireNotRunning();
  environment.currentContext =
      new GroupContext(environment.currentContext, description);
  try {
    body();
  } catch (e, trace) {
    var stack = (trace == null) ? '' : ': ${trace.toString()}';
    environment.uncaughtErrorMessage = "${e.toString()}$stack";
  } finally {
    // Now that the group is over, restore the previous one.
    environment.currentContext = environment.currentContext.parent;
  }
}

/// A convenience function for skipping a group of tests.
void skip_group(String description, void body()) {}

/// Creates a group of tests.
///
/// If [solo_group] is used instead of [group], then all tests not declared with
/// [solo_test] or in a [solo_group] will be disabled. Note that all tests in a
/// [solo_group] will be run, regardless of whether they're declared with [test]
/// or [solo_test].
///
/// [skip_test] and [skip_group] take precedence over [solo_group].
void solo_group(String description, void body()) {
  _requireNotRunning();
  ensureInitialized();
  if (!environment.soloTestSeen) {
    environment.soloTestSeen = true;
    // This is the first solo-ed group. Discard all tests up to now.
    environment.testCases.clear();
  }
  ++environment.soloNestingLevel;
  try {
    group(description, body);
  } finally {
    --environment.soloNestingLevel;
  }
}

/// Registers a function to be run before tests.
///
/// This function will be called before each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run after any set-up callbacks in parent groups or
/// at the top level.
void setUp(Function callback) {
  _requireNotRunning();
  environment.currentContext.testSetUp = callback;
}

/// Registers a function to be run after tests.
///
/// This function will be called after each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run before any tear-down callbacks in parent groups or
/// at the top level.
void tearDown(Function callback) {
  _requireNotRunning();
  environment.currentContext.testTearDown = callback;
}

/// Advance to the next test case.
void _nextTestCase() {
  environment.currentTestCaseIndex++;
  _runTest();
}

/// Handle an error that occurs outside of any test.
void handleExternalError(e, String message, [stackTrace]) {
  var msg = '$message\nCaught $e';

  if (currentTestCase != null) {
    _currentTestCase.error(msg, stackTrace);
  } else {
    environment.uncaughtErrorMessage = "$msg: $stackTrace";
  }
}

/// Remove any tests that match [testFilter].
///
/// [testFilter] can be a predicate function, a [RegExp], or a [String]. If it's
/// a function, it's called with each [TestCase]. If it's a [String], it's
/// parsed as a [RegExp] and matched against each [TestCase.description].
///
/// This is different from enabling or disabling tests in that it removes the
/// tests completely.
void filterTests(testFilter) {
  var filterFunction;
  if (testFilter is String) {
    var re = new RegExp(testFilter);
    filterFunction = (t) => re.hasMatch(t.description);
  } else if (testFilter is RegExp) {
    filterFunction = (t) => testFilter.hasMatch(t.description);
  } else if (testFilter is Function) {
    filterFunction = testFilter;
  }
  environment.testCases.retainWhere(filterFunction);
}

/// Runs all queued tests, one at a time.
void runTests() {
  _requireNotRunning();
  _ensureInitialized(false);
  environment.currentTestCaseIndex = 0;
  config.onStart();
  _runTest();
}

/// Registers an exception that was caught for the current test.
void registerException(error, [StackTrace stackTrace]) =>
    _currentTestCase.registerException(error, stackTrace);

/// Runs the next test.
void _runTest() {
  if (environment.currentTestCaseIndex >= testCases.length) {
    assert(environment.currentTestCaseIndex == testCases.length);
    _completeTests();
    return;
  }

  var testCase = _currentTestCase;
  var f = runZoned(testCase.run, onError: (error, stack) {
    // TODO(kevmoo) Do a better job of flagging these are async errors.
    // https://code.google.com/p/dart/issues/detail?id=16530
    testCase.registerException(error, stack);
  });

  var timer;
  var timeout = unittestConfiguration.timeout;
  if (timeout != null) {
    try {
      timer = new Timer(timeout, () {
        testCase.error("Test timed out after ${timeout.inSeconds} seconds.");
        _nextTestCase();
      });
    } on UnsupportedError catch (e) {
      if (e.message != "Timer greater than 0.") rethrow;
      // Support running on d8 and jsshell which don't support timers.
    }
  }

  f.whenComplete(() {
    if (timer != null) timer.cancel();
    var now = new DateTime.now().millisecondsSinceEpoch;
    if (now - environment.lastBreath >= BREATH_INTERVAL) {
      environment.lastBreath = now;
      Timer.run(_nextTestCase);
    } else {
      scheduleMicrotask(_nextTestCase); // Schedule the next test.
    }
  });
}

/// Notify the configuration that the testing has finished.
void _completeTests() {
  if (!environment.initialized) return;

  var passed = 0;
  var failed = 0;
  var errors = 0;
  for (var testCase in testCases) {
    switch (testCase.result) {
      case PASS:
        passed++;
        break;
      case FAIL:
        failed++;
        break;
      case ERROR:
        errors++;
        break;
    }
  }

  config.onSummary(
      passed, failed, errors, testCases, environment.uncaughtErrorMessage);
  config.onDone(passed > 0 &&
      failed == 0 &&
      errors == 0 &&
      environment.uncaughtErrorMessage == null);
  environment.initialized = false;
  environment.currentTestCaseIndex = -1;
}

/// Initializes the test environment if it hasn't already been initialized.
void ensureInitialized() {
  _ensureInitialized(true);
}

/// Initializes the test environment.
///
/// If [configAutoStart] is `true`, schedule a microtask to run the tests. This
/// microtask is expected to run after all the tests are defined.
void _ensureInitialized(bool configAutoStart) {
  if (environment.initialized) return;

  environment.initialized = true;
  // Hook our async guard into the matcher library.
  wrapAsync = (f, [id]) => expectAsync(f, id: id);

  environment.uncaughtErrorMessage = null;

  unittestConfiguration.onInit();

  // Immediately queue the suite up. It will run after a timeout (i.e. after
  // main() has returned).
  if (configAutoStart && config.autoStart) scheduleMicrotask(runTests);
}

/// Remove all tests other than the one identified by [id].
void setSoloTest(int id) =>
    environment.testCases.retainWhere((t) => t.id == id);

/// Enable the test identified by [id].
void enableTest(int id) => _setTestEnabledState(id, enable: true);

/// Disable the test by [id].
void disableTest(int id) => _setTestEnabledState(id, enable: false);

/// Enable or disable the test identified by [id].
void _setTestEnabledState(int id, {bool enable: true}) {
  // Try fast path first.
  if (testCases.length > id && testCases[id].id == id) {
    environment.testCases[id].enabled = enable;
  } else {
    for (var i = 0; i < testCases.length; i++) {
      if (testCases[i].id != id) continue;
      environment.testCases[i].enabled = enable;
      break;
    }
  }
}

/// Throws a [StateError] if tests are running.
void _requireNotRunning() {
  if (environment.currentTestCaseIndex == -1) return;
  throw new StateError('Not allowed when tests are running.');
}

/// Creates a test environment running in its own zone scope.
///
/// This allows for multiple invocations of the unittest library in the same
/// application instance. This is useful when, for example, creating a test
/// runner application which needs to create a new pristine test environment on
/// each invocation to run a given set of tests.
withTestEnvironment(callback()) {
  return runZoned(callback,
      zoneValues: {#unittest.environment: new TestEnvironment()});
}
