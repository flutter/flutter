// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_shared/devtools_test_utils.dart';
import 'package:test/test.dart';

import 'utils/server_driver.dart';

// Note: this test is broken out from devtools_server_test.dart so that the
// tests run faster and we do not have to mark them as slow.

late final DevToolsServerTestController testController;

void runTest({required bool useVmService}) {
  testController = DevToolsServerTestController();

  setUp(() async {
    await testController.setUp();
  });

  tearDown(() async {
    await testController.tearDown();
  });

  group('Server (${useVmService ? 'VM Service' : 'API'})', () {
    test(
        'DevTools connects back to server API and registers that it is connected',
        () async {
      // Register the VM.
      await testController.send(
        'vm.register',
        {'uri': testController.appFixture.serviceUri.toString()},
      );

      // Send a request to launch DevTools in a browser.
      await testController.sendLaunchDevToolsRequest(
        useVmService: useVmService,
      );

      final serverResponse =
          await testController.waitForClients(requiredConnectionState: true);
      expect(serverResponse, isNotNull);
      expect(serverResponse['clients'], hasLength(1));
      expect(serverResponse['clients'][0]['hasConnection'], isTrue);
      expect(
        serverResponse['clients'][0]['vmServiceUri'],
        testController.appFixture.serviceUri.toString(),
      );
    }, timeout: const Timeout.factor(10));

    test('DevTools reports disconnects from a VM', () async {
      // Register the VM.
      await testController.send(
        'vm.register',
        {'uri': testController.appFixture.serviceUri.toString()},
      );

      // Send a request to launch DevTools in a browser.
      await testController.sendLaunchDevToolsRequest(
        useVmService: useVmService,
      );

      // Wait for the DevTools to inform server that it's connected.
      await testController.waitForClients(requiredConnectionState: true);

      // Terminate the VM.
      await testController.appFixture.teardown();

      // Ensure the client is marked as disconnected.
      final serverResponse = await testController.waitForClients(
        requiredConnectionState: false,
      );
      expect(serverResponse['clients'], hasLength(1));
      expect(serverResponse['clients'][0]['hasConnection'], isFalse);
      expect(serverResponse['clients'][0]['vmServiceUri'], isNull);
    }, timeout: const Timeout.factor(20));

    test('server removes clients that disconnect from the API', () async {
      final event = await testController.serverStartedEvent.future;

      // Spawn our own Chrome process so we can terminate it.
      final devToolsUri =
          'http://${event['params']['host']}:${event['params']['port']}';
      final chrome = await Chrome.locate()!.start(url: devToolsUri);

      // Wait for DevTools to inform server that it's connected.
      await testController.waitForClients();

      // Close the browser, which will disconnect DevTools SSE connection
      // back to the server.
      chrome.kill();

      // Await a long delay to wait for the SSE client to close.
      await delay(duration: const Duration(seconds: 15));

      // Ensure the client is completely removed from the list.
      await testController.waitForClients(expectNone: true);
    }, timeout: const Timeout.factor(20));
  });
}
