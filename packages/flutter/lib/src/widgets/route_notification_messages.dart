// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
  ///  * [SystemNavigator.routeInformationUpdated], which handles subsequent
  ///    navigation requests.
  static void notifyRouteInformationChange(RouteInformation routeInformation) {
    SystemNavigator.routeInformationUpdated(
      location: routeInformation.location,
      state: routeInformation.state,
    );
  }

  /// When the engine is Web notify the platform for a route change.
  static void maybeNotifyRouteChange(String routeName, String previousRouteName) {
    SystemNavigator.routeUpdated(
      routeName: routeName,
      previousRouteName: previousRouteName
    );
  }
}
