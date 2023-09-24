// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'hardware_keyboard.dart';

export 'hardware_keyboard.dart' show KeyDataTransitMode;

/// Override the transit mode with which key events are simulated.
///
/// Setting [debugKeyEventSimulatorTransitModeOverride] is a good way to make
/// certain tests simulate the behavior of different type of platforms in terms
/// of their extent of support for keyboard API.
KeyDataTransitMode? debugKeyEventSimulatorTransitModeOverride;

/// Setting to true will cause extensive logging to occur when key events are
/// received.
///
/// Can be used to debug keyboard issues: each time a key event is received on
/// the framework side, the event details and the current pressed state will
/// be printed.
bool debugPrintKeyboardEvents = false;

/// Returns true if none of the widget library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the services library](services/services-library.html) for a complete list.
bool debugAssertAllServicesVarsUnset(String reason) {
  assert(() {
    if (debugKeyEventSimulatorTransitModeOverride != null) {
      throw FlutterError(reason);
    }
    if (debugPrintKeyboardEvents) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
