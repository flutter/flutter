// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/fallback_discovery.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';

void main() {
  BufferLogger logger;
  FallbackDiscovery fallbackDiscovery;
  MockMDnsObservatoryDiscovery mockMDnsObservatoryDiscovery;
  MockPrototcolDiscovery mockPrototcolDiscovery;
  MockPortForwarder mockPortForwarder;
  MockVmService mockVmService;

  setUp(() {
    logger = BufferLogger(
      terminal: AnsiTerminal(stdio: MockStdio(), platform: const LocalPlatform()),
      outputPreferences: OutputPreferences.test(),
    );
    mockVmService = MockVmService();
    mockMDnsObservatoryDiscovery = MockMDnsObservatoryDiscovery();
    mockPrototcolDiscovery = MockPrototcolDiscovery();
    mockPortForwarder = MockPortForwarder();
    fallbackDiscovery = FallbackDiscovery(
      logger: logger,
      mDnsObservatoryDiscovery: mockMDnsObservatoryDiscovery,
      portForwarder: mockPortForwarder,
      protocolDiscovery: mockPrototcolDiscovery,
      flutterUsage: Usage.test(),
      vmServiceConnectUri: (String uri, {Log log}) async {
        return mockVmService;
      },
      pollingDelay: Duration.zero,
    );
    when(mockPortForwarder.forward(23, hostPort: anyNamed('hostPort')))
      .thenAnswer((Invocation invocation) async => 1);
  });

  testWithoutContext('Selects assumed port if VM service connection is successful', () async {
    when(mockVmService.getVM()).thenAnswer((Invocation invocation) async {
      return VM.parse(<String, Object>{})..isolates = <IsolateRef>[
        IsolateRef.parse(<String, Object>{}),
      ];
    });
    when(mockVmService.getIsolate(any)).thenAnswer((Invocation invocation) async {
      return Isolate.parse(<String, Object>{})
        ..rootLib = (LibraryRef(name: 'main', uri: 'package:hello/main.dart', id: '2'));
    });

    expect(await fallbackDiscovery.discover(
      assumedDevicePort: 23,
      device: null,
      hostVmservicePort: 1,
      packageId: null,
      usesIpv6: false,
      packageName: 'hello',
    ), Uri.parse('http://localhost:1'));
  });

  testWithoutContext('Selects assumed port when another isolate has no root library', () async {
    when(mockVmService.getVM()).thenAnswer((Invocation invocation) async {
      return VM.parse(<String, Object>{})..isolates = <IsolateRef>[
        IsolateRef.parse(<String, Object>{})..id = '1',
        IsolateRef.parse(<String, Object>{})..id = '2',
      ];
    });
    when(mockVmService.getIsolate('1')).thenAnswer((Invocation invocation) async {
      return Isolate.parse(<String, Object>{})
        ..rootLib = null;
    });
    when(mockVmService.getIsolate('2')).thenAnswer((Invocation invocation) async {
      return Isolate.parse(<String, Object>{})
        ..rootLib = (LibraryRef.parse(<String, Object>{})..uri = 'package:hello/main.dart');
    });
    expect(await fallbackDiscovery.discover(
      assumedDevicePort: 23,
      device: null,
      hostVmservicePort: 1,
      packageId: null,
      usesIpv6: false,
      packageName: 'hello',
    ), Uri.parse('http://localhost:1'));
  });

  testWithoutContext('Selects mdns discovery if VM service connecton fails due to Sentinel', () async {
    when(mockVmService.getVM()).thenAnswer((Invocation invocation) async {
      return VM.parse(<String, Object>{})..isolates = <IsolateRef>[
        IsolateRef(
          id: 'a',
          name: 'isolate',
          number: '1',
        ),
      ];
    });
    when(mockVmService.getIsolate(any))
      .thenThrow(SentinelException.parse('Something', <String, dynamic>{}));
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
      device: null,
      hostVmservicePort: 1,
      packageId: 'hello',
      usesIpv6: false,
       packageName: 'hello',
    ), Uri.parse('http://localhost:1234'));
  });

  testWithoutContext('Selects mdns discovery if VM service connecton fails', () async {
    when(mockVmService.getVM()).thenThrow(Exception());

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
      device: null,
      hostVmservicePort: 1,
      packageId: 'hello',
      usesIpv6: false,
       packageName: 'hello',
    ), Uri.parse('http://localhost:1234'));
  });

  testWithoutContext('Selects log scanning if both VM Service and mDNS fails', () async {
    when(mockVmService.getVM()).thenThrow(Exception());
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
      device: null,
      hostVmservicePort: 1,
      packageId: 'hello',
      usesIpv6: false,
      packageName: 'hello',
    ), Uri.parse('http://localhost:5678'));
  });
}

class MockMDnsObservatoryDiscovery extends Mock implements MDnsObservatoryDiscovery {}
class MockPrototcolDiscovery extends Mock implements ProtocolDiscovery {}
class MockPortForwarder extends Mock implements DevicePortForwarder {}
class MockVmService extends Mock implements VmService {}
