// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// A library to connect to a Webkit Inspection Protocol server (like Chrome).
library wip;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, HttpClientResponse, IOException, WebSocket;

import 'src/console.dart';
import 'src/debugger.dart';
import 'src/dom.dart';
import 'src/log.dart';
import 'src/page.dart';
import 'src/runtime.dart';
import 'src/target.dart';

export 'src/console.dart';
export 'src/debugger.dart';
export 'src/dom.dart';
export 'src/log.dart';
export 'src/page.dart';
export 'src/runtime.dart';
export 'src/target.dart';

/// A class to connect to a Chrome instance and reflect on its available tabs.
///
/// This assumes the browser has been started with the `--remote-debugging-port`
/// flag. The data is read from the `http://{host}:{port}/json` url.
class ChromeConnection {
  final HttpClient _client = HttpClient();

  final Uri url;

  ChromeConnection(String host, [int port = 9222])
      : url = Uri.parse('http://$host:$port/');

  /// Return all the available tabs.
  ///
  /// This method can potentially throw a [ConnectionException] on some protocol
  /// issues.
  ///
  /// An optional [retryFor] duration can be used to automatically re-try
  /// connections for some period of time. Anecdotally, Chrome can return errors
  /// when trying to list the available tabs very early in its startup sequence.
  Future<List<ChromeTab>> getTabs({
    Duration? retryFor,
  }) async {
    final start = DateTime.now();
    DateTime? end = retryFor == null ? null : start.add(retryFor);

    var response = await getUrl('/json');
    var responseBody = await utf8.decodeStream(response.cast<List<int>>());

    late List decoded;
    while (true) {
      try {
        decoded = jsonDecode(responseBody);
        return List<ChromeTab>.from(decoded.map((m) => ChromeTab(m as Map)));
      } on FormatException catch (formatException) {
        if (end != null && end.isBefore(DateTime.now())) {
          // Delay for retryFor / 4 milliseconds.
          await Future.delayed(
            Duration(milliseconds: retryFor!.inMilliseconds ~/ 4),
          );
        } else {
          throw ConnectionException(
            formatException: formatException,
            responseStatus: '${response.statusCode} ${response.reasonPhrase}',
            responseBody: responseBody,
          );
        }
      }
    }
  }

  Future<ChromeTab?> getTab(
    bool Function(ChromeTab tab) accept, {
    Duration? retryFor,
  }) async {
    var start = DateTime.now();
    var end = start;
    if (retryFor != null) {
      end = start.add(retryFor);
    }

    while (true) {
      try {
        for (var tab in await getTabs()) {
          if (accept(tab)) {
            return tab;
          }
        }
        if (end.isBefore(DateTime.now())) {
          return null;
        }
      } catch (e) {
        if (end.isBefore(DateTime.now())) {
          rethrow;
        }
      }
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }

  Future<HttpClientResponse> getUrl(String path) async {
    var request = await _client.getUrl(url.resolve(path));
    return await request.close();
  }

  void close() => _client.close(force: true);
}

/// An exception that can be thrown early in the connection sequence for a
/// [ChromeConnection].
///
/// This exception includes the underlying exception, as well as the http
/// response from the browser that we failed on. The [toString] implementation
/// includes a summary of the response.
class ConnectionException implements IOException {
  final FormatException formatException;
  final String responseStatus;
  final String responseBody;

  ConnectionException({
    required this.formatException,
    required this.responseStatus,
    required this.responseBody,
  });

  @override
  String toString() {
    final buf = StringBuffer('${formatException.message}\n');
    buf.writeln('$responseStatus; body:');
    var lines = responseBody.split('\n');
    if (lines.length > 10) {
      lines = [
        ...lines.take(10),
        '...',
      ];
    }
    buf.writeAll(lines, '\n');
    return buf.toString();
  }
}

class ChromeTab {
  final Map _map;

  ChromeTab(this._map);

  String? get description => _map['description'] as String?;

  String? get devtoolsFrontendUrl => _map['devtoolsFrontendUrl'] as String?;

  String? get faviconUrl => _map['faviconUrl'] as String?;

  /// Ex. `E1999E8A-EE27-0450-9900-5BFF4C69CA83`.
  String get id => _map['id'] as String;

  String? get title => _map['title'] as String?;

  /// Ex. `background_page`, `page`.
  String get type => _map['type'] as String;

  String get url => _map['url'] as String;

  /// Ex. `ws://localhost:1234/devtools/page/4F98236D-4EB0-7C6C-5DD1-AF9B6BE4BC71`.
  String get webSocketDebuggerUrl => _map['webSocketDebuggerUrl'] as String;

  bool get hasIcon => _map.containsKey('faviconUrl');

  bool get isChromeExtension => url.startsWith('chrome-extension://');

  bool get isBackgroundPage => type == 'background_page';

  Future<WipConnection> connect() =>
      WipConnection.connect(webSocketDebuggerUrl);

