// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';

// Any changes to this file should be reflected in the debugAssertAllGesturesVarsUnset()
// function below.

/// Whether to print the results of each hit test to the console.
///
/// When this is set, in debug mode, any time a hit test is triggered by the
/// [GestureBinding] the results are dumped to the console.
///
/// This has no effect in release builds.
bool debugPrintHitTestResults = false;

/// Whether to print the details of each mouse hover event to the console.
///
/// When this is set, in debug mode, any time a mouse hover event is triggered
/// by the [GestureBinding], the results are dumped to the console.
///
/// This has no effect in release builds, and only applies to mouse hover
/// events.
bool debugPrintMouseHoverEvents = false;

/// Prints information about gesture recognizers and gesture arenas.
///
/// This flag only has an effect in debug mode.
///
/// See also:
///
///  * [GestureArenaManager], the class that manages gesture arenas.
///  * [debugPrintRecognizerCallbacksTrace], for debugging issues with
///    gesture recognizers.
bool debugPrintGestureArenaDiagnostics = false;

/// Logs a message every time a gesture recognizer callback is invoked.
///
/// This flag only has an effect in debug mode.
///
/// This is specifically used by [GestureRecognizer.invokeCallback]. Gesture
/// recognizers that do not use this method to invoke callbacks may not honor
/// the [debugPrintRecognizerCallbacksTrace] flag.
///
/// See also:
///
///  * [debugPrintGestureArenaDiagnostics], for debugging issues with gesture
///    arenas.
bool debugPrintRecognizerCallbacksTrace = false;

/// Whether to print the resampling margin to the console.
///
/// When this is set, in debug mode, any time resampling is triggered by the
/// [GestureBinding] the resampling margin is dumped to the console. The
/// resampling margin is the delta between the time of the last received
/// touch event and the current sample time. Positive value indicates that
/// resampling is effective and the resampling offset can potentially be
/// reduced for improved latency. Negative value indicates that resampling
/// is failing and resampling offset needs to be increased for smooth
/// touch event processing.
///
/// This has no effect in release builds.
bool debugPrintResamplingMargin = false;

/// Returns true if none of the gestures library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the gestures library](gestures/gestures-library.html) for a complete
/// list.
bool debugAssertAllGesturesVarsUnset(String reason) {
  assert(() {
    if (debugPrintHitTestResults ||
        debugPrintGestureArenaDiagnostics ||
        debugPrintRecognizerCallbacksTrace ||
        debugPrintResamplingMargin)
      throw FlutterError(reason);
    return true;
  }());
  return true;
}
