// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import 'package:async/src/stream_queue.dart';
import 'package:dwds/data/extension_request.dart';
import 'package:dwds/dwds.dart';
import 'package:dwds/src/servers/extension_backend.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';
import 'package:test/test.dart';

class MockSocketHandler implements SocketHandler {
  static const mockResponse = 'Returned from MockSocketHandler';
  @override
  StreamQueue<SocketConnection> get connections =>
      StreamQueue(const Stream.empty());

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(mockResponse);
  }

  @override
  void shutdown() {}
}

void main() {
  ExtensionBackend extensionBackend;

  setUpAll(() async {
    extensionBackend =
        await ExtensionBackend.start(MockSocketHandler(), 'localhost');
  });
  test('returns success statusCode', () async {
    final result = await http.get(Uri.parse(
        'http://localhost:${extensionBackend.port}/$authenticationPath'));
    expect(result.statusCode, 200);
  });

  test('returns expected authentication response', () async {
    final result = await http.get(Uri.parse(
        'http://localhost:${extensionBackend.port}/$authenticationPath'));
    expect(result.body, authenticationResponse);
  });

  test('delegates to the underlying socket handler', () async {
    final result = await http.get(
        Uri.parse('http://localhost:${extensionBackend.port}/somedummypath'));
    expect(result.body, MockSocketHandler.mockResponse);
  });
}
