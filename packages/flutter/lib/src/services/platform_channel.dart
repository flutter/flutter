// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'message_codecs.dart';
import 'platform_messages.dart';

/// A named channel for communicating with platform plugins using asynchronous
/// message passing.
///
/// Messages are encoded into binary before being sent, and binary messages
/// received are decoded into Dart values. The [MessageCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a FlutterMessageChannel counterpart of this channel on the
/// platform side. The Dart type of messages sent and received is [T],
/// but only the values supported by the specified [MessageCodec] can be used.
///
/// The identity of the channel is given by its name, so other uses of that name
/// with may interfere with this channel's communication. Specifically, at most
/// one message handler can be registered with the channel name at any given
/// time.
class PlatformMessageChannel<T> {
  /// Creates a [PlatformMessageChannel] with the specified [name] and [codec].
  ///
  /// Neither [name] nor [codec] may be `null`.
  PlatformMessageChannel(this.name, this.codec) {
    assert(name != null);
    assert(codec != null);
  }

  /// The logical channel on which communication happens, not `null`.
  final String name;

  /// The message codec used by this channel, not `null`.
  final MessageCodec<T> codec;

  /// Sends the specified [message] to the platform plugins on this channel.
  ///
  /// Returns a [Future] which completes to the received and decoded response,
  /// or to a [FormatException], if encoding or decoding fails.
  Future<T> send(T message) async {
    return codec.decodeMessage(
      await PlatformMessages.sendBinary(name, codec.encodeMessage(message))
    );
  }

  /// Sets a callback for receiving messages from the platform plugins on this
  /// channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel's name.
  ///
  /// The handler's return value, if non-null, is sent back to the platform
  /// plugins as a response.
  void setMessageHandler(Future<T> handler(T message)) {
    PlatformMessages.setBinaryMessageHandler(name, (ByteData message) async {
      return codec.encodeMessage(await handler(codec.decodeMessage(message)));
    });
  }

  /// Sets a mock callback for intercepting messages sent on this channel.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// this channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  void setMockMessageHandler(Future<T> handler(T message)) {
    if (handler == null) {
      PlatformMessages.setMockBinaryMessageHandler(name, null);
    } else {
      PlatformMessages.setMockBinaryMessageHandler(name, (ByteData message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }
}

/// A named channel for communicating with platform plugins using asynchronous
/// method calls and event streams.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a FlutterMethodChannel counterpart of this channel on the
/// platform side. The Dart type of messages sent and received is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
///
/// The identity of the channel is given by its name, so other uses of that name
/// with may interfere with this channel's communication.
class PlatformMethodChannel {
  /// Creates a [PlatformMethodChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  ///
  /// Neither [name] nor [codec] may be `null`.
  PlatformMethodChannel(this.name, [this.codec = const StandardMethodCodec()]) {
    assert(name != null);
    assert(codec != null);
  }

  /// The logical channel on which communication happens, not `null`.
  final String name;

  /// The message codec used by this channel, not `null`.
  final MethodCodec codec;

  /// Invokes a [method] on this channel with the specified [arguments].
  ///
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result (possibly `null`), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [FormatException], if encoding or decoding failed.
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    assert(method != null);
    return codec.decodeEnvelope(await PlatformMessages.sendBinary(
        name,
        codec.encodeMethodCall(method, arguments),
    ));
  }

  /// Sets up a broadcast stream for receiving events on this channel.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  /// * a decoded data event (possibly `null`) for each successful event
  /// received from the platform plugin;
  /// * an error event containing a [PlatformException] for each error event
  /// received from the platform plugin;
  /// * an error event containing a [FormatException] for each event received
  /// where decoding fails;
  /// * an error event containing a [PlatformException] or [FormatException]
  /// whenever stream setup fails (stream setup is done only when listener
  /// count changes from 0 to 1).
  ///
  /// Notes for platform plugin implementers:
  ///
  /// Plugins must expose methods named `listen` and `cancel` suitable for
  /// invocations by [invokeMethod]. Both methods are invoked with the specified
  /// [arguments].
  ///
  /// Following the semantics of broadcast streams, `listen` will be called as
  /// the first listener registers with the returned stream, and `cancel` when
  /// the last listener cancels its registration. This pattern may repeat
  /// indefinitely. Platform plugins should consume no stream-related resources
  /// while listener count is zero.
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    StreamController<dynamic> controller;
    controller = new StreamController<dynamic>.broadcast(
        onListen: () async {
          PlatformMessages.setBinaryMessageHandler(
              name,
                  (ByteData reply) async {
                if (reply == null) {
                  controller.close();
                } else {
                  try {
                    controller.add(codec.decodeEnvelope(reply));
                  } catch (e) {
                    controller.addError(e);
                  }
                }
              }
          );
          try {
            await invokeMethod('listen', arguments);
          } catch (e) {
            PlatformMessages.setBinaryMessageHandler(name, null);
            controller.addError(e);
          }
        }, onCancel: () async {
      PlatformMessages.setBinaryMessageHandler(name, null);
      try {
        await invokeMethod('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'services library',
            context: 'while de-activating platform stream on channel $name',
        ));
      }
    }
    );
    return controller.stream;
  }
}
