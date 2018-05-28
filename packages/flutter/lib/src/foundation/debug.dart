// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
bool debugAssertAllFoundationVarsUnset(String reason, { DebugPrintCallback debugPrintOverride: debugPrintThrottled }) {
  assert(() {
    if (debugPrint != debugPrintOverride ||
        debugDefaultTargetPlatformOverride != null)
      throw new FlutterError(reason);
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
/// Returns the result of running [action], wrapped in a `Future` if the action
/// was synchronous.
Future<T> debugInstrumentAction<T>(String description, FutureOr<T> action()) {
  if (!debugInstrumentationEnabled)
    return new Future<T>.value(action());

  Stopwatch stopwatch;
  assert(() {
    stopwatch = new Stopwatch()..start();
    return true;
  } ());
  void stopStopwatchAndPrintElapsed() {
    assert(() {
      stopwatch.stop();
      debugPrint('Action "$description" took ${stopwatch.elapsed}');
      return true;
    }());
  }

  Future<T> returnResult;
  FutureOr<T> actionResult;
  try {
    actionResult = action();
  } finally {
    if (actionResult is Future<T>) {
      returnResult = actionResult.whenComplete(stopStopwatchAndPrintElapsed);
    } else {
      stopStopwatchAndPrintElapsed();
      returnResult = new Future<T>.value(actionResult);
    }
  }
  return returnResult;
}

/// Arguments to whitelist [Timeline] events in order to be shown in the
/// developer centric version of the Observatory Timeline.
const Map<String, String> timelineWhitelistArguments = const <String, String>{
  'mode': 'basic'
};
