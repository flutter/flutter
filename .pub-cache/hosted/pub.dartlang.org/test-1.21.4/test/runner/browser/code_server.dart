// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:test/test.dart' show printOnFailure, TestFailure;
import 'package:web_socket_channel/web_socket_channel.dart';

/// A class that serves Dart and/or JS code and receives WebSocket connections.
class CodeServer {
  final _Handler _handler;

  /// The URL of the server (including the port).
  final Uri url;

  static Future<CodeServer> start() async {
    var server = await HttpMultiServer.loopback(0);
    var handler = _Handler(Zone.current.handleUncaughtError);
    shelf_io.serveRequests(server, (request) {
      if (request.method == 'GET' && request.url.path == 'favicon.ico') {
        return shelf.Response.notFound(null);
      } else {
        return handler(request);
      }
    });

    return CodeServer._(handler, Uri.parse('http://localhost:${server.port}'));
  }

  CodeServer._(this._handler, this.url);

  /// Sets up a handler for the root of the server, "/", that serves a basic
  /// HTML page with a script tag that will run [dart].
  void handleDart(String dart) {
    _handler.expect('GET', '/', (_) {
      return shelf.Response.ok('''
<!doctype html>
<html>
<head>
  <script type="application/dart" src="index.dart"></script>
</head>
</html>
''', headers: {'content-type': 'text/html'});
    });

    _handler.expect('GET', '/index.dart', (_) {
      return shelf.Response.ok('''
import "dart:html";

main() async {
  $dart
}
''', headers: {'content-type': 'application/dart'});
    });
  }

  /// Sets up a handler for the root of the server, "/", that serves a basic
  /// HTML page with a script tag that will run [javaScript].
  void handleJavaScript(String javaScript) {
    _handler.expect('GET', '/', (_) {
      return shelf.Response.ok('''
<!doctype html>
<html>
<head>
  <script src="index.js"></script>
</head>
</html>
''', headers: {'content-type': 'text/html'});
    });

    _handler.expect('GET', '/index.js', (_) {
      return shelf.Response.ok(javaScript,
          headers: {'content-type': 'application/javascript'});
    });
  }

  /// Handles a WebSocket connection to the root of the server, and returns a
  /// future that will complete to the WebSocket.
  Future<WebSocketChannel> handleWebSocket() {
    var completer = Completer<WebSocketChannel>();
    _handler.expect('GET', '/', webSocketHandler(completer.complete));
    return completer.future;
  }
}

/// A [shelf.Handler] that handles requests as specified by [expect].
class _Handler {
  /// A callback called whenever an unexpected exception is thrown.
  ///
  /// This is used over throwing errors directly since the request handler might
  /// not be running in the same error zone as the test.
  final void Function(Object, StackTrace) _onError;

  /// The queue of expected requests to this handler.
  final _expectations = Queue<_Expectation>();

  /// Creates a new handler that handles requests using handlers provided by
  /// [expect].
  _Handler(this._onError);

  /// Expects that a single HTTP request with the given [method] and [path] will
  /// be made to [this].
  ///
  /// The [path] should be root-relative; that is, it should start with "/".
  ///
  /// When a matching request is made, [handler] is used to handle that request.
  ///
  /// If this is called multiple times, the requests are expected to occur in
  /// the same order.
  void expect(String method, String path, shelf.Handler handler) {
    _expectations.add(_Expectation(method, path, handler));
  }

  /// The implementation of [shelf.Handler].
  FutureOr<shelf.Response> call(shelf.Request request) async {
    const description = 'ShelfTesthandler';
    var requestInfo = '${request.method} /${request.url}';
    printOnFailure('[$description] $requestInfo');

    try {
      if (_expectations.isEmpty) {
        throw TestFailure(
            '$description received unexpected request $requestInfo.');
      }

      var expectation = _expectations.removeFirst();
      if ((expectation.method != null &&
              expectation.method != request.method) ||
          (expectation.path != '/${request.url.path}' &&
              expectation.path != null)) {
        var message = '$description received unexpected request $requestInfo.';
        if (expectation.method != null) {
          message += '\nExpected ${expectation.method} ${expectation.path}.';
        }
        throw TestFailure(message);
      }

      return await expectation.handler(request);
    } on shelf.HijackException catch (_) {
      rethrow;
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
      return shelf.Response.internalServerError(body: '$error');
    }
  }
}

/// A single expectation for an HTTP request sent to a [_Handler].
class _Expectation {
  /// The expected request method, or [null] if this allows any requests.
  final String? method;

  /// The expected request path, or [null] if this allows any requests.
  final String? path;

  /// The handler to use for requests that match this expectation.
  final shelf.Handler handler;

  _Expectation(this.method, this.path, this.handler);
}
