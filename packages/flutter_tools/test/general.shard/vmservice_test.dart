// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';

import '../src/common.dart';
import '../src/context.dart';

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

final Map<String, Object> listViews = <String, dynamic>{
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
  testUsingContext('VMService can refreshViews', () async {
    final MockVMService mockVmService = MockVMService();
    final VMService vmService = VMService(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      mockVmService,
      Completer<void>(),
      const Stream<dynamic>.empty(),
    );

    verify(mockVmService.registerService('flutterVersion', 'Flutter Tools')).called(1);

    when(mockVmService.callServiceExtension('getVM',
      args: anyNamed('args'), // Empty
      isolateId: null
    )).thenAnswer((Invocation invocation) async {
      return vm_service.Response.parse(vm);
    });
    await vmService.getVMOld();


    when(mockVmService.callServiceExtension('_flutter.listViews',
      args: anyNamed('args'),
      isolateId: anyNamed('isolateId')
    )).thenAnswer((Invocation invocation) async {
      return vm_service.Response.parse(listViews);
    });
    await vmService.refreshViews(waitForViews: true);

    expect(vmService.vm.name, 'vm');
    expect(vmService.vm.views.single.id, '_flutterView/0x4a4c1f8');
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers reloadSources', () {
    Future<void> reloadSources(String isolateId, { bool pause, bool force}) async {}
    final MockVMService mockVMService = MockVMService();
    VMService(
      null,
      null,
      reloadSources,
      null,
      null,
      null,
      null,
      mockVMService,
      Completer<void>(),
      const Stream<dynamic>.empty(),
    );

    verify(mockVMService.registerService('reloadSources', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers reloadMethod', () {
    Future<void> reloadMethod({  String classId, String libraryId,}) async {}
    final MockVMService mockVMService = MockVMService();
    VMService(
      null,
      null,
      null,
      null,
      null,
      null,
      reloadMethod,
      mockVMService,
      Completer<void>(),
      const Stream<dynamic>.empty(),
    );

    verify(mockVMService.registerService('reloadMethod', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers flutterMemoryInfo service', () {
    final MockDevice mockDevice = MockDevice();
    final MockVMService mockVMService = MockVMService();
    VMService(
      null,
      null,
      null,
      null,
      null,
      mockDevice,
      null,
      mockVMService,
      Completer<void>(),
      const Stream<dynamic>.empty(),
    );

    verify(mockVMService.registerService('flutterMemoryInfo', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VMService returns correct FlutterVersion', () async {
    final MockVMService mockVMService = MockVMService();
    VMService(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      mockVMService,
      Completer<void>(),
      const Stream<dynamic>.empty(),
    );

    verify(mockVMService.registerService('flutterVersion', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    FlutterVersion: () => MockFlutterVersion(),
  });

  testWithoutContext('setAssetDirectory forwards arguments correctly', () async {
    final Completer<String> completer = Completer<String>();
    final vm_service.VmService  vmService = vm_service.VmService(
      const Stream<String>.empty(),
      completer.complete,
    );

    unawaited(vmService.setAssetDirectory(
      assetsDirectory: Uri(path: 'abc', scheme: 'file'),
      viewId: 'abc',
      uiIsolateId: 'def',
    ));

    final Map<String, Object> rawRequest = json.decode(await completer.future) as Map<String, Object>;

    expect(rawRequest, allOf(<Matcher>[
      containsPair('method', kSetAssetBundlePathMethod),
      containsPair('params', allOf(<Matcher>[
        containsPair('viewId', 'abc'),
        containsPair('assetDirectory', '/abc'),
        containsPair('isolateId', 'def'),
      ]))
    ]));
  });

  testWithoutContext('getSkSLs forwards arguments correctly', () async {
    final Completer<String> completer = Completer<String>();
    final vm_service.VmService  vmService = vm_service.VmService(
      const Stream<String>.empty(),
      completer.complete,
    );

    unawaited(vmService.getSkSLs(
      viewId: 'abc',
    ));

    final Map<String, Object> rawRequest = json.decode(await completer.future) as Map<String, Object>;

    expect(rawRequest, allOf(<Matcher>[
      containsPair('method', kGetSkSLsMethod),
      containsPair('params', allOf(<Matcher>[
        containsPair('viewId', 'abc'),
      ]))
    ]));
  });

  testWithoutContext('flushUIThreadTasks forwards arguments correctly', () async {
    final Completer<String> completer = Completer<String>();
    final vm_service.VmService  vmService = vm_service.VmService(
      const Stream<String>.empty(),
      completer.complete,
    );

    unawaited(vmService.flushUIThreadTasks(
      uiIsolateId: 'def',
    ));

    final Map<String, Object> rawRequest = json.decode(await completer.future) as Map<String, Object>;

    expect(rawRequest, allOf(<Matcher>[
      containsPair('method', kFlushUIThreadTasksMethod),
      containsPair('params', allOf(<Matcher>[
        containsPair('isolateId', 'def'),
      ]))
    ]));
  });

  testWithoutContext('runInView forwards arguments correctly', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(method: 'streamListen', id: '1', params: <String, Object>{
          'streamId': 'Isolate'
        }),
        const FakeVmServiceRequest(method: kRunInViewMethod, id: '2', params: <String, Object>{
          'viewId': '1234',
          'mainScript': 'main.dart',
          'assetDirectory': 'flutter_assets/',
        }),
        FakeVmServiceStreamResponse(
          streamId: 'Isolate',
          event: vm_service.Event(
            kind: vm_service.EventKind.kIsolateRunnable,
            timestamp: 1,
          )
        ),
      ]
    );

    await fakeVmServiceHost.vmService.runInView(
      viewId: '1234',
      main: Uri.file('main.dart'),
      assetsDirectory: Uri.file('flutter_assets/'),
    );
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });
}

class FakeVmServiceHost {
  FakeVmServiceHost({
    @required List<VmServiceExpectation> requests,
  }) : _requests = requests {
    _vmService = vm_service.VmService(
      _input.stream,
      _output.add,
    );
    _applyStreamListen();
    _output.stream.listen((String data) {
      final Map<String, Object> request = json.decode(data) as Map<String, Object>;
      if (_requests.isEmpty) {
        throw Exception('Unexpected request: $request');
      }
      final FakeVmServiceRequest fakeRequest = _requests.removeAt(0) as FakeVmServiceRequest;
      expect(fakeRequest, isA<FakeVmServiceRequest>()
        .having((FakeVmServiceRequest request) => request.method, 'method', request['method'])
        .having((FakeVmServiceRequest request) => request.id, 'id', request['id'])
        .having((FakeVmServiceRequest request) => request.params, 'params', request['params'])
      );
      _input.add(json.encode(<String, Object>{
        'jsonrpc': '2.0',
        'id': fakeRequest.id,
        'result': fakeRequest.jsonResponse ?? <String, Object>{'type': 'Success'},
      }));
      _applyStreamListen();
    });
  }

  final List<VmServiceExpectation> _requests;
  final StreamController<String> _input = StreamController<String>();
  final StreamController<String> _output = StreamController<String>();

  vm_service.VmService get vmService => _vmService;
  vm_service.VmService _vmService;

  bool get hasRemainingExpectations => _requests.isNotEmpty;

  // remove FakeStreamResponse objects from _requests until it is empty
  // or until we hit a FakeRequest
  void _applyStreamListen() {
    while (_requests.isNotEmpty && !_requests.first.isRequest) {
      final FakeVmServiceStreamResponse response = _requests.removeAt(0) as FakeVmServiceStreamResponse;
      _input.add(json.encode(<String, Object>{
        'jsonrpc': '2.0',
        'method': 'streamNotify',
        'params': <String, Object>{
          'streamId': response.streamId,
          'event': response.event.toJson(),
        },
      }));
    }
  }
}

abstract class VmServiceExpectation {
  bool get isRequest;
}

class FakeVmServiceRequest implements VmServiceExpectation {
  const FakeVmServiceRequest({
    @required this.method,
    @required this.id,
    @required this.params,
    this.jsonResponse,
  });

  final String method;
  final String id;
  final Map<String, Object> params;
  final Map<String, Object> jsonResponse;

  @override
  bool get isRequest => true;
}

class FakeVmServiceStreamResponse implements VmServiceExpectation {
  const FakeVmServiceStreamResponse({
    @required this.event,
    @required this.streamId,
  });

  final vm_service.Event event;
  final String streamId;

  @override
  bool get isRequest => false;
}

class MockDevice extends Mock implements Device {}
class MockVMService extends Mock implements vm_service.VmService {}
class MockFlutterVersion extends Mock implements FlutterVersion {
  @override
  Map<String, Object> toJson() => const <String, Object>{'Mock': 'Version'};
}
