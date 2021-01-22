// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart' as vms;

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';

import 'common.dart';

void main() {
  group('FuchsiaRemoteConnection.connect', () {
    List<MockPortForwarder> forwardedPorts;
    List<MockVmService> mockVmServices;
    List<Uri> uriConnections;

    setUp(() {
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
            },
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
            },
          ],
        },
      ];

      forwardedPorts = <MockPortForwarder>[];
      mockVmServices = <MockVmService>[];
      uriConnections = <Uri>[];
      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        return Future<vms.VmService>(() async {
          final MockVmService service = MockVmService();
          mockVmServices.add(service);
          uriConnections.add(uri);
          when(service.callMethod('_flutter.listViews'))
              // The local ports match the desired indices for now, so get the
              // canned response from the URI port.
              .thenAnswer((_) => Future<vms.Response>(
                  () => vms.Response.parse(flutterViewCannedResponses[uri.port])));
          return service;
        });
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
    });

    tearDown(() {
      /// Most tests will mock out the port forwarding and connection
      /// functions.
      restoreFuchsiaPortForwardingFunction();
      restoreVmServiceConnectionFunction();
    });

    test('end-to-end with three vm connections and flutter view query', () async {
      int port = 0;
      Future<PortForwarder> mockPortForwardingFunction(
        String address,
        int remotePort, [
        String interface = '',
        String configFile,
      ]) {
        return Future<PortForwarder>(() {
          final MockPortForwarder pf = MockPortForwarder();
          forwardedPorts.add(pf);
          when(pf.port).thenReturn(port++);
          when(pf.remotePort).thenReturn(remotePort);
          return pf;
        });
      }

      fuchsiaPortForwardingFunction = mockPortForwardingFunction;
      final MockSshCommandRunner mockRunner = MockSshCommandRunner();
      // Adds some extra junk to make sure the strings will be cleaned up.
      when(mockRunner.run(argThat(startsWith('/bin/find')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['/hub/blah/blah/blah/vmservice-port\n']));
      when(mockRunner.run(argThat(startsWith('/bin/ls')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['123\n\n\n', '456  ', '789']));
      when(mockRunner.address).thenReturn('fe80::8eae:4cff:fef4:9247');
      when(mockRunner.interface).thenReturn('eno1');

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

      // VMs should be accessed via localhost ports given by
      // [mockPortForwardingFunction].
      expect(uriConnections[0],
        Uri(scheme:'ws', host:'[::1]', port:0, path:'/ws'));
      expect(uriConnections[1],
        Uri(scheme:'ws', host:'[::1]', port:1, path:'/ws'));
      expect(uriConnections[2],
        Uri(scheme:'ws', host:'[::1]', port:2, path:'/ws'));

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

    test('end-to-end with three vms and remote open port', () async {
      int port = 0;
      Future<PortForwarder> mockPortForwardingFunction(
        String address,
        int remotePort, [
        String interface = '',
        String configFile,
      ]) {
        return Future<PortForwarder>(() {
          final MockPortForwarder pf = MockPortForwarder();
          forwardedPorts.add(pf);
          when(pf.port).thenReturn(port++);
          when(pf.remotePort).thenReturn(remotePort);
          when(pf.openPortAddress).thenReturn('fe80::1:2%eno2');
          return pf;
        });
      }

      fuchsiaPortForwardingFunction = mockPortForwardingFunction;
      final MockSshCommandRunner mockRunner = MockSshCommandRunner();
      // Adds some extra junk to make sure the strings will be cleaned up.
      when(mockRunner.run(argThat(startsWith('/bin/find')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['/hub/blah/blah/blah/vmservice-port\n']));
      when(mockRunner.run(argThat(startsWith('/bin/ls')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['123\n\n\n', '456  ', '789']));
      when(mockRunner.address).thenReturn('fe80::8eae:4cff:fef4:9247');
      when(mockRunner.interface).thenReturn('eno1');
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

      // VMs should be accessed via the alternate adddress given by
      // [mockPortForwardingFunction].
      expect(uriConnections[0],
        Uri(scheme:'ws', host:'[fe80::1:2%25eno2]', port:0, path:'/ws'));
      expect(uriConnections[1],
        Uri(scheme:'ws', host:'[fe80::1:2%25eno2]', port:1, path:'/ws'));
      expect(uriConnections[2],
        Uri(scheme:'ws', host:'[fe80::1:2%25eno2]', port:2, path:'/ws'));

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

    test('end-to-end with three vms and ipv4', () async {
      int port = 0;
      Future<PortForwarder> mockPortForwardingFunction(
        String address,
        int remotePort, [
        String interface = '',
        String configFile,
      ]) {
        return Future<PortForwarder>(() {
          final MockPortForwarder pf = MockPortForwarder();
          forwardedPorts.add(pf);
          when(pf.port).thenReturn(port++);
          when(pf.remotePort).thenReturn(remotePort);
          return pf;
        });
      }

      fuchsiaPortForwardingFunction = mockPortForwardingFunction;
      final MockSshCommandRunner mockRunner = MockSshCommandRunner();
      // Adds some extra junk to make sure the strings will be cleaned up.
      when(mockRunner.run(argThat(startsWith('/bin/find')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['/hub/blah/blah/blah/vmservice-port\n']));
      when(mockRunner.run(argThat(startsWith('/bin/ls')))).thenAnswer(
          (_) => Future<List<String>>.value(
              <String>['123\n\n\n', '456  ', '789']));
      when(mockRunner.address).thenReturn('196.168.1.4');

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

      // VMs should be accessed via the ipv4 loopback.
      expect(uriConnections[0],
        Uri(scheme:'ws', host:'127.0.0.1', port:0, path:'/ws'));
      expect(uriConnections[1],
        Uri(scheme:'ws', host:'127.0.0.1', port:1, path:'/ws'));
      expect(uriConnections[2],
        Uri(scheme:'ws', host:'127.0.0.1', port:2, path:'/ws'));

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
          throwsA(isA<FuchsiaRemoteConnectionError>()));
    });
  });
}

class MockSshCommandRunner extends Mock implements SshCommandRunner {}

class MockPortForwarder extends Mock implements PortForwarder {}

class MockVmService extends Mock implements vms.VmService {}
