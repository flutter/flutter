// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'utils/server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  testController = DevToolsServerTestController();

  setUp(() async {
    await testController.setUp();
  });

  tearDown(() async {
    await testController.tearDown();
  });

  test('serves index.html contents for /inspector', () async {
    final server = await DevToolsServerDriver.create();
    final httpClient = HttpClient();
    late HttpClientResponse resp;
    try {
      final startedEvent = (await server.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];

      final req = await httpClient.get(host, port, '/inspector');
      resp = await req.close();
      expect(resp.statusCode, 200);
      final bodyContent = await resp.transform(utf8.decoder).join();
      expect(bodyContent, contains('Dart DevTools'));
      final expectedBaseHref = htmlEscape.convert('/');
      expect(bodyContent, contains('<base href="$expectedBaseHref">'));
    } finally {
      httpClient.close();
      server.kill();
    }
  }, timeout: const Timeout.factor(10));

  test('serves 404 contents for requests that are not pages', () async {
    final server = await DevToolsServerDriver.create();
    final httpClient = HttpClient();
    late HttpClientResponse resp;
    try {
      final startedEvent = (await server.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];

      // The index page is only served up for extension-less requests.
      final req = await httpClient.get(host, port, '/inspector.html');
      resp = await req.close();
      expect(resp.statusCode, 404);
    } finally {
      httpClient.close();
      await resp.drain();
      server.kill();
    }
  }, timeout: const Timeout.factor(10));
}
