// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:stream_channel/stream_channel.dart';

// RFC 2616 requires carriage return delimiters.
String _sseHeaders(String? origin) => 'HTTP/1.1 200 OK\r\n'
    'Content-Type: text/event-stream\r\n'
    'Cache-Control: no-cache\r\n'
    'Connection: keep-alive\r\n'
    'Access-Control-Allow-Credentials: true\r\n' 
    "${origin != null ? 'Access-Control-Allow-Origin: $origin\r\n'  : ''}"
    '\r\n\r\n';

class _SseMessage {
  final int id;
  final String message;
  _SseMessage(this.id, this.message);
}

/// A bi-directional SSE connection between server and browser.
class SseConnection extends StreamChannelMixin<String?> {
  /// Incoming messages from the Browser client.
  final _incomingController = StreamController<String>();

  /// Outgoing messages to the Browser client.
  final _outgoingController = StreamController<String>();

  Sink _sink;

  /// How long to wait after a connection drops before considering it closed.
  final Duration? _keepAlive;

  /// A timer counting down the KeepAlive period (null if hasn't disconnected).
  Timer? _keepAliveTimer;

  /// Whether this connection is currently in the KeepAlive timeout period.
  bool get isInKeepAlivePeriod => _keepAliveTimer?.isActive ?? false;

  /// The id of the last processed incoming message.
  int _lastProcessedId = -1;

  /// Incoming messages that have yet to be processed.
  final _pendingMessages =
      HeapPriorityQueue<_SseMessage>((a, b) => a.id.compareTo(b.id));

  final _closedCompleter = Completer<void>();

  /// Wraps the `_outgoingController.stream` to buffer events to enable keep
  /// alive.
  late StreamQueue _outgoingStreamQueue;

  /// Creates an [SseConnection] for the supplied [_sink].
  ///
  /// If [keepAlive] is supplied, the connection will remain active for this
  /// period after a disconnect and can be reconnected transparently. If there
  /// is no reconnect within that period, the connection will be closed normally.
  ///
  /// If [keepAlive] is not supplied, the connection will be closed immediately
  /// after a disconnect.
  SseConnection(this._sink, {Duration? keepAlive}) : _keepAlive = keepAlive {
    _outgoingStreamQueue = StreamQueue(_outgoingController.stream);
    unawaited(_setUpListener());
    _outgoingController.onCancel = _close;
    _incomingController.onCancel = _close;
  }

  Future<void> _setUpListener() async {
    while (
        !_outgoingController.isClosed && await _outgoingStreamQueue.hasNext) {
      // If we're in a KeepAlive timeout, there's nowhere to send messages so
      // wait a short period and check again.
      if (isInKeepAlivePeriod) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      // Peek the data so we don't remove it from the stream if we're unable to
      // send it.
      final data = await _outgoingStreamQueue.peek;

      // Ignore outgoing messages since the connection may have closed while
      // waiting for the keep alive.
      if (_closedCompleter.isCompleted) break;

      try {
        // JSON encode the message to escape new lines.
        _sink.add('data: ${json.encode(data)}\n');
        _sink.add('\n');
        await _outgoingStreamQueue.next; // Consume from stream if no errors.
      } on StateError catch (_) {
        if (_keepAlive == null || _closedCompleter.isCompleted) {
          rethrow;
        }
        // If we got here then the sink may have closed but the stream.onDone
        // hasn't fired yet, so pause the subscription and skip calling
        // `next` so the message remains in the queue to try again.
        _handleDisconnect();
      }
    }
  }

  /// The message added to the sink has to be JSON encodable.
  @override
  StreamSink<String> get sink => _outgoingController.sink;

  // Add messages to this [StreamSink] to send them to the server.
  /// [Stream] of messages sent from the server to this client.
  ///
  /// A message is a decoded JSON object.
  @override
  Stream<String> get stream => _incomingController.stream;

  /// Adds an incoming [message] to the [stream].
  ///
  /// This will buffer messages to guarantee order.
  void _addIncomingMessage(int id, String message) {
    _pendingMessages.add(_SseMessage(id, message));
    while (_pendingMessages.isNotEmpty) {
      var pendingMessage = _pendingMessages.first;
      // Only process the next incremental message.
      if (pendingMessage.id - _lastProcessedId <= 1) {
        _incomingController.sink.add(pendingMessage.message);
        _lastProcessedId = pendingMessage.id;
        _pendingMessages.removeFirst();
      } else {
        // A message came out of order. Wait until we receive the previous
        // messages to process.
        break;
      }
    }
  }

  void _acceptReconnection(Sink sink) {
    _keepAliveTimer?.cancel();
    _sink = sink;
  }

