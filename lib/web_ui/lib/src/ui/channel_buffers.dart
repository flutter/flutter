// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

/// A callback for [ChannelBuffers.drain], called as it pops stored messages.
typedef DrainChannelCallback = Future<void> Function(ByteData, PlatformMessageResponseCallback);

/// Web implementation of [ChannelBuffers].  Currently it just drops all messages
/// to match legacy behavior and acts as if all caches are size zero.
class ChannelBuffers {
  /// Always returns true to denote an overflow.
  bool push(String channel, ByteData data, PlatformMessageResponseCallback callback) {
    callback(null);
    return true;
  }

  /// Noop in web_ui, caches are always size zero.
  void resize(String channel, int newSize) {}

  /// Remove and process all stored messages for a given channel.
  ///
  /// A noop in web_ui since all caches are size zero.
  Future<void> drain(String channel, DrainChannelCallback callback) async {
  }
}

final ChannelBuffers channelBuffers = ChannelBuffers();
