// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/web/devfs_web.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:shelf/shelf.dart';

import '../../src/common.dart';
import '../../src/io.dart';
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
  WebAssetServer webAssetServer;
  Platform linux;
  Packages packages;
  Platform windows;
  MockHttpServer mockHttpServer;

  setUpAll(() async {
    packages = await loadPackagesFile(Uri.base.resolve('.packages'));
  });

  setUp(() {
    mockHttpServer = MockHttpServer();
    linux = FakePlatform(operatingSystem: 'linux', environment: <String, String>{});
    windows = FakePlatform(operatingSystem: 'windows', environment: <String, String>{});
    testbed = Testbed(setup: () {
      webAssetServer = WebAssetServer(mockHttpServer, packages, InternetAddress.loopbackIPv4);
    });
  });

  test('Handles against malformed manifest', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');

    // Missing ending offset.
    final File manifestMissingOffset = globals.fs.file('manifestA')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0],
        'sourcemap': <int>[0],
      }}));
    final File manifestOutOfBounds = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, 100],
        'sourcemap': <int>[0],
      }}));

    expect(webAssetServer.write(source, manifestMissingOffset, sourcemap), isEmpty);
    expect(webAssetServer.write(source, manifestOutOfBounds, sourcemap), isEmpty);
  }));

  test('serves JavaScript files from in memory cache', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.js')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', source.lengthSync().toString()),
      containsPair('content-type', 'application/javascript'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    Platform: () => linux,
  }));

  test('serves JavaScript files from in memory cache not from manifest', () => testbed.run(() async {
    webAssetServer.writeFile('/foo.js', 'main() {}');

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.js')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', '9'),
      containsPair('content-type', 'application/javascript'),
    ]));
    expect((await response.read().toList()).first, utf8.encode('main() {}'));
  }));

  test('handles missing JavaScript files from in memory cache', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/bar.js')));

    expect(response.statusCode, HttpStatus.notFound);
  }));

  test('serves JavaScript files from in memory cache on Windows', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://localhost/foo.js')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', source.lengthSync().toString()),
      containsPair('content-type', 'application/javascript'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    Platform: () => windows,
  }));

   test('serves asset files from in filesystem with known mime type on Windows', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', source.lengthSync().toString()),
      containsPair('content-type', 'image/png'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type,  Generator>{
    Platform: () => windows,
  }));

  test('serves Dart files from in filesystem on Linux/macOS', () => testbed.run(() async {
    final File source = globals.fs.file('foo.dart').absolute
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.dart')));

    expect(response.headers, containsPair('content-length', source.lengthSync().toString()));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type,  Generator>{
    Platform: () => linux,
  }));

  test('Handles missing Dart files from filesystem', () => testbed.run(() async {
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.dart')));

    expect(response.statusCode, HttpStatus.notFound);
  }));

  test('serves asset files from in filesystem with known mime type', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', source.lengthSync().toString()),
      containsPair('content-type', 'image/png'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('serves asset files files from in filesystem with unknown mime type and length > 12', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(100, 0));

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', '100'),
      containsPair('content-type', 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('serves asset files files from in filesystem with unknown mime type and length < 12', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', '3'),
      containsPair('content-type', 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('handles serving missing asset file', () => testbed.run(() async {
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo')));

    expect(response.statusCode, HttpStatus.notFound);
  }));

  test('serves /packages/<package>/<path> files as if they were '
       'package:<package>/<path> uris', () => testbed.run(() async {
    final Uri expectedUri = packages.resolve(
        Uri.parse('package:flutter_tools/foo.dart'));
    final File source = globals.fs.file(globals.fs.path.fromUri(expectedUri))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http:///packages/flutter_tools/foo.dart')));

    expect(response.headers, allOf(<Matcher>[
      containsPair('content-length', '3'),
      containsPair('content-type', 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('calling dispose closes the http server', () => testbed.run(() async {
    await webAssetServer.dispose();

    verify(mockHttpServer.close()).called(1);
  }));

  test('Can start web server with specified assets', () => testbed.run(() async {
    await IOOverrides.runWithIOOverrides(() async {
      final File outputFile = globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
        ..createSync(recursive: true);
      outputFile.parent.childFile('a.sources').writeAsStringSync('');
      outputFile.parent.childFile('a.json').writeAsStringSync('{}');
      outputFile.parent.childFile('a.map').writeAsStringSync('{}');
      outputFile.parent.childFile('.packages').writeAsStringSync('\n');

      final ResidentCompiler residentCompiler = MockResidentCompiler();
      when(residentCompiler.recompile(
        any,
        any,
        outputPath: anyNamed('outputPath'),
        packagesFilePath: anyNamed('packagesFilePath'),
      )).thenAnswer((Invocation invocation) async {
        return const CompilerOutput('a', 0, <Uri>[]);
      });

      final WebDevFS webDevFS = WebDevFS(
        hostname: 'localhost',
        port: 0,
        packagesFilePath: '.packages',
        urlTunneller: null,
        buildMode: BuildMode.debug,
        enableDwds: false,
        entrypoint: Uri.base,
      );
      webDevFS.requireJS.createSync(recursive: true);
      webDevFS.dartSdk.createSync(recursive: true);
      webDevFS.dartSdkSourcemap.createSync(recursive: true);
      webDevFS.stackTraceMapper.createSync(recursive: true);

      await webDevFS.create();
      await webDevFS.update(
        mainPath: globals.fs.path.join('lib', 'main.dart'),
        generator: residentCompiler,
        trackWidgetCreation: true,
        bundleFirstUpload: true,
        invalidatedFiles: <Uri>[],
      );

      expect(webDevFS.webAssetServer.getFile('/manifest.json'), isNotNull);
      expect(webDevFS.webAssetServer.getFile('/flutter_service_worker.js'), isNotNull);

      await webDevFS.destroy();
      await webDevFS.dwds.stop();
    }, FlutterIOOverrides(fileSystem: globals.fs));
  }), skip: true); // Not clear the best way to test this, since shelf hits the real filesystem.
}

class MockHttpServer extends Mock implements HttpServer {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
