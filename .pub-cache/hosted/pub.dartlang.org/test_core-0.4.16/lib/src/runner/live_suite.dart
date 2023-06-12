// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'package:test_api/src/backend/live_test.dart'; // ignore: implementation_imports

import 'runner_suite.dart';

/// A view of the execution of a test suite.
///
/// This is distinct from [Suite] because it represents the progress of running
/// a suite rather than the suite's contents. It provides events and collections
/// that give the caller a view into the suite's current state.
abstract class LiveSuite {
  /// The suite that's being run.
  RunnerSuite get suite;

  /// A [Future] that completes once the suite is complete.
  ///
  /// Note that even once this completes, the suite may still be running code
  /// asynchronously. A suite is considered complete once all of its tests are
  /// complete, but it's possible for a test to continue running even after it's
  /// been marked complete—see [LiveTest.isComplete] for details.
  ///
  /// The [onClose] future can be used to determine when the suite and its tests
  /// are guaranteed to emit no more events.
  Future get onComplete;

  /// Whether the suite has been closed.
  ///
  /// If this is `true`, no code is running for the suite or any of its tests.
  /// At this point, the caller can be sure that the suites' tests are all in
  /// fixed states that will not change in the future.
  bool get isClosed;

  /// A [Future] that completes when the suite has been closed.
  ///
  /// Once this completes, no code is running for the suite or any of its tests.
  /// At this point, the caller can be sure that the suites' tests are all in
  /// fixed states that will not change in the future.
  Future get onClose;

  /// All the currently-known tests in this suite that have run or are running.
  ///
  /// This is guaranteed to contain the same tests as the union of [passed],
  /// [skipped], [failed], and [active].
  Set<LiveTest> get liveTests => UnionSet.from([
        passed,
        skipped,
        failed,
        if (active != null) {active!}
      ]);

  /// A stream that emits each [LiveTest] in this suite as it's about to start
  /// running.
  ///
  /// This is guaranteed to fire before [LiveTest.onStateChange] first fires. It
  /// will close once all tests the user has selected are run.
  Stream<LiveTest> get onTestStarted;

  /// The set of tests in this suite that have completed and been marked as
  /// passing.
  Set<LiveTest> get passed;

  /// The set of tests in this suite that have completed and been marked as
  /// skipped.
  Set<LiveTest> get skipped;

  /// The set of tests in this suite that have completed and been marked as
  /// failing or error.
  Set<LiveTest> get failed;

  /// The currently running test in this suite, or `null` if no test is running.
  LiveTest? get active;
}
