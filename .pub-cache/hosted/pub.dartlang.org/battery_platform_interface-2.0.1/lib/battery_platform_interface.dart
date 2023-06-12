// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel/method_channel_battery.dart';
import 'enums/battery_state.dart';

export 'enums/battery_state.dart';

/// The interface that implementations of battery must implement.
///
/// Platform implementations should extend this class rather than implement it as `battery`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [BatteryPlatform] methods.
abstract class BatteryPlatform extends PlatformInterface {
  /// Constructs a BatteryPlatform.
  BatteryPlatform() : super(token: _token);

  static final Object _token = Object();

  static BatteryPlatform _instance = MethodChannelBattery();

  /// The default instance of [BatteryPlatform] to use.
  ///
  /// Defaults to [MethodChannelBattery].
  static BatteryPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [BatteryPlatform] when they register themselves.
  static set instance(BatteryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the battery level from device.
  Future<int> batteryLevel() {
    throw UnimplementedError('batteryLevel() has not been implemented.');
  }

  /// gets battery state from device.
  Stream<BatteryState> onBatteryStateChanged() {
    throw UnimplementedError(
        'onBatteryStateChanged() has not been implemented.');
  }
}
