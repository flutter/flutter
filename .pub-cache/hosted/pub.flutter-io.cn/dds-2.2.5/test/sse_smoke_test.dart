// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as service;
import 'package:webdriver/io.dart';

import 'common/test_helper.dart';

// NOTE: this test requires that Chrome is available via PATH or CHROME_PATH
// environment variables.

void main() {
  late Process chromeDriver;
  late DartDevelopmentService dds;
  late SseHandler handler;
  Process? process;
  late HttpServer server;
  late WebDriver webdriver;

  setUpAll(() async {
    final chromedriverUri = Platform.script.resolveUri(
        Uri.parse('../../../third_party/webdriver/chrome/chromedriver'));
    try {
      chromeDriver = await Process.start(chromedriverUri.path, [
        '--port=4444',
        '--url-base=wd/hub',
      ]);
    } catch (e) {
      throw StateError(
          'Could not start ChromeDriver. Is it installed?\nError: $e');
    }
  });

  tearDownAll(() {
    chromeDriver.kill();
  });

  group('DDS', () {
    setUp(() async {
      process = await spawnDartProcess('smoke.dart');

      handler = SseHandler(Uri.parse('/test'));
      final cascade = shelf.Cascade()
          .add(handler.handler)
          .add(_faviconHandler)
          .add(createStaticHandler(Platform.script.resolve('web').path,
              listDirectories: true, defaultDocument: 'index.html'));

      server = await io.serve(cascade.handler, 'localhost', 0);

      final capabilities = Capabilities.chrome
        ..addAll({
          Capabilities.chromeOptions: {
            'args': ['--headless'],
            'binary': Platform.environment['CHROME_PATH'] ?? '',
          },
        });
      webdriver = await createDriver(
        desired: capabilities,
      );
    });

    tearDown(() async {
      await dds.shutdown();
      process?.kill();
      await webdriver.quit();
      await server.close();
      process = null;
    });

    void createTest(bool useAuthCodes) {
      test(
        'SSE Smoke Test with ${useAuthCodes ? "" : "no "}authentication codes',
        () async {
          dds = await DartDevelopmentService.startDartDevelopmentService(
            remoteVmServiceUri,
            serviceUri: Uri.parse('http://localhost:0'),
            enableAuthCodes: useAuthCodes,
          );
          expect(dds.isRunning, true);
          await webdriver.get('http://localhost:${server.port}');
          final testeeConnection = await handler.connections.next;

          // Replace the sse scheme with http as sse isn't supported for CORS.
          testeeConnection.sink
              .add(dds.sseUri!.replace(scheme: 'http').toString());
          final response = json.decode(await testeeConnection.stream.first);
          final version = service.Version.parse(response)!;
          expect(version.major! > 0, isTrue);
          expect(version.minor! >= 0, isTrue);
        },
      );
    }

    createTest(true);
    createTest(false);
  }, timeout: Timeout.none);
}

FutureOr<shelf.Response> _faviconHandler(shelf.Request request) {
  if (request.url.path.endsWith('favicon.ico')) {
    return shelf.Response.ok('');
  }
  return shelf.Response.notFound('');
}
