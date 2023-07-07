// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart'
    show Metadata, RemoteException, SuitePlatform;
import 'package:test_api/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/test.dart'; // ignore: implementation_imports

import '../configuration.dart';
import '../environment.dart';
import '../load_exception.dart';
import '../runner_suite.dart';
import '../runner_test.dart';
import '../suite.dart';

/// A helper method for creating a [RunnerSuiteController] containing tests
/// that communicate over [channel].
///
/// This returns a controller so that the caller has a chance to control the
/// runner suite's debugging state based on plugin-specific logic.
///
/// If the suite is closed, this will close [channel].
///
/// The [message] parameter is an opaque object passed from the runner to
/// [PlatformPlugin.load]. Plugins shouldn't interact with it other than to pass
/// it on to [deserializeSuite].
///
/// If [mapper] is passed, it will be used to adjust stack traces for any errors
/// emitted by tests.
///
/// [gatherCoverage] is a callback which returns a hit-map containing merged
/// coverage report suitable for use with `package:coverage`.
RunnerSuiteController deserializeSuite(
    String path,
    SuitePlatform platform,
    SuiteConfiguration suiteConfig,
    Environment environment,
    StreamChannel<Object?> channel,
    Object /*Map<String, Object?>*/ message,
    {Future<Map<String, dynamic>> Function()? gatherCoverage}) {
  var disconnector = Disconnector<Object?>();
  var suiteChannel = MultiChannel<Object?>(channel.transform(disconnector));

  suiteChannel.sink.add(<String, Object?>{
    'type': 'initial',
    'platform': platform.serialize(),
    'metadata': suiteConfig.metadata.serialize(),
    'asciiGlyphs': Platform.isWindows,
    'path': path,
    'collectTraces': Configuration.current.reporter == 'json' ||
        Configuration.current.fileReporters.containsKey('json') ||
        suiteConfig.line != null ||
        suiteConfig.col != null,
    'noRetry': Configuration.current.noRetry,
    'foldTraceExcept': Configuration.current.foldTraceExcept.toList(),
    'foldTraceOnly': Configuration.current.foldTraceOnly.toList(),
    'allowDuplicateTestNames': suiteConfig.allowDuplicateTestNames,
    'ignoreTimeouts': suiteConfig.ignoreTimeouts,
    ...(message as Map<String, dynamic>),
  });

  var completer = Completer<Group>();

  var loadSuiteZone = Zone.current;
  void handleError(Object error, StackTrace stackTrace) {
    disconnector.disconnect();

    if (completer.isCompleted) {
      // If we've already provided a controller, send the error to the
      // LoadSuite. This will cause the virtual load test to fail, which will
      // notify the user of the error.
      loadSuiteZone.handleUncaughtError(error, stackTrace);
    } else {
      completer.completeError(error, stackTrace);
    }
  }

  suiteChannel.stream.cast<Map<String, Object?>>().listen(
      (response) {
        switch (response['type'] as String) {
          case 'print':
            print(response['line']);
            break;

          case 'loadException':
            handleError(LoadException(path, response['message'] as Object),
                Trace.current());
            break;

          case 'error':
            var asyncError = RemoteException.deserialize(response['error']);
            handleError(
                LoadException(path, asyncError.error), asyncError.stackTrace);
            break;

          case 'success':
            var deserializer = _Deserializer(suiteChannel);
            completer.complete(
                deserializer.deserializeGroup(response['root'] as Map));
            break;
        }
      },
      onError: handleError,
      onDone: () {
        if (completer.isCompleted) return;
        completer.completeError(
            LoadException(path, 'Connection closed before test suite loaded.'),
            Trace.current());
      });

  return RunnerSuiteController(
      environment, suiteConfig, suiteChannel, completer.future, platform,
      path: path,
      onClose: () => disconnector.disconnect().onError(handleError),
      gatherCoverage: gatherCoverage);
}

/// A utility class for storing state while deserializing tests.
class _Deserializer {
  /// The channel over which tests communicate.
  final MultiChannel _channel;

  _Deserializer(this._channel);

  /// Deserializes [group] into a concrete [Group].
  Group deserializeGroup(Map group) {
    var metadata = Metadata.deserialize(group['metadata']);
    return Group(
        group['name'] as String,
        (group['entries'] as List).map((entry) {
          var map = entry as Map;
          if (map['type'] == 'group') return deserializeGroup(map);
          return _deserializeTest(map)!;
        }),
        metadata: metadata,
        trace: group['trace'] == null
            ? null
            : Trace.parse(group['trace'] as String),
        setUpAll: _deserializeTest(group['setUpAll'] as Map?),
        tearDownAll: _deserializeTest(group['tearDownAll'] as Map?));
  }

  /// Deserializes [test] into a concrete [Test] class.
  ///
  /// Returns `null` if [test] is `null`.
  Test? _deserializeTest(Map? test) {
    if (test == null) return null;

    var metadata = Metadata.deserialize(test['metadata']);
    var trace =
        test['trace'] == null ? null : Trace.parse(test['trace'] as String);
    var testChannel = _channel.virtualChannel(test['channel'] as int);
    return RunnerTest(test['name'] as String, metadata, trace, testChannel);
  }
}
