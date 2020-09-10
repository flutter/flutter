// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';

import 'system_channels.dart';

/// Controls specific aspects of the system navigation stack.
class SystemNavigator {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  SystemNavigator._();

  /// Removes the topmost Flutter instance, presenting what was before
  /// it.
  ///
  /// On Android, removes this activity from the stack and returns to
  /// the previous activity.
  ///
  /// On iOS, calls `popViewControllerAnimated:` if the root view
  /// controller is a `UINavigationController`, or
  /// `dismissViewControllerAnimated:completion:` if the top view
  /// controller is a `FlutterViewController`.
  ///
  /// The optional `animated` parameter is ignored on all platforms
  /// except iOS where it is an argument to the aforementioned
  /// methods.
  ///
  /// This method should be preferred over calling `dart:io`'s [exit]
  /// method, as the latter may cause the underlying platform to act
  /// as if the application had crashed.
  static Future<void> pop({bool? animated}) async {
    await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop', animated);
  }

  /// Notifies the platform for a route information change.
  ///
  /// On Web, creates a new browser history entry and update URL with the route
  /// information.
  static void routeInformationUpdated({
    required String location,
    Object? state
  }) {
    SystemChannels.navigation.invokeMethod<void>(
      'routeInformationUpdated',
      <String, dynamic>{
        'location': location,
        'state': state,
      },
    );
  }

  /// Notifies the platform of a route change.
  ///
  /// On Web, updates the URL bar with the [routeName].
  static void routeUpdated({
    String? routeName,
    String? previousRouteName
  }) {
    SystemChannels.navigation.invokeMethod<void>(
      'routeUpdated',
      <String, dynamic>{
        'previousRouteName': previousRouteName,
        'routeName': routeName,
      },
    );
  }
}
