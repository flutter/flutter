// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// A function which takes a platform message and asynchronously returns an encoded response.
typedef MessageHandler = Future<ByteData> Function(ByteData message);

/// A messenger which sends binary data across the Flutter platform barrier.
///
/// This class also registers handlers for incoming messages.
abstract class BinaryMessenger {
  /// A const constructor to allow subclasses to be const.
  const BinaryMessenger();

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [Window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [setMessageHandler].
  Future<void> handlePlatformMessage(String channel, ByteData data, ui.PlatformMessageResponseCallback callback);

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded,
  /// in binary form.
  Future<ByteData> send(String channel, ByteData message);

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any. To remove the handler, pass null as the [handler]
  /// argument.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  void setMessageHandler(String channel, Future<ByteData> handler(ByteData message));

  /// Set a mock callback for intercepting messages from the [send] method on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass null as the
  /// [handler] argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  void setMockMessageHandler(String channel, Future<ByteData> handler(ByteData message));
}

/// The default implementation of [BinaryMessenger].
///
/// This messenger sends messages from the app-side to the platform-side and
/// dispatches incoming messages from the platform-side to the appropriate
/// handler.
class _DefaultBinaryMessenger extends BinaryMessenger {
  const _DefaultBinaryMessenger._();

  // Handlers for incoming messages from platform plugins.
  // This is static so that this class can have a const constructor.
  static final Map<String, MessageHandler> _handlers =
      <String, MessageHandler>{};

  // Mock handlers that intercept and respond to outgoing messages.
  // This is static so that this class can have a const constructor.
  static final Map<String, MessageHandler> _mockHandlers =
      <String, MessageHandler>{};

  Future<ByteData> _sendPlatformMessage(String channel, ByteData message) {
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
          context: ErrorDescription('during a platform message response callback'),
        ));
      }
    });
    return completer.future;
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    ByteData response;
    try {
      final MessageHandler handler = _handlers[channel];
      if (handler != null)
        response = await handler(data);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during a platform message callback'),
      ));
    } finally {
      callback(response);
    }
  }


  @override
  Future<ByteData> send(String channel, ByteData message) {
    final MessageHandler handler = _mockHandlers[channel];
    if (handler != null)
      return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler handler) {
    if (handler == null)
      _handlers.remove(channel);
    else
      _handlers[channel] = handler;
  }

  @override
  void setMockMessageHandler(String channel, MessageHandler handler) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }
}

/// The default instance of [BinaryMessenger].
///
/// This is used to send messages from the application to the platform, and
/// keeps track of which handlers have been registered on each channel so
/// it may dispatch incoming messages to the registered handler.
const BinaryMessenger defaultBinaryMessenger = _DefaultBinaryMessenger._();
