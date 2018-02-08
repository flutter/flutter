// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';
import 'package:fuchsia_remote_debug_protocol/lib_logging.dart';

void main() {
  // Log everything (probably don't need this though).
  Logger.globalLevel = LoggingLevel.all;
  group('FuchsiaRemoteConnection.connect', () {
    MockDartVm mockVmService;
    MockSshCommandRunner mockRunner;
    MockPortForwarder mockPortForwarder;

    setUp(() {
      mockRunner = new MockSshCommandRunner();
      mockVmService = new MockDartVm();
      mockPortForwarder = new MockPortForwarder();
    });

    tearDown(() {
      /// Most functions will mock out the port forwarding and connection
      /// functions.
      restoreFuchsiaPortForwardingFunction();
      restoreVmServiceConnectionFunction();
    });

    test('simple end-to-end with three vm connections', () async {
      final String address = 'fe80::8eae:4cff:fef4:9247';
      final String interface = 'eno1';
      // Adds some extra junk to make sure the strings will be cleaned up.
      when(mockRunner.run(any))
          .thenReturn(<String>['123\n\n\n', '456  ', '789']);
      when(mockRunner.address).thenReturn(address);
      when(mockRunner.interface).thenReturn(interface);
      int port = 0;
      final List<MockPortForwarder> forwardedPorts = <MockPortForwarder>[];
      Future<PortForwarder> mockPortForwardingFunction(
          String address, int remotePort,
          [String interface = '', String configFile]) {
        MockPortForwarder pf = new MockPortForwarder();
        forwardedPorts.add(pf);
        when(pf.port).thenReturn(port++);
        when(pf.remotePort).thenReturn(remotePort);
        return new Future<PortForwarder>(() => pf);
      }

      fuchsiaPortForwardingFunction = mockPortForwardingFunction;
      final FuchsiaRemoteConnection connection =
          await FuchsiaRemoteConnection.connectWithSshCommandRunner(mockRunner);

      // `mockPortForwardingFunction` will have returned three different
      // forwarded ports, incrementing the port each time by one. (Just a sanity
      // check that the forwarding port was called).
      expect(forwardedPorts.length, 3);
      expect(forwardedPorts[0].remotePort, 123);
      expect(forwardedPorts[1].remotePort, 456);
      expect(forwardedPorts[2].remotePort, 789);
      expect(forwardedPorts[0].port, 0);
      expect(forwardedPorts[1].port, 1);
      expect(forwardedPorts[2].port, 2);

      await connection.stop();
      // Ensure the ports are all closed after stop was called.
      verify(forwardedPorts[0].stop());
      verify(forwardedPorts[1].stop());
      verify(forwardedPorts[2].stop());
    });
  });
}

class MockDartVm extends Mock implements DartVm {}

class MockSshCommandRunner extends Mock implements SshCommandRunner {}

class MockPortForwarder extends Mock implements PortForwarder {}

class MockPeer extends Mock implements json_rpc.Peer {}
