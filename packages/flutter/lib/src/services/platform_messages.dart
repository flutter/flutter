// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

ByteData _encodeUTF8(String message) {
  if (message == null)
    return null;
  Uint8List encoded = UTF8.encoder.convert(message);
  return encoded.buffer.asByteData();
}

String _decodeUTF8(ByteData message) {
  return message != null ? UTF8.decoder.convert(message.buffer.asUint8List()) : null;
}

String _encodeJSON(dynamic message) {
  return message != null ? JSON.encode(message) : null;
}

dynamic _decodeJSON(String message) {
  return message != null ? JSON.decode(message) : null;
}

typedef Future<ByteData> _PlatformMessageHandler(ByteData message);

/// Sends message to and receives messages from platform plugins.
///
/// See: <https://flutter.io/platform-services/>
class PlatformMessages {
  PlatformMessages._();

  // Handlers for incoming messages from platform plugins.
  static final Map<String, _PlatformMessageHandler> _handlers =
      <String, _PlatformMessageHandler>{};

  // Mock handlers that intercept and respond to outgoing messages.
  static final Map<String, _PlatformMessageHandler> _mockHandlers =
      <String, _PlatformMessageHandler>{};

  static Future<ByteData> _sendPlatformMessage(String channel, ByteData message) {
    final Completer<ByteData> completer = new Completer<ByteData>();
    ui.window.sendPlatformMessage(channel, message, (ByteData reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
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
  /// from [ui.window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see
  /// [setStringMessageHandler] and [setJSONMessageHandler].
  static Future<Null> handlePlatformMessage(
        String channel, ByteData data, ui.PlatformMessageResponseCallback callback) async {
    ByteData response;
    try {
      _PlatformMessageHandler handler = _handlers[channel];
      if (handler != null)
        response = await handler(data);
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
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
  static Future<ByteData> sendBinary(String channel, ByteData message) {
    final _PlatformMessageHandler handler = _mockHandlers[channel];
    if (handler != null)
      return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  /// Send a string message to the platform plugins on the given channel.
  ///
  /// The message is encoded as UTF-8.
  ///
  /// Returns a [Future] which completes to the received response, decoded as a
  /// UTF-8 string, or to an error, if the decoding fails.
  static Future<String> sendString(String channel, String message) async {
    return _decodeUTF8(await sendBinary(channel, _encodeUTF8(message)));
  }

  /// Send a JSON-encoded message to the platform plugins on the given channel.
  ///
  /// The message is encoded as JSON, then the JSON is encoded as UTF-8.
  ///
  /// Returns a [Future] which completes to the received response, decoded as a
  /// UTF-8-encoded JSON representation of a JSON value (a [String], [bool],
  /// [double], [List], or [Map]), or to an error, if the decoding fails.
  static Future<dynamic> sendJSON(String channel, dynamic json) async {
    return _decodeJSON(await sendString(channel, _encodeJSON(json)));
  }

  /// Send a method call to the platform plugins on the given channel.
  ///
  /// Method calls are encoded as a JSON object with two keys, `method` with the
  /// string given in the `method` argument, and `args` with the arguments given
  /// in the `args` optional argument, as a JSON list. This JSON object is then
  /// encoded as a UTF-8 string.
  ///
  /// The response from the method call is decoded as UTF-8, then the UTF-8 is
  /// decoded as JSON. The returned [Future] completes to this fully decoded
  /// response, or to an error, if the decoding fails.
  static Future<dynamic> invokeMethod(String channel, String method, [ List<dynamic> args = const <Null>[] ]) {
    return sendJSON(channel, <String, dynamic>{
      'method': method,
      'args': args,
    });
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  static void setBinaryMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    _handlers[channel] = handler;
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, decoding the data as UTF-8.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, encoded as
  /// a UTF-8 string.
  static void setStringMessageHandler(String channel, Future<String> handler(String message)) {
    setBinaryMessageHandler(channel, (ByteData message) async {
      return _encodeUTF8(await handler(_decodeUTF8(message)));
    });
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, decoding the data as UTF-8 JSON.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, encoded as
  /// JSON and then as a UTF-8 string.
  static void setJSONMessageHandler(String channel, Future<dynamic> handler(dynamic message)) {
    setStringMessageHandler(channel, (String message) async {
      return _encodeJSON(await handler(_decodeJSON(message)));
    });
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  static void setMockBinaryMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, decoding them as UTF-8.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, encoded as
  /// UTF-8.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  static void setMockStringMessageHandler(String channel, Future<String> handler(String message)) {
    if (handler == null) {
      setMockBinaryMessageHandler(channel, null);
    } else {
      setMockBinaryMessageHandler(channel, (ByteData message) async {
        return _encodeUTF8(await handler(_decodeUTF8(message)));
      });
    }
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, decoding them as UTF-8 JSON.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, encoded as
  /// UTF-8 JSON.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  static void setMockJSONMessageHandler(String channel, Future<dynamic> handler(dynamic message)) {
    if (handler == null) {
      setMockStringMessageHandler(channel, null);
    } else {
      setMockStringMessageHandler(channel, (String message) async {
        return _encodeJSON(await handler(_decodeJSON(message)));
      });
    }
  }
}
