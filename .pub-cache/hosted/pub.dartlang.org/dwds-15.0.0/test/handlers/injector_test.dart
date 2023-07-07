// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';

import 'package:dwds/src/handlers/injector.dart';
import 'package:dwds/src/version.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import '../fixtures/fakes.dart';

void main() {
  HttpServer server;
  const entryEtag = 'entry etag';
  const nonEntryEtag = 'some etag';
  final loadStrategy = FakeStrategy();

  group('InjectedHandlerWithoutExtension', () {
    DwdsInjector injector;
    setUp(() async {
      injector = DwdsInjector(loadStrategy);
      final pipeline = const Pipeline().addMiddleware(injector.middleware);
      server = await shelf_io.serve(pipeline.addHandler((request) {
        if (request.url.path.endsWith(bootstrapJsExtension)) {
          return Response.ok(
              '$entrypointExtensionMarker\n'
              '$mainExtensionMarker\n'
              'app.main.main()',
              headers: {HttpHeaders.etagHeader: entryEtag});
        } else if (request.url.path.endsWith('foo.js')) {
          return Response.ok('some js',
              headers: {HttpHeaders.etagHeader: nonEntryEtag});
        } else {
          return Response.notFound('Not found');
        }
      }), 'localhost', 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('leaves non-entrypoints untouched', () async {
      final result =
          await http.get(Uri.parse('http://localhost:${server.port}/foo.js'));
      expect(result.body, 'some js');
    });

    test('does not update etags for non-entrypoints', () async {
      final result =
          await http.get(Uri.parse('http://localhost:${server.port}/foo.js'));
      expect(result.headers[HttpHeaders.etagHeader], nonEntryEtag);
    });

    test('replaces main marker with injected client', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('Injected by dwds'), isTrue);
      expect(result.body.contains(mainExtensionMarker), isFalse);
    });

    test('prevents main from being called', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('window.\$dartRunMain'), isTrue);
    });

    test('updates etags for injected responses', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.headers[HttpHeaders.etagHeader], isNot(entryEtag));
    });

    test('ignores non-js requests', () async {
      final result = await http
          .get(Uri.parse('http://localhost:${server.port}/main.dart'));
      expect(result.body, 'Not found');
    });

    test('embeds the devHandlerPath', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('window.\$dwdsDevHandlerPath = "http://'),
          isTrue);
    });

    test('emits a devHandlerPath for each entrypoint', () async {
      await http.get(Uri.parse(
          'http://localhost:${server.port}/foo/entrypoint$bootstrapJsExtension'));
      await http.get(Uri.parse(
          'http://localhost:${server.port}/blah/entrypoint$bootstrapJsExtension'));
      expect(
          injector.devHandlerPaths,
          emitsInOrder([
            'http://localhost:${server.port}/foo/\$dwdsSseHandler',
            'http://localhost:${server.port}/blah/\$dwdsSseHandler'
          ]));
    });

    test(
        'Does not return 304 when if-none-match etag matches the original '
        'content etag', () async {
      final result = await http.get(
          Uri.parse(
              'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'),
          headers: {HttpHeaders.ifNoneMatchHeader: entryEtag});
      expect(result.statusCode, HttpStatus.ok);
    });

    test('Does return 304 when if-none-match etag matches the modified etag',
        () async {
      final originalResponse = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      final cachedResponse = await http.get(
          Uri.parse(
              'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'),
          headers: {
            HttpHeaders.ifNoneMatchHeader:
                originalResponse.headers[HttpHeaders.etagHeader]
          });
      expect(cachedResponse.statusCode, HttpStatus.notModified);
    });

    test('Does not inject the extension backend port', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dartExtensionUri'), isFalse);
    });

    test('Has correct DWDS version', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      final expected = r'$dwdsVersion = ';
      final index = result.body.indexOf(expected);
      expect(index, greaterThan(0));
      final nextBit = result.body.substring(index + expected.length);
      final versionPiece = nextBit.split('"')[1];
      expect(versionPiece, packageVersion);
    });

    test('Injects bootstrap', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dummy_bootstrap'), isTrue);
    });

    test('Injects load strategy id', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dummy-id'), isTrue);
    });

    test('Injects the entrypoint path', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(
          result.body
              .contains('dartEntrypointPath = "entrypoint.bootstrap.js"'),
          isTrue);
    });

    test('Injects client load snippet', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dummy-load-client-snippet'), isTrue);
    });

    test('Injects dwds enable devtools launch configuration', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dwdsEnableDevtoolsLaunch'), isTrue);
    });

    test('Delegates to strategy handler', () async {
      final result = await http
          .get(Uri.parse('http://localhost:${server.port}/someDummyPath'));
      expect(result.body, equals('some dummy response'));
    });

    test('the injected client contains a global \$emitDebugEvents', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/dwds/src/injected/client.js'));
      expect(result.body, contains('\$dartEmitDebugEvents'));
    });

    test('the injected client contains a global \$emitDebugEvent', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/dwds/src/injected/client.js'));
      expect(result.body, contains('\$emitDebugEvent'));
    });

    test('the injected client contains a global \$emitRegisterEvent', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/dwds/src/injected/client.js'));
      expect(result.body, contains('\$emitRegisterEvent'));
    });

    test('serves the injected client', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/dwds/src/injected/client.js'));
      expect(result.statusCode, HttpStatus.ok);
    });
  });

  group('InjectedHandlerWithoutExtension using WebSockets', () {
    DwdsInjector injector;
    setUp(() async {
      injector = DwdsInjector(loadStrategy, useSseForInjectedClient: false);
      final pipeline = const Pipeline().addMiddleware(injector.middleware);
      server = await shelf_io.serve(pipeline.addHandler((request) {
        if (request.url.path.endsWith(bootstrapJsExtension)) {
          return Response.ok(
              '$entrypointExtensionMarker\n'
              '$mainExtensionMarker\n'
              'app.main.main()',
              headers: {HttpHeaders.etagHeader: entryEtag});
        } else if (request.url.path.endsWith('foo.js')) {
          return Response.ok('some js',
              headers: {HttpHeaders.etagHeader: nonEntryEtag});
        } else {
          return Response.notFound('Not found');
        }
      }), 'localhost', 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('embeds the devHandlerPath', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(
          result.body.contains('window.\$dwdsDevHandlerPath = "ws://'), isTrue);
    });

    test('emits a devHandlerPath for each entrypoint', () async {
      await http.get(Uri.parse(
          'http://localhost:${server.port}/foo/entrypoint$bootstrapJsExtension'));
      await http.get(Uri.parse(
          'http://localhost:${server.port}/blah/entrypoint$bootstrapJsExtension'));
      expect(
          injector.devHandlerPaths,
          emitsInOrder([
            'ws://localhost:${server.port}/foo/\$dwdsSseHandler',
            'ws://localhost:${server.port}/blah/\$dwdsSseHandler'
          ]));
    });
  });

  group('InjectedHandlerWithExtension', () {
    setUp(() async {
      final extensionUri = 'http://localhost:4000';
      final pipeline = const Pipeline().addMiddleware(
          DwdsInjector(loadStrategy, extensionUri: Future.value(extensionUri))
              .middleware);
      server = await shelf_io.serve(pipeline.addHandler((request) {
        return Response.ok(
            '$entrypointExtensionMarker\n'
            '$mainExtensionMarker\n'
            'app.main.main()',
            headers: {HttpHeaders.etagHeader: entryEtag});
      }), 'localhost', 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('Injects the extension backend port', () async {
      final result = await http.get(Uri.parse(
          'http://localhost:${server.port}/entrypoint$bootstrapJsExtension'));
      expect(result.body.contains('dartExtensionUri'), isTrue);
    });
  });
}
