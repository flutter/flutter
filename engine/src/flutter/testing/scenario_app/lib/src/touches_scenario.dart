// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui';

import 'scenario.dart';

/// A scenario that sends back messages when touches are received.
class TouchesScenario extends Scenario {
  /// Constructor for `TouchesScenario`.
  TouchesScenario(Window window) : super(window);

  @override
  void onPointerDataPacket(PointerDataPacket packet) {
    window.sendPlatformMessage(
      'touches_scenario',
      utf8.encoder
          .convert(const JsonCodec().encode(<String, dynamic>{
            'change': packet.data[0].change.toString(),
          }))
          .buffer
          .asByteData(),
      null,
    );
  }
}
