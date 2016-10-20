// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// A service that can be implemented by the host application and the
/// Flutter framework to exchange application-specific messages.
class HostMessages {
  /// Send a message to the host application.
  static Future<String> sendToHost(String channel, [String message = '']) {
    return PlatformMessages.sendString(channel, message);
  }

  /// Sends a JSON-encoded message to the host application and JSON-decodes the response.
  static Future<dynamic> sendJSON(String channel, [dynamic json]) {
    return PlatformMessages.sendJSON(channel, json);
  }

  /// Register a callback for receiving messages from the host application.
  static void addMessageHandler(String channel, Future<String> callback(String message)) {
    PlatformMessages.setStringMessageHandler(channel, callback);
  }

  /// Register a callback for receiving JSON messages from the host application.
  ///
  /// Messages received from the host application are decoded as JSON before
  /// being passed to `callback`. The result of the callback is encoded as JSON
  /// before being returned to the host application.
  static void addJSONMessageHandler(String channel, Future<dynamic> callback(dynamic json)) {
    PlatformMessages.setJSONMessageHandler(channel, callback);
  }
}
