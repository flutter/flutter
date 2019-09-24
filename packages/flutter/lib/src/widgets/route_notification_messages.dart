// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'navigator.dart';

/// Messages for route change notifications.
class RouteNotificationMessages {
  RouteNotificationMessages._();

  /// When the engine is Web notify the platform for a route change.
  static void maybeNotifyRouteChange(String methodName, Route<dynamic> route, Route<dynamic> previousRoute) {
    if(kIsWeb) {
      _notifyRouteChange(methodName, route, previousRoute);
    } else {
      // No op.
    }
  }

  /// Notifies the platform of a route change.
  ///
  /// There are three methods: 'routePushed', 'routePopped', 'routeReplaced'.
  ///
  /// See also [SystemChannels.navigation], which handles subsequent navigation
  /// requests.
  static void _notifyRouteChange(String methodName, Route<dynamic> route, Route<dynamic> previousRoute) {
    final String previousRouteName = previousRoute?.settings?.name;
    final String routeName = route?.settings?.name;
    if (previousRouteName != null || routeName != null) {
      SystemChannels.navigation.invokeMethod<void>(
        methodName,
        <String, dynamic>{
          'previousRouteName': previousRouteName,
          'routeName': routeName,
        },
      );
    }
  }
}
