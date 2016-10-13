// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

String _decodeUTF8(ByteData data) {
  return data != null ? UTF8.decoder.convert(data.buffer.asUint8List()) : null;
}

dynamic _decodeJSON(String message) {
  return message != null ? JSON.decode(message) : null;
}

void _sendString(String name, String message, void callback(String reply)) {
  Uint8List encoded = UTF8.encoder.convert(message);
  ui.window.sendPlatformMessage(name, encoded.buffer.asByteData(), (ByteData reply) {
    callback(_decodeUTF8(reply));
  });
}

/// Sends messages to the hosting application.
class PlatformMessages {
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
}
