// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' hide Request;
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  group('supports a String body', () {
    test('readAsString', () {
      var response = Response.ok('hello, world');
      expect(response.readAsString(), completion(equals('hello, world')));
    });

    test('read', () {
      var helloWorldBytes = [...helloBytes, ...worldBytes];

      var response = Response.ok('hello, world');
      expect(response.read().toList(), completion(equals([helloWorldBytes])));
    });
  });

  test('supports a Uint8List body without copying', () async {
    var bytes = Uint8List(10);
    var response = Response.ok(bytes);

    expect(response.contentLength, 10);
    expect(await response.read().single, same(bytes));
  });

  test('supports a List<int> body without copying', () async {
    var bytes = <int>[1, 2, 3, 4];
    var response = Response.ok(bytes);

    expect(response.contentLength, 4);
    expect(await response.read().single, same(bytes));
  });

  test('supports a Stream<List<int>> body without copying', () async {
    var bytes = Stream.value(<int>[1, 2, 3, 4]);
    var response = Response.ok(bytes);

    expect(response.read(), same(bytes));
  });

  test('Copies a dynamic list of int elements', () async {
    var bytes = <dynamic>[1, 2, 3, 4];
    var response = Response.ok(bytes);

    expect(response.contentLength, 4);
    expect(await response.read().single,
        isA<List<int>>().having((values) => values, 'values', [1, 2, 3, 4]));
  });

  test('allows content-length header even if body is null', () async {
    // needed for HEAD responses
    var response = Response.ok(null, headers: {'Content-Length': '42'});

    expect(response.contentLength, 42);
    expect(await response.readAsString(), isEmpty);
  });

  test('clears content-length for notModified response', () async {
    var response = Response.notModified(headers: {'Content-Length': '42'});

    expect(response.contentLength, 0);
    expect(await response.readAsString(), isEmpty);
  });

  group('new Response.internalServerError without a body', () {
    test('sets the body to "Internal Server Error"', () {
      var response = Response.internalServerError();
      expect(
          response.readAsString(), completion(equals('Internal Server Error')));
    });

    test('sets the content-type header to text/plain', () {
      var response = Response.internalServerError();
      expect(response.headers, containsPair('content-type', 'text/plain'));
    });

    test('preserves content-type parameters', () {
      var response = Response.internalServerError(headers: {
        'content-type': 'application/octet-stream; param=whatever'
      });
      expect(response.headers,
          containsPair('content-type', 'text/plain; param=whatever'));
    });
  });

  group('Response.badRequest:', () {
    test('no supplied body results in "Bad Request"', () {
      var response = Response.badRequest();
      expect(response.readAsString(), completion(equals('Bad Request')));
    });

    test('sets body', () {
      var response = Response.badRequest(body: 'missing token');
      expect(response.readAsString(), completion(equals('missing token')));
    });
  });

  group('Response.unauthorized:', () {
    test('sets body', () {
      var response = Response.unauthorized('request unauthorized');
      expect(
          response.readAsString(), completion(equals('request unauthorized')));
      expect(response.statusCode, 401);
    });
  });

  group('Response redirect', () {
    test('sets the location header for a String', () {
      var response = Response.found('/foo');
      expect(response.headers, containsPair('location', '/foo'));
    });

    test('sets the location header for a Uri', () {
      var response = Response.found(Uri(path: '/foo'));
      expect(response.headers, containsPair('location', '/foo'));
    });
  });

  group('expires', () {
    test('is null without an Expires header', () {
      expect(Response.ok('okay!').expires, isNull);
    });

    test('comes from the Expires header', () {
      expect(
          Response.ok('okay!',
              headers: {'expires': 'Sun, 06 Nov 1994 08:49:37 GMT'}).expires,
          equals(DateTime.parse('1994-11-06 08:49:37z')));
    });
  });

  group('lastModified', () {
    test('is null without a Last-Modified header', () {
      expect(Response.ok('okay!').lastModified, isNull);
    });

    test('comes from the Last-Modified header', () {
      expect(
          Response.ok('okay!',
                  headers: {'last-modified': 'Sun, 06 Nov 1994 08:49:37 GMT'})
              .lastModified,
          equals(DateTime.parse('1994-11-06 08:49:37z')));
    });
  });

  group('change', () {
    test('with no arguments returns instance with equal values', () {
      var controller = StreamController<Object>();

      var request = Response(345,
          body: 'hèllo, world',
          encoding: latin1,
          headers: {'header1': 'header value 1'},
          context: {'context1': 'context value 1'});

      var copy = request.change();

      expect(copy.statusCode, request.statusCode);
      expect(copy.readAsString(), completion('hèllo, world'));
      expect(copy.headers, same(request.headers));
      expect(copy.encoding, request.encoding);
      expect(copy.context, same(request.context));

      controller.add(helloBytes);
      return Future(() {
        controller
          ..add(worldBytes)
          ..close();
      });
    });

    test('allows the original response to be read', () {
      var response = Response.ok(null);
      var changed = response.change();

      expect(response.read().toList(), completion(isEmpty));
      expect(changed.read, throwsStateError);
    });

    test('allows the changed response to be read', () {
      var response = Response.ok(null);
      var changed = response.change();

      expect(changed.read().toList(), completion(isEmpty));
      expect(response.read, throwsStateError);
    });

    test('allows another changed response to be read', () {
      var response = Response.ok(null);
      var changed1 = response.change();
      var changed2 = response.change();

      expect(changed2.read().toList(), completion(isEmpty));
      expect(changed1.read, throwsStateError);
      expect(response.read, throwsStateError);
    });

    group('change headers', () {
      final response = Response(
        345,
        body: null,
        headers: {'header1': 'header value 1'},
      );

      test('delete value with null', () {
        final r = response.change(
          headers: {'header1': null},
          context: {'context1': null},
        );
        expect(r.headers, {'content-length': '0'});
        expect(r.headersAll, {
          'content-length': ['0'],
        });
        expect(r.context, isEmpty);
      });

      test('delete value with empty list', () {
        final r = response.change(headers: {'header1': <String>[]});
        expect(r.headers, {'content-length': '0'});
        expect(r.headersAll, {
          'content-length': ['0'],
        });
      });

      test('override value with new String', () {
        final r = response.change(headers: {'header1': 'new header value'});
        expect(r.headers, {
          'header1': 'new header value',
          'content-length': '0',
        });
        expect(r.headersAll, {
          'header1': ['new header value'],
          'content-length': ['0'],
        });
      });

      test('override value with new single-item List', () {
        final r = response.change(headers: {
          'header1': ['new header value']
        });
        expect(r.headers, {
          'header1': 'new header value',
          'content-length': '0',
        });
        expect(r.headersAll, {
          'header1': ['new header value'],
          'content-length': ['0'],
        });
      });

      test('override value with new multi-item List', () {
        final r = response.change(headers: {
          'header1': ['new header value', 'other value']
        });
        expect(r.headers, {
          'header1': 'new header value,other value',
          'content-length': '0',
        });
        expect(r.headersAll, {
          'header1': ['new header value', 'other value'],
          'content-length': ['0'],
        });
      });

      test('adding a new values', () {
        final r = response.change(headers: {
          'a': 'A',
          'b': ['B1', 'B2'],
        }).change(headers: {'c': 'C'});
        expect(r.headers, {
          'header1': 'header value 1',
          'content-length': '0',
          'a': 'A',
          'b': 'B1,B2',
          'c': 'C'
        });
        expect(r.headersAll, {
          'header1': ['header value 1'],
          'content-length': ['0'],
          'a': ['A'],
          'b': ['B1', 'B2'],
          'c': ['C'],
        });
      });
    });
  });
}
