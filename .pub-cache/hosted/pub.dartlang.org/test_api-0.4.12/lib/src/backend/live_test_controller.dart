// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import 'group.dart';
import 'live_test.dart';
import 'message.dart';
import 'state.dart';
import 'suite.dart';
import 'test.dart';

/// A concrete [LiveTest] that enforces some lifecycle guarantees.
///
/// This automatically handles some of [LiveTest]'s guarantees, but for the most
/// part it's the caller's responsibility to make sure everything gets
/// dispatched in the correct order.
class LiveTestController extends LiveTest {
  @Deprecated('Use this instance instead')
  LiveTest get liveTest => this;

  @override
  final Suite suite;

  @override
  final List<Group> groups;

  @override
  final Test test;

  /// The function that will actually start the test running.
  final void Function() _onRun;

  /// A function to run when the test is closed.
  ///
  /// This may be `null`.
  final void Function() _onClose;

  /// The list of errors caught by the test.
  final _errors = <AsyncError>[];

  @override
  List<AsyncError> get errors => UnmodifiableListView(_errors);

  /// The current state of the test.
  @override
  var state = const State(Status.pending, Result.success);

  /// The controller for [onStateChange].
  ///
  /// This is synchronous to ensure that events are well-ordered across multiple
  /// streams.
  final _onStateChange = StreamController<State>.broadcast(sync: true);
  @override
  Stream<State> get onStateChange => _onStateChange.stream;

  /// The controller for [onError].
  ///
  /// This is synchronous to ensure that events are well-ordered across multiple
  /// streams.
  final _onError = StreamController<AsyncError>.broadcast(sync: true);
  @override
  Stream<AsyncError> get onError => _onError.stream;

  /// The controller for [onMessage].
  ///
  /// This is synchronous to ensure that events are well-ordered across multiple
  /// streams.
  final _onMessage = StreamController<Message>.broadcast(sync: true);
  @override
  Stream<Message> get onMessage => _onMessage.stream;

  final completer = Completer<void>();

  /// Whether [run] has been called.
  var _runCalled = false;

  /// Whether [close] has been called.
  bool get _isClosed => _onError.isClosed;

  /// Creates a new controller for a [LiveTest].
  ///
  /// [test] is the test being run; [suite] is the suite that contains it.
  ///
  /// [onRun] is a function that's called from [LiveTest.run]. It should start
  /// the test running. The controller takes care of ensuring that
  /// [LiveTest.run] isn't called more than once and that [LiveTest.onComplete]
  /// is returned.
  ///
  /// [onClose] is a function that's called the first time [LiveTest.close] is
  /// called. It should clean up any resources that have been allocated for the
  /// test and ensure that the test finishes quickly if it's still running. It
  /// will only be called if [onRun] has been called first.
  ///
  /// If [groups] is passed, it's used to populate the list of groups that
  /// contain this test. Otherwise, `suite.group` is used.
  LiveTestController(this.suite, this.test, this._onRun, this._onClose,
      {Iterable<Group>? groups})
      : groups = groups == null ? [suite.group] : List.unmodifiable(groups);

  /// Adds an error to the [LiveTest].
  ///
  /// This both adds the error to [LiveTest.errors] and emits it via
  /// [LiveTest.onError]. [stackTrace] is automatically converted into a [Chain]
  /// if it's not one already.
  void addError(Object error, StackTrace? stackTrace) {
    if (_isClosed) return;

    var asyncError = AsyncError(
        error, Chain.forTrace(stackTrace ?? StackTrace.fromString('')));
    _errors.add(asyncError);
    _onError.add(asyncError);
  }

  /// Sets the current state of the [LiveTest] to [newState].
  ///
  /// If [newState] is different than the old state, this both sets
  /// [LiveTest.state] and emits the new state via [LiveTest.onStateChanged]. If
  /// it's not different, this does nothing.
  void setState(State newState) {
    if (_isClosed) return;
    if (state == newState) return;

    state = newState;
    _onStateChange.add(newState);
  }

  /// Emits message over [LiveTest.onMessage].
  void message(Message message) {
    if (_onMessage.hasListener) {
      _onMessage.add(message);
    } else {
      // Make sure all messages get surfaced one way or another to aid in
      // debugging.
      Zone.root.print(message.text);
    }
  }

  @override
  Future<void> run() {
    if (_runCalled) {
      throw StateError('LiveTest.run() may not be called more than once.');
    } else if (_isClosed) {
      throw StateError('LiveTest.run() may not be called for a closed '
          'test.');
    }
    _runCalled = true;

    _onRun();
    return onComplete;
  }

  /// Returns a future that completes when the test is complete.
  ///
  /// We also wait for the state to transition to Status.complete.
  @override
  Future<void> get onComplete => completer.future;

  @override
  Future<void> close() {
    if (_isClosed) return onComplete;

    _onStateChange.close();
    _onError.close();

    if (_runCalled) {
      _onClose();
    } else {
      completer.complete();
    }

    return onComplete;
  }
}
