// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/fallback_discovery.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

// This test still uses `testUsingContext` due to analytics usage.
void main() {
  BufferLogger logger;
  FallbackDiscovery fallbackDiscovery;
  MockMDnsObservatoryDiscovery mockMDnsObservatoryDiscovery;
  MockPrototcolDiscovery mockPrototcolDiscovery;
  MockPortForwarder mockPortForwarder;
  MockHttpClient mockHttpClient;

  setUp(() {
    logger = BufferLogger(
      terminal: AnsiTerminal(stdio: MockStdio(), platform: const LocalPlatform()),
      outputPreferences: OutputPreferences.test(),
    );
    mockMDnsObservatoryDiscovery = MockMDnsObservatoryDiscovery();
    mockPrototcolDiscovery = MockPrototcolDiscovery();
    mockPortForwarder = MockPortForwarder();
    mockHttpClient = MockHttpClient();
    fallbackDiscovery = FallbackDiscovery(
      logger: logger,
      mDnsObservatoryDiscovery: mockMDnsObservatoryDiscovery,
      portForwarder: mockPortForwarder,
      protocolDiscovery: mockPrototcolDiscovery,
      httpClient: mockHttpClient,
    );
  });

  testUsingContext('Selects assumed port of PortFowarder does not throw', () async {
    final MockHttpClientResponse response = MockHttpClientResponse();
    final MockHttpClientRequest request = MockHttpClientRequest();
    when(mockHttpClient.getUrl(any)).thenAnswer((Invocation invocation) async {
      return request;
    });
    when(request.close()).thenAnswer((Invocation invocation) async {
      return response;
    });
    when(response.statusCode).thenReturn(HttpStatus.ok);
    when(response.transform<String>(any)).thenAnswer((Invocation invocation) {
      return Stream<String>.fromIterable(<String>[
        '''
        <!DOCTYPE html>
        <html style="height: 100%">
        <head>
          <meta charset="utf-8">
          <title>Dart VM Observatory</title>
          <link rel="stylesheet" href="packages/charted/charts/themes/quantum_theme.css">
          <link rel="stylesheet" href="packages/observatory/src/elements/css/shared.css">
          <script defer src="main.dart.js"></script>
        </head>
        <body style="height: 100%">
        </body>
        </html>
        '''
      ]);
    });
    when(mockPortForwarder.forward(23, hostPort: anyNamed('hostPort')))
      .thenAnswer((Invocation invocation) async => 1);

    expect(await fallbackDiscovery.discover(
      assumedDevicePort: 23,
      deivce: null,
      hostVmservicePort: 1,
      packageId: null,
      usesIpv6: false,
    ), Uri.parse('http://localhost:1'));
  });

  testUsingContext('Selects mdns discovery if PortForwarder fails', () async {
    when(mockPortForwarder.forward(23, hostPort: anyNamed('hostPort')))
      .thenThrow(Exception());
    when(mockMDnsObservatoryDiscovery.getObservatoryUri(
      'hello',
      null, // Device
      usesIpv6: false,
      hostVmservicePort: 1,
    )).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:1234');
    });

    expect(await fallbackDiscovery.discover(
      assumedDevicePort: 23,
      deivce: null,
      hostVmservicePort: 1,
      packageId: 'hello',
      usesIpv6: false,
    ), Uri.parse('http://localhost:1234'));
  });

  testUsingContext('Selects log scanning if both PortForwarder and mDNS fails', () async {
    when(mockPortForwarder.forward(23, hostPort: anyNamed('hostPort')))
      .thenThrow(Exception());
    when(mockMDnsObservatoryDiscovery.getObservatoryUri(
      'hello',
      null, // Device
      usesIpv6: false,
      hostVmservicePort: 1,
    )).thenThrow(Exception());
    when(mockPrototcolDiscovery.uri).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:5678');
    });

    expect(await fallbackDiscovery.discover(
      assumedDevicePort: 23,
      deivce: null,
      hostVmservicePort: 1,
      packageId: 'hello',
      usesIpv6: false,
    ), Uri.parse('http://localhost:5678'));
  });
}

class MockMDnsObservatoryDiscovery extends Mock implements MDnsObservatoryDiscovery {}
class MockPrototcolDiscovery extends Mock implements ProtocolDiscovery {}
class MockPortForwarder extends Mock implements DevicePortForwarder {}
class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
