// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_util.dart';

void main() {
  setUp(() async {
    await d.file('file.txt', 'contents').create();
    await d.file('random.unknown', 'no clue').create();
  });

  test('serves the file contents', () async {
    final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
    final response = await makeRequest(handler, '/file.txt');
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.contentLength, equals(8));
    expect(response.readAsString(), completion(equals('contents')));
  });

  test('serves a 404 for a non-matching URL', () async {
    final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
    final response = await makeRequest(handler, '/foo/file.txt');
    expect(response.statusCode, equals(HttpStatus.notFound));
  });

  test('serves the file contents under a custom URL', () async {
    final handler =
        createFileHandler(p.join(d.sandbox, 'file.txt'), url: 'foo/bar');
    final response = await makeRequest(handler, '/foo/bar');
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.contentLength, equals(8));
    expect(response.readAsString(), completion(equals('contents')));
  });

  test("serves a 404 if the custom URL isn't matched", () async {
    final handler =
        createFileHandler(p.join(d.sandbox, 'file.txt'), url: 'foo/bar');
    final response = await makeRequest(handler, '/file.txt');
    expect(response.statusCode, equals(HttpStatus.notFound));
  });

  group('the content type header', () {
    test('is inferred from the file path', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(handler, '/file.txt');
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.mimeType, equals('text/plain'));
    });

    test("is omitted if it can't be inferred", () async {
      final handler = createFileHandler(p.join(d.sandbox, 'random.unknown'));
      final response = await makeRequest(handler, '/random.unknown');
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.mimeType, isNull);
    });

    test('comes from the contentType parameter', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'),
          contentType: 'something/weird');
      final response = await makeRequest(handler, '/file.txt');
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.mimeType, equals('something/weird'));
    });
  });

  group('the content range header', () {
    test('is bytes from 0 to 4', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=0-4'},
      );
      expect(response.statusCode, equals(HttpStatus.partialContent));
      expect(
        response.headers,
        containsPair(HttpHeaders.acceptRangesHeader, 'bytes'),
      );
      expect(
        response.headers,
        containsPair(HttpHeaders.contentRangeHeader, 'bytes 0-4/8'),
      );
      expect(response.headers, containsPair('content-length', '5'));
    });

    test('at the end of has overflow from 0 to 9', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=0-9'},
      );
      expect(
        response.statusCode,
        equals(HttpStatus.partialContent),
      );
      expect(
        response.headers,
        containsPair(HttpHeaders.acceptRangesHeader, 'bytes'),
      );
      expect(
        response.headers,
        containsPair(HttpHeaders.contentRangeHeader, 'bytes 0-7/8'),
      );
      expect(response.headers, containsPair('content-length', '8'));
    });

    test('at the start of has overflow from 8 to 9', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=8-9'},
      );
      expect(response.headers, containsPair('content-length', '0'));
      expect(
        response.headers,
        containsPair(HttpHeaders.acceptRangesHeader, 'bytes'),
      );
      expect(
        response.statusCode,
        HttpStatus.requestedRangeNotSatisfiable,
      );
    });

    test('ignores invalid request with start > end', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=2-1'},
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.contentLength, equals(8));
      expect(response.readAsString(), completion(equals('contents')));
    });

    test('ignores request with start > end', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=2-1'},
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.contentLength, equals(8));
      expect(response.readAsString(), completion(equals('contents')));
    });

    test('ignores request with units other than bytes', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'not-bytes=0-1'},
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.contentLength, equals(8));
      expect(response.readAsString(), completion(equals('contents')));
    });

    test('ignores request with no start or end', () async {
      final handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      final response = await makeRequest(
        handler,
        '/file.txt',
        headers: {'range': 'bytes=-'},
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.contentLength, equals(8));
      expect(response.readAsString(), completion(equals('contents')));
    });
  });

  group('throws an ArgumentError for', () {
    test("a file that doesn't exist", () {
      expect(() => createFileHandler(p.join(d.sandbox, 'nothing.txt')),
          throwsArgumentError);
    });

    test('an absolute URL', () {
      expect(
          () => createFileHandler(p.join(d.sandbox, 'nothing.txt'),
              url: '/foo/bar'),
          throwsArgumentError);
    });
  });
}
