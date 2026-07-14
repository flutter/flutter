// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dwds/dwds.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/release_asset_server.dart';
import 'package:flutter_tools/src/isolated/web_asset_server.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:flutter_tools/src/web/web_constants.dart';
import 'package:shelf/shelf.dart';

import '../../src/common.dart';

const kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
];

final Platform platform = FakePlatform(environment: <String, String>{'HOME': '/'});

void main() {
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('web/index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync('hello');
    fileSystem.file('build/flutter_assets/foo.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);
    fileSystem.file('build/flutter_assets/bar')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);
  });

  testWithoutContext(
    'release asset server serves correct mime type and content length for png',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: false,
      );
      fileSystem.file('build/web/assets/foo.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(kTransparentImage);
      final Response response = await assetServer.handle(
        Request('GET', Uri.parse('http://localhost:8080/assets/foo.png')),
      );

      expect(response.headers, <String, String>{
        'Content-Type': 'image/png',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Access-Control-Allow-Origin': '*',
        'content-length': '64',
      });
    },
  );

  testWithoutContext(
    'release asset server serves correct mime type and content length for JavaScript',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: false,
      );
      fileSystem.file('build/web/assets/foo.js')
        ..createSync(recursive: true)
        ..writeAsStringSync('function main() {}');
      final Response response = await assetServer.handle(
        Request('GET', Uri.parse('http://localhost:8080/assets/foo.js')),
      );

      expect(response.headers, <String, String>{
        'Content-Type': 'text/javascript',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Access-Control-Allow-Origin': '*',
        'content-length': '18',
      });
    },
  );

  testWithoutContext(
    'release asset server serves correct mime type and content length for html',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: false,
      );
      fileSystem.file('build/web/assets/foo.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<!doctype html><html></html>');
      final Response response = await assetServer.handle(
        Request('GET', Uri.parse('http://localhost:8080/assets/foo.html')),
      );

      expect(response.headers, <String, String>{
        'Content-Type': 'text/html',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Access-Control-Allow-Origin': '*',
        'content-length': '28',
      });
    },
  );

  testWithoutContext('release asset server serves content from flutter root', () async {
    final assetServer = ReleaseAssetServer(
      Uri.base,
      fileSystem: fileSystem,
      platform: platform,
      flutterRoot: '/flutter',
      webBuildDirectory: 'build/web',
      needsCoopCoep: false,
    );
    fileSystem.file('flutter/bar.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() { }');
    final Response response = await assetServer.handle(
      Request('GET', Uri.parse('http://localhost:8080/flutter/bar.dart')),
    );

    expect(response.statusCode, HttpStatus.ok);
  });

  testWithoutContext('release asset server serves content from project directory', () async {
    final assetServer = ReleaseAssetServer(
      Uri.base,
      fileSystem: fileSystem,
      platform: platform,
      flutterRoot: '/flutter',
      webBuildDirectory: 'build/web',
      needsCoopCoep: false,
    );
    fileSystem.file('bar.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() { }');
    final Response response = await assetServer.handle(
      Request('GET', Uri.parse('http://localhost:8080/bar.dart')),
    );

    expect(response.statusCode, HttpStatus.ok);
  });

  testWithoutContext(
    'release asset server does not serve non-source files from the project or flutter root',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: false,
      );
      // The build output (index.html) is the fallback response for anything
      // that is not served directly.
      fileSystem.file('build/web/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<html></html>');

      // Files that may legitimately be requested for source-map resolution.
      fileSystem.file('lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() { }');
      fileSystem.file('flutter/packages/flutter/lib/widget.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// sdk source');

      // Files in the project root and flutter root that should not be served.
      fileSystem.file('.env')
        ..createSync(recursive: true)
        ..writeAsStringSync('API_KEY=super-secret');
      fileSystem.file('android/key.properties')
        ..createSync(recursive: true)
        ..writeAsStringSync('storePassword=hunter2');
      fileSystem.file('flutter/bin/internal/engine.version')
        ..createSync(recursive: true)
        ..writeAsStringSync('deadbeef');

      // Source files referenced by source maps are still served from the
      // project and flutter roots.
      for (final path in <String>['lib/main.dart', 'flutter/packages/flutter/lib/widget.dart']) {
        final Response response = await assetServer.handle(
          Request('GET', Uri.parse('http://localhost:8080/$path')),
        );
        expect(response.statusCode, HttpStatus.ok, reason: '"$path" should be served');
        expect(
          await response.readAsString(),
          isNot('<html></html>'),
          reason: '"$path" should be served, not the index.html fallback',
        );
      }

      // Unrelated files in the project/flutter roots fall through to the
      // index.html fallback instead of being served.
      for (final path in <String>[
        '.env',
        'android/key.properties',
        'flutter/bin/internal/engine.version',
      ]) {
        final Response response = await assetServer.handle(
          Request('GET', Uri.parse('http://localhost:8080/$path')),
        );
        expect(
          await response.readAsString(),
          '<html></html>',
          reason: '"$path" should not be served and should return the index.html fallback',
        );
      }
    },
  );

  testWithoutContext(
    'release asset server serves html content with COOP/COEP headers when specified',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: true,
      );
      fileSystem.file('build/web/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<html></html>');
      final Response response = await assetServer.handle(
        Request('GET', Uri.parse('http://localhost:8080/index.html')),
      );

      expect(response.statusCode, HttpStatus.ok);
      final Map<String, String> headers = response.headers;
      for (final MapEntry<String, String> entry in kCrossOriginIsolationHeaders.entries) {
        expect(headers, containsPair(entry.key, entry.value));
      }
    },
  );

  testWithoutContext(
    'release asset server serves html content without COOP/COEP headers when specified',
    () async {
      final assetServer = ReleaseAssetServer(
        Uri.base,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: '/flutter',
        webBuildDirectory: 'build/web',
        needsCoopCoep: false,
      );
      fileSystem.file('build/web/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<html></html>');
      final Response response = await assetServer.handle(
        Request('GET', Uri.parse('http://localhost:8080/index.html')),
      );

      expect(response.statusCode, HttpStatus.ok);
      final Map<String, String> headers = response.headers;
      expect(headers.containsKey('Cross-Origin-Opener-Policy'), false);
      expect(headers.containsKey('Cross-Origin-Embedder-Policy'), false);
    },
  );

  group('WebAssetServer', () {
    testWithoutContext('serves with COOP/COEP headers when crossOriginIsolation is true', () async {
      final WebAssetServer server = await WebAssetServer.start(
        null,
        null,
        false,
        false,
        false,
        BuildInfo.debug,
        false,
        const DartDevelopmentServiceConfiguration(enable: false),
        Uri.base,
        null,
        crossOriginIsolation: true,
        webDevServerConfig: const WebDevServerConfig(host: 'localhost'),
        webRenderer: WebRendererMode.canvaskit,
        isWasm: false,
        useLocalCanvasKit: false,
        testMode: true,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
      );

      expect(server.defaultResponseHeaders['Cross-Origin-Opener-Policy'], ['same-origin']);
      expect(server.defaultResponseHeaders['Cross-Origin-Embedder-Policy'], ['credentialless']);
    });

    testWithoutContext(
      'serves without COOP/COEP headers when crossOriginIsolation is false',
      () async {
        final WebAssetServer server = await WebAssetServer.start(
          null,
          null,
          false,
          false,
          false,
          BuildInfo.debug,
          false,
          const DartDevelopmentServiceConfiguration(enable: false),
          Uri.base,
          null,
          crossOriginIsolation: false,
          webDevServerConfig: const WebDevServerConfig(host: 'localhost'),
          webRenderer: WebRendererMode.canvaskit,
          isWasm: false,
          useLocalCanvasKit: false,
          testMode: true,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          platform: platform,
        );

        expect(server.defaultResponseHeaders['Cross-Origin-Opener-Policy'], isNull);
        expect(server.defaultResponseHeaders['Cross-Origin-Embedder-Policy'], isNull);
      },
    );

    testWithoutContext('serves with COOP/COEP headers when web renderer is skwasm', () async {
      final WebAssetServer server = await WebAssetServer.start(
        null,
        null,
        false,
        false,
        false,
        BuildInfo.debug,
        false,
        const DartDevelopmentServiceConfiguration(enable: false),
        Uri.base,
        null,
        crossOriginIsolation: true,
        webDevServerConfig: const WebDevServerConfig(host: 'localhost'),
        webRenderer: WebRendererMode.skwasm,
        isWasm: false,
        useLocalCanvasKit: false,
        testMode: true,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
      );

      expect(server.defaultResponseHeaders['Cross-Origin-Opener-Policy'], ['same-origin']);
      expect(server.defaultResponseHeaders['Cross-Origin-Embedder-Policy'], ['credentialless']);
    });

    testWithoutContext(
      'serves without COOP/COEP headers when web renderer is not skwasm',
      () async {
        final WebAssetServer server = await WebAssetServer.start(
          null,
          null,
          false,
          false,
          false,
          BuildInfo.debug,
          false,
          const DartDevelopmentServiceConfiguration(enable: false),
          Uri.base,
          null,
          crossOriginIsolation: false,
          webDevServerConfig: const WebDevServerConfig(host: 'localhost'),
          webRenderer: WebRendererMode.canvaskit,
          isWasm: false,
          useLocalCanvasKit: false,
          testMode: true,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          platform: platform,
        );

        expect(server.defaultResponseHeaders['Cross-Origin-Opener-Policy'], isNull);
        expect(server.defaultResponseHeaders['Cross-Origin-Embedder-Policy'], isNull);
      },
    );

    testWithoutContext('sets basePath from baseHref config', () async {
      final WebAssetServer server = await WebAssetServer.start(
        null,
        null,
        false,
        false,
        false,
        BuildInfo.debug,
        false,
        const DartDevelopmentServiceConfiguration(enable: false),
        Uri.base,
        null,
        crossOriginIsolation: false,
        webDevServerConfig: const WebDevServerConfig(host: 'localhost', baseHref: '/preview/'),
        webRenderer: WebRendererMode.canvaskit,
        isWasm: false,
        useLocalCanvasKit: false,
        testMode: true,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
      );

      expect(server.basePath, 'preview');
    });

    testWithoutContext('basePath defaults to empty when baseHref is not provided', () async {
      final WebAssetServer server = await WebAssetServer.start(
        null,
        null,
        false,
        false,
        false,
        BuildInfo.debug,
        false,
        const DartDevelopmentServiceConfiguration(enable: false),
        Uri.base,
        null,
        crossOriginIsolation: false,
        webDevServerConfig: const WebDevServerConfig(host: 'localhost'),
        webRenderer: WebRendererMode.canvaskit,
        isWasm: false,
        useLocalCanvasKit: false,
        testMode: true,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
      );

      expect(server.basePath, isEmpty);
    });
  });
}
