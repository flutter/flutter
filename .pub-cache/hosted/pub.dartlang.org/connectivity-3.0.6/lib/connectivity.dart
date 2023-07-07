// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';

// Export enums from the platform_interface so plugin users can use them directly.
export 'package:connectivity_platform_interface/connectivity_platform_interface.dart'
    show ConnectivityResult, LocationAuthorizationStatus;

/// Discover network connectivity configurations: Distinguish between WI-FI and cellular, check WI-FI status and more.
class Connectivity {
  /// Constructs a singleton instance of [Connectivity].
  ///
  /// [Connectivity] is designed to work as a singleton.
  // When a second instance is created, the first instance will not be able to listen to the
  // EventChannel because it is overridden. Forcing the class to be a singleton class can prevent
  // misuse of creating a second instance from a programmer.
  factory Connectivity() {
    if (_singleton == null) {
      _singleton = Connectivity._();
    }
    return _singleton!;
  }

  Connectivity._();

  static Connectivity? _singleton;

  static ConnectivityPlatform get _platform => ConnectivityPlatform.instance;

  /// Fires whenever the connectivity state changes.
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _platform.onConnectivityChanged;
  }

  /// Checks the connection status of the device.
  ///
  /// Do not use the result of this function to decide whether you can reliably
  /// make a network request. It only gives you the radio status.
  ///
  /// Instead listen for connectivity changes via [onConnectivityChanged] stream.
  Future<ConnectivityResult> checkConnectivity() {
    return _platform.checkConnectivity();
  }
}
