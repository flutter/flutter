// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
import 'package:flutter_tools/src/project.dart';
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
  AssetServer assetServer;

  setUp(() {
    testbed = Testbed(
      setup: () {
        fs.file(fs.path.join('lib', 'main.dart'))
          .createSync(recursive: true);
        fs.file(fs.path.join('web', 'index.html'))
          ..createSync(recursive: true)
          ..writeAsStringSync('hello');
        fs.file(fs.path.join('build', 'flutter_assets', 'foo.png'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(kTransparentImage);
        fs.file(fs.path.join('build', 'flutter_assets', 'bar'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(<int>[1, 2, 3]);
        assetServer = DebugAssetServer(FlutterProject.current(), fs.path.join('main'));
      }
    );
  });

  test('can serve an html file from the web directory', () => testbed.run(() async {
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/index.html')));

    expect(response.headers, <String, String>{
      'Content-Type': 'text/html',
      'content-length': '5',
    });
    expect(await response.readAsString(), 'hello');
  }));

  test('can serve an asset with a png content type', () => testbed.run(() async {
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/assets/foo.png')));

    expect(response.headers, <String, String>{
      'Content-Type': 'image/png',
      'content-length': '64',
    });
  }));

  test('can fallback to application/octet-stream', () => testbed.run(() async {
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/assets/bar')));

    expect(response.headers, <String, String>{
      'Content-Type': 'application/octet-stream',
      'content-length': '3',
    });
  }));

  test('handles a missing html file from the web directory', () => testbed.run(() async {
    final Response response = await assetServer
        .handle(Request('GET', Uri.parse('http://localhost:8080/foobar.html')));

    expect(response.statusCode, 404);
  }));
}
