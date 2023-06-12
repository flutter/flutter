// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:battery_platform_interface/battery_platform_interface.dart';

export 'package:battery_platform_interface/battery_platform_interface.dart'
    show BatteryState;

/// API for accessing information about the battery of the device the Flutter
/// app is currently running on.
class Battery {
  /// Returns the current battery level in percent.
  Future<int> get batteryLevel async =>
      await BatteryPlatform.instance.batteryLevel();

  /// Fires whenever the battery state changes.
  Stream<BatteryState> get onBatteryStateChanged =>
      BatteryPlatform.instance.onBatteryStateChanged();
}
