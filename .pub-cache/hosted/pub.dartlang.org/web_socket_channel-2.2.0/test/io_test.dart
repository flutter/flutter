// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  HttpServer server;

  test('communicates using existing WebSockets', () async {
    server = await HttpServer.bind('localhost', 0);
    addTearDown(server.close);
    server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      channel.sink.add('hello!');
      channel.stream.listen((request) {
        expect(request, equals('ping'));
        channel.sink.add('pong');
        channel.sink.close(5678, 'raisin');
      });
    });

    final webSocket = await WebSocket.connect('ws://localhost:${server.port}');
    final channel = IOWebSocketChannel(webSocket);

    var n = 0;
    channel.stream.listen((message) {
      if (n == 0) {
        expect(message, equals('hello!'));
        channel.sink.add('ping');
      } else if (n == 1) {
        expect(message, equals('pong'));
      } else {
        fail('Only expected two messages.');
      }
      n++;
    }, onDone: expectAsync0(() {
      expect(channel.closeCode, equals(5678));
      expect(channel.closeReason, equals('raisin'));
    }));
  });

  test('.connect communicates immediately', () async {
    server = await HttpServer.bind('localhost', 0);
    server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      channel.stream.listen((request) {
        expect(request, equals('ping'));
        channel.sink.add('pong');
      });
    });

    final channel = IOWebSocketChannel.connect('ws://localhost:${server.port}');
    channel.sink.add('ping');

    channel.stream.listen(
        expectAsync1((message) {
          expect(message, equals('pong'));
          channel.sink.close(5678, 'raisin');
        }, count: 1),
        onDone: expectAsync0(() {}));
  });

  test('.connect communicates immediately using platform independent api',
      () async {
    server = await HttpServer.bind('localhost', 0);
    server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      channel.stream.listen((request) {
        expect(request, equals('ping'));
        channel.sink.add('pong');
      });
    });

    final channel =
        WebSocketChannel.connect(Uri.parse('ws://localhost:${server.port}'));
    channel.sink.add('ping');

    channel.stream.listen(
        expectAsync1((message) {
          expect(message, equals('pong'));
          channel.sink.close(5678, 'raisin');
        }, count: 1),
        onDone: expectAsync0(() {}));
  });

  test('.connect with an immediate call to close', () async {
    server = await HttpServer.bind('localhost', 0);
    server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
      expect(() async {
        final channel = IOWebSocketChannel(webSocket);
        await channel.stream.drain();
        expect(channel.closeCode, equals(5678));
        expect(channel.closeReason, equals('raisin'));
      }(), completes);
    });

    final channel = IOWebSocketChannel.connect('ws://localhost:${server.port}');
    await channel.sink.close(5678, 'raisin');
  });

  test('.connect wraps a connection error in WebSocketChannelException',
      () async {
    server = await HttpServer.bind('localhost', 0);
    server.listen((request) {
      request.response.statusCode = 404;
      request.response.close();
    });

    final channel = IOWebSocketChannel.connect('ws://localhost:${server.port}');
    expect(channel.stream.drain(), throwsA(isA<WebSocketChannelException>()));
  });

  test('.protocols fail', () async {
    const passedProtocol = 'passed-protocol';
    const failedProtocol = 'failed-protocol';
    String selector(List<String> receivedProtocols) => passedProtocol;

    server = await HttpServer.bind('localhost', 0);
    server.listen((HttpRequest request) {
      expect(
        WebSocketTransformer.upgrade(request, protocolSelector: selector),
        throwsException,
      );
    });

    final channel = IOWebSocketChannel.connect(
      'ws://localhost:${server.port}',
      protocols: [failedProtocol],
    );
    expect(
      channel.stream.drain(),
      throwsA(isA<WebSocketChannelException>()),
    );
  });

  test('.protocols pass', () async {
    const passedProtocol = 'passed-protocol';
    String selector(List<String> receivedProtocols) => passedProtocol;

    server = await HttpServer.bind('localhost', 0);
    server.listen((HttpRequest request) async {
      final webSocket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: selector,
      );
      expect(webSocket.protocol, passedProtocol);
      await webSocket.close();
    });

    final channel = IOWebSocketChannel.connect('ws://localhost:${server.port}',
        protocols: [passedProtocol]);
    await channel.stream.drain();
    expect(channel.protocol, passedProtocol);
  });
}
