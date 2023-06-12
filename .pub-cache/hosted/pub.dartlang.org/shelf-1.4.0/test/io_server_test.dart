// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  late IOServer server;

  setUp(() async {
    try {
      server = await IOServer.bind(InternetAddress.loopbackIPv6, 0);
    } on SocketException catch (_) {
      server = await IOServer.bind(InternetAddress.loopbackIPv4, 0);
    }
  });

  tearDown(() => server.close());

  test('serves HTTP requests with the mounted handler', () async {
    server.mount(syncHandler);
    expect(await http.read(server.url), equals('Hello from /'));
  });

  test('Handles malformed requests gracefully.', () async {
    server.mount(syncHandler);
    final rs = await http
        .get(Uri.parse('${server.url}/%D0%C2%BD%A8%CE%C4%BC%FE%BC%D0.zip'));
    expect(rs.statusCode, 400);
    expect(rs.body, 'Bad Request');
  });

  test('delays HTTP requests until a handler is mounted', () async {
    expect(http.read(server.url), completion(equals('Hello from /')));
    await Future<void>.delayed(Duration.zero);

    server.mount(asyncHandler);
  });

  test('disallows more than one handler from being mounted', () async {
    server.mount((_) => throw UnimplementedError());
    expect(
      () => server.mount((_) => throw UnimplementedError()),
      throwsStateError,
    );
    expect(
      () => server.mount((_) => throw UnimplementedError()),
      throwsStateError,
    );
  });
}
