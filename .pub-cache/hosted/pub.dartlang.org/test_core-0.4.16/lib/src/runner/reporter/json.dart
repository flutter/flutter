// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show pid;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';
import 'package:test_api/hooks.dart' // ignore: implementation_imports
    show
        TestFailure;
import 'package:test_api/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/live_test.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/metadata.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/state.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite.dart'; // ignore: implementation_imports

import '../engine.dart';
import '../load_suite.dart';
import '../reporter.dart';
import '../runner_suite.dart';
import '../suite.dart';
import '../version.dart';

/// A reporter that prints machine-readable JSON-formatted test results.
class JsonReporter implements Reporter {
  /// Whether the test runner will pause for debugging.
  final bool _isDebugRun;

  /// The engine used to run the tests.
  final Engine _engine;

  /// A stopwatch that tracks the duration of the full run.
  final _stopwatch = Stopwatch();

  /// Whether we've started [_stopwatch].
  ///
  /// We can't just use `_stopwatch.isRunning` because the stopwatch is stopped
  /// when the reporter is paused.
  var _stopwatchStarted = false;

  /// An expando that associates unique IDs with [LiveTest]s.
  final _liveTestIDs = <LiveTest, int>{};

  /// An expando that associates unique IDs with [Suite]s.
  final _suiteIDs = <Suite, int>{};

  /// An expando that associates unique IDs with [Group]s.
  final _groupIDs = <Group, int>{};

  /// The next ID to associate with a [LiveTest].
  var _nextID = 0;

  /// Whether the reporter is paused.
  var _paused = false;

  /// The set of all subscriptions to various streams.
  final _subscriptions = <StreamSubscription>{};

  final StringSink _sink;

  /// Watches the tests run by [engine] and prints their results as JSON.
  static JsonReporter watch(Engine engine, StringSink sink,
          {required bool isDebugRun}) =>
      JsonReporter._(engine, sink, isDebugRun);

  JsonReporter._(this._engine, this._sink, this._isDebugRun) {
    _subscriptions.add(_engine.onTestStarted.listen(_onTestStarted));

    // Convert the future to a stream so that the subscription can be paused or
    // canceled.
    _subscriptions.add(_engine.success.asStream().listen(_onDone));

    _subscriptions.add(_engine.onSuiteAdded.listen(null, onDone: () {
      _emit('allSuites', {
        'count': _engine.addedSuites.length,
        'time': _stopwatch.elapsed.inMilliseconds
      });
    }));

    _emit('start',
        {'protocolVersion': '0.1.1', 'runnerVersion': testVersion, 'pid': pid});
  }

  @override
  void pause() {
    if (_paused) return;
    _paused = true;

    _stopwatch.stop();

    for (var subscription in _subscriptions) {
      subscription.pause();
    }
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;

    if (_stopwatchStarted) _stopwatch.start();

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
    if (!_stopwatchStarted) {
      _stopwatchStarted = true;
      _stopwatch.start();
    }

    var suiteID = _idForSuite(liveTest.suite);

    // Don't emit groups for load suites. They're always empty and they provide
    // unnecessary clutter.
    var groupIDs = liveTest.suite is LoadSuite
        ? <int>[]
        : _idsForGroups(liveTest.groups, liveTest.suite);

    var suiteConfig = _configFor(liveTest.suite);
    var id = _nextID++;
    _liveTestIDs[liveTest] = id;
    _emit('testStart', {
      'test': {
        'id': id,
        'name': liveTest.test.name,
        'suiteID': suiteID,
        'groupIDs': groupIDs,
        'metadata': _serializeMetadata(suiteConfig, liveTest.test.metadata),
        ..._frameInfo(suiteConfig, liveTest.test.trace,
            liveTest.suite.platform.runtime, liveTest.suite.path!),
      }
    });

    // Convert the future to a stream so that the subscription can be paused or
    // canceled.
    _subscriptions.add(
        liveTest.onComplete.asStream().listen((_) => _onComplete(liveTest)));

    _subscriptions.add(liveTest.onError
        .listen((error) => _onError(liveTest, error.error, error.stackTrace)));

    _subscriptions.add(liveTest.onMessage.listen((message) {
      _emit('print', {
        'testID': id,
        'messageType': message.type.name,
        'message': message.text
      });
    }));
  }

  /// Returns an ID for [suite].
  ///
  /// If [suite] doesn't have an ID yet, this assigns one and emits a new event
  /// for that suite.
  int _idForSuite(Suite suite) {
    if (_suiteIDs.containsKey(suite)) return _suiteIDs[suite]!;

    var id = _nextID++;
    _suiteIDs[suite] = id;

    // Give the load suite's suite the same ID, because it doesn't have any
    // different metadata.
    if (suite is LoadSuite) {
      suite.suite.then((runnerSuite) {
        if (runnerSuite == null) return;
        _suiteIDs[runnerSuite] = id;
        if (!_isDebugRun) return;

        // TODO(nweiz): test this when we have a library for communicating with
        // the Chrome remote debugger, or when we have VM debug support.
        _emit('debug', {
          'suiteID': id,
          'observatory': runnerSuite.environment.observatoryUrl?.toString(),
          'remoteDebugger':
              runnerSuite.environment.remoteDebuggerUrl?.toString(),
        });
      });
    }

    _emit('suite', {
      'suite': <String, Object?>{
        'id': id,
        'platform': suite.platform.runtime.identifier,
        'path': suite.path
      }
    });
    return id;
  }

