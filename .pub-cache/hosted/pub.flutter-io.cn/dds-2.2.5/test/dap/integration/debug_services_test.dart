// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode', () {
    test('reports the VM Service URI to the client', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);
      final vmServiceUri = (await client.vmServiceUri)!;
      expect(vmServiceUri.scheme, anyOf('ws', 'wss'));

      await client.terminate();
    });

    test('exposes VM services to the client', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Capture our test service registration.
      final myServiceRegistrationFuture = client.serviceRegisteredEvents
          .firstWhere((event) => event['service'] == 'myService');
      await client.hitBreakpoint(testFile, breakpointLine);
      final vmServiceUri = await client.vmServiceUri;

      // Register a service that echos back its params.
      final vmService = await vmServiceConnectUri(vmServiceUri.toString());
      // A service seems mandatory for this to work, even though it's unused.
      await vmService.registerService('myService', 'myServiceAlias');
      vmService.registerServiceCallback('myService', (params) async {
        return {'result': params};
      });

      // Ensure the service registration event is emitted and includes the
      // method to call it.
      final myServiceRegistration = await myServiceRegistrationFuture;
      final myServiceRegistrationMethod =
          myServiceRegistration['method'] as String;

      // Call the method and expect it to return the same values.
      final response = await client.callService(
        myServiceRegistrationMethod,
        {'foo': 'bar'},
      );
      final result = response.body as Map<String, Object?>;
      expect(result['foo'], equals('bar'));

      await vmService.dispose();
      await client.terminate();
    });

    test('exposes VM service extensions to the client', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(serviceExtensionProgram);

      // Capture our test service registration.
      final serviceExtensionAddedFuture = client.serviceExtensionAddedEvents
          .firstWhere(
              (event) => event['extensionRPC'] == 'ext.service.extension');
      await client.start(file: testFile);

      // Ensure the service registration event is emitted and includes the
      // method to call it.
      final serviceExtensionAdded = await serviceExtensionAddedFuture;
      final extensionRPC = serviceExtensionAdded['extensionRPC'] as String;
      final isolateId = serviceExtensionAdded['isolateId'] as String;

      // Call the method and expect it to return the same values.
      final response = await client.callService(
        extensionRPC,
        {
          'isolateId': isolateId,
          'foo': 'bar',
        },
      );
      final result = response.body as Map<String, Object?>;
      expect(result['foo'], equals('bar'));
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
