// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  setUp(startServer);

  tearDown(stopServer);

  group('contentLength', () {
    test('controls the Content-Length header', () async {
      var request = http.StreamedRequest('POST', serverUrl)
        ..contentLength = 10
        ..sink.add([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        ..sink.close();

      var response = await request.send();
      expect(
          await utf8.decodeStream(response.stream),
          parse(
              containsPair('headers', containsPair('content-length', ['10']))));
    });

    test('defaults to sending no Content-Length', () async {
      var request = http.StreamedRequest('POST', serverUrl);
      request.sink.add([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      request.sink.close();

      var response = await request.send();
      expect(await utf8.decodeStream(response.stream),
          parse(containsPair('headers', isNot(contains('content-length')))));
    });
  });

  // Regression test.
  test('.send() with a response with no content length', () async {
    var request =
        http.StreamedRequest('GET', serverUrl.resolve('/no-content-length'));
    request.sink.close();
    var response = await request.send();
    expect(await utf8.decodeStream(response.stream), equals('body'));
  });
}
