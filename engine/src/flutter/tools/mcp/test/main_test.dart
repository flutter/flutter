// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;

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

    expect(outputString, contains('"jsonrpc":"2.0"'));
    expect(outputString, contains('"id":1'));
    expect(outputString, contains('"result"'));
    expect(outputString, contains('"tools"'));

    await inputController.close();
    await server.close();
  });
}
