// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'utils.dart';

/// An implementation of [ConnectivityPlatform] that uses method channels.
class MethodChannelConnectivity extends ConnectivityPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  MethodChannel methodChannel =
      MethodChannel('plugins.flutter.io/connectivity');

  /// The event channel used to receive ConnectivityResult changes from the native platform.
  @visibleForTesting
  EventChannel eventChannel =
      EventChannel('plugins.flutter.io/connectivity_status');

  Stream<ConnectivityResult>? _onConnectivityChanged;

  /// Fires whenever the connectivity state changes.
  Stream<ConnectivityResult> get onConnectivityChanged {
    if (_onConnectivityChanged == null) {
      _onConnectivityChanged =
          eventChannel.receiveBroadcastStream().map((dynamic result) {
        return result != null ? result.toString() : '';
      }).map(parseConnectivityResult);
    }
    return _onConnectivityChanged!;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    final String checkResult =
        await methodChannel.invokeMethod<String>('check') ?? '';
    return parseConnectivityResult(checkResult);
  }

  @override
  Future<String?> getWifiName() async {
    String? wifiName = await methodChannel.invokeMethod<String>('wifiName');
    // as Android might return <unknown ssid>, uniforming result
    // our iOS implementation will return null
    if (wifiName == '<unknown ssid>') {
      wifiName = null;
    }
    return wifiName;
  }

  @override
  Future<String?> getWifiBSSID() {
    return methodChannel.invokeMethod<String>('wifiBSSID');
  }

  @override
  Future<String?> getWifiIP() {
    return methodChannel.invokeMethod<String>('wifiIPAddress');
  }

  @override
  Future<LocationAuthorizationStatus> requestLocationServiceAuthorization({
    bool requestAlwaysLocationUsage = false,
  }) async {
    final String requestLocationServiceResult = await methodChannel
            .invokeMethod<String>('requestLocationServiceAuthorization',
                <bool>[requestAlwaysLocationUsage]) ??
        '';
    return parseLocationAuthorizationStatus(requestLocationServiceResult);
  }

  @override
  Future<LocationAuthorizationStatus> getLocationServiceAuthorization() async {
    final String getLocationServiceResult = await methodChannel
            .invokeMethod<String>('getLocationServiceAuthorization') ??
        '';
    return parseLocationAuthorizationStatus(getLocationServiceResult);
  }
}
