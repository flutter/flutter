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

/// Profile and print statistics on Platform Channel usage.
///
/// When this is true statistics about the usage of Platform Channels will be
/// printed out periodically to the console and Timeline events will show the
/// time between sending and receiving a message (encoding and decoding time
/// excluded).
///
/// The statistics include the total bytes transmitted and the average number of
/// bytes per invocation in the last quantum. "Up" means in the direction of
/// Flutter to the host platform, "down" is the host platform to flutter.
bool debugProfilePlatformChannels = false;

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
    if (debugProfilePlatformChannels) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
