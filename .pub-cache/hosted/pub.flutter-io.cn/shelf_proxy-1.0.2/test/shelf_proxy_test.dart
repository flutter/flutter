// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:test/test.dart';

/// The URI of the server the current proxy server is proxying to.
late Uri targetUri;

/// The URI of the current proxy server.
late Uri proxyUri;

void main() {
  group('forwarding', () {
    test('forwards request method', () async {
      await createProxy((request) {
        expect(request.method, equals('DELETE'));
        return shelf.Response.ok(':)');
      });

      await http.delete(proxyUri);
    });

    test('forwards request headers', () async {
      await createProxy((request) {
        expect(request.headers, containsPair('foo', 'bar'));
        expect(request.headers, containsPair('accept', '*/*'));
        return shelf.Response.ok(':)');
      });

      await get(headers: {'foo': 'bar', 'accept': '*/*'});
    });

    test('forwards request body', () async {
      await createProxy((request) {
        expect(request.readAsString(), completion(equals('hello, server')));
        return shelf.Response.ok(':)');
      });

      await http.post(proxyUri, body: 'hello, server');
    });

    test('forwards response status', () async {
      await createProxy((request) => shelf.Response(567));

      final response = await get();
      expect(response.statusCode, equals(567));
    });

    test('forwards response headers', () async {
      await createProxy((request) =>
          shelf.Response.ok(':)', headers: {'foo': 'bar', 'accept': '*/*'}));

      final response = await get();

      expect(response.headers, containsPair('foo', 'bar'));
      expect(response.headers, containsPair('accept', '*/*'));
    });

    test('forwards response body', () async {
      await createProxy((request) => shelf.Response.ok('hello, client'));

      expect(await http.read(proxyUri), equals('hello, client'));
    });

    test('adjusts the Host header for the target server', () async {
      await createProxy((request) {
        expect(request.headers, containsPair('host', targetUri.authority));
        return shelf.Response.ok(':)');
      });

      await get();
    });
  });

  group('via', () {
    test('adds a Via header to the request', () async {
      await createProxy((request) {
        expect(request.headers, containsPair('via', '1.1 shelf_proxy'));
        return shelf.Response.ok(':)');
      });

      await get();
    });

    test("adds to a request's existing Via header", () async {
      await createProxy((request) {
        expect(request.headers,
            containsPair('via', '1.0 something, 1.1 shelf_proxy'));
        return shelf.Response.ok(':)');
      });

      await get(headers: {'via': '1.0 something'});
    });

    test('adds a Via header to the response', () async {
      await createProxy((request) => shelf.Response.ok(':)'));

      final response = await get();
      expect(response.headers, containsPair('via', '1.1 shelf_proxy'));
    });

    test("adds to a response's existing Via header", () async {
      await createProxy((request) =>
          shelf.Response.ok(':)', headers: {'via': '1.0 something'}));

      final response = await get();
      expect(response.headers,
          containsPair('via', '1.0 something, 1.1 shelf_proxy'));
    });
  });

  group('redirects', () {
    test("doesn't modify a Location for a foreign server", () async {
      await createProxy(
          (request) => shelf.Response.found('http://dartlang.org'));

      final response = await get();
      expect(response.headers, containsPair('location', 'http://dartlang.org'));
    });

    test('relativizes a reachable root-relative Location', () async {
      await createProxy((request) => shelf.Response.found('/foo/bar'),
          targetPath: '/foo');

      final response = await get();
      expect(response.headers, containsPair('location', '/bar'));
    });

    test('absolutizes an unreachable root-relative Location', () async {
      await createProxy((request) => shelf.Response.found('/baz'),
          targetPath: '/foo');

      final response = await get();
      expect(response.headers,
          containsPair('location', targetUri.resolve('/baz').toString()));
    });
  });

  test('removes a transfer-encoding header', () async {
    final handler = mockHandler((request) =>
        http.Response('', 200, headers: {'transfer-encoding': 'chunked'}));

    final response =
        await handler(shelf.Request('GET', Uri.parse('http://localhost/')));

    expect(response.headers, isNot(contains('transfer-encoding')));
  });

  test('removes content-length and content-encoding for a gzipped response',
      () async {
    final handler = mockHandler((request) => http.Response('', 200,
        headers: {'content-encoding': 'gzip', 'content-length': '1234'}));

    final response =
        await handler(shelf.Request('GET', Uri.parse('http://localhost/')));

    expect(response.headers, isNot(contains('content-encoding')));
    expect(response.headers, isNot(contains('content-length')));
    expect(response.headers,
        containsPair('warning', '214 shelf_proxy "GZIP decoded"'));
  });
}

/// Creates a proxy server proxying to a server running [handler].
///
/// [targetPath] is the root-relative path on the target server to proxy to. It
/// defaults to `/`.
Future<void> createProxy(shelf.Handler handler, {String? targetPath}) async {
  handler = expectAsync1(handler, reason: 'target server handler');
  final targetServer = await shelf_io.serve(handler, 'localhost', 0);
  targetUri = Uri.parse('http://localhost:${targetServer.port}');
  if (targetPath != null) targetUri = targetUri.resolve(targetPath);
  final proxyServerHandler =
      expectAsync1(proxyHandler(targetUri), reason: 'proxy server handler');

  final proxyServer = await shelf_io.serve(proxyServerHandler, 'localhost', 0);
  proxyUri = Uri.parse('http://localhost:${proxyServer.port}');

  addTearDown(() {
    proxyServer.close(force: true);
    targetServer.close(force: true);
  });
}

/// Creates a [shelf.Handler] that's backed by a [MockClient] running
/// [callback].
shelf.Handler mockHandler(
    FutureOr<http.Response> Function(http.Request) callback) {
  final client = MockClient((request) async => await callback(request));
  return proxyHandler('http://dartlang.org', client: client);
}

/// Schedules a GET request with [headers] to the proxy server.
Future<http.Response> get({Map<String, String>? headers}) {
  final uri = proxyUri;
  final request = http.Request('GET', uri);
  if (headers != null) request.headers.addAll(headers);
  request.followRedirects = false;
  return request.send().then(http.Response.fromStream);
}
