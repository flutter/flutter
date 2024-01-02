// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' show stdout;
import 'dart:isolate';

import 'test.dart';

/// A suite of tests, added with the [test] method, which will be run in a
/// following event.
class TestSuite {
  /// Creates a new [TestSuite] with logs written to [logger] and callbacks
  /// given by [lifecycle].
  TestSuite({
    StringSink? logger,
    Lifecycle? lifecycle,
  }) :
    _logger = logger ?? stdout,
    _lifecycle = lifecycle ?? _DefaultLifecycle();

  final Lifecycle _lifecycle;
  final StringSink _logger;
  bool _testQueuePrimed = false;
  final Queue<Test> _testQueue = Queue<Test>();
  final Map<String, Test> _runningTests = <String, Test>{};

  /// Adds a test to the test suite.
  void test(
    String name,
    dynamic Function() body, {
    bool skip = false,
  }) {
    if (_runningTests.isNotEmpty) {
      throw StateError(
        'Test "$name" added after tests have started to run. '
        'Calls to test() must be synchronous with main().',
      );
    }
    if (skip) {
      _logger.writeln('Test "$name": Skipped');
      _primeQueue();
      return;
    }
    _pushTest(name, body);
  }

  void _primeQueue() {
    if (!_testQueuePrimed) {
      // All tests() must be added synchronously with main, so we can enqueue an
      // event to start all tests to run after main() is done.
      Timer.run(_startAllTests);
      _testQueuePrimed = true;
    }
  }

  void _pushTest(
    String name,
    dynamic Function() body,
  ) {
    final Test newTest = Test(name, body, logger: _logger);
    _testQueue.add(newTest);
    newTest.state = TestState.queued;
    _primeQueue();
  }

  void _startAllTests() {
    for (final Test t in _testQueue) {
      _runningTests[t.name] = t;
      t.run(onDone: () {
        _runningTests.remove(t.name);
        if (_runningTests.isEmpty) {
          _lifecycle.onDone(_testQueue);
        }
      });
    }
    _lifecycle.onStart();
    if (_testQueue.isEmpty) {
      _logger.writeln('All tests skipped.');
      _lifecycle.onDone(_testQueue);
    }
  }
}

/// Callbacks for the lifecycle of a [TestSuite].
abstract class Lifecycle {
  /// Called after a test suite has started.
  void onStart();

  /// Called after the last test in a test suite has completed.
  void onDone(Queue<Test> tests);
}

class _DefaultLifecycle implements Lifecycle {
  final ReceivePort _suitePort = ReceivePort('Suite port');
  late Queue<Test> _tests;

  @override
  void onStart() {
    _suitePort.listen((dynamic msg) {
      _suitePort.close();
      _processResults();
    });
  }

  @override
  void onDone(Queue<Test> tests) {
    _tests = tests;
    _suitePort.sendPort.send(null);
  }

  void _processResults() {
    bool testsSucceeded = true;
    for (final Test t in _tests) {
      testsSucceeded = testsSucceeded && (t.state == TestState.succeeded);
    }
    if (!testsSucceeded) {
      throw 'A test failed';
    }
  }
}
