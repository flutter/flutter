// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:shelf/src/message.dart';
import 'package:test/test.dart';

import 'test_util.dart';

class _TestMessage extends Message {
  _TestMessage(Map<String, /* String | List<String> */ Object>? headers,
      Map<String, Object>? context, super.body, Encoding? encoding)
      : super(headers: headers, context: context, encoding: encoding);

  @override
  Message change(
      {Map<String, String>? headers,
      Map<String, Object>? context,
      Object? body}) {
    throw UnimplementedError();
  }
}

Message _createMessage(
    {Map<String, /* String | List<String> */ Object>? headers,
    Map<String, Object>? context,
    Object? body,
    Encoding? encoding}) {
  return _TestMessage(headers, context, body, encoding);
}

void main() {
  group('headers', () {
    test('message headers are case insensitive', () {
      var message = _createMessage(headers: {'foo': 'bar'});

      expect(message.headers, containsPair('foo', 'bar'));
      expect(message.headers, containsPair('Foo', 'bar'));
      expect(message.headers, containsPair('FOO', 'bar'));
      expect(message.headersAll, containsPair('foo', ['bar']));
      expect(message.headersAll, containsPair('Foo', ['bar']));
      expect(message.headersAll, containsPair('FOO', ['bar']));
    });

    test('null header value becomes default', () {
      var message = _createMessage();
      expect(message.headers, equals({'content-length': '0'}));
      expect(message.headers, containsPair('CoNtEnT-lEnGtH', '0'));
      expect(message.headers, same(_createMessage().headers));
      expect(() => message.headers['h1'] = 'value1', throwsUnsupportedError);
      expect(
          () => message.headersAll['h1'] = ['value1'], throwsUnsupportedError);
    });

    test('headers are immutable', () {
      var message = _createMessage(headers: {'h1': 'value1'});
      expect(() => message.headers['h1'] = 'value1', throwsUnsupportedError);
      expect(() => message.headers['h1'] = 'value2', throwsUnsupportedError);
      expect(() => message.headers['h2'] = 'value2', throwsUnsupportedError);
      expect(
          () => message.headersAll['h1'] = ['value1'], throwsUnsupportedError);
      expect(
          () => message.headersAll['h1'] = ['value2'], throwsUnsupportedError);
      expect(
          () => message.headersAll['h2'] = ['value2'], throwsUnsupportedError);
    });

    test('headers with multiple values', () {
      final message = _createMessage(headers: {
        'a': 'A',
        'b': ['B1', 'B2'],
      });
      expect(message.headers, {
        'a': 'A',
        'b': 'B1,B2',
        'content-length': '0',
      });
      expect(message.headersAll, {
        'a': ['A'],
        'b': ['B1', 'B2'],
        'content-length': ['0'],
      });
    });
  });

  group('context', () {
    test('is accessible', () {
      var message = _createMessage(context: {'foo': 'bar'});
      expect(message.context, containsPair('foo', 'bar'));
    });

    test('null context value becomes empty and immutable', () {
      var message = _createMessage();
      expect(message.context, isEmpty);
      expect(() => message.context['key'] = 'value', throwsUnsupportedError);
    });

    test('is immutable', () {
      var message = _createMessage(context: {'key': 'value'});
      expect(() => message.context['key'] = 'value', throwsUnsupportedError);
      expect(() => message.context['key2'] = 'value', throwsUnsupportedError);
    });
  });

  group('readAsString', () {
    test('supports a null body', () {
      var request = _createMessage();
      expect(request.readAsString(), completion(equals('')));
    });

    test('supports a Stream<List<int>> body', () {
      var controller = StreamController<Object>();
      var request = _createMessage(body: controller.stream);
      expect(request.readAsString(), completion(equals('hello, world')));

      controller.add(helloBytes);
      return Future(() {
        controller
          ..add(worldBytes)
          ..close();
      });
    });

    test('defaults to UTF-8', () {
      var request = _createMessage(
          body: Stream.fromIterable([
        [195, 168]
      ]));
      expect(request.readAsString(), completion(equals('è')));
    });

    test('the content-type header overrides the default', () {
      var request = _createMessage(
          headers: {'content-type': 'text/plain; charset=iso-8859-1'},
          body: Stream.fromIterable([
            [195, 168]
          ]));
      expect(request.readAsString(), completion(equals('Ã¨')));
    });

    test('an explicit encoding overrides the content-type header', () {
      var request = _createMessage(
          headers: {'content-type': 'text/plain; charset=iso-8859-1'},
          body: Stream.fromIterable([
            [195, 168]
          ]));
      expect(request.readAsString(latin1), completion(equals('Ã¨')));
    });
  });

  group('read', () {
    test('supports a null body', () {
      var request = _createMessage();
      expect(request.read().toList(), completion(isEmpty));
    });

    test('supports a Stream<List<int>> body', () {
      var controller = StreamController<Object>();
      var request = _createMessage(body: controller.stream);
      expect(request.read().toList(),
          completion(equals([helloBytes, worldBytes])));

      controller.add(helloBytes);
      return Future(() {
        controller
          ..add(worldBytes)
          ..close();
      });
    });

    test('supports a List<int> body', () {
      var request = _createMessage(body: helloBytes);
      expect(request.read().toList(), completion(equals([helloBytes])));
    });

    test('throws when calling read()/readAsString() multiple times', () {
      Message request;

      request = _createMessage();
      expect(request.read().toList(), completion(isEmpty));
      expect(() => request.read(), throwsStateError);

      request = _createMessage();
      expect(request.readAsString(), completion(isEmpty));
      expect(() => request.readAsString(), throwsStateError);

      request = _createMessage();
      expect(request.readAsString(), completion(isEmpty));
      expect(() => request.read(), throwsStateError);

      request = _createMessage();
      expect(request.read().toList(), completion(isEmpty));
      expect(() => request.readAsString(), throwsStateError);
    });
  });

  group('content-length', () {
    test('is 0 with a default body and without a content-length header', () {
      var request = _createMessage();
      expect(request.contentLength, 0);
    });

    test('comes from a byte body', () {
      var request = _createMessage(body: [1, 2, 3]);
      expect(request.contentLength, 3);
    });

    test('comes from a string body', () {
      var request = _createMessage(body: 'foobar');
      expect(request.contentLength, 6);
    });

    test('is set based on byte length for a string body', () {
      var request = _createMessage(body: 'fööbär');
      expect(request.contentLength, 9);

      request = _createMessage(body: 'fööbär', encoding: latin1);
      expect(request.contentLength, 6);
    });

    test('is null for a stream body', () {
      var request = _createMessage(body: Stream<List<int>>.empty());
      expect(request.contentLength, isNull);
    });

    test('uses the content-length header for a stream body', () {
      var request = _createMessage(
          body: Stream<List<int>>.empty(), headers: {'content-length': '42'});
      expect(request.contentLength, 42);
    });

    test('real body length takes precedence over content-length header', () {
      var request =
          _createMessage(body: [1, 2, 3], headers: {'content-length': '42'});
      expect(request.contentLength, 3);
    });

    test('is null for a chunked transfer encoding', () {
      var request = _createMessage(
          body: '1\r\na0\r\n\r\n', headers: {'transfer-encoding': 'chunked'});
      expect(request.contentLength, isNull);
    });

    test('is null for a non-identity transfer encoding', () {
      var request = _createMessage(
          body: '1\r\na0\r\n\r\n', headers: {'transfer-encoding': 'custom'});
      expect(request.contentLength, isNull);
    });

    test('is set for identity transfer encoding', () {
      var request = _createMessage(
          body: '1\r\na0\r\n\r\n', headers: {'transfer-encoding': 'identity'});
      expect(request.contentLength, equals(9));
    });
  });

  group('mimeType', () {
    test('is null without a content-type header', () {
      expect(_createMessage().mimeType, isNull);
    });

    test('comes from the content-type header', () {
      expect(_createMessage(headers: {'content-type': 'text/plain'}).mimeType,
          equals('text/plain'));
    });

    test("doesn't include parameters", () {
      expect(
          _createMessage(
                  headers: {'content-type': 'text/plain; foo=bar; bar=baz'})
              .mimeType,
          equals('text/plain'));
    });
  });

  group('encoding', () {
    test('is null without a content-type header', () {
      expect(_createMessage().encoding, isNull);
    });

    test('is null without a charset parameter', () {
      expect(_createMessage(headers: {'content-type': 'text/plain'}).encoding,
          isNull);
    });

    test('is null with an unrecognized charset parameter', () {
      expect(
          _createMessage(
              headers: {'content-type': 'text/plain; charset=fblthp'}).encoding,
          isNull);
    });

    test('comes from the content-type charset parameter', () {
      expect(
          _createMessage(
                  headers: {'content-type': 'text/plain; charset=iso-8859-1'})
              .encoding,
          equals(latin1));
    });

    test('comes from the content-type charset parameter with a different case',
        () {
      expect(
          _createMessage(
                  headers: {'Content-Type': 'text/plain; charset=iso-8859-1'})
              .encoding,
          equals(latin1));
    });

    test('defaults to encoding a String as UTF-8', () {
      expect(
          _createMessage(body: 'è').read().toList(),
          completion(equals([
            [195, 168]
          ])));
    });

    test('uses the explicit encoding if available', () {
      expect(
          _createMessage(body: 'è', encoding: latin1).read().toList(),
          completion(equals([
            [232]
          ])));
    });

    test('adds an explicit encoding to the content-type', () {
      var request = _createMessage(
          body: 'è', encoding: latin1, headers: {'content-type': 'text/plain'});
      expect(request.headers,
          containsPair('content-type', 'text/plain; charset=iso-8859-1'));
    });

    test('adds an explicit encoding to the content-type with a different case',
        () {
      var request = _createMessage(
          body: 'è', encoding: latin1, headers: {'Content-Type': 'text/plain'});
      expect(request.headers,
          containsPair('Content-Type', 'text/plain; charset=iso-8859-1'));
    });

    test(
        'sets an absent content-type to application/octet-stream in order to '
        'set the charset', () {
      var request = _createMessage(body: 'è', encoding: latin1);
      expect(
          request.headers,
          containsPair(
              'content-type', 'application/octet-stream; charset=iso-8859-1'));
    });

    test('overwrites an existing charset if given an explicit encoding', () {
      var request = _createMessage(
          body: 'è',
          encoding: latin1,
          headers: {'content-type': 'text/plain; charset=whatever'});
      expect(request.headers,
          containsPair('content-type', 'text/plain; charset=iso-8859-1'));
    });
  });
}
