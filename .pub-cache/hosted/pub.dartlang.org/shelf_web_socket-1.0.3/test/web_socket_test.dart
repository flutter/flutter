// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Map<String, String> get _handshakeHeaders => {
      'Upgrade': 'websocket',
      'Connection': 'Upgrade',
      'Sec-WebSocket-Key': 'x3JJHMbDL1EzLkh9GBhXDw==',
      'Sec-WebSocket-Version': '13'
    };

void main() {
  test('can communicate with a dart:io WebSocket client', () async {
    final server =
        await shelf_io.serve(webSocketHandler((WebSocketChannel webSocket) {
      webSocket.sink.add('hello!');
      webSocket.stream.first.then((request) {
        expect(request, equals('ping'));
        webSocket.sink.add('pong');
        webSocket.sink.close();
      });
    }), 'localhost', 0);

    try {
      final webSocket =
          await WebSocket.connect('ws://localhost:${server.port}');
      var n = 0;
      await webSocket.listen((message) {
        if (n == 0) {
          expect(message, equals('hello!'));
          webSocket.add('ping');
        } else if (n == 1) {
          expect(message, equals('pong'));
          webSocket.close();
          server.close();
        } else {
          fail('Only expected two messages.');
        }
        n++;
      }).asFuture<void>();
    } finally {
      await server.close();
    }
  });

  test('negotiates the sub-protocol', () async {
    final server = await shelf_io.serve(
        webSocketHandler((WebSocketChannel webSocket, String? protocol) {
          expect(protocol, equals('two'));
          webSocket.sink.close();
        }, protocols: ['three', 'two', 'x']),
        'localhost',
        0);

    try {
      final webSocket = await WebSocket.connect('ws://localhost:${server.port}',
          protocols: ['one', 'two', 'three']);
      expect(webSocket.protocol, equals('two'));
      return webSocket.close();
    } finally {
      await server.close();
    }
  });

  test('handles protocol header without allowed protocols', () async {
    final server =
        await shelf_io.serve(webSocketHandler((WebSocketChannel webSocket) {
      webSocket.sink.close();
    }), 'localhost', 0);

    try {
      final webSocket = await WebSocket.connect('ws://localhost:${server.port}',
          protocols: ['one', 'two', 'three']);
      expect(webSocket.protocol, isNull);
      return webSocket.close();
    } finally {
      await server.close();
    }
  });

  test('allows two argument callbacks without protocols', () async {
    final server = await shelf_io.serve(
        webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      expect(protocol, isNull);
      webSocket.sink.close();
    }), 'localhost', 0);

    try {
      final webSocket = await WebSocket.connect('ws://localhost:${server.port}',
          protocols: ['one', 'two', 'three']);
      expect(webSocket.protocol, isNull);
      return webSocket.close();
    } finally {
      await server.close();
    }
  });

  group('with a set of allowed origins', () {
    late HttpServer server;
    late Uri url;
    setUp(() async {
      server = await shelf_io.serve(
          webSocketHandler((WebSocketChannel webSocket) {
            webSocket.sink.close();
          }, allowedOrigins: ['pub.dartlang.org', 'GoOgLe.CoM']),
          'localhost',
          0);
      url = Uri.http('localhost:${server.port}', '');
    });

    tearDown(() => server.close());

    test('allows access with an allowed origin', () {
      final headers = _handshakeHeaders;
      headers['Origin'] = 'pub.dartlang.org';
      expect(http.get(url, headers: headers), hasStatus(101));
    });

    test('forbids access with a non-allowed origin', () {
      final headers = _handshakeHeaders;
      headers['Origin'] = 'dartlang.org';
      expect(http.get(url, headers: headers), hasStatus(403));
    });

    test('allows access with no origin', () {
      expect(http.get(url, headers: _handshakeHeaders), hasStatus(101));
    });

    test('ignores the case of the client origin', () {
      final headers = _handshakeHeaders;
      headers['Origin'] = 'PuB.DaRtLaNg.OrG';
      expect(http.get(url, headers: headers), hasStatus(101));
    });

    test('ignores the case of the server origin', () {
      final headers = _handshakeHeaders;
      headers['Origin'] = 'google.com';
      expect(http.get(url, headers: headers), hasStatus(101));
    });
  });

  // Regression test for issue 21894.
  test('allows a Connection header with multiple values', () async {
    final server =
        await shelf_io.serve(webSocketHandler((WebSocketChannel webSocket) {
      webSocket.sink.close();
    }), 'localhost', 0);

    final url = Uri.http('localhost:${server.port}', '');
    final headers = _handshakeHeaders;
    headers['Connection'] = 'Other-Token, Upgrade';
    expect(http.get(url, headers: headers).whenComplete(server.close),
        hasStatus(101));
  });

  group('HTTP errors', () {
    late HttpServer server;
    late Uri url;
    setUp(() async {
      server = await shelf_io.serve(webSocketHandler((_) {
        fail('should not create a WebSocket');
      }), 'localhost', 0);
      url = Uri.http('localhost:${server.port}', '');
    });

    tearDown(() => server.close());

    test('404s for non-GET requests', () {
      expect(http.delete(url, headers: _handshakeHeaders), hasStatus(404));
    });

    test('404s for non-Upgrade requests', () {
      final headers = _handshakeHeaders..remove('Connection');
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test('404s for non-websocket upgrade requests', () {
      final headers = _handshakeHeaders;
      headers['Upgrade'] = 'fblthp';
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test('400s for a missing Sec-WebSocket-Version', () {
      final headers = _handshakeHeaders..remove('Sec-WebSocket-Version');
      expect(http.get(url, headers: headers), hasStatus(400));
    });

    test('404s for an unknown Sec-WebSocket-Version', () {
      final headers = _handshakeHeaders;
      headers['Sec-WebSocket-Version'] = '15';
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test('400s for a missing Sec-WebSocket-Key', () {
      final headers = _handshakeHeaders..remove('Sec-WebSocket-Key');
      expect(http.get(url, headers: headers), hasStatus(400));
    });
  });
}

Matcher hasStatus(int status) => completion(predicate((http.Response response) {
      expect(response, isA<http.Response>());
      expect(response.statusCode, equals(status));
      return true;
    }));