  @override
  String toString() => url;
}

/// A Webkit Inspection Protocol (WIP) connection.
class WipConnection {
  /// The WebSocket URL.
  final String url;

  final WebSocket _ws;

  int _nextId = 0;

  @Deprecated('This domain is deprecated - use Runtime or Log instead')
  late final WipConsole console = WipConsole(this);

  late final WipDebugger debugger = WipDebugger(this);

  late final WipDom dom = WipDom(this);

  late final WipPage page = WipPage(this);

  late final WipTarget target = WipTarget(this);

  late final WipLog log = WipLog(this);

  late final WipRuntime runtime = WipRuntime(this);

  final StreamController<String> _onSend =
      StreamController.broadcast(sync: true);
  final StreamController<String> _onReceive =
      StreamController.broadcast(sync: true);

  final Map<int, Completer<WipResponse>> _completers = {};

  final _closeController = StreamController<WipConnection>.broadcast();
  final _notificationController = StreamController<WipEvent>.broadcast();

  static Future<WipConnection> connect(String url) {
    return WebSocket.connect(url).then((socket) {
      return WipConnection._(url, socket);
    });
  }

  WipConnection._(this.url, this._ws) {
    _ws.listen((data) {
      var json = jsonDecode(data as String) as Map<String, dynamic>;
      _onReceive.add(data);

      if (json.containsKey('id')) {
        _handleResponse(json);
      } else {
        _handleNotification(json);
      }
    }, onDone: _handleClose);
  }

  Stream<WipConnection> get onClose => _closeController.stream;

  Stream<WipEvent> get onNotification => _notificationController.stream;

  Future close() => _ws.close();

  @override
  String toString() => url;

  Future<WipResponse> sendCommand(String method,
      [Map<String, dynamic>? params]) {
    var completer = Completer<WipResponse>();
    var json = {'id': _nextId++, 'method': method};
    if (params != null) {
      json['params'] = params;
    }
    _completers[json['id'] as int] = completer;
    String message = jsonEncode(json);
    _ws.add(message);
    _onSend.add(message);
    return completer.future;
  }

  void _handleNotification(Map<String, dynamic> json) {
    _notificationController.add(WipEvent(json));
  }

  void _handleResponse(Map<String, dynamic> event) {
    var completer = _completers.remove(event['id'])!;

    if (event.containsKey('error')) {
      completer.completeError(WipError(event));
    } else {
      completer.complete(WipResponse(event));
    }
  }

  void _handleClose() {
    _closeController.add(this);
    _closeController.close();
    _notificationController.close();
  }

  /// Listen for all traffic sent on this WipConnection.
  Stream<String> get onSend => _onSend.stream;

  /// Listen for all traffic received by this WipConnection.
  Stream<String> get onReceive => _onReceive.stream;
}

class WipEvent {
  final Map<String, dynamic> json;

  final String method;
  final Map<String, dynamic>? params;

  WipEvent(this.json)
      : method = json['method'] as String,
        params = json['params'] as Map<String, dynamic>?;

  @override
  String toString() => 'WipEvent: $method($params)';
}

class WipError implements Exception {
  final Map<String, dynamic> json;

  final int id;
  final Map<String, dynamic>? error;

  WipError(this.json)
      : id = json['id'] as int,
        error = json['error'] as Map<String, dynamic>?;

  int? get code => error == null ? null : error!['code'];

  String? get message => error == null ? null : error!['message'];

  @override
  String toString() => 'WipError $code $message';
}

class WipResponse {
  final Map<String, dynamic> json;

  final int id;
  final Map<String, dynamic>? result;

  WipResponse(this.json)
      : id = json['id'] as int,
        result = json['result'] as Map<String, dynamic>?;

  @override
  String toString() => 'WipResponse $id: $result';
}

typedef WipEventTransformer<T> = T Function(WipEvent event);

/// @optional
const String optional = 'optional';

abstract class WipDomain {
  final Map<String, Stream> _eventStreams = {};

  final WipConnection connection;

  late final Stream<WipDomain> onClosed = StreamTransformer.fromHandlers(
      handleData: (event, EventSink<WipDomain> sink) {
    sink.add(this);
  }).bind(connection.onClose);

  WipDomain(this.connection);

  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) {
    return _eventStreams
        .putIfAbsent(
          method,
          () => StreamTransformer.fromHandlers(
            handleData: (WipEvent event, EventSink<T> sink) {
              if (event.method == method) {
                sink.add(transformer(event));
              }
            },
          ).bind(connection.onNotification),
        )
        .cast();
  }

  Future<WipResponse> sendCommand(
    String method, {
    Map<String, dynamic>? params,
  }) {
    return connection.sendCommand(method, params);
  }
}

// ignore: library_private_types_in_public_api
const _Experimental experimental = _Experimental();

class _Experimental {
  const _Experimental();
}
