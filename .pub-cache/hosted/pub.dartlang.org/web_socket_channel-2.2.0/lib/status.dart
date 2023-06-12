// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Status codes that are defined in the WebSocket spec.
///
/// This library is intended to be imported with a prefix.
///
/// ```dart
/// import 'package:web_socket_channel/web_socket_channel.dart';
/// import 'package:web_socket_channel/status.dart' as status;
///
/// void main() async {
///   var channel = WebSocketChannel.connect(Uri.parse('ws://localhost:1234'));
///   // ...
///   channel.close(status.goingAway);
/// }
/// ```
library web_socket_channel.status;

import 'dart:core';

/// The purpose for which the connection was established has been fulfilled.
const normalClosure = 1000;

/// An endpoint is "going away", such as a server going down or a browser having
/// navigated away from a page.
const goingAway = 1001;

/// An endpoint is terminating the connection due to a protocol error.
const protocolError = 1002;

/// An endpoint is terminating the connection because it has received a type of
/// data it cannot accept.
///
/// For example, an endpoint that understands only text data MAY send this if it
/// receives a binary message).
const unsupportedData = 1003;

/// No status code was present.
///
/// This **must not** be set explicitly by an endpoint.
const noStatusReceived = 1005;

/// The connection was closed abnormally.
///
/// For example, this is used if the connection was closed without sending or
/// receiving a Close control frame.
///
/// This **must not** be set explicitly by an endpoint.
const abnormalClosure = 1006;

/// An endpoint is terminating the connection because it has received data
/// within a message that was not consistent with the type of the message.
///
/// For example, the endpoint may have receieved non-UTF-8 data within a text
/// message.
const invalidFramePayloadData = 1007;

/// An endpoint is terminating the connection because it has received a message
/// that violates its policy.
///
/// This is a generic status code that can be returned when there is no other
/// more suitable status code (such as [unsupportedData] or [messageTooBig]), or
/// if there is a need to hide specific details about the policy.
const policyViolation = 1008;

/// An endpoint is terminating the connection because it has received a message
/// that is too big for it to process.
const messageTooBig = 1009;

/// The client is terminating the connection because it expected the server to
/// negotiate one or more extensions, but the server didn't return them in the
/// response message of the WebSocket handshake.
///
/// The list of extensions that are needed should appear in the close reason.
/// Note that this status code is not used by the server, because it can fail
/// the WebSocket handshake instead.
const missingMandatoryExtension = 1010;

/// The server is terminating the connection because it encountered an
/// unexpected condition that prevented it from fulfilling the request.
const internalServerError = 1011;

/// The connection was closed due to a failure to perform a TLS handshake.
///
/// For example, the server certificate may not have been verified.
///
/// This **must not** be set explicitly by an endpoint.
const tlsHandshakeFailed = 1015;
