// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_util.dart';

void main() {
  setUp(() async {
    await d.file('index.html', '<html></html>').create();
    await d.file('root.txt', 'root txt').create();
    await d.file('random.unknown', 'no clue').create();

    const pngBytesContent =
        r'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAABmJLR0QA/wD/AP+gvae'
        r'TAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AYRETkSXaxBzQAAAB1pVFh0Q2'
        r'9tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAAAbUlEQVQI1wXBvwpBYRwA0'
        r'HO/kjBKJmXRLWXxJ4PsnsMTeAEPILvNZrybF7B4A6XvQW6k+DkHwqgM1TnMpoEoDMtw'
        r'OJE7pB/VXmF3CdseucmjxaAruR41Pl9p/Gbyoq5B9FeL2OR7zJ+3aC/X8QdQCyIArPs'
        r'HkQAAAABJRU5ErkJggg==';

    const webpBytesContent =
        r'UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAQAcJaQAA3AA/v3AgAA=';

    await d.dir('files', [
      d.file('test.txt', 'test txt content'),
      d.file('with space.txt', 'with space content'),
      d.file('header_bytes_test_image', base64Decode(pngBytesContent)),
      d.file('header_bytes_test_webp', base64Decode(webpBytesContent))
    ]).create();
  });

  test('access root file', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/root.txt');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 8);
    expect(response.readAsString(), completion('root txt'));
  });

  test('HEAD', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/root.txt', method: 'HEAD');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 8);
    expect(await response.readAsString(), isEmpty);
  });

  test('access root file with space', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/files/with%20space.txt');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 18);
    expect(response.readAsString(), completion('with space content'));
  });

  test('access root file with unencoded space', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/files/with%20space.txt');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 18);
    expect(response.readAsString(), completion('with space content'));
  });

  test('access file under directory', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/files/test.txt');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 16);
    expect(response.readAsString(), completion('test txt content'));
  });

  test('file not found', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/not_here.txt');
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('last modified', () async {
    final handler = createStaticHandler(d.sandbox);

    final rootPath = p.join(d.sandbox, 'root.txt');
    final modified = File(rootPath).statSync().modified.toUtc();

    final response = await makeRequest(handler, '/root.txt');
    expect(response.lastModified, atSameTimeToSecond(modified));
  });

  group('if modified since', () {
    test('same as last modified', () async {
      final handler = createStaticHandler(d.sandbox);

      final rootPath = p.join(d.sandbox, 'root.txt');
      final modified = File(rootPath).statSync().modified.toUtc();

      final headers = {
        HttpHeaders.ifModifiedSinceHeader: formatHttpDate(modified)
      };

      final response =
          await makeRequest(handler, '/root.txt', headers: headers);
      expect(response.statusCode, HttpStatus.notModified);
      expect(response.contentLength, 0);
    });

    test('before last modified', () async {
      final handler = createStaticHandler(d.sandbox);

      final rootPath = p.join(d.sandbox, 'root.txt');
      final modified = File(rootPath).statSync().modified.toUtc();

      final headers = {
        HttpHeaders.ifModifiedSinceHeader:
            formatHttpDate(modified.subtract(const Duration(seconds: 1)))
      };

      final response =
          await makeRequest(handler, '/root.txt', headers: headers);
      expect(response.statusCode, HttpStatus.ok);
      expect(response.lastModified, atSameTimeToSecond(modified));
    });

    test('after last modified', () async {
      final handler = createStaticHandler(d.sandbox);

      final rootPath = p.join(d.sandbox, 'root.txt');
      final modified = File(rootPath).statSync().modified.toUtc();

      final headers = {
        HttpHeaders.ifModifiedSinceHeader:
            formatHttpDate(modified.add(const Duration(seconds: 1)))
      };

      final response =
          await makeRequest(handler, '/root.txt', headers: headers);
      expect(response.statusCode, HttpStatus.notModified);
      expect(response.contentLength, 0);
    });

    test('after file modification', () async {
      // This test updates a file on disk to ensure the file stamp is updated
      // which was previously not the case on Windows due to the files "changed"
      // date being the creation date.
      // https://github.com/dart-lang/shelf_static/issues/37

      final handler = createStaticHandler(d.sandbox);
      final rootPath = p.join(d.sandbox, 'root.txt');

      final response1 = await makeRequest(handler, '/root.txt');
      final originalModificationDate = response1.lastModified!;

      // Ensure the timestamp change is > 1s.
      await Future<void>.delayed(const Duration(seconds: 2));
      File(rootPath).writeAsStringSync('updated root txt');

      final headers = {
        HttpHeaders.ifModifiedSinceHeader:
            formatHttpDate(originalModificationDate)
      };

      final response2 =
          await makeRequest(handler, '/root.txt', headers: headers);
      expect(response2.statusCode, HttpStatus.ok);
      expect(response2.lastModified!.millisecondsSinceEpoch,
          greaterThan(originalModificationDate.millisecondsSinceEpoch));
    });
  });

  group('content type', () {
    test('root.txt should be text/plain', () async {
      final handler = createStaticHandler(d.sandbox);

      final response = await makeRequest(handler, '/root.txt');
      expect(response.mimeType, 'text/plain');
    });

    test('index.html should be text/html', () async {
      final handler = createStaticHandler(d.sandbox);

      final response = await makeRequest(handler, '/index.html');
      expect(response.mimeType, 'text/html');
    });

    test('random.unknown should be null', () async {
      final handler = createStaticHandler(d.sandbox);

      final response = await makeRequest(handler, '/random.unknown');
      expect(response.mimeType, isNull);
    });

    test('header_bytes_test_image should be image/png', () async {
      final handler =
          createStaticHandler(d.sandbox, useHeaderBytesForContentType: true);

      final response =
          await makeRequest(handler, '/files/header_bytes_test_image');
      expect(response.mimeType, 'image/png');
    });

    test('header_bytes_test_webp should be image/webp', () async {
      final resolver = mime.MimeTypeResolver()
        ..addMagicNumber(
          <int>[
            0x52, 0x49, 0x46, 0x46, 0x00, 0x00, //
            0x00, 0x00, 0x57, 0x45, 0x42, 0x50
          ],
          'image/webp',
          mask: <int>[
            0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, //
            0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF
          ],
        );
      final handler = createStaticHandler(d.sandbox,
          useHeaderBytesForContentType: true, contentTypeResolver: resolver);

      final response =
          await makeRequest(handler, '/files/header_bytes_test_webp');
      expect(response.mimeType, 'image/webp');
    });
  });
}
