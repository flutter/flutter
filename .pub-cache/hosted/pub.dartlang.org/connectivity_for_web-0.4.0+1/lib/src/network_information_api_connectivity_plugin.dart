// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html show window, NetworkInformation;
import 'dart:js' show allowInterop;
import 'dart:js_util' show setProperty;

import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';
import 'package:connectivity_for_web/connectivity_for_web.dart';
import 'package:flutter/foundation.dart';

import 'utils/connectivity_result.dart';

/// The web implementation of the ConnectivityPlatform of the Connectivity plugin.
class NetworkInformationApiConnectivityPlugin extends ConnectivityPlugin {
  final html.NetworkInformation _networkInformation;

  /// A check to determine if this version of the plugin can be used.
  static bool isSupported() => html.window.navigator.connection != null;

  /// The constructor of the plugin.
  NetworkInformationApiConnectivityPlugin()
      : this.withConnection(html.window.navigator.connection!);

  /// Creates the plugin, with an override of the NetworkInformation object.
  @visibleForTesting
  NetworkInformationApiConnectivityPlugin.withConnection(
      html.NetworkInformation connection)
      : _networkInformation = connection;

  /// Checks the connection status of the device.
  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return networkInformationToConnectivityResult(_networkInformation);
  }

  StreamController<ConnectivityResult>? _connectivityResultStreamController;
  late Stream<ConnectivityResult> _connectivityResultStream;

  /// Returns a Stream of ConnectivityResults changes.
  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    if (_connectivityResultStreamController == null) {
      _connectivityResultStreamController =
          StreamController<ConnectivityResult>();

      // Directly write the 'onchange' function on the networkInformation object.
      setProperty(_networkInformation, 'onchange', allowInterop((_) {
        _connectivityResultStreamController!
            .add(networkInformationToConnectivityResult(_networkInformation));
      }));
      // TODO: Implement the above with _networkInformation.onChange:
      // _networkInformation.onChange.listen((_) {
      //   _connectivityResult
      //       .add(networkInformationToConnectivityResult(_networkInformation));
      // });
      // Once we can detect when to *cancel* a subscription to the _networkInformation
      // onChange Stream upon hot restart.
      // https://github.com/dart-lang/sdk/issues/42679
      _connectivityResultStream =
          _connectivityResultStreamController!.stream.asBroadcastStream();
    }
    return _connectivityResultStream;
  }
}
