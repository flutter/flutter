// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/src/dds_impl.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'common/fakes.dart';

Future<HttpServer> startHttpServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((event) async {
    event.response.add([1, 2, 3]);
    await event.response.flush();
    await server.close(force: true);
  });
  return server;
}

void main() {
  webSocketBuilder = (Uri _) => FakeWebSocketChannel();
  peerBuilder = (WebSocketChannel _, dynamic __) async => FakePeer();

  test("Handles 'Connection closed before full header was received'", () async {
    final httpServer = await startHttpServer();
    final dds = await DartDevelopmentService.startDartDevelopmentService(
      Uri(scheme: 'http', host: httpServer.address.host, port: httpServer.port),
      enableAuthCodes: false,
    );
    final uri = dds.uri!;

    try {
      final client = HttpClient();
      final request = await client.get(uri.host, uri.port, 'getVM');
      await request.close();
      fail('Unexpected successful response');
    } catch (e) {
      expect(
        e.toString(),
        contains(
          'Connection closed before full header was received',
        ),
      );
    } finally {
      await dds.shutdown();
      await dds.done;
    }
  });
}
