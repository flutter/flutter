// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'hardware_keyboard.dart';

/// Override the vehicle used to simulate key events.
///
/// Setting [debugKeySimulationVehicleOverride] changes
/// [KeyEventSimulator.vehicle], and is a good way to make certain tests
/// simulate the behavior of different type of platforms in terms of their
/// support for keyboard API.
KeyEventVehicle? debugKeySimulationVehicleOverride;

/// Returns true if none of the widget library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the services library](services/services-library.html) for a complete list.
bool debugAssertAllServicesVarsUnset(String reason) {
  assert(() {
    if (debugKeySimulationVehicleOverride != null) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
