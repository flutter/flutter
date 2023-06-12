// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('#contentLength', () {
    test('is computed from bodyBytes', () {
      var request = http.Request('POST', dummyUrl)..bodyBytes = [1, 2, 3, 4, 5];
      expect(request.contentLength, equals(5));
      request.bodyBytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      expect(request.contentLength, equals(10));
    });

    test('is computed from body', () {
      var request = http.Request('POST', dummyUrl)..body = 'hello';
      expect(request.contentLength, equals(5));
      request.body = 'hello, world';
      expect(request.contentLength, equals(12));
    });

    test('is not directly mutable', () {
      var request = http.Request('POST', dummyUrl);
      expect(() => request.contentLength = 50, throwsUnsupportedError);
    });
  });

  group('#encoding', () {
    test('defaults to utf-8', () {
      var request = http.Request('POST', dummyUrl);
      expect(request.encoding.name, equals(utf8.name));
    });

    test('can be set', () {
      var request = http.Request('POST', dummyUrl)..encoding = latin1;
      expect(request.encoding.name, equals(latin1.name));
    });

    test('is based on the content-type charset if it exists', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'text/plain; charset=iso-8859-1';
      expect(request.encoding.name, equals(latin1.name));
    });

    test('remains the default if the content-type charset is set and unset',
        () {
      var request = http.Request('POST', dummyUrl)
        ..encoding = latin1
        ..headers['Content-Type'] = 'text/plain; charset=utf-8';
      expect(request.encoding.name, equals(utf8.name));

      request.headers.remove('Content-Type');
      expect(request.encoding.name, equals(latin1.name));
    });

    test('throws an error if the content-type charset is unknown', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] =
          'text/plain; charset=not-a-real-charset';
      expect(() => request.encoding, throwsFormatException);
    });
  });

  group('#bodyBytes', () {
    test('defaults to empty', () {
      var request = http.Request('POST', dummyUrl);
      expect(request.bodyBytes, isEmpty);
    });

    test('can be set', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyBytes = [104, 101, 108, 108, 111];
      expect(request.bodyBytes, equals([104, 101, 108, 108, 111]));
    });

    test('changes when body changes', () {
      var request = http.Request('POST', dummyUrl)..body = 'hello';
      expect(request.bodyBytes, equals([104, 101, 108, 108, 111]));
    });
  });

  group('#body', () {
    test('defaults to empty', () {
      var request = http.Request('POST', dummyUrl);
      expect(request.body, isEmpty);
    });

    test('can be set', () {
      var request = http.Request('POST', dummyUrl)..body = 'hello';
      expect(request.body, equals('hello'));
    });

    test('changes when bodyBytes changes', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyBytes = [104, 101, 108, 108, 111];
      expect(request.body, equals('hello'));
    });

    test('is encoded according to the given encoding', () {
      var request = http.Request('POST', dummyUrl)
        ..encoding = latin1
        ..body = 'föøbãr';
      expect(request.bodyBytes, equals([102, 246, 248, 98, 227, 114]));
    });

    test('is decoded according to the given encoding', () {
      var request = http.Request('POST', dummyUrl)
        ..encoding = latin1
        ..bodyBytes = [102, 246, 248, 98, 227, 114];
      expect(request.body, equals('föøbãr'));
    });
  });

  group('#bodyFields', () {
    test("can't be read without setting the content-type", () {
      var request = http.Request('POST', dummyUrl);
      expect(() => request.bodyFields, throwsStateError);
    });

    test("can't be read with the wrong content-type", () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'text/plain';
      expect(() => request.bodyFields, throwsStateError);
    });

    test("can't be set with the wrong content-type", () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'text/plain';
      expect(() => request.bodyFields = {}, throwsStateError);
    });

    test('defaults to empty', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      expect(request.bodyFields, isEmpty);
    });

    test('can be set with no content-type', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyFields = {'hello': 'world'};
      expect(request.bodyFields, equals({'hello': 'world'}));
    });

    test('changes when body changes', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      request.body = 'key%201=value&key+2=other%2bvalue';
      expect(request.bodyFields,
          equals({'key 1': 'value', 'key 2': 'other+value'}));
    });

    test('is encoded according to the given encoding', () {
      var request = http.Request('POST', dummyUrl)
        ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
        ..encoding = latin1
        ..bodyFields = {'föø': 'bãr'};
      expect(request.body, equals('f%F6%F8=b%E3r'));
    });

    test('is decoded according to the given encoding', () {
      var request = http.Request('POST', dummyUrl)
        ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
        ..encoding = latin1
        ..body = 'f%F6%F8=b%E3r';
      expect(request.bodyFields, equals({'föø': 'bãr'}));
    });
  });

  group('content-type header', () {
    test('defaults to empty', () {
      var request = http.Request('POST', dummyUrl);
      expect(request.headers['Content-Type'], isNull);
    });

    test('defaults to empty if only encoding is set', () {
      var request = http.Request('POST', dummyUrl)..encoding = latin1;
      expect(request.headers['Content-Type'], isNull);
    });

    test('name is case insensitive', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['CoNtEnT-tYpE'] = 'application/json';
      expect(request.headers, containsPair('content-type', 'application/json'));
    });

    test(
        'is set to application/x-www-form-urlencoded with charset utf-8 if '
        'bodyFields is set', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyFields = {'hello': 'world'};
      expect(request.headers['Content-Type'],
          equals('application/x-www-form-urlencoded; charset=utf-8'));
    });

    test(
        'is set to application/x-www-form-urlencoded with the given charset '
        'if bodyFields and encoding are set', () {
      var request = http.Request('POST', dummyUrl)
        ..encoding = latin1
        ..bodyFields = {'hello': 'world'};
      expect(request.headers['Content-Type'],
          equals('application/x-www-form-urlencoded; charset=iso-8859-1'));
    });

    test(
        'is set to text/plain and the given encoding if body and encoding are '
        'both set', () {
      var request = http.Request('POST', dummyUrl)
        ..encoding = latin1
        ..body = 'hello, world';
      expect(request.headers['Content-Type'],
          equals('text/plain; charset=iso-8859-1'));
    });

    test('is modified to include utf-8 if body is set', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/json';
      request.body = '{"hello": "world"}';
      expect(request.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
    });

    test('is modified to include the given encoding if encoding is set', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/json';
      request.encoding = latin1;
      expect(request.headers['Content-Type'],
          equals('application/json; charset=iso-8859-1'));
    });

    test('has its charset overridden by an explicit encoding', () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.encoding = latin1;
      expect(request.headers['Content-Type'],
          equals('application/json; charset=iso-8859-1'));
    });

    test("doesn't have its charset overridden by setting bodyFields", () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] =
          'application/x-www-form-urlencoded; charset=iso-8859-1';
      request.bodyFields = {'hello': 'world'};
      expect(request.headers['Content-Type'],
          equals('application/x-www-form-urlencoded; charset=iso-8859-1'));
    });

    test("doesn't have its charset overridden by setting body", () {
      var request = http.Request('POST', dummyUrl);
      request.headers['Content-Type'] = 'application/json; charset=iso-8859-1';
      request.body = '{"hello": "world"}';
      expect(request.headers['Content-Type'],
          equals('application/json; charset=iso-8859-1'));
    });
  });

  group('#finalize', () {
    test('returns a stream that emits the request body', () {
      var request = http.Request('POST', dummyUrl)..body = 'Hello, world!';
      expect(request.finalize().bytesToString(),
          completion(equals('Hello, world!')));
    });

    test('freezes #persistentConnection', () {
      var request = http.Request('POST', dummyUrl)..finalize();

      expect(request.persistentConnection, isTrue);
      expect(() => request.persistentConnection = false, throwsStateError);
    });

    test('freezes #followRedirects', () {
      var request = http.Request('POST', dummyUrl)..finalize();

      expect(request.followRedirects, isTrue);
      expect(() => request.followRedirects = false, throwsStateError);
    });

    test('freezes #maxRedirects', () {
      var request = http.Request('POST', dummyUrl)..finalize();

      expect(request.maxRedirects, equals(5));
      expect(() => request.maxRedirects = 10, throwsStateError);
    });

    test('freezes #encoding', () {
      var request = http.Request('POST', dummyUrl)..finalize();

      expect(request.encoding.name, equals(utf8.name));
      expect(() => request.encoding = ascii, throwsStateError);
    });

    test('freezes #bodyBytes', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyBytes = [1, 2, 3]
        ..finalize();

      expect(request.bodyBytes, equals([1, 2, 3]));
      expect(() => request.bodyBytes = [4, 5, 6], throwsStateError);
    });

    test('freezes #body', () {
      var request = http.Request('POST', dummyUrl)
        ..body = 'hello'
        ..finalize();

      expect(request.body, equals('hello'));
      expect(() => request.body = 'goodbye', throwsStateError);
    });

    test('freezes #bodyFields', () {
      var request = http.Request('POST', dummyUrl)
        ..bodyFields = {'hello': 'world'}
        ..finalize();

      expect(request.bodyFields, equals({'hello': 'world'}));
      expect(() => request.bodyFields = {}, throwsStateError);
    });

    test("can't be called twice", () {
      var request = http.Request('POST', dummyUrl)..finalize();
      expect(request.finalize, throwsStateError);
    });
  });

  group('#toString()', () {
    test('includes the method and URL', () {
      var request = http.Request('POST', dummyUrl);
      expect(request.toString(), 'POST $dummyUrl');
    });
  });

  group('#method', () {
    test('must be a token', () {
      expect(() => http.Request('LLAMA[0]', dummyUrl), throwsArgumentError);
    });
  });
}
