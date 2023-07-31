// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:matcher/expect.dart';
import 'package:test_api/hooks_testing.dart';

/// Asserts that [monitor] has completed and passed.
///
/// If the test had any errors, they're surfaced nicely into the outer test.
void expectTestPassed(TestCaseMonitor monitor) {
  // Since the test is expected to pass, we forward any current or future errors
  // to the running test, because they're definitely unexpected and it is most
  // useful for the error to point directly to the throw point.
  for (var error in monitor.errors) {
    Zone.current.handleUncaughtError(error.error, error.stackTrace);
  }
  monitor.onError.listen((error) {
    Zone.current.handleUncaughtError(error.error, error.stackTrace);
  });

  expect(monitor.state, State.passed);
}

/// Asserts that [monitor] failed with a single [TestFailure] whose message
/// matches [message].
void expectTestFailed(TestCaseMonitor monitor, Object? message) {
  expect(monitor.state, State.failed);
  expect(monitor.errors, [isAsyncError(isTestFailure(message))]);
}

/// Returns a matcher that matches a [AsyncError] with an `error` field matching
/// [errorMatcher].
Matcher isAsyncError(Matcher errorMatcher) =>
    isA<AsyncError>().having((e) => e.error, 'error', errorMatcher);

/// Returns a matcher that matches a [TestFailure] with the given [message].
///
/// [message] can be a string or a [Matcher].
Matcher isTestFailure(Object? message) => const TypeMatcher<TestFailure>()
    .having((e) => e.message, 'message', message);

/// Returns a matcher that matches a callback or Future that throws a
/// [TestFailure] with the given [message].
///
/// [message] can be a string or a [Matcher].
Matcher throwsTestFailure(Object? message) => throwsA(isTestFailure(message));
