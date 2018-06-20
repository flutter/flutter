// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fuchsia_remote_debug_protocol/src/dart/dart_vm.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('DartVm.connect', () {
    tearDown(() {
      restoreVmServiceConnectionFunction();
    });

    test('null connector', () async {
      Future<json_rpc.Peer> mockServiceFunction(Uri uri) {
        return new Future<json_rpc.Peer>(() => null);
      }

      fuchsiaVmServiceConnectionFunction = mockServiceFunction;
      expect(await DartVm.connect(Uri.parse('http://this.whatever/ws')),
          equals(null));
    });

    test('disconnect closes peer', () async {
      final MockPeer peer = new MockPeer();
      Future<json_rpc.Peer> mockServiceFunction(Uri uri) {
        return new Future<json_rpc.Peer>(() => peer);
      }

      fuchsiaVmServiceConnectionFunction = mockServiceFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://this.whatever/ws'));
      expect(vm, isNot(null));
      await vm.stop();
      verify(peer.close());
    });
  });

  group('DartVm.getAllFlutterViews', () {
    MockPeer mockPeer;

    setUp(() {
      mockPeer = new MockPeer();
    });

    tearDown(() {
      restoreVmServiceConnectionFunction();
    });

    test('basic flutter view parsing', () async {
      final Map<String, dynamic> flutterViewCannedResponses = <String, dynamic>{
        'views': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'FlutterView',
            'id': 'flutterView0',
          },
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
      };

      Future<json_rpc.Peer> mockVmConnectionFunction(Uri uri) {
        when(mockPeer.sendRequest(
                typed<String>(any), typed<Map<String, dynamic>>(any)))
            .thenAnswer((_) => new Future<Map<String, dynamic>>(
                () => flutterViewCannedResponses));
        return new Future<json_rpc.Peer>(() => mockPeer);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      final List<FlutterView> views = await vm.getAllFlutterViews();
      expect(views.length, 3);
      // Check ID's as they cannot be null.
      expect(views[0].id, 'flutterView0');
      expect(views[1].id, 'flutterView1');
      expect(views[2].id, 'flutterView2');

      // Verify names.
      expect(views[0].name, equals(null));
      expect(views[1].name, 'file://flutterBinary1');
      expect(views[2].name, 'file://flutterBinary2');
    });

    test('invalid flutter view missing ID', () async {
      final Map<String, dynamic> flutterViewCannedResponseMissingId =
          <String, dynamic>{
        'views': <Map<String, dynamic>>[
          // Valid flutter view.
          <String, dynamic>{
            'type': 'FlutterView',
            'id': 'flutterView1',
            'isolate': <String, dynamic>{
              'type': '@Isolate',
              'name': 'IsolateThing',
              'fixedId': 'true',
              'id': 'isolates/1',
              'number': '1',
            },
          },

          // Missing ID.
          <String, dynamic>{
            'type': 'FlutterView',
          },
        ]
      };

      Future<json_rpc.Peer> mockVmConnectionFunction(Uri uri) {
        when(mockPeer.sendRequest(
                typed<String>(any), typed<Map<String, dynamic>>(any)))
            .thenAnswer((_) => new Future<Map<String, dynamic>>(
                () => flutterViewCannedResponseMissingId));
        return new Future<json_rpc.Peer>(() => mockPeer);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      Future<Null> failingFunction() async {
        await vm.getAllFlutterViews();
      }

      // Both views should be invalid as they were missing required fields.
      expect(failingFunction, throwsA(const isInstanceOf<RpcFormatError>()));
    });

    test('invalid flutter view missing ID', () async {
      final Map<String, dynamic> flutterViewCannedResponseMissingIsolateName =
          <String, dynamic>{
        'views': <Map<String, dynamic>>[
          // Missing isolate name.
          <String, dynamic>{
            'type': 'FlutterView',
            'id': 'flutterView1',
            'isolate': <String, dynamic>{
              'type': '@Isolate',
              'fixedId': 'true',
              'id': 'isolates/1',
              'number': '1',
            },
          },
        ],
      };

      Future<json_rpc.Peer> mockVmConnectionFunction(Uri uri) {
        when(mockPeer.sendRequest(
                typed<String>(any), typed<Map<String, dynamic>>(any)))
            .thenAnswer((_) => new Future<Map<String, dynamic>>(
                () => flutterViewCannedResponseMissingIsolateName));
        return new Future<json_rpc.Peer>(() => mockPeer);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      Future<Null> failingFunction() async {
        await vm.getAllFlutterViews();
      }

      // Both views should be invalid as they were missing required fields.
      expect(failingFunction, throwsA(const isInstanceOf<RpcFormatError>()));
    });
  });

  group('DartVm.invokeRpc', () {
    MockPeer mockPeer;

    setUp(() {
      mockPeer = new MockPeer();
    });

    tearDown(() {
      restoreVmServiceConnectionFunction();
    });

    test('verify timeout fires', () async {
      const Duration timeoutTime = const Duration(milliseconds: 100);
      Future<json_rpc.Peer> mockVmConnectionFunction(Uri uri) {
        // Return a command that will never complete.
        when(mockPeer.sendRequest(
                typed<String>(any), typed<Map<String, dynamic>>(any)))
            .thenAnswer((_) => new Completer<Map<String, dynamic>>().future);
        return new Future<json_rpc.Peer>(() => mockPeer);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      Future<Null> failingFunction() async {
        await vm.invokeRpc('somesillyfunction', timeout: timeoutTime);
      }

      expect(failingFunction, throwsA(const isInstanceOf<TimeoutException>()));
    });
  });
}

class MockPeer extends Mock implements json_rpc.Peer {}
