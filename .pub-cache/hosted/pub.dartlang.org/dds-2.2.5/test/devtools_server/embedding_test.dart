// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  test('allows embedding without flag', () async {
    final server = await DevToolsServerDriver.create();
    final httpClient = HttpClient();
    late HttpClientResponse resp;
    try {
      final startedEvent = (await server.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];

      final req = await httpClient.get(host, port, '/');
      resp = await req.close();
      expect(resp.headers.value('x-frame-options'), isNull);
    } finally {
      httpClient.close();
      await resp.drain();
      server.kill();
    }
  }, timeout: const Timeout.factor(10));
}
