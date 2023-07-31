// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../utils.dart';

class TestClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

void main() {
  late Uri serverUrl;
  setUpAll(() async {
    serverUrl = await startServer();
  });

  group('http.', () {
    test('head', () async {
      var response = await http.head(serverUrl);
      expect(response.statusCode, equals(200));
      expect(response.body, equals(''));
    });

    test('head runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.head(serverUrl), () => TestClient()),
          throwsUnimplementedError);
    });

    test('get', () async {
      var response = await http.get(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('get runWithClient', () {
      expect(
          () =>
              http.runWithClient(() => http.get(serverUrl), () => TestClient()),
          throwsUnimplementedError);
    });

    test('post', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('post with string', () async {
      var response = await http.post(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('post with bytes', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('post with fields', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('post runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.post(serverUrl, body: 'testing'), () => TestClient()),
          throwsUnimplementedError);
    });

    test('put', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('put with string', () async {
      var response = await http.put(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('put with bytes', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('put with fields', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('put runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.put(serverUrl, body: 'testing'), () => TestClient()),
          throwsUnimplementedError);
    });

    test('patch', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('patch with string', () async {
      var response = await http.patch(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('patch with bytes', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('patch with fields', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('delete', () async {
      var response = await http.delete(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(allOf(
              containsPair('method', 'DELETE'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('patch runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.patch(serverUrl, body: 'testing'), () => TestClient()),
          throwsUnimplementedError);
    });

    test('read', () async {
      var response = await http.read(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(
          response,
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('read throws an error for a 4** status code', () {
      expect(http.read(serverUrl.resolve('/error')), throwsClientException());
    });

    test('read runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.read(serverUrl), () => TestClient()),
          throwsUnimplementedError);
    });

    test('readBytes', () async {
      var bytes = await http.readBytes(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });

      expect(
          String.fromCharCodes(bytes),
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('readBytes throws an error for a 4** status code', () {
      expect(
          http.readBytes(serverUrl.resolve('/error')), throwsClientException());
    });

    test('readBytes runWithClient', () {
      expect(
          () => http.runWithClient(
              () => http.readBytes(serverUrl), () => TestClient()),
          throwsUnimplementedError);
    });
  });
}
