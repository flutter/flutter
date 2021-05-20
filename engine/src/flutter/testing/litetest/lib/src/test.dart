// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'dart:async';
import 'dart:io' show stdout;
import 'dart:isolate';

import 'package:async_helper/async_minitest.dart' as m;
import 'package:expect/expect.dart' as e;

/// The state that each [Test] may be in.
enum TestState {
  /// Initial state of a [Test] after it has been allocated.
  allocated,

  /// State of a [Test] when it is on the queue of a [TestSuite].
  queued,

  /// State of a [Test] when it has been started.
  started,

  /// State of a [Test] when it has succeeded.
  succeeded,

  /// State of a [Test] when it has failed.
  failed,
}

/// A test that a [TestSuite] can enqueue to run.
class Test {
  /// Creates a [Test] with the given name, body, logger, and lifecycle.
  Test(
    this.name,
    this.body, {
    StringSink? logger,
    TestLifecycle? lifecycle,
  }) :
    _logger = logger ?? stdout,
    _lifecycle = lifecycle ?? _DefaultTestLifecycle(name);

  /// The name of the test.
  final String name;

  /// The body of the test.
  final dynamic Function() body;

  /// The logger that records information about the test.
  final StringSink _logger;

  /// The state that the test is in.
  TestState state = TestState.allocated;

  final TestLifecycle _lifecycle;

  /// Runs the test.
  ///
  /// Also signals the test's progress to the [TestLifecycle] object
  /// that was provided when the [Test] was constructed, which will eventually
  /// call the provided [onDone] callback.
  void run({
    void Function()? onDone,
  }) {
    m.test(name, () async {
      await Future<void>(() async {
        state = TestState.started;
        _logger.writeln('Test "$name": Started');
        try {
          await body();
          state = TestState.succeeded;
          _logger.writeln('Test "$name": Passed');
        } on e.ExpectException catch (e, st) {
          state = TestState.failed;
          _logger.writeln('Test "$name": Failed\n$e\n$st');
        } finally {
          _lifecycle.onDone(cleanup: onDone);
        }
      });
    });
    _lifecycle.onStart();
  }
}

/// Callbacks for the lifecycle of a test.
abstract class TestLifecycle {
  /// Called after a test has started.
  void onStart();

  /// Called when a test is finished.
  ///
  /// The callback should ensure that the [cleanup] function should run
  /// eventually if provided.
  void onDone({void Function()? cleanup});
}

class _DefaultTestLifecycle implements TestLifecycle {
  _DefaultTestLifecycle(String name) : _port = ReceivePort(name);

  final ReceivePort _port;

  void Function()? _cleanup;

  @override
  void onStart() {
    _port.listen((dynamic msg) {
      _port.close();
      if (_cleanup != null) {
        _cleanup!();
      }
    });
  }

  @override
  void onDone({void Function()? cleanup}) {
    _port.sendPort.send(null);
    _cleanup = cleanup;
  }
}
