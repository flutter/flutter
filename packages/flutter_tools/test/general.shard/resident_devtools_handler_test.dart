// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';

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
  extensionRPCs: <String>['foo']
);

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  extensionRPCs: <String>[],
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
);

final vm_service.VM fakeVM = vm_service.VM(
  isolates: <vm_service.IsolateRef>[fakeUnpausedIsolate],
  pid: 1,
  hostCPU: '',
  isolateGroups: <vm_service.IsolateGroupRef>[],
  targetCPU: '',
  startTime: 0,
  name: 'dart',
  architectureBits: 64,
  operatingSystem: '',
  version: '',
  systemIsolateGroups: <vm_service.IsolateGroupRef>[],
  systemIsolates: <vm_service.IsolateRef>[],
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: fakeUnpausedIsolate,
);

final FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      fakeFlutterView.toJson(),
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
          'streamId': 'Extension',
        }
      ),
      FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
      FakeVmServiceRequest(
        method: 'getIsolate',
        jsonResponse: isolate.toJson(),
        args: <String, Object>{
          'isolateId': '1',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Extension',
        event: vm_service.Event(
          timestamp: 0,
          extensionKind: 'Flutter.FrameworkInitialization',
          kind: 'test',
        ),
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
    ]);

    final FakeFlutterDevice device = FakeFlutterDevice()
      ..vmService = fakeVmServiceHost.vmService;
    setHttpAddress(Uri.parse('http://localhost:1234'), fakeVmServiceHost.vmService);

    await handler.serveAndAnnounceDevTools(
      flutterDevices: <FlutterDevice>[device],
    );
  });

  testWithoutContext('wait for extension handles an immediate extension', () {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Extension',
        }
      ),
      FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
      FakeVmServiceRequest(
        method: 'getIsolate',
        jsonResponse: isolate.toJson(),
        args: <String, Object>{
          'isolateId': '1',
        },
      ),
    ]);
    waitForExtension(fakeVmServiceHost.vmService, 'foo');
  });

  testWithoutContext('wait for extension handles no isolates', () {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Extension',
        }
      ),
      FakeVmServiceRequest(method: 'getVM', jsonResponse: vm_service.VM(
        isolates: <vm_service.IsolateRef>[],
        pid: 1,
        hostCPU: '',
        isolateGroups: <vm_service.IsolateGroupRef>[],
        targetCPU: '',
        startTime: 0,
        name: 'dart',
        architectureBits: 64,
        operatingSystem: '',
        version: '',
        systemIsolateGroups: <vm_service.IsolateGroupRef>[],
        systemIsolates: <vm_service.IsolateRef>[],
      ).toJson()),
      FakeVmServiceStreamResponse(
        streamId: 'Extension',
        event: vm_service.Event(
          timestamp: 0,
          extensionKind: 'Flutter.FrameworkInitialization',
          kind: 'test',
        ),
      ),
    ]);
    waitForExtension(fakeVmServiceHost.vmService, 'foo');
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
  vm_service.VmService vmService;
}
