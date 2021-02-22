// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/convert.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:fake_async/fake_async.dart';

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
  testUsingContext('VmService registers reloadSources', () async {
    Future<void> reloadSources(String isolateId, { bool pause, bool force}) async {}

    final MockVMService mockVMService = MockVMService();
    setUpVmService(
      reloadSources,
      null,
      null,
      null,
      null,
      null,
      mockVMService,
    );

    verify(mockVMService.registerService('reloadSources', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers flutterMemoryInfo service', () async {
    final FakeDevice mockDevice = FakeDevice();

    final MockVMService mockVMService = MockVMService();
    setUpVmService(
      null,
      null,
      null,
      mockDevice,
      null,
      null,
      mockVMService,
    );

    verify(mockVMService.registerService('flutterMemoryInfo', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers flutterGetSkSL service', () async {
    final MockVMService mockVMService = MockVMService();
    setUpVmService(
      null,
      null,
      null,
      null,
      () async => 'hello',
      null,
      mockVMService,
    );

    verify(mockVMService.registerService('flutterGetSkSL', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VmService registers flutterPrintStructuredErrorLogMethod', () async {
    final MockVMService mockVMService = MockVMService();
    when(mockVMService.onExtensionEvent).thenAnswer((Invocation invocation) {
      return const Stream<vm_service.Event>.empty();
    });
    setUpVmService(
      null,
      null,
      null,
      null,
      null,
      (vm_service.Event event) async => 'hello',
      mockVMService,
    );
    verify(mockVMService.streamListen(vm_service.EventStreams.kExtension)).called(1);
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger.test()
  });

  testUsingContext('VMService returns correct FlutterVersion', () async {
    final MockVMService mockVMService = MockVMService();
    setUpVmService(
      null,
      null,
      null,
      null,
      null,
      null,
      mockVMService,
    );

    verify(mockVMService.registerService('flutterVersion', 'Flutter Tools')).called(1);
  }, overrides: <Type, Generator>{
    FlutterVersion: () => FakeFlutterVersion(),
  });

  testUsingContext('VMService prints messages for connection failures', () {
    FakeAsync().run((FakeAsync time) {
      final Uri uri = Uri.parse('ws://127.0.0.1:12345/QqL7EFEDNG0=/ws');
      unawaited(connectToVmService(uri));

      time.elapse(const Duration(seconds: 5));
      expect(testLogger.statusText, isEmpty);

      time.elapse(const Duration(minutes: 2));

      final String statusText = testLogger.statusText;
      expect(
        statusText,
        containsIgnoringWhitespace('Connecting to the VM Service is taking longer than expected...'),
      );
      expect(
        statusText,
        containsIgnoringWhitespace('try re-running with --host-vmservice-port'),
      );
      expect(
        statusText,
        containsIgnoringWhitespace('Exception attempting to connect to the VM Service:'),
      );
      expect(
        statusText,
        containsIgnoringWhitespace('This was attempt #50. Will retry'),
      );
    });
  }, overrides: <Type, Generator>{
    WebSocketConnector: () => failingWebSocketConnector,
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
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Isolate'
        }),
        const FakeVmServiceRequest(method: kRunInViewMethod, args: <String, Object>{
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

  testWithoutContext('Framework service extension invocations return null if service disappears ', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(
          method: kGetSkSLsMethod,
          args: <String, Object>{
            'viewId': '1234',
          },
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
        const FakeVmServiceRequest(
          method: kScreenshotMethod,
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
        const FakeVmServiceRequest(
          method: kScreenshotSkpMethod,
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
        const FakeVmServiceRequest(
          method: 'setVMTimelineFlags',
          args: <String, dynamic>{
            'recordedStreams': <String>['test'],
          },
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
        const FakeVmServiceRequest(
          method: 'getVMTimeline',
          errorCode: RPCErrorCodes.kServiceDisappeared,
        ),
      ]
    );

    final Map<String, Object> skSLs = await fakeVmServiceHost.vmService.getSkSLs(
      viewId: '1234',
    );
    expect(skSLs, isNull);

    final List<FlutterView> views = await fakeVmServiceHost.vmService.getFlutterViews();
    expect(views, isEmpty);

    final vm_service.Response screenshot = await fakeVmServiceHost.vmService.screenshot();
    expect(screenshot, isNull);

    final vm_service.Response screenshotSkp = await fakeVmServiceHost.vmService.screenshotSkp();
    expect(screenshotSkp, isNull);

    // Checking that this doesn't throw.
    await fakeVmServiceHost.vmService.setTimelineFlags(<String>['test']);

    final vm_service.Response timeline = await fakeVmServiceHost.vmService.getTimeline();
    expect(timeline, isNull);

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('getIsolateOrNull returns null if service disappears ', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(method: 'getIsolate', args: <String, Object>{
          'isolateId': 'isolate/123',
        }, errorCode: RPCErrorCodes.kServiceDisappeared),
      ]
    );

    final vm_service.Isolate isolate = await fakeVmServiceHost.vmService.getIsolateOrNull(
      'isolate/123',
    );
    expect(isolate, null);

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('getFlutterViews polls until a view is returned', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[],
          },
        ),
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[],
          },
        ),
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[
              <String, Object>{
                'id': 'a',
                'isolate': <String, Object>{},
              },
            ],
          },
        ),
      ]
    );

    expect(
      await fakeVmServiceHost.vmService.getFlutterViews(
        delay: Duration.zero,
      ),
      isNotEmpty,
    );
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('getFlutterViews does not poll if returnEarly is true', () async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[],
          },
        ),
      ]
    );

    expect(
      await fakeVmServiceHost.vmService.getFlutterViews(
        returnEarly: true,
      ),
      isEmpty,
    );
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  });

  testWithoutContext('expandos are null safe', () {
    vm_service.VmService vmService;

    expect(vmService.httpAddress, null);
    expect(vmService.wsAddress, null);
  });

  testWithoutContext('Can process log events from the vm service', () {
    final vm_service.Event event = vm_service.Event(
      bytes: base64.encode(utf8.encode('Hello There\n')),
      timestamp: 0,
      kind: vm_service.EventKind.kLogging,
    );

    expect(processVmServiceMessage(event), 'Hello There');
  });
}

class MockVMService extends Mock implements vm_service.VmService {}
class FakeDevice extends Fake implements Device {}
class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  Map<String, Object> toJson() => const <String, Object>{'Fake': 'Version'};
}

/// A [WebSocketConnector] that always throws an [io.SocketException].
Future<io.WebSocket> failingWebSocketConnector(
  String url, {
  io.CompressionOptions compression,
}) {
  throw const io.SocketException('Failed WebSocket connection');
}
