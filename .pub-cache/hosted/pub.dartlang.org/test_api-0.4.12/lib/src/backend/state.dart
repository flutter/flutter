// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The state of a [LiveTest].
///
/// A test's state is made up of two components, its [status] and its [result].
/// The [status] represents where the test is in its process of running; the
/// [result] represents the outcome as far as its known.
class State {
  /// Where the test is in its process of running.
  final Status status;

  /// The outcome of the test, as far as it's known.
  ///
  /// Note that if [status] is [Status.pending], [result] will always be
  /// [Result.success] since the test hasn't yet had a chance to fail.
  final Result result;

  /// Whether a test in this state is expected to be done running code.
  ///
  /// If [status] is [Status.complete] and [result] doesn't indicate an error, a
  /// properly-written test case should not be running any more code. However,
  /// it may have started asynchronous processes without notifying the test
  /// runner.
  bool get shouldBeDone => status == Status.complete && result.isPassing;

  const State(this.status, this.result);

  @override
  bool operator ==(other) =>
      other is State && status == other.status && result == other.result;

  @override
  int get hashCode => status.hashCode ^ (7 * result.hashCode);

  @override
  String toString() {
    if (status == Status.pending) return 'pending';
    if (status == Status.complete) return result.toString();
    if (result == Result.success) return 'running';
    return 'running with $result';
  }
}

/// Where the test is in its process of running.
class Status {
  /// The test has not yet begun running.
  static const pending = Status._('pending');

  /// The test is currently running.
  static const running = Status._('running');

  /// The test has finished running.
  ///
  /// Note that even if the test is marked [complete], it may still be running
  /// code asynchronously. A test is considered complete either once it hits its
  /// first error or when all [expectAsync] callbacks have been called and any
  /// returned [Future] has completed, but it's possible for further processing
  /// to happen, which may cause further errors.
  static const complete = Status._('complete');

  /// The name of the status.
  final String name;

  factory Status.parse(String name) {
    switch (name) {
      case 'pending':
        return Status.pending;
      case 'running':
        return Status.running;
      case 'complete':
        return Status.complete;
      default:
        throw ArgumentError('Invalid status name "$name".');
    }
  }

  const Status._(this.name);

  @override
  String toString() => name;
}

/// The outcome of the test, as far as it's known.
class Result {
  /// The test has not yet failed in any way.
  ///
  /// Note that this doesn't mean that the test won't fail in the future.
  static const success = Result._('success');

  /// The test, or some part of it, has been skipped.
  ///
  /// This implies that the test hasn't failed *yet*. However, it this doesn't
  /// mean that the test won't fail in the future.
  static const skipped = Result._('skipped');

  /// The test has failed.
  ///
  /// A failure is specifically caused by a [TestFailure] being thrown; any
  /// other exception causes an error.
  static const failure = Result._('failure');

  /// The test has crashed.
  ///
  /// Any exception other than a [TestFailure] is considered to be an error.
  static const error = Result._('error');

  /// The name of the result.
  final String name;

  /// Whether this is a passing result.
  ///
  /// A test is considered to have passed if it's a success or if it was
  /// skipped.
  bool get isPassing => this == success || this == skipped;

  /// Whether this is a failing result.
  ///
  /// A test is considered to have failed if it experiences a failure or an
  /// error.
  bool get isFailing => !isPassing;

  factory Result.parse(String name) {
    switch (name) {
      case 'success':
        return Result.success;
      case 'skipped':
        return Result.skipped;
      case 'failure':
        return Result.failure;
      case 'error':
        return Result.error;
      default:
        throw ArgumentError('Invalid result name "$name".');
    }
  }

  const Result._(this.name);

  @override
  String toString() => name;
}
