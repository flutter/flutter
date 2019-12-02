// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

import 'plugin_registry.dart';

/// A named channel for sending events to the framework-side using streams.
///
/// This is the platform-side equivalent of [EventChannel]. Whereas
/// [EventChannel] receives a stream of events from platform plugins, this
/// channel sends a stream of events to the handler listening on the
/// framework-side.
///
/// The channel [name] must not be null. If no [codec] is provided, then
/// [StandardMethodCodec] is used. If no [binaryMessenger] is provided, then
/// [pluginBinaryMessenger], which sends messages to the framework-side,
/// is used.
class PluginEventChannel<T> {
  /// Creates a new plugin event channel.
  const PluginEventChannel(
    this.name, [
    this.codec = const StandardMethodCodec(),
    BinaryMessenger binaryMessenger,
  ])  : assert(name != null),
        assert(codec != null),
        _binaryMessenger = binaryMessenger;

  /// The logical channel on which communication happens.
  ///
  /// This must not be null.
  final String name;

  /// The message codec used by this channel.
  ///
  /// This must not be null. This defaults to [StandardMethodCodec].
  final MethodCodec codec;

  /// The messenger used by this channel to send platform messages.
  ///
  /// This must not be null. If not provided, defaults to
  /// [pluginBinaryMessenger], which sends messages from the platform-side
  /// to the framework-side.
  BinaryMessenger get binaryMessenger =>
      _binaryMessenger ?? pluginBinaryMessenger;
  final BinaryMessenger _binaryMessenger;

  /// Set the stream controller for this event channel.
  set controller(StreamController<T> controller) {
    final _EventChannelHandler<T> handler = _EventChannelHandler<T>(
      name,
      codec,
      controller,
      binaryMessenger,
    );
    binaryMessenger.setMessageHandler(
        name, controller == null ? null : handler.handle);
  }
}

class _EventChannelHandler<T> {
  _EventChannelHandler(this.name, this.codec, this.controller, this.messenger);

  final String name;
  final MethodCodec codec;
  final StreamController<T> controller;
  final BinaryMessenger messenger;

  StreamSubscription<T> subscription;

  Future<ByteData> handle(ByteData message) {
    final MethodCall call = codec.decodeMethodCall(message);
    switch (call.method) {
      case 'listen':
        return _listen();
      case 'cancel':
        return _cancel();
    }
    return null;
  }

  // TODO(hterkelsen): Support arguments.
  Future<ByteData> _listen() async {
    if (subscription != null) {
      await subscription.cancel();
    }
    subscription = controller.stream.listen((dynamic event) {
      messenger.send(name, codec.encodeSuccessEnvelope(event));
    }, onError: (dynamic error) {
      messenger.send(name,
          codec.encodeErrorEnvelope(code: 'error', message: error.toString()));
    });

    return codec.encodeSuccessEnvelope(null);
  }

  // TODO(hterkelsen): Support arguments.
  Future<ByteData> _cancel() async {
    if (subscription == null) {
      return codec.encodeErrorEnvelope(
          code: 'error', message: 'No active stream to cancel.');
    }
    await subscription.cancel();
    subscription = null;
    return codec.encodeSuccessEnvelope(null);
  }
}
