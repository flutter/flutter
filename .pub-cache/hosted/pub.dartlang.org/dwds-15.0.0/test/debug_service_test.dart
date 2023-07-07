// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fixtures/context.dart';

final context = TestContext();

void main() {
  setUpAll(() async {
    // Disable DDS as we're testing DWDS behavior.
    await context.setUp(spawnDds: false);
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('Refuses connections without the auth token', () async {
    expect(
        WebSocket.connect('ws://localhost:${context.debugConnection.port}/ws'),
        throwsA(isA<WebSocketException>()));
  });

  test('Accepts connections with the auth token', () async {
    expect(
        WebSocket.connect('${context.debugConnection.uri}/ws')
            .then((ws) => ws.close()),
        completes);
  });

  test('Refuses additional connections when in single client mode', () async {
    final ddsWs = await WebSocket.connect(
      '${context.debugConnection.uri}/ws',
    );
    final completer = Completer<void>();
    ddsWs.listen((event) {
      final response = json.decode(event as String);
      expect(response['id'], '0');
      expect(response.containsKey('result'), isTrue);
      final result = response['result'] as Map<String, dynamic>;
      expect(result['type'], 'Success');
      completer.complete();
    });

    const yieldControlToDDS = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': '0',
      'method': '_yieldControlToDDS',
      'params': {
        'uri': 'http://localhost:123',
      },
    };
    ddsWs.add(json.encode(yieldControlToDDS));
    await completer.future;

    // While DDS is connected, expect additional connections to fail.
    await expectLater(WebSocket.connect('${context.debugConnection.uri}/ws'),
        throwsA(isA<WebSocketException>()));

    // However, once DDS is disconnected, additional clients can connect again.
    await ddsWs.close();
    expect(
        WebSocket.connect('${context.debugConnection.uri}/ws')
            .then((ws) => ws.close()),
        completes);
  });
}
