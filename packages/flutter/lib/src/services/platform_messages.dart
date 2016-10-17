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

void _sendString(String name, String message, void callback(String reply)) {
  Uint8List encoded = UTF8.encoder.convert(message);
  ui.window.sendPlatformMessage(name, encoded.buffer.asByteData(), (ByteData reply) {
    try {
      callback(_decodeUTF8(reply));
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: 'during a platform message response callback',
      ));
    }
  });
}

typedef Future<ByteData> _PlatformMessageHandler(ByteData message);

/// Sends message to and receives messages from the underlying platform.
class PlatformMessages {
  static final Map<String, _PlatformMessageHandler> _handlers =
      <String, _PlatformMessageHandler>{};

  /// Calls the handler registered for the given name.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [ui.window.onPlatformMessage].
  ///
  /// To register a handler for a given message name, see
  /// [setStringMessageHandler] and [setJSONMessageHandler].
  static Future<Null> handlePlatformMessage(
        String name, ByteData data, ui.PlatformMessageResponseCallback callback) async {
    ByteData response;
    try {
      _PlatformMessageHandler handler = _handlers[name];
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

  /// Send a string message to the host application.
  static Future<String> sendString(String name, String message) {
    Completer<String> completer = new Completer<String>();
    _sendString(name, message, (String reply) {
      completer.complete(reply);
    });
    return completer.future;
  }

  /// Sends a JSON-encoded message to the host application and JSON-decodes the response.
  static Future<dynamic> sendJSON(String name, dynamic json) {
    Completer<dynamic> completer = new Completer<dynamic>();
    _sendString(name, JSON.encode(json), (String reply) {
      completer.complete(_decodeJSON(reply));
    });
    return completer.future;
  }

  /// Set a callback for receiving binary messages from the platform.
  ///
  /// The given callback will replace the currently registered callback (if any).
  static void setBinaryMessageHandler(String name, Future<ByteData> handler(ByteData message)) {
    _handlers[name] = handler;
  }

  /// Set a callback for receiving string messages from the platform.
  ///
  /// The given callback will replace the currently registered callback (if any).
  static void setStringMessageHandler(String name, Future<String> handler(String message)) {
    setBinaryMessageHandler(name, (ByteData message) async {
      return _encodeUTF8(await handler(_decodeUTF8(message)));
    });
  }

  /// Set a callback for receiving JSON messages from the platform.
  ///
  /// Messages received are decoded as JSON before being passed to the given
  /// callback. The result of the callback is encoded as JSON before being
  /// returned as the response to the message.
  ///
  /// The given callback will replace the currently registered callback (if any).
  static void setJSONMessageHandler(String name, Future<dynamic> handler(dynamic message)) {
    setStringMessageHandler(name, (String message) async {
      return _encodeJSON(await handler(_decodeJSON(message)));
    });
  }
}
