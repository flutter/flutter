// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'channel_util.dart';
import 'scenario.dart';

/// A scenario that sends back messages when touches are received.
class TouchesScenario extends Scenario {
  final Map<int, int> _knownDevices = <int, int>{};
  int _sequenceNo = 0;

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
      final int deviceId =
          _knownDevices.putIfAbsent(datum.device, () => _knownDevices.length);
      sendJsonMessage(
        dispatcher: dispatcher,
        channel: 'display_data',
        json: <String, dynamic>{
          'data': _sequenceNo.toString() +
              ',' +
              datum.change.toString() +
              ',device=' +
              deviceId.toString() +
              ',buttons=' +
              datum.buttons.toString(),
        },
      );
      _sequenceNo++;
    }
  }
}
