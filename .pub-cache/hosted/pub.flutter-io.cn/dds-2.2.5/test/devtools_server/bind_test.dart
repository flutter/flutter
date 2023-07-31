// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  test('can bind to next available port', () async {
    final server1 = await DevToolsServerDriver.create(port: 8855);
    try {
      // Wait for the first server to start up and ensure it got the
      // expected port.
      final event1 = (await server1.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      expect(event1['params']['port'], 8855);

      // Now spawn another requesting the same port and ensure it got the next
      // port number.
      final server2 = await DevToolsServerDriver.create(
        port: 8855,
        tryPorts: 2,
      );
      try {
        final event2 = (await server2.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;

        expect(event2['params']['port'], 8856);
      } finally {
        server2.kill();
      }
    } finally {
      server1.kill();
    }
  }, timeout: const Timeout.factor(10));
}
