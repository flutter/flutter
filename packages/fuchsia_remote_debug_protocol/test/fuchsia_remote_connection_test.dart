// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';

import 'common.dart';

void main() {
  group('FuchsiaRemoteConnection.connect', () {
    MockSshCommandRunner mockRunner;
    List<MockPortForwarder> forwardedPorts;
    List<MockPeer> mockPeerConnections;
    List<Uri> uriConnections;

    setUp(() {
      mockRunner = MockSshCommandRunner();
      // Adds some extra junk to make sure the strings will be cleaned up.
      when(mockRunner.run(any)).thenAnswer((_) =>
          Future<List<String>>.value(<String>['123\n\n\n', '456  ', '789']));
      const String address = 'fe80::8eae:4cff:fef4:9247';
      const String interface = 'eno1';
      when(mockRunner.address).thenReturn(address);
      when(mockRunner.interface).thenReturn(interface);
      forwardedPorts = <MockPortForwarder>[];
      int port = 0;
      Future<PortForwarder> mockPortForwardingFunction(
          String address, int remotePort,
          [String interface = '', String configFile]) {
        return Future<PortForwarder>(() {
          final MockPortForwarder pf = MockPortForwarder();
          forwardedPorts.add(pf);
          when(pf.port).thenReturn(port++);
          when(pf.remotePort).thenReturn(remotePort);
          return pf;
        });
      }

      final List<Map<String, dynamic>> flutterViewCannedResponses =
          <Map<String, dynamic>>[
        <String, dynamic>{
          'views': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'FlutterView',
              'id': 'flutterView0',
            },
          ],
        },
        <String, dynamic>{
          'views': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'FlutterView',
              'id': 'flutterView1',
              'isolate': <String, dynamic>{
                'type': '@Isolate',
                'fixedId': 'true',
                'id': 'isolates/1',
                'name': 'file://flutterBinary1',
                'number': '1',
              },
            }
          ],
        },
        <String, dynamic>{
          'views': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'FlutterView',
              'id': 'flutterView2',
              'isolate': <String, dynamic>{
                'type': '@Isolate',
                'fixedId': 'true',
                'id': 'isolates/2',
                'name': 'file://flutterBinary2',
                'number': '2',
              },
            }
          ],
        },
      ];

      mockPeerConnections = <MockPeer>[];
      uriConnections = <Uri>[];
      Future<json_rpc.Peer> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        return Future<json_rpc.Peer>(() async {
          final MockPeer mp = MockPeer();
          mockPeerConnections.add(mp);
          uriConnections.add(uri);
          when(mp.sendRequest(any, any))
              // The local ports match the desired indices for now, so get the
              // canned response from the URI port.
              .thenAnswer((_) => Future<Map<String, dynamic>>(
                  () => flutterViewCannedResponses[uri.port]));
          return mp;
        });
      }

      fuchsiaPortForwardingFunction = mockPortForwardingFunction;
      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
    });

    tearDown(() {
      /// Most tests will mock out the port forwarding and connection
      /// functions.
      restoreFuchsiaPortForwardingFunction();
      restoreVmServiceConnectionFunction();
    });

    test('end-to-end with three vm connections and flutter view query',
        () async {
      final FuchsiaRemoteConnection connection =
          await FuchsiaRemoteConnection.connectWithSshCommandRunner(mockRunner);

      // [mockPortForwardingFunction] will have returned three different
      // forwarded ports, incrementing the port each time by one. (Just a sanity
      // check that the forwarding port was called).
      expect(forwardedPorts.length, 3);
      expect(forwardedPorts[0].remotePort, 123);
      expect(forwardedPorts[1].remotePort, 456);
      expect(forwardedPorts[2].remotePort, 789);
      expect(forwardedPorts[0].port, 0);
      expect(forwardedPorts[1].port, 1);
      expect(forwardedPorts[2].port, 2);

      final List<FlutterView> views = await connection.getFlutterViews();
      expect(views, isNot(null));
      expect(views.length, 3);
      // Since name can be null, check for the ID on all of them.
      expect(views[0].id, 'flutterView0');
      expect(views[1].id, 'flutterView1');
      expect(views[2].id, 'flutterView2');

      expect(views[0].name, equals(null));
      expect(views[1].name, 'file://flutterBinary1');
      expect(views[2].name, 'file://flutterBinary2');

      // Ensure the ports are all closed after stop was called.
      await connection.stop();
      verify(forwardedPorts[0].stop());
      verify(forwardedPorts[1].stop());
      verify(forwardedPorts[2].stop());
    });

    test('env variable test without remote addr', () async {
      Future<void> failingFunction() async {
        await FuchsiaRemoteConnection.connect();
      }

      // Should fail as no env variable has been passed.
      expect(failingFunction,
          throwsA(isInstanceOf<FuchsiaRemoteConnectionError>()));
    });
  });
}

class MockSshCommandRunner extends Mock implements SshCommandRunner {}

class MockPortForwarder extends Mock implements PortForwarder {}

class MockPeer extends Mock implements json_rpc.Peer {}
