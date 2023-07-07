// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:test_api/src/backend/live_test.dart';
import 'package:test_api/src/backend/message.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/util/pretty_print.dart';

import '../engine.dart';
import '../load_suite.dart';
import '../reporter.dart';

/// A reporter that prints test output using formatting for Github Actions.
///
/// See
/// https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions
/// for a description of the output format, and
/// https://github.com/dart-lang/test/issues/1415 for discussions about this
/// implementation.
class GithubReporter implements Reporter {
  /// The engine used to run the tests.
  final Engine _engine;

  /// Whether the path to each test's suite should be printed.
  final bool _printPath;

  /// Whether the platform each test is running on should be printed.
  final bool _printPlatform;

  /// Whether the reporter is paused.
  var _paused = false;

  /// The set of all subscriptions to various streams.
  final _subscriptions = <StreamSubscription>{};

  final StringSink _sink;

  final Map<LiveTest, List<Message>> _testMessages = {};

  final Set<LiveTest> _completedTests = {};

  /// Watches the tests run by [engine] and prints their results as JSON.
  static GithubReporter watch(
    Engine engine,
    StringSink sink, {
    required bool printPath,
    required bool printPlatform,
  }) =>
      GithubReporter._(engine, sink, printPath, printPlatform);

  GithubReporter._(
      this._engine, this._sink, this._printPath, this._printPlatform) {
    _subscriptions.add(_engine.onTestStarted.listen(_onTestStarted));
    _subscriptions.add(_engine.success.asStream().listen(_onDone));

    // Add a spacer between pre-test output and the test results.
    _sink.writeln();
  }

  @override
  void pause() {
    if (_paused) return;
    _paused = true;

    for (var subscription in _subscriptions) {
      subscription.pause();
    }
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;

    for (var subscription in _subscriptions) {
      subscription.resume();
    }
  }

  void _cancel() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// A callback called when the engine begins running [liveTest].
  void _onTestStarted(LiveTest liveTest) {
    // Convert the future to a stream so that the subscription can be paused or
    // canceled.
    _subscriptions.add(
        liveTest.onComplete.asStream().listen((_) => _onComplete(liveTest)));

    // Collect messages from tests as they are emitted.
    _subscriptions.add(liveTest.onMessage.listen((message) {
      if (_completedTests.contains(liveTest)) {
        // The test has already completed and it's previous messages were
        // written out; ensure this post-completion output is not lost.
        _sink.writeln(message.text);
      } else {
        _testMessages.putIfAbsent(liveTest, () => []).add(message);
      }
    }));
  }

  /// A callback called when [liveTest] finishes running.
  void _onComplete(LiveTest test) {
    final errors = test.errors;
    final messages = _testMessages[test] ?? [];
    final skipped = test.state.result == Result.skipped;
    final failed = errors.isNotEmpty;
    final loadSuite = test.suite is LoadSuite;
    final synthetic = loadSuite ||
        test.individualName == '(setUpAll)' ||
        test.individualName == '(tearDownAll)';

    // Mark this test as having completed.
    _completedTests.add(test);

    // Don't emit any info for loadSuite, setUpAll, or tearDownAll tests
    // unless they contain errors or other info.
    if (synthetic && (errors.isEmpty && messages.isEmpty)) {
      return;
    }

    // For now, we use the same icon for both tests and test-like structures
    // (loadSuite, setUpAll, tearDownAll).
    var defaultIcon = synthetic ? _GithubMarkup.passed : _GithubMarkup.passed;
    final prefix = failed
        ? _GithubMarkup.failed
        : skipped
            ? _GithubMarkup.skipped
            : defaultIcon;
    final statusSuffix = failed
        ? ' (failed)'
        : skipped
            ? ' (skipped)'
            : '';

    var name = test.test.name;
    if (!loadSuite) {
      if (_printPath && test.suite.path != null) {
        name = '${test.suite.path}: $name';
      }
    }
    if (_printPlatform) {
      name = '[${test.suite.platform.runtime.name}] $name';
    }
    _sink.writeln(_GithubMarkup.startGroup('$prefix $name$statusSuffix'));
    for (var message in messages) {
      _sink.writeln(message.text);
    }
    for (var error in errors) {
      _sink.writeln('${error.error}');
      _sink.writeln(error.stackTrace.toString().trimRight());
    }
    _sink.writeln(_GithubMarkup.endGroup);
  }

  void _onDone(bool? success) {
    _cancel();

    _sink.writeln();

    final hadFailures = _engine.failed.isNotEmpty;
    final message = StringBuffer('${_engine.passed.length} '
        '${pluralize('test', _engine.passed.length)} passed');
    if (_engine.failed.isNotEmpty) {
      message.write(', ${_engine.failed.length} failed');
    }
    if (_engine.skipped.isNotEmpty) {
      message.write(', ${_engine.skipped.length} skipped');
    }
    message.write('.');
    _sink.writeln(
      hadFailures
          ? _GithubMarkup.error(message.toString())
          : '${_GithubMarkup.success} $message',
    );
  }
}

abstract class _GithubMarkup {
  // Char sets avilable at https://www.compart.com/en/unicode/.
  static const String passed = '✅';
  static const String skipped = '❎';
  static const String failed = '❌';
  // The 'synthetic' icon is currently not used but is something to consider in
  // order to draw a distinction between user tests and test-like supporting
  // infrastructure.
  // static const String synthetic = '⏺';
  static const String success = '🎉';

  static String startGroup(String title) =>
      '::group::${title.replaceAll('\n', ' ')}';

  static final String endGroup = '::endgroup::';

  static String error(String message) => '::error::$message';
}
