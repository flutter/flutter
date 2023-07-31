// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following code is copied from sdk/lib/io/websocket.dart. The "dart:io"
// implementation isn't used directly to support non-"dart:io" applications.
//
// Because it's copied directly, only modifications necessary to support the
// desired public API and to remove "dart:io" dependencies have been made.
//
// This is up-to-date as of sdk revision
// 365f7b5a8b6ef900a5ee23913b7203569b81b175.

// ignore_for_file: constant_identifier_names

/// Web socket status codes used when closing a web socket connection.
abstract class WebSocketStatus {
  static const int NORMAL_CLOSURE = 1000;
  static const int GOING_AWAY = 1001;
  static const int PROTOCOL_ERROR = 1002;
  static const int UNSUPPORTED_DATA = 1003;
  static const int RESERVED_1004 = 1004;
  static const int NO_STATUS_RECEIVED = 1005;
  static const int ABNORMAL_CLOSURE = 1006;
  static const int INVALID_FRAME_PAYLOAD_DATA = 1007;
  static const int POLICY_VIOLATION = 1008;
  static const int MESSAGE_TOO_BIG = 1009;
  static const int MISSING_MANDATORY_EXTENSION = 1010;
  static const int INTERNAL_SERVER_ERROR = 1011;
  static const int RESERVED_1015 = 1015;
}

abstract class WebSocket {
  /// Possible states of the connection.
  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;
}
