// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart' hide Result;
import 'package:collection/collection.dart';
import 'package:test_api/src/backend/live_test.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/state.dart'; // ignore: implementation_imports

import 'live_suite.dart';
import 'runner_suite.dart';

/// An implementation of [LiveSuite] that's controlled by a
/// [LiveSuiteController].
class _LiveSuite extends LiveSuite {
  final LiveSuiteController _controller;

  @override
  RunnerSuite get suite => _controller._suite;

  @override
  Future get onComplete => _controller._onCompleteGroup.future;

  @override
  bool get isClosed => _controller._onCloseCompleter.isCompleted;

  @override
  Future get onClose => _controller._onCloseCompleter.future;

  @override
  Stream<LiveTest> get onTestStarted =>
      _controller._onTestStartedController.stream;

  @override
  Set<LiveTest> get passed => UnmodifiableSetView(_controller._passed);

  @override
  Set<LiveTest> get skipped => UnmodifiableSetView(_controller._skipped);

  @override
  Set<LiveTest> get failed => UnmodifiableSetView(_controller._failed);

  @override
  LiveTest? get active => _controller._active;

  _LiveSuite(this._controller);
}

/// A controller that drives a [LiveSuite].
///
/// This is a utility class to make it easier for [Engine] to create the
/// [LiveSuite]s exposed by various APIs. The [LiveSuite] is accessible through
/// [LiveSuiteController.liveSuite]. When a live test is run, it should be
/// passed to [reportLiveTest], and once tests are finished being run for this
/// suite, [noMoreLiveTests] should be called. Once the suite should be torn
/// down, [close] should be called.
class LiveSuiteController {
  /// The [LiveSuite] being controlled.
  late final liveSuite = _LiveSuite(this);

  /// The suite that's being run.
  final RunnerSuite _suite;

  /// The future group that backs [LiveSuite.onComplete].
  ///
  /// This contains all the futures from tests that are run in this suite.
  final _onCompleteGroup = FutureGroup();

  /// The completer that backs [LiveSuite.onClose].
  ///
  /// This is completed when the live suite is closed.
  final _onCloseCompleter = Completer();

  /// The controller for [LiveSuite.onTestStarted].
  final _onTestStartedController =
      StreamController<LiveTest>.broadcast(sync: true);

  /// The set that backs [LiveTest.passed].
  final _passed = <LiveTest>{};

  /// The set that backs [LiveTest.skipped].
  final _skipped = <LiveTest>{};

  /// The set that backs [LiveTest.failed].
  final _failed = <LiveTest>{};

  /// The test exposed through [LiveTest.active].
  LiveTest? _active;

  /// Creates a controller for a live suite representing running the tests in
  /// [suite].
  ///
  /// Once this is called, the controller assumes responsibility for closing the
  /// suite. The caller should call [LiveSuiteController.close] rather than
  /// calling [RunnerSuite.close] directly.
  LiveSuiteController(this._suite);

  /// Reports the status of [liveTest] through [liveSuite].
  ///
  /// The live test is assumed to be a member of this suite. If [countSuccess]
  /// is `true` (the default), the test is put into [passed] if it succeeds.
  /// Otherwise, it's removed from [liveTests] entirely.
  ///
  /// Throws a [StateError] if called after [noMoreLiveTests].
  void reportLiveTest(LiveTest liveTest, {bool countSuccess = true}) {
    if (_onTestStartedController.isClosed) {
      throw StateError("Can't call reportLiveTest() after noMoreTests().");
    }

    assert(liveTest.suite == _suite);
    assert(_active == null);

    _active = liveTest;

    liveTest.onStateChange.listen((state) {
      if (state.status != Status.complete) return;
      _active = null;

      if (state.result == Result.skipped) {
        _skipped.add(liveTest);
      } else if (state.result != Result.success) {
        _passed.remove(liveTest);
        _failed.add(liveTest);
      } else if (countSuccess) {
        _passed.add(liveTest);
        // A passing test that was once failing was retried
        _failed.remove(liveTest);
      }
    });

    _onTestStartedController.add(liveTest);

    _onCompleteGroup.add(liveTest.onComplete);
  }

  /// Indicates that all the live tests that are going to be provided for this
  /// suite have already been provided.
  void noMoreLiveTests() {
    _onTestStartedController.close();
    _onCompleteGroup.close();
  }

  /// Closes the underlying suite.
  Future close() => _closeMemo.runOnce(() async {
        try {
          await _suite.close();
        } finally {
          _onCloseCompleter.complete();
        }
      });
  final _closeMemo = AsyncMemoizer();
}
