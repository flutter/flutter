// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/src/util.dart';
import 'package:test/test.dart';

import 'ssl_certs.dart';
import 'test_util.dart';

void main() {
  tearDown(() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  });

  test('sync handler returns a value to the client', () async {
    await _scheduleServer(syncHandler);

    var response = await _get();
    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /');
  });

  test('async handler returns a value to the client', () async {
    await _scheduleServer(asyncHandler);

    var response = await _get();
    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /');
  });

  test('thrown error leads to a 500', () async {
    await _scheduleServer((request) {
      throw UnsupportedError('test');
    });

    var response = await _get();
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.body, 'Internal Server Error');
  });

  test('async error leads to a 500', () async {
    await _scheduleServer((request) {
      return Future.error('test');
    });

    var response = await _get();
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.body, 'Internal Server Error');
  });

  test('supports HEAD requests', () async {
    await _scheduleServer((request) {
      return Response(200, headers: {'content-length': '1'});
    });
    var response = await _head();
    expect(response.headers['content-length'], '1');
  });

  test('Request is populated correctly', () async {
    late Uri uri;

    await _scheduleServer((request) {
      expect(request.method, 'GET');

      expect(request.requestedUri, uri);

      expect(request.url.path, 'foo/bar');
      expect(request.url.pathSegments, ['foo', 'bar']);
      expect(request.protocolVersion, '1.1');
      expect(request.url.query, 'qs=value');
      expect(request.handlerPath, '/');

      return syncHandler(request);
    });

    uri = Uri.http('localhost:$_serverPort', '/foo/bar', {'qs': 'value'});
    var response = await http.get(uri);

    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /foo/bar');
  });

  test('Request can handle colon in first path segment', () async {
    await _scheduleServer(syncHandler);

    var response = await _get(path: 'user:42');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /user:42');
  });

  test('chunked requests are un-chunked', () async {
    await _scheduleServer(expectAsync1((request) {
      expect(request.contentLength, isNull);
      expect(request.method, 'POST');
      expect(
          request.headers, isNot(contains(HttpHeaders.transferEncodingHeader)));
      expect(
          request.read().toList(),
          completion(equals([
            [1, 2, 3, 4]
          ])));
      return Response.ok(null);
    }));

    var request =
        http.StreamedRequest('POST', Uri.http('localhost:$_serverPort', ''));
    request.sink.add([1, 2, 3, 4]);
    request.sink.close();

    var response = await request.send();
    expect(response.statusCode, HttpStatus.ok);
  });

  test('custom response headers are received by the client', () async {
    await _scheduleServer((request) {
      return Response.ok('Hello from /',
          headers: {'test-header': 'test-value', 'test-list': 'a, b, c'});
    });

    var response = await _get();
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers['test-header'], 'test-value');
    expect(response.body, 'Hello from /');
  });

  test('multiple headers are received from the client', () async {
    await _scheduleServer((request) {
      return Response.ok('Hello from /', headers: {
        'requested-values': request.headersAll['request-values']!,
        'requested-values-length':
            request.headersAll['request-values']!.length.toString(),
        'set-cookie-values': request.headersAll['set-cookie']!,
        'set-cookie-values-length':
            request.headersAll['set-cookie']!.length.toString(),
      });
    });

    final response = await _get(headers: {
      'request-values': ['a', 'b'],
      'set-cookie': ['c', 'd'],
    });
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers['requested-values'], 'a, b');
    expect(response.headers['requested-values-length'], '1');
    expect(response.headers['set-cookie-values'], 'c, d');
    expect(response.headers['set-cookie-values-length'], '2');
  });

  test('custom status code is received by the client', () async {
    await _scheduleServer((request) {
      return Response(299, body: 'Hello from /');
    });

    var response = await _get();
    expect(response.statusCode, 299);
    expect(response.body, 'Hello from /');
  });

  test('custom request headers are received by the handler', () async {
    await _scheduleServer((request) {
      expect(request.headers, containsPair('custom-header', 'client value'));

      // dart:io HttpServer splits multi-value headers into an array
      // validate that they are combined correctly
      expect(request.headers, containsPair('multi-header', 'foo,bar,baz'));
      return syncHandler(request);
    });

    var headers = {
      'custom-header': 'client value',
      'multi-header': 'foo,bar,baz'
    };

    var response = await _get(headers: headers);
    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /');
  });

  test('post with empty content', () async {
    await _scheduleServer((request) async {
      expect(request.mimeType, isNull);
      expect(request.encoding, isNull);
      expect(request.method, 'POST');
      expect(request.contentLength, 0);

      var body = await request.readAsString();
      expect(body, '');
      return syncHandler(request);
    });

    var response = await _post();
    expect(response.statusCode, HttpStatus.ok);
    expect(response.stream.bytesToString(), completion('Hello from /'));
  });

  test('post with request content', () async {
    await _scheduleServer((request) async {
      expect(request.mimeType, 'text/plain');
      expect(request.encoding, utf8);
      expect(request.method, 'POST');
      expect(request.contentLength, 9);

      var body = await request.readAsString();
      expect(body, 'test body');
      return syncHandler(request);
    });

    var response = await _post(body: 'test body');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.stream.bytesToString(), completion('Hello from /'));
  });

  test('supports request hijacking', () async {
    await _scheduleServer((request) {
      expect(request.method, 'POST');

      request.hijack(expectAsync1((channel) {
        expect(channel.stream.first, completion(equals('Hello'.codeUnits)));

        channel.sink.add(('HTTP/1.1 404 Not Found\r\n'
                'date: Mon, 23 May 2005 22:38:34 GMT\r\n'
                'Content-Length: 13\r\n'
                '\r\n'
                'Hello, world!')
            .codeUnits);
        channel.sink.close();
      }));
    });

    var response = await _post(body: 'Hello');
    expect(response.statusCode, HttpStatus.notFound);
    expect(response.headers['date'], 'Mon, 23 May 2005 22:38:34 GMT');
    expect(
        response.stream.bytesToString(), completion(equals('Hello, world!')));
  });

  test('reports an error if a HijackException is thrown without hijacking',
      () async {
    await _scheduleServer((request) => throw const HijackException());

    var response = await _get();
    expect(response.statusCode, HttpStatus.internalServerError);
  });

  test('passes asynchronous exceptions to the parent error zone', () async {
    await runZonedGuarded(() async {
      var server = await shelf_io.serve((request) {
        Future(() => throw 'oh no');
        return syncHandler(request);
      }, 'localhost', 0);

      var response = await http.get(Uri.http('localhost:${server.port}', '/'));
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, 'Hello from /');
      await server.close();
    }, expectAsync2((error, stack) {
      expect(error, equals('oh no'));
    }));
  });

  test("doesn't pass asynchronous exceptions to the root error zone", () async {
    var response = await Zone.root.run(() async {
      var server = await shelf_io.serve((request) {
        Future(() => throw 'oh no');
        return syncHandler(request);
      }, 'localhost', 0);

      try {
        return await http.get(Uri.http('localhost:${server.port}', '/'));
      } finally {
        await server.close();
      }
    });

    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, 'Hello from /');
  });

  test('a bad HTTP host request results in a 500 response', () async {
    await _scheduleServer(syncHandler);

    var socket = await Socket.connect('localhost', _serverPort);

    try {
      socket.write('GET / HTTP/1.1\r\n');
      socket.write('Host: ^^super bad !@#host\r\n');
      socket.write('\r\n');
    } finally {
      await socket.close();
    }

    expect(
        await utf8.decodeStream(socket), contains('500 Internal Server Error'));
  });

  test('a bad HTTP URL request results in a 400 response', () async {
    await _scheduleServer(syncHandler);
    final socket = await Socket.connect('localhost', _serverPort);

    try {
      socket.write('GET /#/ HTTP/1.1\r\n');
      socket.write('Host: localhost\r\n');
      socket.write('\r\n');
    } finally {
      await socket.close();
    }

    expect(await utf8.decodeStream(socket), contains('400 Bad Request'));
  });

  group('date header', () {
    test('is sent by default', () async {
      await _scheduleServer(syncHandler);

      // Update beforeRequest to be one second earlier. HTTP dates only have
      // second-level granularity and the request will likely take less than a
      // second.
      var beforeRequest = DateTime.now().subtract(Duration(seconds: 1));

      var response = await _get();
      expect(response.headers, contains('date'));
      var responseDate = parser.parseHttpDate(response.headers['date']!);

      expect(responseDate.isAfter(beforeRequest), isTrue);
      expect(responseDate.isBefore(DateTime.now()), isTrue);
    });

    test('defers to header in response', () async {
      var date = DateTime.utc(1981, 6, 5);
      await _scheduleServer((request) {
        return Response.ok('test',
            headers: {HttpHeaders.dateHeader: parser.formatHttpDate(date)});
      });

      var response = await _get();
      expect(response.headers, contains('date'));
      var responseDate = parser.parseHttpDate(response.headers['date']!);
      expect(responseDate, date);
    });
  });

  group('X-Powered-By header', () {
    const poweredBy = 'x-powered-by';
    test('defaults to "Dart with package:shelf"', () async {
      await _scheduleServer(syncHandler);

      var response = await _get();
      expect(
        response.headers,
        containsPair(poweredBy, 'Dart with package:shelf'),
      );
    });

    test('defers to header in response when default', () async {
      await _scheduleServer((request) {
        return Response.ok('test', headers: {poweredBy: 'myServer'});
      });

      var response = await _get();
      expect(response.headers, containsPair(poweredBy, 'myServer'));
    });

    test('can be set at the server level', () async {
      _server = await shelf_io.serve(
        syncHandler,
        'localhost',
        0,
        poweredByHeader: 'ourServer',
      );
      var response = await _get();
      expect(
        response.headers,
        containsPair(poweredBy, 'ourServer'),
      );
    });

    test('defers to header in response when set at the server level', () async {
      _server = await shelf_io.serve(
        (request) {
          return Response.ok('test', headers: {poweredBy: 'myServer'});
        },
        'localhost',
        0,
        poweredByHeader: 'ourServer',
      );

      var response = await _get();
      expect(response.headers, containsPair(poweredBy, 'myServer'));
    });

    test('is omitted when set to null', () async {
      _server = await shelf_io.serve(
        syncHandler,
        'localhost',
        0,
        poweredByHeader: null,
      );

      var response = await _get();
      expect(
        response.headers,
        isNot(contains(poweredBy)),
      );
    });
  });

  group('chunked coding', () {
    group('is added when the transfer-encoding header is', () {
      test('unset', () async {
        await _scheduleServer((request) {
          return Response.ok(Stream.fromIterable([
            [1, 2, 3, 4]
          ]));
        });

        var response = await _get();
        expect(response.headers,
            containsPair(HttpHeaders.transferEncodingHeader, 'chunked'));
        expect(response.bodyBytes, equals([1, 2, 3, 4]));
      });

      test('"identity"', () async {
        await _scheduleServer((request) {
          return Response.ok(
              Stream.fromIterable([
                [1, 2, 3, 4]
              ]),
              headers: {HttpHeaders.transferEncodingHeader: 'identity'});
        });

        var response = await _get();
        expect(response.headers,
            containsPair(HttpHeaders.transferEncodingHeader, 'chunked'));
        expect(response.bodyBytes, equals([1, 2, 3, 4]));
      });
    });

    test('is preserved when the transfer-encoding header is "chunked"',
        () async {
      await _scheduleServer((request) {
        return Response.ok(
            Stream.fromIterable(['2\r\nhi\r\n0\r\n\r\n'.codeUnits]),
            headers: {HttpHeaders.transferEncodingHeader: 'chunked'});
      });

      var response = await _get();
      expect(response.headers,
          containsPair(HttpHeaders.transferEncodingHeader, 'chunked'));
      expect(response.body, equals('hi'));
    });

    group('is not added when', () {
      test('content-length is set', () async {
        await _scheduleServer((request) {
          return Response.ok(
              Stream.fromIterable([
                [1, 2, 3, 4]
              ]),
              headers: {HttpHeaders.contentLengthHeader: '4'});
        });

        var response = await _get();
        expect(response.headers,
            isNot(contains(HttpHeaders.transferEncodingHeader)));
        expect(response.bodyBytes, equals([1, 2, 3, 4]));
      });

      test('status code is 1xx', () async {
        await _scheduleServer((request) {
          return Response(123, body: Stream<List<int>>.empty());
        });

        var response = await _get();
        expect(response.headers,
            isNot(contains(HttpHeaders.transferEncodingHeader)));
        expect(response.body, isEmpty);
      });

      test('status code is 204', () async {
        await _scheduleServer((request) {
          return Response(204, body: Stream<List<int>>.empty());
        });

        var response = await _get();
        expect(response.headers,
            isNot(contains(HttpHeaders.transferEncodingHeader)));
        expect(response.body, isEmpty);
      });

      test('status code is 304', () async {
        await _scheduleServer((request) {
          return Response(304, body: Stream<List<int>>.empty());
        });

        var response = await _get();
        expect(response.headers,
            isNot(contains(HttpHeaders.transferEncodingHeader)));
        expect(response.body, isEmpty);
      });
    });
  });

  test('respects the "shelf.io.buffer_output" context parameter', () async {
    var controller = StreamController<String>();
    await _scheduleServer((request) {
      controller.add('Hello, ');

      return Response.ok(utf8.encoder.bind(controller.stream),
          context: {'shelf.io.buffer_output': false});
    });

    var request = http.Request('GET', Uri.http('localhost:$_serverPort', ''));

    var response = await request.send();
    var stream = StreamQueue(utf8.decoder.bind(response.stream));

    var data = await stream.next;
    expect(data, equals('Hello, '));
    controller.add('world!');

    data = await stream.next;
    expect(data, equals('world!'));
    await controller.close();
    expect(stream.hasNext, completion(isFalse));
  });

  test('includes the dart:io HttpConnectionInfo in request context', () async {
    await _scheduleServer((request) {
      expect(
          request.context,
          containsPair(
              'shelf.io.connection_info', TypeMatcher<HttpConnectionInfo>()));

      var connectionInfo =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo;
      expect(connectionInfo.remoteAddress, equals(_server!.address));
      expect(connectionInfo.localPort, equals(_server!.port));

      return syncHandler(request);
    });

    var response = await _get();
    expect(response.statusCode, HttpStatus.ok);
  });

  group('ssl tests', () {
    var securityContext = SecurityContext()
      ..setTrustedCertificatesBytes(certChainBytes)
      ..useCertificateChainBytes(certChainBytes)
      ..usePrivateKeyBytes(certKeyBytes, password: 'dartdart');

    var sslClient = HttpClient(context: securityContext);

    Future<HttpClientRequest> scheduleSecureGet() =>
        sslClient.getUrl(Uri.https('localhost:${_server!.port}', ''));

    test('secure sync handler returns a value to the client', () async {
      await _scheduleServer(syncHandler, securityContext: securityContext);

      var req = await scheduleSecureGet();

      var response = await req.close();
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.cast<List<int>>().transform(utf8.decoder).single,
          'Hello from /');
    });

    test('secure async handler returns a value to the client', () async {
      await _scheduleServer(asyncHandler, securityContext: securityContext);

      var req = await scheduleSecureGet();
      var response = await req.close();
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.cast<List<int>>().transform(utf8.decoder).single,
          'Hello from /');
    });
  });
}

