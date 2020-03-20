// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:quiver/testing/async.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

final Map<String, Object> vm = <String, dynamic>{
  'type': 'VM',
  'name': 'vm',
  'architectureBits': 64,
  'targetCPU': 'x64',
  'hostCPU': '      Intel(R) Xeon(R) CPU    E5-1650 v2 @ 3.50GHz',
  'version': '2.1.0-dev.7.1.flutter-45f9462398 (Fri Oct 19 19:27:56 2018 +0000) on "linux_x64"',
  '_profilerMode': 'Dart',
  '_nativeZoneMemoryUsage': 0,
  'pid': 103707,
  'startTime': 1540426121876,
  '_embedder': 'Flutter',
  '_maxRSS': 312614912,
  '_currentRSS': 33091584,
  'isolates': <dynamic>[
    <String, dynamic>{
      'type': '@Isolate',
      'fixedId': true,
      'id': 'isolates/242098474',
      'name': 'main.dart:main()',
      'number': 242098474,
    },
  ],
};

final vm_service.Isolate isolate = vm_service.Isolate.parse(
  <String, dynamic>{
    'type': 'Isolate',
    'fixedId': true,
    'id': 'isolates/242098474',
    'name': 'main.dart:main()',
    'number': 242098474,
    '_originNumber': 242098474,
    'startTime': 1540488745340,
    '_heaps': <String, dynamic>{
      'new': <String, dynamic>{
        'used': 0,
        'capacity': 0,
        'external': 0,
        'collections': 0,
        'time': 0.0,
        'avgCollectionPeriodMillis': 0.0,
      },
      'old': <String, dynamic>{
        'used': 0,
        'capacity': 0,
        'external': 0,
        'collections': 0,
        'time': 0.0,
        'avgCollectionPeriodMillis': 0.0,
      },
    },
  }
);

final Map<String, Object> _listViews = <String, dynamic>{
  'type': 'FlutterViewList',
  'views': <dynamic>[
    <String, dynamic>{
      'type': 'FlutterView',
      'id': '_flutterView/0x4a4c1f8',
      'isolate': <String, dynamic>{
        'type': '@Isolate',
        'fixedId': true,
        'id': 'isolates/242098474',
        'name': 'main.dart:main()',
        'number': 242098474,
      },
    },
  ]
};

typedef ServiceCallback = Future<Map<String, dynamic>> Function(Map<String, Object>);

void main() {
  MockStdio mockStdio;
  final MockFlutterVersion mockVersion = MockFlutterVersion();
  group('VMService', () {

    // setUp(() {
    //   mockStdio = MockStdio();
    // });

    testUsingContext('fails connection eagerly in the connect() method', () async {
      FakeAsync().run((FakeAsync time) {
        bool failed = false;
        final Future<VMService> future = VMService.connect(Uri.parse('http://host.invalid:9999/'));
        future.whenComplete(() {
          failed = true;
        });
        time.elapse(const Duration(seconds: 5));
        expect(failed, isFalse);
        expect(mockStdio.writtenToStdout.join(''), '');
        expect(mockStdio.writtenToStderr.join(''), '');
        time.elapse(const Duration(seconds: 5));
        expect(failed, isFalse);
        expect(mockStdio.writtenToStdout.join(''), 'This is taking longer than expected...\n');
        expect(mockStdio.writtenToStderr.join(''), '');
      });
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(
        outputPreferences: OutputPreferences.test(),
        stdio: mockStdio,
        terminal: AnsiTerminal(
          stdio: mockStdio,
          platform: const LocalPlatform(),
        ),
        timeoutConfiguration: const TimeoutConfiguration(),
      ),
      WebSocketConnector: () => (String url, {CompressionOptions compression}) async => throw const SocketException('test'),
    });

    testUsingContext('refreshViews', () async {
      final MockVMService mockVmService = MockVMService();
      ServiceCallback serviceCallback;
      when(mockVmService.registerServiceCallback('streamNotify', any))
        .thenAnswer((Invocation invocation) {
          serviceCallback = invocation.positionalArguments[1] as ServiceCallback;
        });
      final VMService vmService = VMService(null, null, null, null, null, null, null, mockVmService, Completer<void>());

      expect(serviceCallback, isNotNull);
      verify(mockVmService.registerService('flutterVersion', 'Flutter Tools')).called(1);

      final Future<void> onVMLoaded = vmService.getVMOld();
      verify(mockVmService.callServiceExtension('getVM',
        args: anyNamed('args'), // Empty
        isolateId: null
      )).called(1);
      await serviceCallback(<String, Object>{
        'streamId': 'Isolate',
        'event': vm,
      });
      await onVMLoaded;

      final Future<void> ready = vmService.refreshViews(waitForViews: true);
      verify(mockVmService.callServiceExtension('_flutter.listViews',
        args: anyNamed('args'),
        isolateId: anyNamed('isolateId')
      )).called(1);
      await serviceCallback(_listViews);
      await ready;

    }, overrides: <Type, Generator>{
      Logger: () => BufferLogger.test()
    });

    // testUsingContext('registers hot UI method', () {
    //   FakeAsync().run((FakeAsync time) {
    //     final MockPeer mockPeer = MockPeer();
    //     Future<void> reloadMethod({ String classId, String libraryId }) async {}
    //     VMService(mockPeer, null, null, null, null, null, null, reloadMethod);

    //     expect(mockPeer.registeredMethods, contains('reloadMethod'));
    //   });
    // }, overrides: <Type, Generator>{
    //   Logger: () => StdoutLogger(
    //     outputPreferences: globals.outputPreferences,
    //     terminal: AnsiTerminal(
    //       stdio: mockStdio,
    //       platform: const LocalPlatform(),
    //     ),
    //     stdio: mockStdio,
    //     timeoutConfiguration: const TimeoutConfiguration(),
    //   ),
    // });

    // testUsingContext('registers flutterMemoryInfo service', () {
    //   FakeAsync().run((FakeAsync time) {
    //     final MockDevice mockDevice = MockDevice();
    //     final MockPeer mockPeer = MockPeer();
    //     Future<void> reloadSources(String isolateId, { bool pause, bool force}) async {}
    //     VMService(mockPeer, null, null, reloadSources, null, null, mockDevice, null);

    //     expect(mockPeer.registeredMethods, contains('flutterMemoryInfo'));
    //   });
    // }, overrides: <Type, Generator>{
    //   Logger: () => StdoutLogger(
    //     outputPreferences: globals.outputPreferences,
    //     terminal: AnsiTerminal(
    //       stdio: mockStdio,
    //       platform: const LocalPlatform(),
    //     ),
    //     stdio: mockStdio,
    //     timeoutConfiguration: const TimeoutConfiguration(),
    //   ),
    // });

    // testUsingContext('returns correct FlutterVersion', () {
    //   FakeAsync().run((FakeAsync time) async {
    //     final MockPeer mockPeer = MockPeer();
    //     VMService(mockPeer, null, null, null, null, null, MockDevice(), null);

    //     expect(mockPeer.registeredMethods, contains('flutterVersion'));
    //     expect(await mockPeer.sendRequest('flutterVersion'), equals(mockVersion.toJson()));
    //   });
    // }, overrides: <Type, Generator>{
    //   FlutterVersion: () => mockVersion,
    // });
  });
}

class MockDevice extends Mock implements Device {}

class MockFlutterVersion extends Mock implements FlutterVersion {
  @override
  Map<String, Object> toJson() => const <String, Object>{'Mock': 'Version'};
}

class MockVMService extends Mock implements vm_service.VmService {}