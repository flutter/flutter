// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'assertions.dart';
import 'platform.dart';
import 'print.dart';

/// Returns true if none of the foundation library debug variables have been
/// changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// The `debugPrintOverride` argument can be specified to indicate the expected
/// value of the [debugPrint] variable. This is useful for test frameworks that
/// override [debugPrint] themselves and want to check that their own custom
/// value wasn't overridden by a test.
///
/// See [https://docs.flutter.io/flutter/foundation/foundation-library.html] for
/// a complete list.
bool debugAssertAllFoundationVarsUnset(String reason, { DebugPrintCallback debugPrintOverride = debugPrintThrottled }) {
  assert(() {
    if (debugPrint != debugPrintOverride ||
        debugDefaultTargetPlatformOverride != null)
      throw FlutterError(reason);
    return true;
  }());
  return true;
}

/// Boolean value indicating whether [debugInstrumentAction] will instrument
/// actions in debug builds.
bool debugInstrumentationEnabled = false;

/// Runs the specified [action], timing how long the action takes in debug
/// builds when [debugInstrumentationEnabled] is true.
///
/// The instrumentation will be printed to the logs using [debugPrint]. In
/// non-debug builds, or when [debugInstrumentationEnabled] is false, this will
/// run [action] without any instrumentation.
///
/// Returns the result of running [action].
///
/// See also:
///
///   * [Timeline], which is used to record synchronous tracing events for
///     visualization in Chrome's tracing format. This method does not
///     implicitly add any timeline events.
Future<T> debugInstrumentAction<T>(String description, Future<T> action()) {
  bool instrument = false;
  assert(() { instrument = debugInstrumentationEnabled; return true; }());
  if (instrument) {
    final Stopwatch stopwatch = Stopwatch()..start();
    return action().whenComplete(() {
      stopwatch.stop();
      debugPrint('Action "$description" took ${stopwatch.elapsed}');
    });
  } else {
    return action();
  }
}

/// A callback that, when evaluated, returns a log message.  Log messages must
/// be encodable as JSON using `json.encode()`.
typedef DebugLogMessageCallback = Object Function();

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `debugShouldLogEvent(key)` is true).
///
/// Messages are obtained by evaluating [messageCallback] and must be encodable
/// as JSON strings using `json.encode()`. In the event that logging is not
/// enabled for the given [channel], [messageCallback] will not be evaluated.
/// The cost of logging calls can be further mitigated at call sites by invoking
/// them in a function that is only evaluated in profile or debug modes. For
/// example,
///
/// ```dart
/// profile(() {
///   debugLogEvent(logGestures, () => <String, int> {
///    'x' : x,
///    'y' : y,
///    'z' : z,
///   });
/// });
///```
///
/// ignores logging entirely in release mode and no performance penalty is paid.
///
/// Logging for a given event channel can be enabled programmatically via
/// [debugEnableLogging] or using a VM service call.
///
void debugLogEvent(String channel, DebugLogMessageCallback messageCallback) {
  assert(channel != null);
  if (!debugShouldLogEvent(channel)) {
    return;
  }

  assert(messageCallback != null);
  final Object message = messageCallback();
  assert(message != null);

  developer.log(json.encode(message), name: channel);
}

final Set<String> _debugLogEventChannels = Set<String>();

/// Enable (or disable) logging for all events on the given [channel].
void debugEnableLogging(String channel, [bool enable = true]) {
  assert(channel != null);
  if (enable) {
    _debugLogEventChannels.add(channel);
  } else {
    _debugLogEventChannels.remove(channel);
  }
}

/// Returns true if events on the given event [channel] should be logged.
bool debugShouldLogEvent(String channel) {
  assert(channel != null);
  return _debugLogEventChannels.contains(channel);
}

/// Arguments to whitelist [Timeline] events in order to be shown in the
/// developer centric version of the Observatory Timeline.
const Map<String, String> timelineWhitelistArguments = <String, String>{
  'mode': 'basic'
};
