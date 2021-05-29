// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';

final vm_service.Isolate isolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[
    vm_service.LibraryRef(
      id: '1',
      uri: 'file:///hello_world/main.dart',
      name: '',
    ),
  ],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
  extensionRPCs: <String>['ext.flutter.connectedVmServiceUri'],
);

final FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      FlutterView(
        id: 'a',
        uiIsolate: isolate,
      ).toJson()
    ],
  },
);

void main() {
  testWithoutContext('Does not serve devtools if launcher is null', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      null,
      FakeResidentRunner(),
      BufferLogger.test(),
    );

    await handler.serveAndAnnounceDevTools(flutterDevices: <FlutterDevice>[]);

    expect(handler.activeDevToolsServer, null);
  });

  testWithoutContext('Does not serve devtools if ResidentRunner does not support the service protocol', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      FakeDevtoolsLauncher(),
      FakeResidentRunner()..supportsServiceProtocol = false,
      BufferLogger.test(),
    );

    await handler.serveAndAnnounceDevTools(flutterDevices: <FlutterDevice>[]);

    expect(handler.activeDevToolsServer, null);
  });

  testWithoutContext('Can use devtools with existing devtools URI', () async {
    final DevtoolsServerLauncher launcher = DevtoolsServerLauncher(
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      pubExecutable: 'pub',
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      persistentToolState: null,
    );
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      // Uses real devtools instance which should be a no-op if
      // URI is already set.
      launcher,
      FakeResidentRunner(),
      BufferLogger.test(),
    );

    await handler.serveAndAnnounceDevTools(
      devToolsServerAddress: Uri.parse('http://localhost:8181'),
      flutterDevices: <FlutterDevice>[],
    );

    expect(handler.activeDevToolsServer.host, 'localhost');
    expect(handler.activeDevToolsServer.port, 8181);
  });

  testWithoutContext('serveAndAnnounceDevTools with attached device does not fail on null vm service', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      FakeDevtoolsLauncher()..activeDevToolsServer = DevToolsServerAddress('localhost', 8080),
      FakeResidentRunner(),
      BufferLogger.test(),
    );

    // VM Service is intentionally null
    final FakeFlutterDevice device = FakeFlutterDevice();

    await handler.serveAndAnnounceDevTools(
      flutterDevices: <FlutterDevice>[device],
    );
  });

  testWithoutContext('serveAndAnnounceDevTools with invokes devtools and vm_service setter', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      FakeDevtoolsLauncher()..activeDevToolsServer = DevToolsServerAddress('localhost', 8080),
      FakeResidentRunner(),
      BufferLogger.test(),
    );
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        }
      ),
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        jsonResponse: isolate.toJson(),
        args: <String, Object>{
          'isolateId': '1',
        },
      ),
      const FakeVmServiceRequest(
        method: 'streamCancel',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.activeDevToolsServerAddress',
        args: <String, Object>{
          'isolateId': '1',
          'value': 'http://localhost:8080',
        },
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.connectedVmServiceUri',
        args: <String, Object>{
          'isolateId': '1',
          'value': 'http://localhost:1234',
        },
      ),
    ], httpAddress: Uri.parse('http://localhost:1234'));

    final FakeFlutterDevice device = FakeFlutterDevice()
      ..vmService = fakeVmServiceHost.vmService;

    await handler.serveAndAnnounceDevTools(
      flutterDevices: <FlutterDevice>[device],
    );
  });

  testWithoutContext('serveAndAnnounceDevTools with skips calling service extensions when VM service disappears', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      FakeDevtoolsLauncher()..activeDevToolsServer = DevToolsServerAddress('localhost', 8080),
      FakeResidentRunner(),
      BufferLogger.test(),
    );
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      const FakeVmServiceRequest(
        method: kListViewsMethod,
        errorCode: RPCErrorCodes.kServiceDisappeared,
      ),
      const FakeVmServiceRequest(
        method: 'streamCancel',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
        errorCode: RPCErrorCodes.kServiceDisappeared,
      ),
    ], httpAddress: Uri.parse('http://localhost:1234'));

    final FakeFlutterDevice device = FakeFlutterDevice()
      ..vmService = fakeVmServiceHost.vmService;

    await handler.serveAndAnnounceDevTools(
      flutterDevices: <FlutterDevice>[device],
    );
  });

  testWithoutContext('serveAndAnnounceDevTools with multiple devices and VM service disappears on one', () async {
    final ResidentDevtoolsHandler handler = FlutterResidentDevtoolsHandler(
      FakeDevtoolsLauncher()..activeDevToolsServer = DevToolsServerAddress('localhost', 8080),
      FakeResidentRunner(),
      BufferLogger.test(),
    );

    final FakeVmServiceHost vmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        jsonResponse: isolate.toJson(),
        args: <String, Object>{
          'isolateId': '1',
        },
      ),
      const FakeVmServiceRequest(
        method: 'streamCancel',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.activeDevToolsServerAddress',
        args: <String, Object>{
          'isolateId': '1',
          'value': 'http://localhost:8080',
        },
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.connectedVmServiceUri',
        args: <String, Object>{
          'isolateId': '1',
          'value': 'http://localhost:1234',
        },
      ),
    ], httpAddress: Uri.parse('http://localhost:1234'));

    final FakeVmServiceHost vmServiceHostThatDisappears = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      const FakeVmServiceRequest(
        method: kListViewsMethod,
        errorCode: RPCErrorCodes.kServiceDisappeared,
      ),
      const FakeVmServiceRequest(
        method: 'streamCancel',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
        errorCode: RPCErrorCodes.kServiceDisappeared,
      ),
    ], httpAddress: Uri.parse('http://localhost:5678'));

    await handler.serveAndAnnounceDevTools(
      flutterDevices: <FlutterDevice>[
        FakeFlutterDevice()
          ..vmService = vmServiceHostThatDisappears.vmService,
        FakeFlutterDevice()
          ..vmService = vmServiceHost.vmService,
      ],
    );
  });
}

class FakeDevtoolsLauncher extends Fake implements DevtoolsLauncher {
  @override
  DevToolsServerAddress activeDevToolsServer;

  @override
  Future<DevToolsServerAddress> serve() {
    return null;
  }

  @override
  Future<void> get ready => Future<void>.value();
}

class FakeResidentRunner extends Fake implements ResidentRunner {
  @override
  bool supportsServiceProtocol = true;

  @override
  bool reportedDebuggers = false;
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  @override
  final Device device = FakeDevice();

  @override
  FlutterVmService vmService;
}

class FakeDevice extends Fake implements Device {}
