// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'dart:ui';

import 'channel_util.dart';
import 'scenario.dart';

/// A scenario that sends back messages when touches are received.
class TouchesScenario extends Scenario {
  /// Constructor for `TouchesScenario`.
  TouchesScenario(PlatformDispatcher dispatcher) : super(dispatcher);

  @override
  void onBeginFrame(Duration duration) {
    // It is necessary to render frames for touch events to work properly on iOS
    final Scene scene = SceneBuilder().build();
    window.render(scene);
    scene.dispose();
  }

  @override
  void onPointerDataPacket(PointerDataPacket packet) {
    for (final PointerData datum in packet.data) {
      sendJsonMessage(
        dispatcher: dispatcher,
        channel: 'display_data',
        json: <String, dynamic>{
          'data': datum.change.toString() + ':' + datum.buttons.toString(),
        },
      );
    }
  }
}
