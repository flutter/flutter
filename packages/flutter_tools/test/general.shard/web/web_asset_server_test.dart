// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/web/devfs_web.dart';
import 'package:shelf/shelf.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed(
      setup: () {
        globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
          .createSync(recursive: true);
        globals.fs.file(globals.fs.path.join('web', 'index.html'))
          ..createSync(recursive: true)
          ..writeAsStringSync('hello');
        globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(kTransparentImage);
        globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'bar'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(<int>[1, 2, 3]);
      }
    );
  });

  test('release asset server serves correct mime type and content length for png', () => testbed.run(() async {
    final ReleaseAssetServer assetServer = ReleaseAssetServer();
    globals.fs.file(globals.fs.path.join('build', 'web', 'assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/assets/foo.png')));

    expect(response.headers, <String, String>{
      'Content-Type': 'image/png',
      'content-length': '64',
    });
  }));

  test('release asset server serves correct mime type and content length for JavaScript', () => testbed.run(() async {
    final ReleaseAssetServer assetServer = ReleaseAssetServer();
    globals.fs.file(globals.fs.path.join('build', 'web', 'assets', 'foo.js'))
      ..createSync(recursive: true)
      ..writeAsStringSync('function main() {}');
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/assets/foo.js')));

    expect(response.headers, <String, String>{
      'Content-Type': 'application/javascript',
      'content-length': '18',
    });
  }));

  test('release asset server serves correct mime type and content length for html', () => testbed.run(() async {
    final ReleaseAssetServer assetServer = ReleaseAssetServer();
    globals.fs.file(globals.fs.path.join('build', 'web', 'assets', 'foo.html'))
      ..createSync(recursive: true)
      ..writeAsStringSync('<!doctype html><html></html>');
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/assets/foo.html')));

    expect(response.headers, <String, String>{
      'Content-Type': 'text/html',
      'content-length': '28',
    });
  }));

  test('release asset server serves content from flutter root', () => testbed.run(() async {
    final ReleaseAssetServer assetServer = ReleaseAssetServer();
    globals.fs.file(globals.fs.path.join('flutter', 'bar.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() { }');
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/flutter/bar.dart')));

    expect(response.statusCode, HttpStatus.ok);
  }));

  test('release asset server serves content from project directory', () => testbed.run(() async {
    final ReleaseAssetServer assetServer = ReleaseAssetServer();
    globals.fs.file(globals.fs.path.join('lib', 'bar.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() { }');
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/bar.dart')));

    expect(response.statusCode, HttpStatus.ok);
  }));
}