// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/enums.dart';
import 'src/method_channel_connectivity.dart';

export 'src/enums.dart';

/// The interface that implementations of connectivity must implement.
///
/// Platform implementations should extend this class rather than implement it as `Connectivity`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ConnectivityPlatform] methods.
abstract class ConnectivityPlatform extends PlatformInterface {
  /// Constructs a ConnectivityPlatform.
  ConnectivityPlatform() : super(token: _token);

  static final Object _token = Object();

  static ConnectivityPlatform _instance = MethodChannelConnectivity();

  /// The default instance of [ConnectivityPlatform] to use.
  ///
  /// Defaults to [MethodChannelConnectivity].
  static ConnectivityPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ConnectivityPlatform] when they register themselves.
  static set instance(ConnectivityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks the connection status of the device.
  Future<ConnectivityResult> checkConnectivity() {
    throw UnimplementedError('checkConnectivity() has not been implemented.');
  }

  /// Returns a Stream of ConnectivityResults changes.
  Stream<ConnectivityResult> get onConnectivityChanged {
    throw UnimplementedError(
        'get onConnectivityChanged has not been implemented.');
  }

  /// Obtains the wifi name (SSID) of the connected network
  Future<String?> getWifiName() {
    throw UnimplementedError('getWifiName() has not been implemented.');
  }

  /// Obtains the wifi BSSID of the connected network.
  Future<String?> getWifiBSSID() {
    throw UnimplementedError('getWifiBSSID() has not been implemented.');
  }

  /// Obtains the IP address of the connected wifi network
  Future<String?> getWifiIP() {
    throw UnimplementedError('getWifiIP() has not been implemented.');
  }

  /// Request to authorize the location service (Only on iOS).
  Future<LocationAuthorizationStatus> requestLocationServiceAuthorization(
      {bool requestAlwaysLocationUsage = false}) {
    throw UnimplementedError(
        'requestLocationServiceAuthorization() has not been implemented.');
  }

  /// Get the current location service authorization (Only on iOS).
  Future<LocationAuthorizationStatus> getLocationServiceAuthorization() {
    throw UnimplementedError(
        'getLocationServiceAuthorization() has not been implemented.');
  }
}
