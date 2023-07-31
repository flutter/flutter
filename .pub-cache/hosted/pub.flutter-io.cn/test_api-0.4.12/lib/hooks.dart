// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'src/backend/closed_exception.dart';
import 'src/backend/invoker.dart';
import 'src/backend/stack_trace_formatter.dart';

export 'src/backend/test_failure.dart' show TestFailure;
export 'src/scaffolding/utils.dart' show pumpEventQueue;

class TestHandle {
  /// Returns handle for the currently running test.
  ///
  /// This must be called from within the zone that the test is running in. If
  /// the current zone is not a test's zone throws [OutsideTestException].
  static TestHandle get current {
    final invoker = Invoker.current;
    if (invoker == null) throw OutsideTestException();
    return TestHandle._(
        invoker, StackTraceFormatter.current ?? _defaultFormatter);
  }

  static final _defaultFormatter = StackTraceFormatter();

  final Invoker _invoker;
  final StackTraceFormatter _stackTraceFormatter;
  TestHandle._(this._invoker, this._stackTraceFormatter);

  String get name => _invoker.liveTest.test.name;

  /// Whether this test has already completed successfully.
  ///
  /// If a callback originating from a test case is invoked after the test has
  /// already passed it may be an indication of a test that fails to wait for
  /// all work to be finished, or of an asynchronous callback that is called
  /// more times or later than expected.
  bool get shouldBeDone => _invoker.liveTest.state.shouldBeDone;

  /// Marks this test as skipped.
  ///
  /// A skipped test may still fail if any exception is thrown, including
  /// uncaught asynchronous errors.
  void markSkipped(String message) {
    if (_invoker.closed) throw ClosedException();
    _invoker.skip(message);
  }

  /// Indicates that this test should not be considered done until the returned
  /// [OutstandingWork] is marked as complete.
  ///
  /// The test may time out before the outstanding work completes.
  OutstandingWork markPending() {
    if (_invoker.closed) throw ClosedException();
    return OutstandingWork._(_invoker, Zone.current);
  }

  /// Converts [stackTrace] to a [Chain] according to the current test's
  /// configuration.
  Chain formatStackTrace(StackTrace stackTrace) =>
      _stackTraceFormatter.formatStackTrace(stackTrace);
}

class OutstandingWork {
  final Invoker _invoker;
  final Zone _zone;
  var _isComplete = false;
  OutstandingWork._(this._invoker, this._zone) {
    _invoker.addOutstandingCallback();
  }
  void complete() {
    if (_isComplete) return;
    _isComplete = true;
    _zone.run(_invoker.removeOutstandingCallback);
  }
}

class OutsideTestException implements Exception {}
