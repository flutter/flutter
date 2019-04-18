// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'binding.dart' show ServicesBinding;
import 'platform_channel.dart';

typedef _MessageHandler = Future<ByteData> Function(ByteData message);

/// Sends binary messages to and receives binary messages from platform plugins.
///
/// See also:
///
///  * [BasicMessageChannel], which provides basic messaging services similar to
///    `BinaryMessages`, but with pluggable message codecs in support of sending
///    strings or semi-structured messages.
///  * [MethodChannel], which provides platform communication using asynchronous
///    method calls.
///  * [EventChannel], which provides platform communication using event streams.
///  * <https://flutter.dev/platform-channels/>
class BinaryMessages {
  BinaryMessages._();

  // Handlers for incoming messages from platform plugins.
  static final Map<String, _MessageHandler> _handlers =
      <String, _MessageHandler>{};

  // Mock handlers that intercept and respond to outgoing messages.
  static final Map<String, _MessageHandler> _mockHandlers =
      <String, _MessageHandler>{};

  static Future<ByteData> _sendPlatformMessage(String channel, ByteData message) {
    final Completer<ByteData> completer = Completer<ByteData>();
    // ui.window is accessed directly instead of using ServicesBinding.instance.window
    // because this method might be invoked before any binding is initialized.
    // This issue was reported in #27541. It is not ideal to statically access
    // ui.window because the Window may be dependency injected elsewhere with
    // a different instance. However, static access at this location seems to be
    // the least bad option.
    ui.window.sendPlatformMessage(channel, message, (ByteData reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'during a platform message response callback',
        ));
      }
    });
    return completer.future;
  }

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [Window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [setMessageHandler].
  static Future<void> handlePlatformMessage(
    String channel,
    ByteData data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    ByteData response;
    try {
      final _MessageHandler handler = _handlers[channel];
      if (handler != null)
        response = await handler(data);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: 'during a platform message callback',
      ));
    } finally {
      callback(response);
    }
  }

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded, in
  /// binary form.
  static Future<ByteData> send(String channel, ByteData message) {
    final _MessageHandler handler = _mockHandlers[channel];
    if (handler != null)
      return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any. To remove the handler, pass null as the `handler`
  /// argument.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  static void setMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _handlers.remove(channel);
    else
      _handlers[channel] = handler;
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass null as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  static void setMockMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }
}
