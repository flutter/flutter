// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonDecode, utf8;

import 'package:engine_mcp/server.dart' as engine_mcp;
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

void main() {
  test('list tools', () async {
    final McpServer server = engine_mcp.makeServer();
    final inputController = StreamController<List<int>>();
    final outputController = StreamController<List<int>>();

    server.connect(IOStreamTransport(
      stream: inputController.stream,
      sink: outputController.sink,
    ));

    final responseFuture = outputController.stream.first;

    const requestJson = '{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }\n';
    inputController.add(utf8.encode(requestJson));

    final List<int> outputBytes = await responseFuture;
    final String outputString = utf8.decode(outputBytes);

    final Map<String, dynamic> json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(1), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['tools'], isNotEmpty, reason: outputString);

    await inputController.close();
    await server.close();
  });
}
