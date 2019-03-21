// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:flutter_channels/flutter_channels.dart';

import 'platform_messages.dart';

/// A [BinaryMessenger] which uses [BinaryMessages] to send platform messages.
class _ClientBinaryMessenger extends BinaryMessenger {
  const _ClientBinaryMessenger();

  @override
  Future<ByteData> send(String channel, ByteData message) =>
      BinaryMessages.send(channel, message);

  @override
  void setMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    return BinaryMessages.setMessageHandler(channel, handler);
  }

  @override
  void setMockMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    return BinaryMessages.setMockMessageHandler(channel, handler);
  }
}

/// A named channel for communicating with platform plugins using asynchronous
/// message passing.
///
/// Messages are encoded into binary before being sent, and binary messages
/// received are decoded into Dart values. The [MessageCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a basic message channel counterpart of this channel on the
/// platform side. The Dart type of messages sent and received is [T],
/// but only the values supported by the specified [MessageCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null message is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.io/platform-channels/>
class BasicMessageChannel<T> extends BaseMessageChannel<T> {
  /// Constructs a [BasicMessageChannel] with the default messenger.
  const BasicMessageChannel(String name, MessageCodec<T> codec)
      : super(name, codec, const _ClientBinaryMessenger());
}

/// A named channel for communicating with platform plugins using asynchronous
/// method calls.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a method channel counterpart of this channel on the
/// platform side. The Dart type of arguments and results is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null value is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.io/platform-channels/>
class MethodChannel extends BaseMethodChannel {
  /// Constructs a [MethodChannel] with the default messenger.
  const MethodChannel(String name,
      [MethodCodec codec = const StandardMethodCodec()])
      : super(name, const _ClientBinaryMessenger(), codec);
}

/// A [MethodChannel] that ignores missing platform plugins.
///
/// When [invokeMethod] fails to find the platform plugin, it returns null
/// instead of throwing an exception.
class OptionalMethodChannel extends MethodChannel {
  /// Creates a [MethodChannel] that ignores missing platform plugins.
  const OptionalMethodChannel(String name, [MethodCodec codec = const StandardMethodCodec()])
    : super(name, codec);

  @override
  Future<T> invokeMethod<T>(String method, [ dynamic arguments ]) async {
    try {
      final T result = await super.invokeMethod<T>(method, arguments);
      return result;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<List<T>> invokeListMethod<T>(String method, [ dynamic arguments ]) async {
    final List<dynamic> result = await invokeMethod<List<dynamic>>(method, arguments);
    return result.cast<T>();
  }

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method, [ dynamic arguments ]) async {
    final Map<dynamic, dynamic> result = await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result.cast<K, V>();
  }

}

/// A named channel for communicating with platform plugins using event streams.
///
/// Stream setup requests are encoded into binary before being sent,
/// and binary events and errors received are decoded into Dart values.
/// The [MethodCodec] used must be compatible with the one used by the platform
/// plugin. This can be achieved by creating an `EventChannel` counterpart of
/// this channel on the platform side. The Dart type of events sent and received
/// is `dynamic`, but only values supported by the specified [MethodCodec] can
/// be used.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.io/platform-channels/>
class EventChannel {
  /// Creates an [EventChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  ///
  /// Neither [name] nor [codec] may be null.
  const EventChannel(this.name, [this.codec = const StandardMethodCodec()]);

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The message codec used by this channel, not null.
  final MethodCodec codec;

  /// Sets up a broadcast stream for receiving events on this channel.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  /// * a decoded data event (possibly null) for each successful event
  /// received from the platform plugin;
  /// * an error event containing a [PlatformException] for each error event
  /// received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the [FlutterError] facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  Stream<dynamic> receiveBroadcastStream([ dynamic arguments ]) {
    final MethodChannel methodChannel = MethodChannel(name, codec);
    StreamController<dynamic> controller;
    controller = StreamController<dynamic>.broadcast(onListen: () async {
      BinaryMessages.setMessageHandler(name, (ByteData reply) async {
        if (reply == null) {
          controller.close();
        } else {
          try {
            controller.add(codec.decodeEnvelope(reply));
          } on PlatformException catch (e) {
            controller.addError(e);
          }
        }
        return null;
      });
      try {
        await methodChannel.invokeMethod<void>('listen', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while activating platform stream on channel $name',
        ));
      }
    }, onCancel: () async {
      BinaryMessages.setMessageHandler(name, null);
      try {
        await methodChannel.invokeMethod<void>('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while de-activating platform stream on channel $name',
        ));
      }
    });
    return controller.stream;
  }
}
