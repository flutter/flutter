// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/dwds.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_runner/devfs_web.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
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
  WebAssetServer webAssetServer;
  Platform linux;
  PackageConfig packages;
  Platform windows;
  MockHttpServer mockHttpServer;

  setUpAll(() async {
    packages = await loadPackageConfigUri(Uri.base.resolve('.packages'));
  });

  setUp(() {
    mockHttpServer = MockHttpServer();
    linux = FakePlatform(operatingSystem: 'linux', environment: <String, String>{});
    windows = FakePlatform(operatingSystem: 'windows', environment: <String, String>{});
    testbed = Testbed(setup: () {
      webAssetServer = WebAssetServer(
        mockHttpServer,
        packages,
        InternetAddress.loopbackIPv4,
        null,
        null,
      );
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
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'application/javascript'),
      containsPair(HttpHeaders.etagHeader, isNotNull)
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    Platform: () => linux,
  }));

  test('Removes leading slashes for valid requests to avoid requesting outside'
    ' of served directory', () => testbed.run(() async {
    globals.fs.file('foo.png').createSync();
    globals.fs.currentDirectory = globals.fs.directory('project_directory')
      ..createSync();

    final File source = globals.fs.file(globals.fs.path.join('web', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar////foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('serves JavaScript files from in memory cache not from manifest', () => testbed.run(() async {
    webAssetServer.writeFile('foo.js', 'main() {}');

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.js')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, '9'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/javascript'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, utf8.encode('main() {}'));
  }));

  test('Returns notModified when the ifNoneMatch header matches the etag', () => testbed.run(() async {
    webAssetServer.writeFile('foo.js', 'main() {}');

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.js')));
    final String etag = response.headers[HttpHeaders.etagHeader];

    final Response cachedResponse = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.js'), headers: <String, String>{
        HttpHeaders.ifNoneMatchHeader: etag
      }));

    expect(cachedResponse.statusCode, HttpStatus.notModified);
    expect(await cachedResponse.read().toList(), isEmpty);
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

  test('serves default index.html', () => testbed.run(() async {
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/')));

    expect(response.statusCode, HttpStatus.ok);
    expect((await response.read().toList()).first,
      containsAllInOrder(utf8.encode('<html>')));
  }));

  test('handles web server paths without .lib extension', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.dart.lib.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.dart.js')));

    expect(response.statusCode, HttpStatus.ok);
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
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'application/javascript'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    Platform: () => windows,
  }));

   test('serves asset files from in filesystem with url-encoded paths', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', Uri.encodeFull('abcd象形字.png')))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/abcd%25E8%25B1%25A1%25E5%25BD%25A2%25E5%25AD%2597.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));
  test('serves files from web directory', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('web', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

   test('serves asset files from in filesystem with known mime type on Windows', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
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

    expect(response.headers, containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()));
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
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
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
      containsPair(HttpHeaders.contentLengthHeader, '100'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
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
      containsPair(HttpHeaders.contentLengthHeader, '3'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('serves valid etag header for asset files with non-ascii chracters', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'fooπ'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/fooπ')));
    final String etag = response.headers[HttpHeaders.etagHeader];

    expect(etag.runes, everyElement(predicate((int char) => char < 255)));
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
      containsPair(HttpHeaders.contentLengthHeader, '3'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }));

  test('calling dispose closes the http server', () => testbed.run(() async {
    await webAssetServer.dispose();

    verify(mockHttpServer.close()).called(1);
  }));

  test('Can start web server with specified assets', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
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
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('a', 0, <Uri>[]);
    });

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      buildMode: BuildMode.debug,
      enableDwds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();
    webDevFS.webAssetServer.entrypointCacheDirectory = globals.fs.currentDirectory;
    globals.fs.currentDirectory
      .childDirectory('lib')
      .childFile('web_entrypoint.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('GENERATED');
    webDevFS.webAssetServer.dartSdk
      ..createSync(recursive: true)
      ..writeAsStringSync('HELLO');
    webDevFS.webAssetServer.dartSdkSourcemap
      ..createSync(recursive: true)
      ..writeAsStringSync('THERE');
    webDevFS.webAssetServer.canvasKitDartSdk
      ..createSync(recursive: true)
      ..writeAsStringSync('OL');
    webDevFS.webAssetServer.canvasKitDartSdkSourcemap
      ..createSync(recursive: true)
      ..writeAsStringSync('CHUM');
    webDevFS.webAssetServer.dartSdkSourcemap.createSync(recursive: true);

    await webDevFS.update(
      mainUri: globals.fs.file(globals.fs.path.join('lib', 'main.dart')).uri,
      generator: residentCompiler,
      trackWidgetCreation: true,
      bundleFirstUpload: true,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
    );

    expect(webDevFS.webAssetServer.getFile('require.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('stack_trace_mapper.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('main.dart'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('manifest.json'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('flutter_service_worker.js'), isNotNull);
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'HELLO');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'THERE');

    // Update to the SDK.
    webDevFS.webAssetServer.dartSdk.writeAsStringSync('BELLOW');

    // New SDK should be visible..
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'BELLOW');

    // Toggle CanvasKit
    webDevFS.webAssetServer.canvasKitRendering = true;
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'OL');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'CHUM');

    // Generated entrypoint.
    expect(await webDevFS.webAssetServer.dartSourceContents('web_entrypoint.dart'),
      contains('GENERATED'));

    // served on localhost
    expect(uri, Uri.http('localhost:0', ''));

    await webDevFS.destroy();
  }));

  test('Can start web server with hostname any', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
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
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('a', 0, <Uri>[]);
    });

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'any',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      buildMode: BuildMode.debug,
      enableDwds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();

    expect(uri, Uri.http('localhost:0', ''));
    await webDevFS.destroy();
  }));

  test('Launches DWDS with the correct arguments', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
    final WebAssetServer server = await WebAssetServer.start(
      null,
      'any',
      8123,
      (String url) => null,
      true,
      BuildMode.debug,
      true,
      Uri.file('test.dart'),
      null,
      dwdsLauncher: ({
        AssetReader assetReader,
        Stream<BuildResult> buildResults,
        ConnectionProvider chromeConnection,
        bool enableDebugExtension,
        bool enableDebugging,
        ExpressionCompiler expressionCompiler,
        String hostname,
        LoadStrategy loadStrategy,
        void Function(Level, String) logWriter,
        bool serveDevTools,
        UrlEncoder urlEncoder,
        bool useSseForDebugProxy,
        bool verbose,
      }) async {
        expect(serveDevTools, false);
        expect(verbose, null);
        expect(enableDebugging, true);
        expect(enableDebugExtension, true);
        expect(useSseForDebugProxy, true);
        expect(hostname, 'any');

        return MockDwds();
      });

    await server.dispose();
  }));
}

class MockHttpServer extends Mock implements HttpServer {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
class MockDwds extends Mock implements Dwds {}
