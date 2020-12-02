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
  void onPointerDataPacket(PointerDataPacket packet) {
    sendJsonMessage(
      dispatcher: dispatcher,
      channel: 'display_data',
      json: <String, dynamic>{
      'data': packet.data[0].change.toString(),
      },
    );
  }
}
