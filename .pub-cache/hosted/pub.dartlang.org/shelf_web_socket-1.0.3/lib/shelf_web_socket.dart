// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'src/web_socket_handler.dart';

/// Creates a Shelf handler that upgrades HTTP requests to WebSocket
/// connections.
///
/// Only valid WebSocket upgrade requests are upgraded. If a request doesn't
/// look like a WebSocket upgrade request, a 404 Not Found is returned; if a
/// request looks like an upgrade request but is invalid, a 400 Bad Request is
/// returned; and if a request is a valid upgrade request but has an origin that
/// doesn't match [allowedOrigins] (see below), a 403 Forbidden is returned.
/// This means that this can be placed first in a [Cascade] and only upgrade
/// requests will be handled.
///
/// The [onConnection] must take a [WebSocketChannel] as its first argument. It
/// may also take a string, the [WebSocket subprotocol][], as its second
/// argument. The subprotocol is determined by looking at the client's
/// `Sec-WebSocket-Protocol` header and selecting the first entry that also
/// appears in [protocols]. If no subprotocols are shared between the client and
/// the server, `null` will be passed instead and no subprotocol heaader will be
/// sent to the client which may cause it to disconnect.
///
/// [WebSocket subprotocol]: https://tools.ietf.org/html/rfc6455#section-1.9
///
/// If [allowedOrigins] is passed, browser connections will only be accepted if
/// they're made by a script from one of the given origins. This ensures that
/// malicious scripts running in the browser are unable to fake a WebSocket
/// handshake. Note that non-browser programs can still make connections freely.
/// See also the WebSocket spec's discussion of [origin considerations][].
///
/// [origin considerations]: https://tools.ietf.org/html/rfc6455#section-10.2
///
/// If [pingInterval] is specified, it will get passed to the created
/// channel instance, enabling round-trip disconnect detection.
/// See [WebSocketChannel] for more details.
Handler webSocketHandler(Function onConnection,
    {Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval}) {
  if (onConnection is! void Function(Never, Never)) {
    final innerOnConnection = onConnection;
    // ignore: inference_failure_on_untyped_parameter
    onConnection = (webSocket, _) => innerOnConnection(webSocket);
  }

  return WebSocketHandler(
    onConnection,
    protocols?.toSet(),
    allowedOrigins?.map((origin) => origin.toLowerCase()).toSet(),
    pingInterval,
  ).handle;
}
