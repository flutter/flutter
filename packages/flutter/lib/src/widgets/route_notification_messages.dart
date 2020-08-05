// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'router.dart';

/// Messages for route change notifications.
class RouteNotificationMessages {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  RouteNotificationMessages._();

  /// Notifies the platform for a route information change.
  ///
  /// See also:
  ///
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests.
  static void notifyRouteInformationChange(RouteInformation routeInformation) {
    SystemChannels.navigation.invokeMethod<void>(
      'routeInformationUpdated',
      <String, dynamic>{
        'routeInformation': _convertRouteInformationToMap(routeInformation),
      },
    );
  }

  /// When the engine is Web notify the platform for a route change.
  static void maybeNotifyRouteChange(String routeName, String previousRouteName) {
    if(kIsWeb) {
      _notifyRouteChange(routeName, previousRouteName);
    } else {
      // No op.
    }
  }

  static Map<String, dynamic> _convertRouteInformationToMap(RouteInformation routeInformation) {
    return <String, dynamic>{
      'location': routeInformation.location,
      'state': routeInformation.state,
    };
  }

  /// Notifies the platform of a route change.
  ///
  /// See also:
  ///
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests.
  static void _notifyRouteChange(String routeName, String previousRouteName) {
    SystemChannels.navigation.invokeMethod<void>(
      'routeUpdated',
      <String, dynamic>{
        'previousRouteName': previousRouteName,
        'routeName': routeName,
      },
    );
  }
}
