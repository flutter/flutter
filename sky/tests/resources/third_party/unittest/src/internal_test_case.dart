// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.internal_test_case;

import 'dart:async';

import '../unittest.dart';
import 'test_environment.dart';
import 'utils.dart';

/// An implementation of [TestCase] that exposes internal properties for other
/// unittest use.
class InternalTestCase implements TestCase {
  final int id;
  final String description;

  /// The setup function to call before the test, if any.
  Function _setUp;

  /// The teardown function to call after the test, if any.
  Function _tearDown;

  /// The body of the test case.
  TestFunction _testFunction;

  /// Remaining number of callback functions that must reach a 'done' state
  /// before the test completes.
  int callbackFunctionsOutstanding = 0;

  /// The error or failure message for the tests.
  ///
  /// Initially an empty string.
  String message = '';

  /// The result of the test case.
  ///
  /// If the test case has is completed, this will be one of [PASS], [FAIL], or
  /// [ERROR]. Otherwise, it will be `null`.
  String result;

  /// Returns whether this test case passed.
  bool get passed => result == PASS;

  /// The stack trace for the error that caused this test case to fail, or
  /// `null` if it succeeded.
  StackTrace stackTrace;

  /// The name of the group within which this test is running.
  final String currentGroup;

  /// The time the test case started running.
  ///
  /// `null` if the test hasn't yet begun running.
  DateTime get startTime => _startTime;
  DateTime _startTime;

  /// The amount of time the test case took.
  ///
  /// `null` if the test hasn't finished running.
  Duration get runningTime => _runningTime;
  Duration _runningTime;

  /// Whether this test is enabled.
  ///
  /// Disabled tests won't be run.
  bool enabled = true;

  /// A completer that will complete when the test is finished.
  ///
  /// This is only non-`null` when outstanding callbacks exist.
  Completer _testComplete;

  /// Whether this test case has finished running.
  bool get isComplete => !enabled || result != null;

  InternalTestCase(this.id, this.description, this._testFunction)
      : currentGroup = environment.currentContext.fullName,
        _setUp = environment.currentContext.testSetUp,
        _tearDown = environment.currentContext.testTearDown;

  /// A function that returns another function to handle errors from [Future]s.
  ///
  /// [stage] is a string description of the stage of testing that failed.
  Function _errorHandler(String stage) => (e, stack) {
    if (stack == null && e is Error) {
      stack = e.stackTrace;
    }
    if (result == null || result == PASS) {
      if (e is TestFailure) {
        fail("$e", stack);
      } else {
        error("$stage failed: Caught $e", stack);
      }
    }
  };

  /// Performs any associated [_setUp] function and runs the test.
  ///
  /// Returns a [Future] that can be used to schedule the next test. If the test
  /// runs to completion synchronously, or is disabled, null is returned, to
  /// tell unittest to schedule the next test immediately.
  Future run() {
    if (!enabled) return new Future.value();

    result = stackTrace = null;
    message = '';

    // Avoid calling [new Future] to avoid issue 11911.
    return new Future.value().then((_) {
      if (_setUp != null) return _setUp();
    }).catchError(_errorHandler('Setup')).then((_) {
      // Skip the test if setup failed.
      if (result != null) return new Future.value();
      config.onTestStart(this);
      _startTime = new DateTime.now();
      _runningTime = null;
      callbackFunctionsOutstanding++;
      var testReturn = _testFunction();
      // If _testFunction() returned a future, we want to wait for it like we
      // would a callback, so if a failure occurs while waiting, we can abort.
      if (testReturn is Future) {
        callbackFunctionsOutstanding++;
        testReturn
            .catchError(_errorHandler('Test'))
            .whenComplete(markCallbackComplete);
      }
    }).catchError(_errorHandler('Test')).then((_) {
      markCallbackComplete();
      if (result == null) {
        // Outstanding callbacks exist; we need to return a Future.
        _testComplete = new Completer();
        return _testComplete.future.whenComplete(() {
          if (_tearDown != null) {
            return _tearDown();
          }
        }).catchError(_errorHandler('Teardown'));
      } else if (_tearDown != null) {
        return _tearDown();
      }
    }).catchError(_errorHandler('Teardown')).whenComplete(() {
      _setUp = null;
      _tearDown = null;
      _testFunction = null;
    });
  }

  /// Marks the test as having completed with [testResult], which should be one
  /// of [PASS], [FAIL], or [ERROR].
  void _complete(String testResult,
      [String messageText = '', StackTrace stack]) {
    if (runningTime == null) {
      // The startTime can be `null` if an error happened during setup. In this
      // case we simply report a running time of 0.
      if (startTime != null) {
        _runningTime = new DateTime.now().difference(startTime);
      } else {
        _runningTime = const Duration(seconds: 0);
      }
    }
    _setResult(testResult, messageText, stack);
    if (_testComplete != null) {
      var t = _testComplete;
      _testComplete = null;
      t.complete(this);
    }
  }

  // Sets [this]'s fields to reflect the test result, and notifies the current
  // configuration that the test has completed.
  //
  // Returns true if this is the first time the result has been set.
  void _setResult(String testResult, String messageText, StackTrace stack) {
    message = messageText;
    stackTrace = getTrace(stack, formatStacks, filterStacks);
    if (stackTrace == null) stackTrace = stack;
    if (result == null) {
      result = testResult;
      config.onTestResult(this);
    } else {
      result = testResult;
      config.onTestResultChanged(this);
    }
  }

  /// Marks the test as having passed.
  void pass() {
    _complete(PASS);
  }

  void registerException(error, [StackTrace stackTrace]) {
    var message = error is TestFailure ? error.message : 'Caught $error';
    if (result == null) {
      fail(message, stackTrace);
    } else {
      error(message, stackTrace);
    }
  }

  /// Marks the test as having failed.
  void fail(String messageText, [StackTrace stack]) {
    if (result != null) {
      var newMessage = result == PASS
          ? 'Test failed after initially passing: $messageText'
          : 'Test failed more than once: $messageText';
      // TODO(gram): Should we combine the stack with the old one?
      _complete(ERROR, newMessage, stack);
    } else {
      _complete(FAIL, messageText, stack);
    }
  }

  /// Marks the test as having had an unexpected error.
  void error(String messageText, [StackTrace stack]) {
    _complete(ERROR, messageText, stack);
  }

  /// Indicates that an asynchronous callback has completed, and marks the test
  /// as passing if all outstanding callbacks are complete.
  void markCallbackComplete() {
    callbackFunctionsOutstanding--;
    if (callbackFunctionsOutstanding == 0 && !isComplete) pass();
  }

  String toString() => result != null ? "$description: $result" : description;
}
