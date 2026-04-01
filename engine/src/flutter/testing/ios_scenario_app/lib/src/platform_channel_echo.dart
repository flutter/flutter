// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;
import 'dart:ui';

import 'scenario.dart';

/// A scenario which intercepts all messages on the given channel, and sends back
/// the same message to the engine on a channel with the same name.
class EchoPlatformChannelScenario extends Scenario {
  /// Constructor for `EchoPlatformChannelScenario`.
  EchoPlatformChannelScenario(super.view, {required this.channel}) {
    channelBuffers.setListener(channel, _onHandlePlatformMessage);
  }

  /// The name of the channel where all messages should be intercepted.
  final String channel;

  void _onHandlePlatformMessage(ByteData? data, PlatformMessageResponseCallback _) {
    view.platformDispatcher.sendPlatformMessage(channel, data, null);
  }

  @override
  void unmount() {
    channelBuffers.clearListener(channel);
    super.unmount();
  }
}
