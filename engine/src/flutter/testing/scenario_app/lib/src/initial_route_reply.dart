// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:ui';

import 'package:scenario_app/src/channel_util.dart';

import 'scenario.dart';

/// A blank page that just sends back to the platform what the set initial
/// route is.
class InitialRouteReply extends Scenario {
  /// Creates the InitialRouteReply.
  ///
  /// The [window] parameter must not be null.
  InitialRouteReply(Window window)
      : assert(window != null),
        super(window);

  @override
  void onBeginFrame(Duration duration) {
    sendJsonMethodCall(
      window: window,
      channel: 'initial_route_test_channel',
      method: window.defaultRouteName,
    );
  }
}
