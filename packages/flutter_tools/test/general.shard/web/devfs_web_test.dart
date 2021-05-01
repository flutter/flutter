// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' hide Directory, File;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:package_config/package_config.dart';
import 'package:shelf/shelf.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

void main() {
  WebAssetServer webAssetServer;
  ReleaseAssetServer releaseAssetServer;
  Platform linux;
  PackageConfig packages;
  Platform windows;
  FakeHttpServer httpServer;
  FileSystem fileSystem;

  setUpAll(() async {
    packages = PackageConfig(<Package>[
      Package('flutter_tools', Uri.file('/flutter_tools/lib/').normalizePath())
    ]);
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    httpServer = FakeHttpServer();
    linux = FakePlatform(operatingSystem: 'linux', environment: <String, String>{});
    windows = FakePlatform(operatingSystem: 'windows', environment: <String, String>{});
    webAssetServer = WebAssetServer(
      httpServer,
      packages,
      InternetAddress.loopbackIPv4,
      null,
      null,
      null,
    );
    releaseAssetServer = ReleaseAssetServer(
      fileSystem.file('main.dart').uri,
      fileSystem: fileSystem,
      flutterRoot: null,
      platform: null,
      webBuildDirectory: null,
      basePath: null,
    );
  });

  testUsingContext('Handles against malformed manifest', () async {
    final File source = fileSystem.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')
      ..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')
      ..writeAsStringSync('{}');

    // Missing ending offset.
    final File manifestMissingOffset = fileSystem.file('manifestA')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0],
        'sourcemap': <int>[0],
        'metadata': <int>[0],
      }}));
    final File manifestOutOfBounds = fileSystem.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, 100],
        'sourcemap': <int>[0],
        'metadata': <int>[0],
      }}));

    expect(webAssetServer.write(source, manifestMissingOffset, sourcemap, metadata), isEmpty);
    expect(webAssetServer.write(source, manifestOutOfBounds, sourcemap, metadata), isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves JavaScript files from in memory cache', () async {
    final File source = fileSystem.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')
      ..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')
      ..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
        'metadata':  <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap, metadata);

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
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves metadata files from in memory cache', () async {
    const String metadataContents = '{"name":"foo"}';
    final File source = fileSystem.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')
      ..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')
      ..writeAsStringSync(metadataContents);
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, sourcemap.lengthSync()],
        'metadata':  <int>[0, metadata.lengthSync()],
      }}));
    webAssetServer.write(source, manifest, sourcemap, metadata);

    final String merged = await webAssetServer.metadataContents('main_module.ddc_merged_metadata');
    expect(merged, equals(metadataContents));

    final String single = await webAssetServer.metadataContents('foo.js.metadata');
    expect(single, equals(metadataContents));
  }, overrides: <Type, Generator>{
    Platform: () => linux,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Removes leading slashes for valid requests to avoid requesting outside'
    ' of served directory', () async {
    fileSystem.file('foo.png').createSync();
    fileSystem.currentDirectory = fileSystem.directory('project_directory')
      ..createSync();

    final File source = fileSystem.file(fileSystem.path.join('web', 'foo.png'))
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
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('takes base path into account when serving', () async {
    webAssetServer.basePath = 'base/path';

    fileSystem.file('foo.png').createSync();
    fileSystem.currentDirectory = fileSystem.directory('project_directory')
      ..createSync();

    final File source = fileSystem.file(fileSystem.path.join('web', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    final Response response =
      await webAssetServer.handleRequest(
        Request('GET', Uri.parse('http://foobar/base/path/foo.png')),
      );

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
      containsPair(HttpHeaders.etagHeader, isNotNull),
      containsPair(HttpHeaders.cacheControlHeader, 'max-age=0, must-revalidate')
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves index.html at the base path', () async {
    webAssetServer.basePath = 'base/path';

    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/base/path/')));

    expect(response.statusCode, HttpStatus.ok);
    expect(await response.readAsString(), htmlContent);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('does not serve outside the base path', () async {
    webAssetServer.basePath = 'base/path';

    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/')));

    expect(response.statusCode, HttpStatus.notFound);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('parses base path from index.html', () async {
    const String htmlContent = '<html><head><base href="/foo/bar/"></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final WebAssetServer webAssetServer = WebAssetServer(
      httpServer,
      packages,
      InternetAddress.loopbackIPv4,
      null,
      null,
      null,
    );

    expect(webAssetServer.basePath, 'foo/bar');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('handles lack of base path in index.html', () async {
    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final WebAssetServer webAssetServer = WebAssetServer(
      httpServer,
      packages,
      InternetAddress.loopbackIPv4,
      null,
      null,
      null,
    );

    // Defaults to "/" when there's no base element.
    expect(webAssetServer.basePath, '');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('throws if base path is relative', () async {
    const String htmlContent = '<html><head><base href="foo/bar/"></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    expect(
      () => WebAssetServer(
        httpServer,
        packages,
        InternetAddress.loopbackIPv4,
        null,
        null,
        null,
      ),
      throwsToolExit(),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('throws if base path does not end with slash', () async {
    const String htmlContent = '<html><head><base href="/foo/bar"></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    expect(
      () => WebAssetServer(
        httpServer,
        packages,
        InternetAddress.loopbackIPv4,
        null,
        null,
        null,
      ),
      throwsToolExit(),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves JavaScript files from in memory cache not from manifest', () async {
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
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Returns notModified when the ifNoneMatch header matches the etag', () async {
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
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves index.html when path is unknown', () async {
    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/bar/baz')));

    expect(response.statusCode, HttpStatus.ok);
    expect(await response.readAsString(), htmlContent);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('does not serve outside the base path', () async {
    webAssetServer.basePath = 'base/path';

    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/')));

    expect(response.statusCode, HttpStatus.notFound);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('does not serve index.html when path is inside assets or packages', () async {
    const String htmlContent = '<html><head></head><body id="test"></body></html>';
    final Directory webDir = fileSystem.currentDirectory
      .childDirectory('web')
      ..createSync();
    webDir.childFile('index.html').writeAsStringSync(htmlContent);

    Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo/bar.png')));
    expect(response.statusCode, HttpStatus.notFound);

    response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/packages/foo/bar.dart.js')));
    expect(response.statusCode, HttpStatus.notFound);

    webAssetServer.basePath = 'base/path';

    response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/base/path/assets/foo/bar.png')));
    expect(response.statusCode, HttpStatus.notFound);

    response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/base/path/packages/foo/bar.dart.js')));
    expect(response.statusCode, HttpStatus.notFound);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves default index.html', () async {
    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/')));

    expect(response.statusCode, HttpStatus.ok);
    expect((await response.read().toList()).first,
      containsAllInOrder(utf8.encode('<html>')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('handles web server paths without .lib extension', () async {
    final File source = fileSystem.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')
      ..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')
      ..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.dart.lib.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
        'metadata': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap, metadata);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.dart.js')));

    expect(response.statusCode, HttpStatus.ok);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves JavaScript files from in memory cache on Windows', () async {
    final File source = fileSystem.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')
      ..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')
      ..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
        'metadata': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap, metadata);
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
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves asset files from in filesystem with url-encoded paths', () async {
    final File source = fileSystem.file(fileSystem.path.join('build', 'flutter_assets', Uri.encodeFull('abcd象形字.png')))
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
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves files from web directory', () async {
    final File source = fileSystem.file(fileSystem.path.join('web', 'foo.png'))
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
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves asset files from in filesystem with known mime type on Windows', () async {
    final File source = fileSystem.file(fileSystem.path.join('build', 'flutter_assets', 'foo.png'))
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
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves Dart files from in filesystem on Linux/macOS', () async {
    final File source = fileSystem.file('foo.dart').absolute
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/foo.dart')));

    expect(response.headers, containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type,  Generator>{
    Platform: () => linux,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves asset files from in filesystem with known mime type', () async {
    final File source = fileSystem.file(fileSystem.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo.png')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, source.lengthSync().toString()),
      containsPair(HttpHeaders.contentTypeHeader, 'image/png'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves asset files files from in filesystem with unknown mime type and length > 12', () async {
    final File source = fileSystem.file(fileSystem.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(100, 0));

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, '100'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves asset files files from in filesystem with unknown mime type and length < 12', () async {
    final File source = fileSystem.file(fileSystem.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/foo')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, '3'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves valid etag header for asset files with non-ascii chracters', () async {
    fileSystem.file(fileSystem.path.join('build', 'flutter_assets', 'fooπ'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http://foobar/assets/fooπ')));
    final String etag = response.headers[HttpHeaders.etagHeader];

    expect(etag.runes, everyElement(predicate((int char) => char < 255)));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('serves /packages/<package>/<path> files as if they were '
       'package:<package>/<path> uris', () async {
    final Uri expectedUri = packages.resolve(
        Uri.parse('package:flutter_tools/foo.dart'));
    final File source = fileSystem.file(fileSystem.path.fromUri(expectedUri))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    final Response response = await webAssetServer
      .handleRequest(Request('GET', Uri.parse('http:///packages/flutter_tools/foo.dart')));

    expect(response.headers, allOf(<Matcher>[
      containsPair(HttpHeaders.contentLengthHeader, '3'),
      containsPair(HttpHeaders.contentTypeHeader, 'application/octet-stream'),
    ]));
    expect((await response.read().toList()).first, source.readAsBytesSync());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('calling dispose closes the http server', () async {
    await webAssetServer.dispose();

    expect(httpServer.closed, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can start web server with specified assets', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');
    outputFile.parent.childFile('a.metadata').writeAsStringSync('{}');

    final ResidentCompiler residentCompiler = FakeResidentCompiler()
      ..output = const CompilerOutput('a', 0, <Uri>[]);

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      nullAssertions: true,
      nativeNullAssertions: true,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        nullSafetyMode: NullSafetyMode.unsound,
      ),
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullSafetyMode: NullSafetyMode.unsound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();
    webDevFS.webAssetServer.entrypointCacheDirectory = fileSystem.currentDirectory;
    final String webPrecompiledSdk = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledSdk).path;
    final String webPrecompiledSdkSourcemaps = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledSdkSourcemaps).path;
    final String webPrecompiledCanvaskitSdk = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledCanvaskitSdk).path;
    final String webPrecompiledCanvaskitSdkSourcemaps = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledCanvaskitSdkSourcemaps).path;
    fileSystem.currentDirectory
      .childDirectory('lib')
      .childFile('web_entrypoint.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('GENERATED');
    fileSystem.file(webPrecompiledSdk)
      ..createSync(recursive: true)
      ..writeAsStringSync('HELLO');
    fileSystem.file(webPrecompiledSdkSourcemaps)
      ..createSync(recursive: true)
      ..writeAsStringSync('THERE');
    fileSystem.file(webPrecompiledCanvaskitSdk)
      ..createSync(recursive: true)
      ..writeAsStringSync('OL');
    fileSystem.file(webPrecompiledCanvaskitSdkSourcemaps)
      ..createSync(recursive: true)
      ..writeAsStringSync('CHUM');

    await webDevFS.update(
      mainUri: fileSystem.file(fileSystem.path.join('lib', 'main.dart')).uri,
      generator: residentCompiler,
      trackWidgetCreation: true,
      bundleFirstUpload: true,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
      pathToReload: '',
      dillOutputPath: 'out.dill',
    );

    expect(webDevFS.webAssetServer.getFile('require.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('stack_trace_mapper.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('main.dart'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('manifest.json'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('flutter_service_worker.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('version.json'),isNotNull);
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'HELLO');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'THERE');

    // Update to the SDK.
   fileSystem.file(webPrecompiledSdk).writeAsStringSync('BELLOW');

    // New SDK should be visible..
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'BELLOW');

    // Toggle CanvasKit
    expect(webDevFS.webAssetServer.webRenderer, WebRendererMode.html);
    webDevFS.webAssetServer.webRenderer = WebRendererMode.canvaskit;

    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'OL');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'CHUM');

    // Generated entrypoint.
    expect(await webDevFS.webAssetServer.dartSourceContents('web_entrypoint.dart'),
      contains('GENERATED'));

    // served on localhost
    expect(uri.host, 'localhost');

    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can start web server with specified assets in sound null safety mode', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');
    outputFile.parent.childFile('a.metadata').writeAsStringSync('{}');

    final ResidentCompiler residentCompiler = FakeResidentCompiler()
      ..output = const CompilerOutput('a', 0, <Uri>[]);

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      nullAssertions: true,
      nativeNullAssertions: true,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        nullSafetyMode: NullSafetyMode.sound,
      ),
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullSafetyMode: NullSafetyMode.sound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();
    webDevFS.webAssetServer.entrypointCacheDirectory = fileSystem.currentDirectory;
    fileSystem.currentDirectory
      .childDirectory('lib')
      .childFile('web_entrypoint.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('GENERATED');
    final String webPrecompiledSdk = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledSoundSdk).path;
    final String webPrecompiledSdkSourcemaps = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledSoundSdkSourcemaps).path;
    final String webPrecompiledCanvaskitSdk = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledCanvaskitSoundSdk).path;
    final String webPrecompiledCanvaskitSdkSourcemaps = globals.artifacts
      .getHostArtifact(HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps).path;
    fileSystem.file(webPrecompiledSdk)
      ..createSync(recursive: true)
      ..writeAsStringSync('HELLO');
    fileSystem.file(webPrecompiledSdkSourcemaps)
      ..createSync(recursive: true)
      ..writeAsStringSync('THERE');
    fileSystem.file(webPrecompiledCanvaskitSdk)
      ..createSync(recursive: true)
      ..writeAsStringSync('OL');
    fileSystem.file(webPrecompiledCanvaskitSdkSourcemaps)
      ..createSync(recursive: true)
      ..writeAsStringSync('CHUM');

    await webDevFS.update(
      mainUri: fileSystem.file(fileSystem.path.join('lib', 'main.dart')).uri,
      generator: residentCompiler,
      trackWidgetCreation: true,
      bundleFirstUpload: true,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
      pathToReload: '',
      dillOutputPath: '',
    );

    expect(webDevFS.webAssetServer.getFile('require.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('stack_trace_mapper.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('main.dart'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('manifest.json'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('flutter_service_worker.js'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('version.json'), isNotNull);
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'HELLO');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'THERE');

    // Update to the SDK.
    fileSystem.file(webPrecompiledSdk).writeAsStringSync('BELLOW');

    // New SDK should be visible..
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'BELLOW');

    // Toggle CanvasKit
    webDevFS.webAssetServer.webRenderer = WebRendererMode.canvaskit;
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js'), 'OL');
    expect(await webDevFS.webAssetServer.dartSourceContents('dart_sdk.js.map'), 'CHUM');

    // Generated entrypoint.
    expect(await webDevFS.webAssetServer.dartSourceContents('web_entrypoint.dart'),
      contains('GENERATED'));

    // served on localhost
    expect(uri.host, 'localhost');

    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can start web server with hostname any', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'any',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      buildInfo: BuildInfo.debug,
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullAssertions: true,
      nativeNullAssertions: true,
      nullSafetyMode: NullSafetyMode.sound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();

    expect(uri.host, 'localhost');
    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can start web server with canvaskit enabled', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      nullAssertions: true,
      nativeNullAssertions: true,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        dartDefines: <String>[
          'FLUTTER_WEB_USE_SKIA=true',
        ]
      ),
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullSafetyMode: NullSafetyMode.sound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    await webDevFS.create();

    expect(webDevFS.webAssetServer.webRenderer, WebRendererMode.canvaskit);

    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can start web server with auto detect enabled', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      nullAssertions: true,
      nativeNullAssertions: true,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        dartDefines: <String>[
          'FLUTTER_WEB_AUTO_DETECT=true',
        ]
      ),
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullSafetyMode: NullSafetyMode.sound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    await webDevFS.create();

    expect(webDevFS.webAssetServer.webRenderer, WebRendererMode.autoDetect);

    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('allows frame embedding', () async {
    final WebAssetServer webAssetServer = await WebAssetServer.start(
      null,
      'localhost',
      0,
      null,
      true,
      true,
      true,
      const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
      ),
      false,
      false,
      Uri.base,
      null,
      null,
      testMode: true);

    expect(webAssetServer.defaultResponseHeaders['x-frame-options'], null);
    await webAssetServer.dispose();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('WebAssetServer responds to POST requests with 404 not found', () async {
    final Response response = await webAssetServer.handleRequest(
      Request('POST', Uri.parse('http://foobar/something')),
    );
    expect(response.statusCode, 404);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ReleaseAssetServer responds to POST requests with 404 not found', () async {
    final Response response = await releaseAssetServer.handle(
      Request('POST', Uri.parse('http://foobar/something')),
    );
    expect(response.statusCode, 404);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('WebAssetServer strips leading base href off off asset requests', () async {
    const String htmlContent = '<html><head><base href="/foo/"></head><body id="test"></body></html>';
    fileSystem.currentDirectory
      .childDirectory('web')
      .childFile('index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync(htmlContent);
    final WebAssetServer webAssetServer = WebAssetServer(
      FakeHttpServer(),
      PackageConfig.empty,
      InternetAddress.anyIPv4,
      <String, String>{},
      <String, String>{},
      NullSafetyMode.sound,
    );

    expect(await webAssetServer.metadataContents('foo/main_module.ddc_merged_metadata'), null);
    // Not base href.
    expect(() async => webAssetServer.metadataContents('bar/main_module.ddc_merged_metadata'), throwsException);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('DevFS URI includes any specified base path.', () async {
    final File outputFile = fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      ..createSync(recursive: true);
    const String htmlContent = '<html><head><base href="/foo/"></head><body id="test"></body></html>';
    fileSystem.currentDirectory
      .childDirectory('web')
      .childFile('index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync(htmlContent);
    outputFile.parent.childFile('a.sources').writeAsStringSync('');
    outputFile.parent.childFile('a.json').writeAsStringSync('{}');
    outputFile.parent.childFile('a.map').writeAsStringSync('{}');
    outputFile.parent.childFile('a.metadata').writeAsStringSync('{}');

    final WebDevFS webDevFS = WebDevFS(
      hostname: 'localhost',
      port: 0,
      packagesFilePath: '.packages',
      urlTunneller: null,
      useSseForDebugProxy: true,
      useSseForDebugBackend: true,
      useSseForInjectedClient: true,
      nullAssertions: true,
      nativeNullAssertions: true,
      buildInfo: BuildInfo.debug,
      enableDwds: false,
      enableDds: false,
      entrypoint: Uri.base,
      testMode: true,
      expressionCompiler: null,
      chromiumLauncher: null,
      nullSafetyMode: NullSafetyMode.unsound,
    );
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    final Uri uri = await webDevFS.create();

    // served on localhost
    expect(uri.host, 'localhost');
    // Matches base URI specified in html.
    expect(uri.path, '/foo');

    await webDevFS.destroy();
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class FakeHttpServer extends Fake implements HttpServer {
  bool closed = false;

  @override
  Future<void> close({bool force = false}) async {
    closed = true;
  }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  CompilerOutput output;

  @override
  void addFileSystemRoot(String root) { }

  @override
  Future<CompilerOutput> recompile(Uri mainUri, List<Uri> invalidatedFiles, {
    String outputPath,
    PackageConfig packageConfig,
    String projectRootPath,
    FileSystem fs,
    bool suppressErrors = false,
  }) async {
    return output;
  }
}
