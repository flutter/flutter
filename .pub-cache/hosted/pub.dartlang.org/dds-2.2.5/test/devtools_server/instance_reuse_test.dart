// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_shared/devtools_test_utils.dart';
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

  for (final bool useVmService in [true, false]) {
    group('Server (${useVmService ? 'VM Service' : 'API'})', () {
      test('reuses DevTools instance if already connected to same VM',
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

        {
          final serverResponse = await testController.waitForClients(
            requiredConnectionState: true,
          );
          expect(serverResponse['clients'], hasLength(1));
        }

        // Request again, allowing reuse, and server emits an event saying the
        // window was reused.
        final launchResponse = await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
        );
        expect(launchResponse['reused'], isTrue);

        // Ensure there's still only one connection (eg. we didn't spawn a new one
        // we reused the existing one).
        final serverResponse =
            await testController.waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
      }, timeout: const Timeout.factor(20));

      test('Server does not reuse DevTools instance if embedded', () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Spawn an embedded version of DevTools in a browser.
        final event = await testController.serverStartedEvent.future;
        final devToolsUri =
            'http://${event['params']['host']}:${event['params']['port']}';
        final launchUrl = '$devToolsUri/?embed=true&page=logging'
            '&uri=${Uri.encodeQueryComponent(testController.appFixture.serviceUri.toString())}';
        final chrome = await Chrome.locate()!.start(url: launchUrl);
        try {
          {
            final serverResponse = await testController.waitForClients(
              requiredConnectionState: true,
            );
            expect(serverResponse['clients'], hasLength(1));
          }

          // Send a request to the server to launch and ensure it did
          // not reuse the existing connection. Launch it on a different page
          // so we can easily tell once this one has connected.
          final launchResponse = await testController.sendLaunchDevToolsRequest(
            useVmService: useVmService,
            reuseWindows: true,
            page: 'memory',
          );
          expect(launchResponse['reused'], isFalse);

          // Ensure there's now two connections.
          final serverResponse = await testController.waitForClients(
            requiredConnectionState: true,
            requiredPage: 'memory',
          );
          expect(serverResponse['clients'], hasLength(2));
        } finally {
          chrome.kill();
        }
      }, timeout: const Timeout.factor(20));

      test('reuses DevTools instance if not connected to a VM', () async {
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
        await testController.waitForClients(requiredConnectionState: false);

        // Start up a new app.
        await testController.startApp();
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a new request to launch.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          notify: true,
        );

        // Ensure we now have a single connected client.
        final serverResponse =
            await testController.waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
      }, timeout: const Timeout.factor(20));
    });
  }
}
