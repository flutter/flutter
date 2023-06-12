// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late Uri serverUrl;
  setUpAll(() async {
    serverUrl = await startServer();
  });

  test('send happy case', () async {
    final request = http.Request('GET', serverUrl)
      ..body = 'hello'
      ..headers['User-Agent'] = 'Dart';

    final response = await request.send();

    expect(response.statusCode, equals(200));
    final bytesString = await response.stream.bytesToString();
    expect(
        bytesString,
        parse(equals({
          'method': 'GET',
          'path': '/',
          'headers': {
            'content-type': ['text/plain; charset=utf-8'],
            'accept-encoding': ['gzip'],
            'user-agent': ['Dart'],
            'content-length': ['5']
          },
          'body': 'hello',
        })));
  });

  test('without redirects', () async {
    final request = http.Request('GET', serverUrl.resolve('/redirect'))
      ..followRedirects = false;
    final response = await request.send();

    expect(response.statusCode, equals(302));
  });

  test('with redirects', () async {
    final request = http.Request('GET', serverUrl.resolve('/redirect'));
    final response = await request.send();

    expect(response.statusCode, equals(200));
    final bytesString = await response.stream.bytesToString();
    expect(bytesString, parse(containsPair('path', '/')));
  });

  test('exceeding max redirects', () async {
    final request = http.Request('GET', serverUrl.resolve('/loop?1'))
      ..maxRedirects = 2;
    expect(
        request.send(),
        throwsA(isA<http.ClientException>()
            .having((e) => e.message, 'message', 'Redirect limit exceeded')));
  });
}
