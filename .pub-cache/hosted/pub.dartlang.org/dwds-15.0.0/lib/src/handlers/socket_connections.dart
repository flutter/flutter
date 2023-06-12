// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// An individual (transport-agnostic) bidirectional socket connection.
abstract class SocketConnection {
  /// Whether this connection is currently in the KeepAlive timeout period.
  bool get isInKeepAlivePeriod;

  /// Messages added to the sink must be JSON encodable.
  StreamSink<dynamic> get sink;

  Stream<String> get stream;

  /// Immediately close the connection, ignoring any keepAlive period.
  void shutdown();
}

/// A handler that accepts (transport-agnostic) bidirection socket connections.
abstract class SocketHandler {
  StreamQueue<SocketConnection> get connections;
  FutureOr<Response> handler(Request request);
  void shutdown();
}

/// An implemenation of [SocketConnection] that users server-sent events (SSE)
/// and HTTP POSTS for bidirectional communication by wrapping an [SseConnection].
class SseSocketConnection extends SocketConnection {
  final SseConnection _connection;

  SseSocketConnection(this._connection);

  @override
  bool get isInKeepAlivePeriod => _connection.isInKeepAlivePeriod;
  @override
  StreamSink<dynamic> get sink => _connection.sink;
  @override
  Stream<String> get stream => _connection.stream;
  @override
  void shutdown() => _connection.shutdown();
}

/// An implemenation of [SocketHandler] that accepts server-sent events (SSE)
/// connections and wraps them in an [SseSocketConnection].
class SseSocketHandler extends SocketHandler {
  final SseHandler _sseHandler;
  final StreamController<SseSocketConnection> _connectionsStream =
      StreamController<SseSocketConnection>();
  StreamQueue<SseSocketConnection>? _connectionsStreamQueue;

  SseSocketHandler(this._sseHandler) {
    unawaited(() async {
      final injectedConnections = _sseHandler.connections;
      while (await injectedConnections.hasNext) {
        _connectionsStream
            .add(SseSocketConnection(await injectedConnections.next));
      }
    }());
  }

  @override
  StreamQueue<SseSocketConnection> get connections =>
      _connectionsStreamQueue ??= StreamQueue(_connectionsStream.stream);
  @override
  FutureOr<Response> handler(Request request) => _sseHandler.handler(request);
  @override
  void shutdown() => _sseHandler.shutdown();
}

/// An implemenation of [SocketConnection] that uses WebSockets for communication
/// by wrapping [WebSocketChannel].
class WebSocketConnection extends SocketConnection {
  final WebSocketChannel _channel;
  WebSocketConnection(this._channel);

  @override
  bool get isInKeepAlivePeriod => false;

  @override
  StreamSink<dynamic> get sink => _channel.sink;

  @override
  Stream<String> get stream => _channel.stream.map((dynamic o) => o.toString());

  @override
  void shutdown() => _channel.sink.close();
}

/// An implemenation of [SocketHandler] that accepts WebSocket connections and
/// wraps them in a [WebSocketConnection].
class WebSocketSocketHandler extends SocketHandler {
  late Handler _handler;
  final StreamController<WebSocketConnection> _connectionsStream =
      StreamController<WebSocketConnection>();
  StreamQueue<WebSocketConnection>? _connectionsStreamQueue;

  WebSocketSocketHandler() {
    _handler = webSocketHandler((WebSocketChannel channel) =>
        _connectionsStream.add(WebSocketConnection(channel)));
  }

  @override
  StreamQueue<WebSocketConnection> get connections =>
      _connectionsStreamQueue ??= StreamQueue(_connectionsStream.stream);

  @override
  FutureOr<Response> handler(Request request) => _handler(request);

  @override
  void shutdown() {}
}
