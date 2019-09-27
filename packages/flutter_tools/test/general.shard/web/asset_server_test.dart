// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:shelf/shelf.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

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
        assetServer = AssetServer(FlutterProject.current(), fs.path.join('main'));
      }
    );
  });

  test('can serve an html file from the web directory', () => testbed.run(() async {
    final Response response = await assetServer
      .handle(Request('GET', Uri.parse('http://localhost:8080/index.html')));

    expect(response.headers, <String, String>{
      'Content-Type': 'text/html',
      'content-length': '5'
    });
    expect(await response.readAsString(), 'hello');
  }));

  test('handles a missing html file from the web directory', () => testbed.run(() async {
    final Response response = await assetServer
        .handle(Request('GET', Uri.parse('http://localhost:8080/foobar.html')));

    expect(response.statusCode, 404);
  }));
}