  void _handleDisconnect() {
    if (_keepAlive == null) {
      // Close immediately if we're not keeping alive.
      _close();
    } else if (!isInKeepAlivePeriod && !_closedCompleter.isCompleted) {
      // Otherwise if we didn't already have an active timer and we've not already
      // been completely closed, set a timer to close after the timeout period.
      // If the connection comes back, this will be cancelled and all messages left
      // in the queue tried again.
      _keepAliveTimer = Timer(_keepAlive!, _close);
    }
  }

  void _close() {
    if (!_closedCompleter.isCompleted) {
      _closedCompleter.complete();
      // Cancel any existing timer in case we were told to explicitly shut down
      // to avoid keeping the process alive.
      _keepAliveTimer?.cancel();
      _sink.close();
      if (!_outgoingController.isClosed) {
        _outgoingStreamQueue.cancel(immediate: true);
        _outgoingController.close();
      }
      if (!_incomingController.isClosed) _incomingController.close();
    }
  }

  /// Immediately close the connection, ignoring any keepAlive period.
  void shutdown() {
    _close();
  }
}

/// [SseHandler] handles requests on a user defined path to create
/// two-way communications of JSON encodable data between server and clients.
///
/// A server sends messages to a client through an SSE channel, while
/// a client sends message to a server through HTTP POST requests.
class SseHandler {
  final _logger = Logger('SseHandler');
  final Uri _uri;
  final Duration? _keepAlive;
  final _connections = <String?, SseConnection>{};
  final _connectionController = StreamController<SseConnection>();

  StreamQueue<SseConnection>? _connectionsStream;

  /// [_uri] is the URL under which the server is listening for
  /// incoming bi-directional SSE connections.
  ///
  /// If [keepAlive] is supplied, connections will remain active for this
  /// period after a disconnect and can be reconnected transparently. If there
  /// is no reconnect within that period, the connection will be closed
  /// normally.
  ///
  /// If [keepAlive] is not supplied, connections will be closed immediately
  /// after a disconnect.
  SseHandler(this._uri, {Duration? keepAlive}) : _keepAlive = keepAlive;

  StreamQueue<SseConnection> get connections =>
      _connectionsStream ??= StreamQueue(_connectionController.stream);

  shelf.Handler get handler => _handle;

  int get numberOfClients => _connections.length;

  shelf.Response _createSseConnection(shelf.Request req, String path) {
    req.hijack((channel) async {
      var sink = utf8.encoder.startChunkedConversion(channel.sink);
      sink.add(_sseHeaders(req.headers['origin']));
      var clientId = req.url.queryParameters['sseClientId'];

      // Check if we already have a connection for this ID that is in the process
      // of timing out (in which case we can reconnect it transparently).
      if (_connections[clientId] != null &&
          _connections[clientId]!.isInKeepAlivePeriod) {
        _connections[clientId]!._acceptReconnection(sink);
      } else {
        var connection = SseConnection(sink, keepAlive: _keepAlive);
        _connections[clientId] = connection;
        unawaited(connection._closedCompleter.future.then((_) {
          _connections.remove(clientId);
        }));
        _connectionController.add(connection);
      }
      // Remove connection when it is remotely closed or the stream is
      // cancelled.
      channel.stream.listen((_) {
        // SSE is unidirectional. Responses are handled through POST requests.
      }, onDone: () {
        _connections[clientId]?._handleDisconnect();
      });
    });
  }

  String _getOriginalPath(shelf.Request req) => req.requestedUri.path;

  Future<shelf.Response> _handle(shelf.Request req) async {
    var path = _getOriginalPath(req);
    if (_uri.path != path) {
      return shelf.Response.notFound('');
    }

    if (req.headers['accept'] == 'text/event-stream' && req.method == 'GET') {
      return _createSseConnection(req, path);
    }

    if (req.headers['accept'] != 'text/event-stream' && req.method == 'POST') {
      return _handleIncomingMessage(req, path);
    }

    return shelf.Response.notFound('');
  }

  Future<shelf.Response> _handleIncomingMessage(
      shelf.Request req, String path) async {
    try {
      var clientId = req.url.queryParameters['sseClientId'];
      var messageId = int.parse(req.url.queryParameters['messageId'] ?? '0');
      var message = await req.readAsString();
      var jsonObject = json.decode(message) as String;
      _connections[clientId]?._addIncomingMessage(messageId, jsonObject);
    } catch (e, st) {
      _logger.fine('Failed to handle incoming message. $e $st');
    }
    return shelf.Response.ok('', headers: {
      'access-control-allow-credentials': 'true',
      'access-control-allow-origin': _originFor(req),
    });
  }

  String _originFor(shelf.Request req) =>
      // Firefox does not set header "origin".
      // https://bugzilla.mozilla.org/show_bug.cgi?id=1508661
      req.headers['origin'] ?? req.headers['host']!;

  /// Immediately close all connections, ignoring any keepAlive periods.
  void shutdown() {
    for (final connection in _connections.values) {
      connection.shutdown();
    }
  }
}

void closeSink(SseConnection connection) => connection._sink.close();
