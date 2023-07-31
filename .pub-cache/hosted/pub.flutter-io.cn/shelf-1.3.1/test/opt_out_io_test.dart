// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9
@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/src/util.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() async {
    if (_server != null) {
      await _server.close(force: true);
      _server = null;
    }
  });

  test('sync null response leads to a 500', () async {
    await _scheduleServer((request) => null);

    var response = await _get();
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.body, 'Internal Server Error');
  });

  test('async null response leads to a 500', () async {
    await _scheduleServer((request) async => null);

    var response = await _get();
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.body, 'Internal Server Error');
  });
}

int get _serverPort => _server.port;

HttpServer _server;

Future<void> _scheduleServer(
  Handler handler, {
  SecurityContext securityContext,
}) async {
  assert(_server == null);
  _server = await shelf_io.serve(
    handler,
    'localhost',
    0,
    securityContext: securityContext,
  );
}

Future<http.Response> _get({
  Map<String, /* String | List<String> */ Object> headers,
  String path = '',
}) async {
  // TODO: use http.Client once it supports sending/receiving multiple headers.
  final client = HttpClient();
  try {
    final rq =
        await client.getUrl(Uri.parse('http://localhost:$_serverPort/$path'));
    headers?.forEach((key, value) {
      rq.headers.add(key, value);
    });
    final rs = await rq.close();
    final rsHeaders = <String, String>{};
    rs.headers.forEach((name, values) {
      rsHeaders[name] = joinHeaderValues(values);
    });
    return http.Response.fromStream(http.StreamedResponse(
      rs,
      rs.statusCode,
      headers: rsHeaders,
    ));
  } finally {
    client.close(force: true);
  }
}