  /// Returns a list of the IDs for all the groups in [groups], which are
  /// contained in the suite identified by [suiteID].
  ///
  /// If a group doesn't have an ID yet, this assigns one and emits a new event
  /// for that group.
  List<int> _idsForGroups(Iterable<Group> groups, Suite suite) {
    int? parentID;
    return groups.map((group) {
      if (_groupIDs.containsKey(group)) {
        return parentID = _groupIDs[group]!;
      }

      var id = _nextID++;
      _groupIDs[group] = id;

      var suiteConfig = _configFor(suite);
      _emit('group', {
        'group': {
          'id': id,
          'suiteID': _idForSuite(suite),
          'parentID': parentID,
          'name': group.name,
          'metadata': _serializeMetadata(suiteConfig, group.metadata),
          'testCount': group.testCount,
          ..._frameInfo(
              suiteConfig, group.trace, suite.platform.runtime, suite.path!)
        }
      });
      parentID = id;
      return id;
    }).toList();
  }

  /// Serializes [metadata] into a JSON-protocol-compatible map.
  Map _serializeMetadata(SuiteConfiguration suiteConfig, Metadata metadata) =>
      suiteConfig.runSkipped
          ? {'skip': false, 'skipReason': null}
          : {'skip': metadata.skip, 'skipReason': metadata.skipReason};

  /// A callback called when [liveTest] finishes running.
  void _onComplete(LiveTest liveTest) {
    _emit('testDone', {
      'testID': _liveTestIDs[liveTest],
      'result': _normalizeTestResult(liveTest),
      'skipped': liveTest.state.result == Result.skipped,
      'hidden': !_engine.liveTests.contains(liveTest)
    });
  }

  String _normalizeTestResult(LiveTest liveTest) {
    // For backwards-compatibility, report skipped tests as successes.
    if (liveTest.state.result == Result.skipped) return 'success';
    // if test is still active, it was probably cancelled
    if (_engine.active.contains(liveTest)) return 'error';
    return liveTest.state.result.toString();
  }

  /// A callback called when [liveTest] throws [error].
  void _onError(LiveTest liveTest, error, StackTrace stackTrace) {
    _emit('error', {
      'testID': _liveTestIDs[liveTest],
      'error': error.toString(),
      'stackTrace': '$stackTrace',
      'isFailure': error is TestFailure
    });
  }

  /// A callback called when the engine is finished running tests.
  ///
  /// [success] will be `true` if all tests passed, `false` if some tests
  /// failed, and `null` if the engine was closed prematurely.
  void _onDone(bool? success) {
    _cancel();
    _stopwatch.stop();

    _emit('done', {'success': success});
  }

  /// Returns the configuration for [suite].
  ///
  /// If [suite] is a [RunnerSuite], this returns [RunnerSuite.config].
  /// Otherwise, it returns [SuiteConfiguration.empty].
  SuiteConfiguration _configFor(Suite suite) =>
      suite is RunnerSuite ? suite.config : SuiteConfiguration.empty;

  /// Emits an event with the given type and attributes.
  void _emit(String type, Map attributes) {
    attributes['type'] = type;
    attributes['time'] = _stopwatch.elapsed.inMilliseconds;
    _sink.writeln(jsonEncode(attributes));
  }

  /// Returns a map with the line, column, and URL information for the first
  /// frame of [trace], as well as the first line in the original file.
  ///
  /// If javascript traces are enabled and the test is on a javascript platform,
  /// or if the [trace] is null or empty, then the line, column, and url will
  /// all be `null`.
  Map<String, dynamic> _frameInfo(SuiteConfiguration suiteConfig, Trace? trace,
      Runtime runtime, String suitePath) {
    var absoluteSuitePath = p.absolute(suitePath);
    var frame = trace?.frames.first;
    if (frame == null || (suiteConfig.jsTrace && runtime.isJS)) {
      return {'line': null, 'column': null, 'url': null};
    }

    var rootFrame = trace?.frames.firstWhereOrNull((frame) =>
        frame.uri.scheme == 'file' &&
        frame.uri.toFilePath() == absoluteSuitePath);
    return {
      'line': frame.line,
      'column': frame.column,
      'url': frame.uri.toString(),
      if (rootFrame != null && rootFrame != frame) ...{
        'root_line': rootFrame.line,
        'root_column': rootFrame.column,
        'root_url': rootFrame.uri.toString(),
      }
    };
  }
}
