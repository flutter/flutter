// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'convert.dart';

/// Parse binary streams in the JSON RPC format understood by the daemon, and
/// convert it into a stream of JSON RPC messages.
Stream<Map<String, Object?>> _convertInputStream(Stream<List<int>> inputStream) {
  return utf8.decoder.bind(inputStream)
  .transform<String>(const LineSplitter())
  .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
  .map<Map<String, Object?>?>((String line) {
    line = line.substring(1, line.length - 1);
    return castStringKeyedMap(json.decode(line));
  })
  .where((Map<String, Object?>? entry) => entry != null)
  .cast<Map<String, Object?>>();
}

/// A stream that a [DaemonConnection] uses to communicate with each other.
abstract class DaemonStreams {
  /// Stream that contains input to the [DaemonConnection].
  Stream<Map<String, Object?>> get inputStream;

  /// Outputs a message through the connection.
  void send(Map<String, Object?> message);

  /// Cleans up any resources used.
  Future<void> dispose() async { }
}

/// A [DaemonStream] that uses stdin and stdout as the underlying streams.
class StdioDaemonStreams extends DaemonStreams {
  StdioDaemonStreams(Stdio stdio) :
    _stdio = stdio,
    inputStream = _convertInputStream(stdio.stdin);

  final Stdio _stdio;

  @override
  final Stream<Map<String, Object?>> inputStream;

  @override
  void send(Map<String, Object?> message) {
    _stdio.stdoutWrite(
      '[${json.encode(message)}]\n',
      fallback: (String message, Object? error, StackTrace stack) {
        throwToolExit('Failed to write daemon command response to stdout: $error');
      },
    );
  }
}

/// A [DaemonStream] that uses [Socket] as the underlying stream.
class TcpDaemonStreams extends DaemonStreams {
  /// Creates a [DaemonStreams] with an existing [Socket].
  TcpDaemonStreams(
    Socket socket, {
    required Logger logger,
  }): _logger = logger {
    _socket = Future<Socket>.value(_initializeSocket(socket));
  }

  /// Connects to a remote host and creates a [DaemonStreams] from the socket.
  TcpDaemonStreams.connect(
    String host,
    int port, {
    required Logger logger,
  }) : _logger = logger {
    _socket = Socket.connect(host, port).then(_initializeSocket);
  }

  late final Future<Socket> _socket;
  final StreamController<Map<String, Object?>> _commands = StreamController<Map<String, Object?>>();
  final Logger _logger;

  @override
  Stream<Map<String, Object?>> get inputStream => _commands.stream;

  @override
  void send(Map<String, Object?> message) {
    _socket.then((Socket socket) {
      try {
        socket.write('[${json.encode(message)}]\n');
      } on SocketException catch (error) {
        _logger.printError('Failed to write daemon command response to socket: $error');
        // Failed to send, close the connection
        socket.close();
      }
    });
  }

  Socket _initializeSocket(Socket socket) {
    _commands.addStream(_convertInputStream(socket));
    return socket;
  }

  @override
  Future<void> dispose() async {
    await (await _socket).close();
  }
}

/// Connection between a flutter daemon and a client.
class DaemonConnection {
  DaemonConnection({
    required DaemonStreams daemonStreams,
    required Logger logger,
  }): _logger = logger,
      _daemonStreams = daemonStreams {
    _commandSubscription = daemonStreams.inputStream.listen(
      _handleData,
      onError: (Object error, StackTrace stackTrace) {
        // We have to listen for on error otherwise the error on the socket
        // will end up in the Zone error handler.
        // Do nothing here and let the stream close handlers handle shutting
        // down the daemon.
      }
    );
  }

  final DaemonStreams _daemonStreams;

  final Logger _logger;

  late final StreamSubscription<Map<String, Object?>> _commandSubscription;

  int _outgoingRequestId = 0;
  final Map<String, Completer<Object?>> _outgoingRequestCompleters = <String, Completer<Object?>>{};

  final StreamController<Map<String, Object?>> _events = StreamController<Map<String, Object?>>.broadcast();
  final StreamController<Map<String, Object?>> _incomingCommands = StreamController<Map<String, Object?>>();

  /// A stream that contains all the incoming requests.
  Stream<Map<String, Object?>> get incomingCommands => _incomingCommands.stream;

  /// Listens to the event with the event name [eventToListen].
  Stream<Object?> listenToEvent(String eventToListen) {
    return _events.stream
      .where((Map<String, Object?> event) => event['event'] == eventToListen)
      .map<Object?>((Map<String, Object?> event) => event['params']);
  }

  /// Sends a request to the other end of the connection.
  ///
  /// Returns a [Future] that resolves with the content.
  Future<Object?> sendRequest(String method, [Object? params]) async {
    final String id = '${++_outgoingRequestId}';
    final Completer<Object?> completer = Completer<Object?>();
    _outgoingRequestCompleters[id] = completer;
    final Map<String, Object?> data = <String, Object?>{
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    _logger.printTrace('-> Sending to daemon, id = $id, method = $method');
    _daemonStreams.send(data);
    return completer.future;
  }

  /// Sends a response to the other end of the connection.
  void sendResponse(Object id, [Object? result]) {
    _daemonStreams.send(<String, Object?>{
      'id': id,
      if (result != null) 'result': result,
    });
  }

  /// Sends an error response to the other end of the connection.
  void sendErrorResponse(Object id, Object error, StackTrace trace) {
    _daemonStreams.send(<String, Object?>{
      'id': id,
      'error': error,
      'trace': '$trace',
    });
  }

  /// Sends an event to the client.
  void sendEvent(String name, [ Object? params ]) {
    _daemonStreams.send(<String, Object?>{
      'event': name,
      if (params != null) 'params': params,
    });
  }

  /// Handles the input from the stream.
  ///
  /// There are three kinds of data: Request, Response, Event.
  ///
  /// Request:
  /// {"id": <Object>. "method": <String>, "params": <optional, Object?>}
  ///
  /// Response:
  /// {"id": <Object>. "result": <optional, Object?>} for a successful response.
  /// {"id": <Object>. "error": <Object>, "stackTrace": <String>} for an error response.
  ///
  /// Event:
  /// {"event": <String>. "params": <optional, Object?>}
  void _handleData(Map<String, Object?> data) {
    if (data['id'] != null) {
      if (data['method'] == null) {
        // This is a response to previously sent request.
        final String id = data['id']! as String;
        if (data['error'] != null) {
          // This is an error response.
          _logger.printTrace('<- Error response received from daemon, id = $id');
          final Object error = data['error']!;
          final String stackTrace = data['stackTrace'] as String? ?? '';
          _outgoingRequestCompleters.remove(id)?.completeError(error, StackTrace.fromString(stackTrace));
        } else {
          _logger.printTrace('<- Response received from daemon, id = $id');
          final Object? result = data['result'];
          _outgoingRequestCompleters.remove(id)?.complete(result);
        }
      } else {
        _incomingCommands.add(data);
      }
    } else if (data['event'] != null) {
      // This is an event
      _logger.printTrace('<- Event received: ${data['event']}');
      _events.add(data);
    } else {
      _logger.printError('Unknown data received from daemon');
    }
  }

  /// Cleans up any resources used in the connection.
  Future<void> dispose() async {
    await _commandSubscription.cancel();
    await _daemonStreams.dispose();
    unawaited(_events.close());
    unawaited(_incomingCommands.close());
  }
}
