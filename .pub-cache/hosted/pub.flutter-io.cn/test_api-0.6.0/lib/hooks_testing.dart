// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'src/backend/group.dart';
import 'src/backend/invoker.dart';
import 'src/backend/live_test.dart';
import 'src/backend/metadata.dart';
import 'src/backend/runtime.dart';
import 'src/backend/state.dart';
import 'src/backend/suite.dart';
import 'src/backend/suite_platform.dart';

export 'src/backend/state.dart' show Result, Status;
export 'src/backend/test_failure.dart' show TestFailure;

/// A monitor for the behavior of a callback when it is run as the body of a
/// test case.
///
/// Allows running a callback as the body of a local test case and querying for
/// the current [state], and [errors], and subscribing to future errors.
///
/// Use [run] to run a test body and query for the success or failure.
///
/// Use [start] to start a test and query for whether it has finished running.
class TestCaseMonitor {
  final LiveTest _liveTest;
  final _done = Completer<void>();
  TestCaseMonitor._(FutureOr<void> Function() body)
      : _liveTest = _createTest(body);

  /// Run [body] as a test case and return a [TestCaseMonitor] with the result.
  ///
  /// The [state] will either [State.passed], [State.skipped], or
  /// [State.failed], the test will no longer be running.
  ///
  /// {@template result-late-fail}
  /// Note that a test can change state from [State.passed] to [State.failed]
  /// if the test surfaces an unawaited asynchronous error.
  /// {@endtemplate}
  ///
  /// ```dart
  /// final monitor = await TestCaseMonitor.run(() {
  ///   fail('oh no!');
  /// });
  /// assert(monitor.state == State.failed);
  /// assert((monitor.errors.single.error as TestFailure).message == 'oh no!');
  /// ```
  static Future<TestCaseMonitor> run(FutureOr<void> Function() body) async {
    final monitor = TestCaseMonitor.start(body);
    await monitor.onDone;
    return monitor;
  }

  /// Start [body] as a test case and return a [TestCaseMonitor] with the status
  /// and result.
  ///
  /// The [state] will start as [State.pending] if queried synchronously, but it
  /// will switch to [State.running]. After `onDone` completes the state will be
  /// one of [State.passed], [State.skipped], or [State.failed].
  ///
  /// {@macro result-late-fail}
  ///
  /// ```dart
  /// late void Function() completeWork;
  /// final monitor = TestCaseMonitor.start(() {
  ///   final outstandingWork = TestHandle.current.markPending();
  ///   completeWork = outstandingWork.complete;
  /// });
  /// await pumpEventQueue();
  /// assert(monitor.state == State.running);
  /// completeWork();
  /// await monitor.onDone;
  /// assert(monitor.state == State.passed);
  /// ```
  static TestCaseMonitor start(FutureOr<void> Function() body) =>
      TestCaseMonitor._(body).._start();

  void _start() {
    _liveTest.run().whenComplete(_done.complete);
  }

  /// A future that completes after this test has finished running, or has
  /// surfaced an error.
  Future<void> get onDone => _done.future;

  /// The running and success or failure status for the test case.
  State get state {
    final status = _liveTest.state.status;
    if (status == Status.pending) return State.pending;
    if (status == Status.running) return State.running;
    final result = _liveTest.state.result;
    if (result == Result.skipped) return State.skipped;
    if (result == Result.success) return State.passed;
    // result == Result.failure || result == Result.error
    return State.failed;
  }

  /// The errors surfaced by the test.
  ///
  /// A test with any errors will have a [state] of [State.failed].
  ///
  /// {@macro result-late-fail}
  ///
  /// A test may have more than one error if there were unhandled asynchronous
  /// errors surfaced after the test is done.
  Iterable<AsyncError> get errors => _liveTest.errors;

  /// A stream of errors surfaced by the test.
  ///
  /// This stream will not close, asynchronous errors may be surfaced within the
  /// test's error zone at any point.
  Stream<AsyncError> get onError => _liveTest.onError;
}

/// Returns a local [LiveTest] that runs [body].
LiveTest _createTest(FutureOr<void> Function() body) {
  var test = LocalTest('test', Metadata(chainStackTraces: true), body);
  var suite = Suite(Group.root([test]), _suitePlatform, ignoreTimeouts: false);
  return test.load(suite);
}

/// A dummy suite platform to use for testing suites.
final _suitePlatform =
    SuitePlatform(Runtime.vm, compiler: Runtime.vm.defaultCompiler);

/// The running and success state of a test monitored by a [TestCaseMonitor].
enum State {
  /// The test is has not yet started.
  pending,

  /// The test is running and has not yet failed.
  running,

  /// The test has completed without any error.
  ///
  /// This implies that the test body has completed, and no error has surfaced
  /// *yet*. However, it this doesn't mean that the test won't fail in the
  /// future.
  passed,

  /// The test, or some part of it, has been skipped.
  ///
  /// This does not imply that the test has not had an error, but if there are
  /// errors they are ignored.
  skipped,

  /// The test has failed.
  ///
  /// An test fails when any exception, typically a [TestFailure], is thrown in
  /// the test's zone. A test that has failed may still have additional errors
  /// that surface as unhandled asynchronous errors.
  failed,
}
