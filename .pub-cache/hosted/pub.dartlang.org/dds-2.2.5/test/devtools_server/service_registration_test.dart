// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dds/devtools_server.dart';
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

  test('registers service', () async {
    final serverResponse = await testController.send(
      'vm.register',
      {'uri': testController.appFixture.serviceUri.toString()},
    );
    expect(serverResponse['success'], isTrue);

    // Expect the VM service to see the launchDevTools service registered.
    expect(
      testController.registeredServices,
      contains(DevToolsServer.launchDevToolsService),
    );
  }, timeout: const Timeout.factor(10));
}