int get _serverPort => _server!.port;

HttpServer? _server;

Future<void> _scheduleServer(
  Handler handler, {
  SecurityContext? securityContext,
}) async {
  assert(_server == null);
  _server = await shelf_io.serve(
    handler,
    'localhost',
    0,
    securityContext: securityContext,
  );
}

Future<http.Response> _get(
        {Map<String, /* String | List<String> */ Object>? headers,
        String path = ''}) =>
    _request((client, url) => client.getUrl(url), headers: headers, path: path);

Future<http.Response> _head(
        {Map<String, /* String | List<String> */ Object>? headers,
        String path = ''}) =>
    _request((client, url) => client.headUrl(url),
        headers: headers, path: path);

Future<http.Response> _request(
  Future<HttpClientRequest> Function(HttpClient, Uri) request, {
  Map<String, /* String | List<String> */ Object>? headers,
  String path = '',
}) async {
  // TODO: use http.Client once it supports sending/receiving multiple headers.
  final client = HttpClient();
  try {
    final rq = await request(client, Uri.http('localhost:$_serverPort', path));
    headers?.forEach((key, value) {
      rq.headers.add(key, value);
    });
    final rs = await rq.close();
    final rsHeaders = <String, String>{};
    rs.headers.forEach((name, values) {
      rsHeaders[name] = joinHeaderValues(values)!;
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

Future<http.StreamedResponse> _post(
    {Map<String, String>? headers, String? body}) {
  var request = http.Request('POST', Uri.http('localhost:$_serverPort', ''));

  if (headers != null) request.headers.addAll(headers);
  if (body != null) request.body = body;

  return request.send();
}
