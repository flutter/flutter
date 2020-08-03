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

  /// When the engine is Web notify the platform for a route information change.
  static void maybeNotifyRouteInformationChange(RouteInformation routeInformation, RouteInformation previousRouteInformation) {
    if(kIsWeb) {
      _notifyRouteInformationChange(routeInformation, previousRouteInformation);
    } else {
      // No op.
    }
  }

  /// When the engine is Web notify the platform for a route change.
  static void maybeNotifyRouteChange(String routeName, String previousRouteName) {
    if(kIsWeb) {
      _notifyRouteChange(routeName, previousRouteName);
    } else {
      // No op.
    }
  }

  /// Notifies the platform of a route information change.
  ///
  /// See also:
  ///
  ///  * [SystemChannels.router], which handles subsequent router requests
  static void _notifyRouteInformationChange(RouteInformation routeInformation, RouteInformation previousRouteInformation) {
    SystemChannels.router.invokeMethod<void>(
      'routeInformationUpdated',
      <String, dynamic>{
        'previousRouteName': _convertRouteInformationToMap(previousRouteInformation),
        'routeName': _convertRouteInformationToMap(routeInformation),
      },
    );
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
