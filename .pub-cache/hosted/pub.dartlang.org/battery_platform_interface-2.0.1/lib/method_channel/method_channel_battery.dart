import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'package:battery_platform_interface/battery_platform_interface.dart';

import '../battery_platform_interface.dart';

/// An implementation of [BatteryPlatform] that uses method channels.
class MethodChannelBattery extends BatteryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel channel = MethodChannel('plugins.flutter.io/battery');

  /// The event channel used to interact with the native platform.
  @visibleForTesting
  final EventChannel eventChannel = EventChannel('plugins.flutter.io/charging');

  /// Method channel for getting battery level.
  Future<int> batteryLevel() async {
    return (await channel.invokeMethod('getBatteryLevel')).toInt();
  }

  /// Stream variable for storing battery state.
  Stream<BatteryState>? _onBatteryStateChanged;

  /// Event channel for getting battery change state.
  Stream<BatteryState> onBatteryStateChanged() {
    if (_onBatteryStateChanged == null) {
      _onBatteryStateChanged = eventChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseBatteryState(event));
    }

    return _onBatteryStateChanged!;
  }
}

/// Method for parsing battery state.
BatteryState _parseBatteryState(String state) {
  switch (state) {
    case 'full':
      return BatteryState.full;
    case 'charging':
      return BatteryState.charging;
    case 'discharging':
      return BatteryState.discharging;
    default:
      throw ArgumentError('$state is not a valid BatteryState.');
  }
}
