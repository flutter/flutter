import 'dart:async';

import 'package:flutter/services.dart';

import 'plugin_registry.dart';

/// A named channel for sending events to the framework-side using streams.
///
/// This is the platform-side equivalent of [EventChannel]. Whereas
/// [EventChannel] receives a stream of events from platform plugins, this
/// channel sends a stream of events to the handler listening on the
/// framework-side.
class PluginEventChannel {
  PluginEventChannel(
    this.name, [
    this.codec = const StandardMethodCodec(),
    BinaryMessenger binaryMessenger,
  ])  : assert(name != null),
        assert(codec != null),
        _binaryMessenger = binaryMessenger;

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The message codec used by this channel, not null.
  final MethodCodec codec;

  /// The messenger used by this channel to send platform messages, not null.
  BinaryMessenger get binaryMessenger =>
      _binaryMessenger ?? pluginBinaryMessenger;
  final BinaryMessenger _binaryMessenger;

  /// Set the stream controller for this event channel.
  set controller(StreamController controller) {
    final _EventChannelHandler handler = _EventChannelHandler(
      name,
      codec,
      controller,
      binaryMessenger,
    );
    binaryMessenger.setMessageHandler(
        name, controller == null ? null : handler.handle);
  }
}

class _EventChannelHandler {
  _EventChannelHandler(this.name, this.codec, this.controller, this.messenger);

  final String name;
  final MethodCodec codec;
  final StreamController controller;
  final BinaryMessenger messenger;

  StreamSubscription subscription;

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
