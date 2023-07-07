// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A class that exposes a handler for upgrading WebSocket requests.
class WebSocketHandler {
  /// The function to call when a request is upgraded.
  final Function _onConnection;

  /// The set of protocols the user supports, or `null`.
  final Set<String>? _protocols;

  /// The set of allowed browser origin connections, or `null`..
  final Set<String>? _allowedOrigins;

  /// The ping interval used for verifying connection, or `null`.
  final Duration? _pingInterval;

  WebSocketHandler(this._onConnection, this._protocols, this._allowedOrigins,
      this._pingInterval);

  /// The [Handler].
  Response handle(Request request) {
    if (request.method != 'GET') return _notFound();

    final connection = request.headers['Connection'];
    if (connection == null) return _notFound();
    final tokens =
        connection.toLowerCase().split(',').map((token) => token.trim());
    if (!tokens.contains('upgrade')) return _notFound();

    final upgrade = request.headers['Upgrade'];
    if (upgrade == null) return _notFound();
    if (upgrade.toLowerCase() != 'websocket') return _notFound();

    final version = request.headers['Sec-WebSocket-Version'];
    if (version == null) {
      return _badRequest('missing Sec-WebSocket-Version header.');
    } else if (version != '13') {
      return _notFound();
    }

    if (request.protocolVersion != '1.1') {
      return _badRequest('unexpected HTTP version '
          '"${request.protocolVersion}".');
    }

    final key = request.headers['Sec-WebSocket-Key'];
    if (key == null) return _badRequest('missing Sec-WebSocket-Key header.');

    if (!request.canHijack) {
      throw ArgumentError('webSocketHandler may only be used with a server '
          'that supports request hijacking.');
    }

    // The Origin header is always set by browser connections. By filtering out
    // unexpected origins, we ensure that malicious JavaScript is unable to fake
    // a WebSocket handshake.
    final origin = request.headers['Origin'];
    if (origin != null &&
        _allowedOrigins != null &&
        !_allowedOrigins!.contains(origin.toLowerCase())) {
      return _forbidden('invalid origin "$origin".');
    }

    final protocol = _chooseProtocol(request);
    request.hijack((channel) {
      final sink = utf8.encoder.startChunkedConversion(channel.sink)
        ..add('HTTP/1.1 101 Switching Protocols\r\n'
            'Upgrade: websocket\r\n'
            'Connection: Upgrade\r\n'
            'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(key)}\r\n');
      if (protocol != null) sink.add('Sec-WebSocket-Protocol: $protocol\r\n');
      sink.add('\r\n');

      _onConnection(
          WebSocketChannel(channel, pingInterval: _pingInterval), protocol);
    });
  }

  /// Selects a subprotocol to use for the given connection.
  ///
  /// If no matching protocol can be found, returns `null`.
  String? _chooseProtocol(Request request) {
    final requestProtocols = request.headers['Sec-WebSocket-Protocol'];
    if (requestProtocols == null) return null;
    if (_protocols == null) return null;
    for (var requestProtocol in requestProtocols.split(',')) {
      requestProtocol = requestProtocol.trim();
      if (_protocols!.contains(requestProtocol)) return requestProtocol;
    }
    return null;
  }

  /// Returns a 404 Not Found response.
  Response _notFound() => _htmlResponse(
      404, '404 Not Found', 'Only WebSocket connections are supported.');

  /// Returns a 400 Bad Request response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _badRequest(String message) => _htmlResponse(
      400, '400 Bad Request', 'Invalid WebSocket upgrade request: $message');

  /// Returns a 403 Forbidden response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _forbidden(String message) => _htmlResponse(
      403, '403 Forbidden', 'WebSocket upgrade refused: $message');

  /// Creates an HTTP response with the given [statusCode] and an HTML body with
  /// [title] and [message].
  ///
  /// [title] and [message] will be automatically HTML-escaped.
  Response _htmlResponse(int statusCode, String title, String message) {
    title = htmlEscape.convert(title);
    message = htmlEscape.convert(message);
    return Response(statusCode, body: '''
      <!doctype html>
      <html>
        <head><title>$title</title></head>
        <body>
          <h1>$title</h1>
          <p>$message</p>
        </body>
      </html>
    ''', headers: {'content-type': 'text/html'});
  }
}
