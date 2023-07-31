// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'group.dart';
import 'message.dart';
import 'state.dart';
import 'suite.dart';
import 'test.dart';

/// A runnable instance of a test.
///
/// This is distinct from [Test] in order to keep [Test] immutable. Running a
/// test requires state, and [LiveTest] provides a view of the state of the test
/// as it runs.
///
/// If the state changes, [state] will be updated before [onStateChange] fires.
/// Likewise, if an error is caught, it will be added to [errors] before being
/// emitted via [onError]. If an error causes a state change, [onStateChange]
/// will fire before [onError]. If an error or other state change causes the
/// test to complete, [onComplete] will complete after [onStateChange] and
/// [onError] fire.
abstract class LiveTest {
  /// The suite within which this test is being run.
  Suite get suite;

  /// The groups within which this test is being run, from the outermost to the
  /// innermost.
  ///
  /// This will always contain at least the implicit top-level group.
  List<Group> get groups;

  /// The running test.
  Test get test;

  /// The current state of the running test.
  ///
  /// This starts as [Status.pending] and [Result.success]. It will be updated
  /// before [onStateChange] fires.
  ///
  /// Note that even if this is marked [Status.complete], the test may still be
  /// running code asynchronously. A test is considered complete either once it
  /// hits its first error or when all [expectAsync] callbacks have been called
  /// and any returned [Future] has completed, but it's possible for further
  /// processing to happen, which may cause further errors. It's even possible
  /// for a test that was marked [Status.complete] and [Result.success] to be
  /// marked as [Result.error] later.
  State get state;

  /// Returns whether this test has completed.
  ///
  /// This is equivalent to [state.status] being [Status.complete].
  ///
  /// Note that even if this returns `true`, the test may still be
  /// running code asynchronously. A test is considered complete either once it
  /// hits its first error or when all [expectAsync] callbacks have been called
  /// and any returned [Future] has completed, but it's possible for further
  /// processing to happen, which may cause further errors.
  bool get isComplete => state.status == Status.complete;

  // A stream that emits a new [State] whenever [state] changes.
  //
  // This will only ever emit a [State] if it's different than the previous
  // [state]. It will emit an event after [state] has been updated. Note that
  // since this is an asynchronous stream, it's possible for [state] not to
  // match the [State] that it emits within the [Stream.listen] callback.
  Stream<State> get onStateChange;

  /// An unmodifiable list of all errors that have been caught while running
  /// this test.
  ///
  /// This will be updated before [onError] fires. These errors are not
  /// guaranteed to have the same types as when they were thrown; for example,
  /// they may need to be serialized across isolate boundaries. The stack traces
  /// will be [Chain]s.
  List<AsyncError> get errors;

  /// A stream that emits a new [AsyncError] whenever an error is caught.
  ///
  /// This will emit an event after [errors] is updated. These errors are not
  /// guaranteed to have the same types as when they were thrown; for example,
  /// they may need to be serialized across isolate boundaries. The stack traces
  /// will be [Chain]s.
  Stream<AsyncError> get onError;

  /// A stream that emits messages produced by the test.
  Stream<Message> get onMessage;

  /// A [Future] that completes once the test is complete.
  ///
  /// This will complete after [onStateChange] has fired, and after [onError]
  /// has fired if the test completes because of an error. It's the same as the
  /// [Future] returned by [run].
  ///
  /// Note that even once this completes, the test may still be running code
  /// asynchronously. A test is considered complete either once it hits its
  /// first error or when all [expectAsync] callbacks have been called and any
  /// returned [Future] has completed, but it's possible for further processing
  /// to happen, which may cause further errors.
  Future get onComplete;

  /// The name of this live test without any group prefixes.
  String get individualName {
    var group = groups.last;
    if (group.name.isEmpty) return test.name;
    if (!test.name.startsWith(group.name)) return test.name;

    // The test will have the same name as the group for virtual tests created
    // to represent skipping the entire group.
    if (test.name.length == group.name.length) return '';

    return test.name.substring(group.name.length + 1);
  }

  /// Loads a copy of this [LiveTest] that's able to be run again.
  LiveTest copy() => test.load(suite, groups: groups);

  /// Signals that this test should start running as soon as possible.
  ///
  /// A test may not start running immediately for various reasons specific to
  /// the means by which it's defined. Until it starts running, [state] will
  /// continue to be marked [Status.pending].
  ///
  /// This returns the same [Future] as [onComplete]. It may not be called more
  /// than once.
  Future run();

  /// Signals that this test should stop emitting events and release any
  /// resources it may have allocated.
  ///
  /// Once [close] is called, [onComplete] will complete if it hasn't already
  /// and [onStateChange] and [onError] will close immediately. This means that,
  /// if the test was running at the time [close] is called, it will never emit
  /// a [Status.complete] state-change event. Once a test is closed, [expect]
  /// and [expectAsync] will throw a [ClosedException] to help the test
  /// terminate as quickly as possible.
  ///
  /// This doesn't automatically happen after the test completes because there
  /// may be more asynchronous work going on in the background that could
  /// produce new errors.
  ///
  /// Returns a [Future] that completes once all resources are released *and*
  /// the test has completed. This allows the caller to wait until the test's
  /// tear-down logic has run.
  Future close();
}
