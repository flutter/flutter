// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../types/javascript_channel.dart';
import '../types/javascript_message.dart';

/// Utility class for managing named JavaScript channels and forwarding incoming
/// messages on the correct channel.
class JavascriptChannelRegistry {
  /// Constructs a [JavascriptChannelRegistry] initializing it with the given
  /// set of [JavascriptChannel]s.
  JavascriptChannelRegistry(Set<JavascriptChannel>? channels) {
    updateJavascriptChannelsFromSet(channels);
  }

  /// Maps a channel name to a channel.
  final Map<String, JavascriptChannel> channels = <String, JavascriptChannel>{};

  /// Invoked when a JavaScript channel message is received.
  void onJavascriptChannelMessage(String channel, String message) {
    final JavascriptChannel? javascriptChannel = channels[channel];

    if (javascriptChannel == null) {
      throw ArgumentError('No channel registered with name $channel.');
    }

    javascriptChannel.onMessageReceived(JavascriptMessage(message));
  }

  /// Updates the set of [JavascriptChannel]s with the new set.
  void updateJavascriptChannelsFromSet(Set<JavascriptChannel>? channels) {
    this.channels.clear();
    if (channels == null) {
      return;
    }

    for (final JavascriptChannel channel in channels) {
      this.channels[channel.name] = channel;
    }
  }
}
