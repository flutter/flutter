// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html show window;

import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';
import 'package:connectivity_for_web/connectivity_for_web.dart';

/// The web implementation of the ConnectivityPlatform of the Connectivity plugin.
class DartHtmlConnectivityPlugin extends ConnectivityPlugin {
  /// Checks the connection status of the device.
  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return html.window.navigator.onLine ?? false
        ? ConnectivityResult.wifi
        : ConnectivityResult.none;
  }

  StreamController<ConnectivityResult>? _connectivityResult;

  /// Returns a Stream of ConnectivityResults changes.
  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    if (_connectivityResult == null) {
      _connectivityResult = StreamController<ConnectivityResult>.broadcast();
      // Fallback to dart:html window.onOnline / window.onOffline
      html.window.onOnline.listen((event) {
        _connectivityResult!.add(ConnectivityResult.wifi);
      });
      html.window.onOffline.listen((event) {
        _connectivityResult!.add(ConnectivityResult.none);
      });
    }
    return _connectivityResult!.stream;
  }
}
