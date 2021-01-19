// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fuchsia_remote_debug_protocol/src/dart/dart_vm.dart';
import 'package:vm_service/vm_service.dart' as vms;
import 'package:mockito/mockito.dart';

import '../../common.dart';

void main() {
  group('DartVm.connect', () {
    tearDown(() {
      restoreVmServiceConnectionFunction();
    });

    test('null connector', () async {
      Future<vms.VmService> mockServiceFunction(
        Uri uri, {
        Duration timeout,
      }) {
        return Future<vms.VmService>(() => null);
      }

      fuchsiaVmServiceConnectionFunction = mockServiceFunction;
      expect(await DartVm.connect(Uri.parse('http://this.whatever/ws')),
          equals(null));
    });

    test('disconnect closes peer', () async {
      final MockVmService service = MockVmService();
      Future<vms.VmService> mockServiceFunction(
        Uri uri, {
        Duration timeout,
      }) {
        return Future<vms.VmService>(() => service);
      }

      fuchsiaVmServiceConnectionFunction = mockServiceFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://this.whatever/ws'));
      expect(vm, isNot(null));
      await vm.stop();
      verify(service.dispose());
    });
  });

  group('DartVm.getAllFlutterViews', () {
    MockVmService mockService;

    setUp(() {
      mockService = MockVmService();
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

      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        when(mockService.callMethod('_flutter.listViews')).thenAnswer((_) async =>
            vms.Response.parse(flutterViewCannedResponses));
        return Future<vms.VmService>(() => mockService);
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

    test('basic flutter view parsing with casting checks', () async {
      final Map<String, dynamic> flutterViewCannedResponses = <String, dynamic>{
        'views': <dynamic>[
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

      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        when(mockService.callMethod('_flutter.listViews')).thenAnswer((_) async =>
            vms.Response.parse(flutterViewCannedResponses));
        return Future<vms.VmService>(() => mockService);
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
        ],
      };

      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        when(mockService.callMethod('_flutter.listViews')).thenAnswer((_) async =>
            vms.Response.parse(flutterViewCannedResponseMissingId));
        return Future<vms.VmService>(() => mockService);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      Future<void> failingFunction() async {
        await vm.getAllFlutterViews();
      }

      // Both views should be invalid as they were missing required fields.
      expect(failingFunction, throwsA(isA<RpcFormatError>()));
    });

    test('get isolates by pattern', () async {
      final List<vms.IsolateRef> isolates = <vms.IsolateRef>[
        vms.IsolateRef.parse(<String, dynamic>{
          'type': '@Isolate',
          'fixedId': 'true',
          'id': 'isolates/1',
          'name': 'file://thingThatWillNotMatch:main()',
          'number': '1',
        }),
        vms.IsolateRef.parse(<String, dynamic>{
          'type': '@Isolate',
          'fixedId': 'true',
          'id': 'isolates/2',
          'name': '0:dart_name_pattern()',
          'number': '2',
        }),
        vms.IsolateRef.parse(<String, dynamic>{
          'type': '@Isolate',
          'fixedId': 'true',
          'id': 'isolates/3',
          'name': 'flutterBinary.cmx',
          'number': '3',
        }),
        vms.IsolateRef.parse(<String, dynamic>{
          'type': '@Isolate',
          'fixedId': 'true',
          'id': 'isolates/4',
          'name': '0:some_other_dart_name_pattern()',
          'number': '4',
        }),
      ];

      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        when(mockService.getVM()).thenAnswer((_) async =>
            FakeVM(isolates: isolates));
        return Future<vms.VmService>(() => mockService);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      final List<IsolateRef> matchingFlutterIsolates =
          await vm.getMainIsolatesByPattern('flutterBinary.cmx');
      expect(matchingFlutterIsolates.length, 1);
      final List<IsolateRef> allIsolates = await vm.getMainIsolatesByPattern('');
      expect(allIsolates.length, 4);
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

      Future<vms.VmService> mockVmConnectionFunction(
        Uri uri, {
        Duration timeout,
      }) {
        when(mockService.callMethod(any)).thenAnswer((_) async =>
            vms.Response.parse(flutterViewCannedResponseMissingIsolateName));
        return Future<vms.VmService>(() => mockService);
      }

      fuchsiaVmServiceConnectionFunction = mockVmConnectionFunction;
      final DartVm vm =
          await DartVm.connect(Uri.parse('http://whatever.com/ws'));
      expect(vm, isNot(null));
      Future<void> failingFunction() async {
        await vm.getAllFlutterViews();
      }

      // Both views should be invalid as they were missing required fields.
      expect(failingFunction, throwsA(isA<RpcFormatError>()));
    });
  });
}

class MockVmService extends Mock implements vms.VmService {}

class FakeVM extends Fake implements vms.VM {
  FakeVM({
    this.isolates = const <vms.IsolateRef>[],
  });

  @override
  List<vms.IsolateRef> isolates;
}
