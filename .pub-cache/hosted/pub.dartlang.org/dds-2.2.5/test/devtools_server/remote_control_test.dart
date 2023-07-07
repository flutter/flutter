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

  for (final bool useVmService in [true, false]) {
    group('Server (${useVmService ? 'VM Service' : 'API'})', () {
      test('can launch on a specific page', () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a request to launch at a certain page.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );

        final serverResponse =
            await testController.waitForClients(requiredPage: 'memory');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'memory');
      }, timeout: const Timeout.factor(10));

      test('can switch page', () async {
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Launch on the memory page and wait for the connection.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );
        await testController.waitForClients(requiredPage: 'memory');

        // Re-launch, allowing reuse and with a different page.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          page: 'logging',
        );

        final serverResponse =
            await testController.waitForClients(requiredPage: 'logging');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'logging');
      }, timeout: const Timeout.factor(20));
    });
  }
}
