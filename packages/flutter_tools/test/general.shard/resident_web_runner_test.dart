// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/resident_web_runner.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';

const List<VmServiceExpectation> kAttachLogExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(
    method: 'streamListen',
    args: <String, Object>{
      'streamId': 'Stdout',
    },
  ),
  FakeVmServiceRequest(
    method: 'streamListen',
    args: <String, Object>{
      'streamId': 'Stderr',
    },
  )
];

const List<VmServiceExpectation> kAttachIsolateExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(
    method: 'streamListen',
    args: <String, Object>{
      'streamId': 'Isolate'
    }
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{
      'service': 'reloadSources',
      'alias': 'Flutter Tools',
    }
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{
      'service': 'flutterVersion',
      'alias': 'Flutter Tools',
    }
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{
      'service': 'flutterMemoryInfo',
      'alias': 'Flutter Tools',
    }
  ),
  FakeVmServiceRequest(
    method: 'streamListen',
    args: <String, Object>{
      'streamId': 'Extension',
    },
  ),
];

const List<VmServiceExpectation> kAttachExpectations = <VmServiceExpectation>[
  ...kAttachLogExpectations,
  ...kAttachIsolateExpectations,
];

void main() {
  MockDebugConnection mockDebugConnection;
  MockChromeDevice mockChromeDevice;
  MockAppConnection mockAppConnection;
  MockFlutterDevice mockFlutterDevice;
  MockWebDevFS mockWebDevFS;
  MockResidentCompiler mockResidentCompiler;
  MockChromeConnection mockChromeConnection;
  MockChromeTab mockChromeTab;
  MockWipConnection mockWipConnection;
  MockWipDebugger mockWipDebugger;
  MockWebServerDevice mockWebServerDevice;
  MockDevice mockDevice;
  FakeVmServiceHost fakeVmServiceHost;
  FileSystem fileSystem;
  ProcessManager processManager;
  TestUsage testUsage;

  setUp(() {
    testUsage = TestUsage();
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.any();
    mockDebugConnection = MockDebugConnection();
    mockDevice = MockDevice();
    mockAppConnection = MockAppConnection();
    mockFlutterDevice = MockFlutterDevice();
    mockWebDevFS = MockWebDevFS();
    mockResidentCompiler = MockResidentCompiler();
    mockChromeConnection = MockChromeConnection();
    mockChromeTab = MockChromeTab();
    mockWipConnection = MockWipConnection();
    mockWipDebugger = MockWipDebugger();
    mockWebServerDevice = MockWebServerDevice();
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockFlutterDevice.device).thenReturn(mockDevice);
    when(mockWebDevFS.connect(any)).thenAnswer((Invocation invocation) async {
      return ConnectionResult(
        mockAppConnection,
        mockDebugConnection,
        mockDebugConnection.vmService,
      );
    });
    fileSystem.file('.packages').writeAsStringSync('\n');
  });

  void _setupMocks() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('web/index.html').createSync(recursive: true);
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: true,  syncedBytes: 0);
    });
    when(mockDebugConnection.vmService).thenAnswer((Invocation invocation) {
      return fakeVmServiceHost.vmService.service;
    });
    when(mockDebugConnection.onDone).thenAnswer((Invocation invocation) {
      return Completer<void>().future;
    });
    when(mockDebugConnection.uri).thenReturn('ws://127.0.0.1/abcd/');
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockWebDevFS.sources).thenReturn(<Uri>[]);
    when(mockWebDevFS.baseUri).thenReturn(Uri.parse('http://localhost:12345'));
    when(mockFlutterDevice.generator).thenReturn(mockResidentCompiler);
    when(mockChromeConnection.getTab(any)).thenAnswer((Invocation invocation) async {
      return mockChromeTab;
    });
    when(mockChromeTab.connect()).thenAnswer((Invocation invocation) async {
      return mockWipConnection;
    });
    when(mockWipConnection.debugger).thenReturn(mockWipDebugger);
  }

  testUsingContext('runner with web server device does not support debugging without --start-paused', () {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: BufferLogger.test(),
    ));
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    expect(profileResidentWebRunner.debuggingEnabled, false);

    when(mockFlutterDevice.device).thenReturn(MockChromeDevice());

    expect(residentWebRunner.debuggingEnabled, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('runner with web server device supports debugging with --start-paused', () {
    fileSystem.file('.packages')
      ..createSync(recursive: true)
      ..writeAsStringSync('\n');
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: BufferLogger.test(),
    ));
    final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    expect(profileResidentWebRunner.uri, mockWebDevFS.baseUri);
    expect(profileResidentWebRunner.debuggingEnabled, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });
  testUsingContext('profile does not supportsServiceProtocol', () {
    fileSystem.file('.packages')
      ..createSync(recursive: true)
      ..writeAsStringSync('\n');
    final ResidentRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    when(mockFlutterDevice.device).thenReturn(mockChromeDevice);
    final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    expect(profileResidentWebRunner.supportsServiceProtocol, false);
    expect(residentWebRunner.supportsServiceProtocol, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can successfully run and connect to vmservice', () async {
    final BufferLogger bufferLogger = BufferLogger.test();
    final FakeStatusLogger logger = FakeStatusLogger(bufferLogger);
    fileSystem.file('.packages')
      ..createSync(recursive: true)
      ..writeAsStringSync('\n');
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    final MockStatus status = MockStatus();
    logger.status = status;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    verify(mockAppConnection.runMain()).called(1);
    verify(status.stop()).called(1);
    expect(bufferLogger.statusText, contains('Debug service listening on ws://127.0.0.1/abcd/'));
    expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
  }, overrides: <Type, Generator>{
    Logger: () => FakeStatusLogger(BufferLogger.test()),
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('WebRunner copies compiled app.dill to cache during startup', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();

    residentWebRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(await fileSystem.file(fileSystem.path.join('build', 'cache.dill')).readAsString(), 'ABC');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentWebRunner calls appFailedToStart if initial compilation fails', () async {
    _setupMocks();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fileSystem.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: false, syncedBytes: 0);
    });

    expect(await residentWebRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentWebRunner.waitForAppToFinish(), 1);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can successfully run without an index.html including status warning', () async {
    final BufferLogger logger = BufferLogger.test();
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    fileSystem.file(fileSystem.path.join('web', 'index.html'))
      .deleteSync();
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: false,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: logger,
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    expect(await residentWebRunner.run(), 0);
    expect(logger.statusText,
      contains('This application is not configured to build on the web'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can successfully run and disconnect with --no-resident', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    final ResidentRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: false,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    expect(await residentWebRunner.run(), 0);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Listens to stdout and stderr streams before running main', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachLogExpectations,
      FakeVmServiceStreamResponse(
        streamId: 'Stdout',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventStreams.kStdout,
          bytes: base64.encode(utf8.encode('THIS MESSAGE IS IMPORTANT'))
        ),
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Stderr',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventStreams.kStderr,
          bytes: base64.encode(utf8.encode('SO IS THIS'))
        ),
      ),
      ...kAttachIsolateExpectations,
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(logger.statusText, contains('THIS MESSAGE IS IMPORTANT'));
    expect(logger.statusText, contains('SO IS THIS'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Listens to extension events with structured errors', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: testLogger);
    final Map<String, String> extensionData = <String, String>{
      'test': 'data',
      'renderedErrorText': 'error text',
    };
    final Map<String, String> emptyExtensionData = <String, String>{
      'test': 'data',
      'renderedErrorText': '',
    };
    final Map<String, String> nonStructuredErrorData = <String, String>{
      'other': 'other stuff',
    };
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      FakeVmServiceStreamResponse(
        streamId: 'Extension',
        event: vm_service.Event(
          timestamp: 0,
          extensionKind: 'Flutter.Error',
          extensionData: vm_service.ExtensionData.parse(extensionData),
          kind: vm_service.EventStreams.kExtension,
        ),
      ),
      // Empty error text should not break anything.
      FakeVmServiceStreamResponse(
        streamId: 'Extension',
        event: vm_service.Event(
          timestamp: 0,
          extensionKind: 'Flutter.Error',
          extensionData: vm_service.ExtensionData.parse(emptyExtensionData),
          kind: vm_service.EventStreams.kExtension,
        ),
      ),
      // This is not Flutter.Error kind data, so it should not be logged.
      FakeVmServiceStreamResponse(
        streamId: 'Extension',
        event: vm_service.Event(
          timestamp: 0,
          extensionKind: 'Other',
          extensionData: vm_service.ExtensionData.parse(nonStructuredErrorData),
          kind: vm_service.EventStreams.kExtension,
        ),
      ),
    ]);

    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await null;

    expect(testLogger.statusText, contains('\nerror text'));
    expect(testLogger.statusText, isNot(contains('other stuff')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Does not run main with --start-paused', () async {
    final ResidentRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();

    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    verifyNever(mockAppConnection.runMain());
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can hot reload after attaching', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(
      mockFlutterDevice,
      logger: logger,
      systemClock: SystemClock.fixed(DateTime(2001, 1, 1)),
    );
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'hotRestart',
        jsonResponse: <String, Object>{
          'type': 'Success',
        }
      ),
    ]);
    _setupMocks();
    final TestChromiumLauncher chromiumLauncher = TestChromiumLauncher();
    final Chromium chrome = Chromium(1, mockChromeConnection, chromiumLauncher: chromiumLauncher);
    chromiumLauncher.instance = chrome;

    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      // Generated entrypoint file in temp dir.
      expect(invocation.namedArguments[#mainUri].toString(), contains('entrypoint.dart'));
      return UpdateFSReport(success: true);
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo, isNotNull);

    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(logger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);

    // ensure that analytics are sent.
    expect(testUsage.events, const <TestUsageEvent>[
      TestUsageEvent('hot', 'restart', parameters: <String, String>{'cd27': 'web-javascript', 'cd28': '', 'cd29': 'false', 'cd30': 'true', 'cd13': '0'}),
    ]);
    expect(testUsage.timings, const <TestTimingEvent>[
      TestTimingEvent('hot', 'web-incremental-restart', Duration.zero),
    ]);
  }, overrides: <Type, Generator>{
    Usage: () => testUsage,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can hot restart after attaching', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(
      mockFlutterDevice,
      logger: logger,
      systemClock: SystemClock.fixed(DateTime(2001, 1, 1)),
    );
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'hotRestart',
        jsonResponse: <String, Object>{
          'type': 'Success',
        }
      ),
    ]);
    _setupMocks();
    final TestChromiumLauncher chromiumLauncher = TestChromiumLauncher();
    final Chromium chrome = Chromium(1, mockChromeConnection, chromiumLauncher: chromiumLauncher);
    chromiumLauncher.instance = chrome;

    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    Uri entrypointFileUri;
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      entrypointFileUri = invocation.namedArguments[#mainUri] as Uri;
      return UpdateFSReport(success: true);
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    // Ensure that generated entrypoint is generated correctly.
    expect(entrypointFileUri, isNotNull);
    final String entrypointContents = fileSystem.file(entrypointFileUri).readAsStringSync();
    expect(entrypointContents, contains('// Flutter web bootstrap script'));
    expect(entrypointContents, contains("import 'dart:ui' as ui;"));
    expect(entrypointContents, contains('await ui.webOnlyInitializePlatform();'));

    expect(logger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);

	  // ensure that analytics are sent.
    expect(testUsage.events, const <TestUsageEvent>[
      TestUsageEvent('hot', 'restart', parameters: <String, String>{'cd27': 'web-javascript', 'cd28': '', 'cd29': 'false', 'cd30': 'true', 'cd13': '0'}),
    ]);
    expect(testUsage.timings, const <TestTimingEvent>[
      TestTimingEvent('hot', 'web-incremental-restart', Duration.zero),
    ]);
  }, overrides: <Type, Generator>{
    Usage: () => testUsage,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Can hot restart after attaching with web-server device', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(
      mockFlutterDevice,
      logger: logger,
      systemClock: SystemClock.fixed(DateTime(2001, 1, 1)),
    );
    fakeVmServiceHost = FakeVmServiceHost(requests :kAttachExpectations);
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(mockWebServerDevice);
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return UpdateFSReport(success: true);
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(logger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);

	  // web-server device does not send restart analytics
    expect(testUsage.events, isEmpty);
    expect(testUsage.timings, isEmpty);
  }, overrides: <Type, Generator>{
    Usage: () => testUsage,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('web resident runner is debuggable', () {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());

    expect(residentWebRunner.debuggingEnabled, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Exits when initial compile fails', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: false,  syncedBytes: 0);
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));

    expect(await residentWebRunner.run(), 1);
    expect(testUsage.events, isEmpty);
    expect(testUsage.timings, isEmpty);
  }, overrides: <Type, Generator>{
    Usage: () => testUsage,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Faithfully displays stdout messages with leading/trailing spaces', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachLogExpectations,
      FakeVmServiceStreamResponse(
        streamId: 'Stdout',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventStreams.kStdout,
          bytes: base64.encode(
            utf8.encode('    This is a message with 4 leading and trailing spaces    '),
          ),
        ),
      ),
      ...kAttachIsolateExpectations,
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(logger.statusText,
      contains('    This is a message with 4 leading and trailing spaces    '));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Fails on compilation errors in hot restart', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: false,  syncedBytes: 0);
    });

    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
    expect(testUsage.events, isEmpty);
    expect(testUsage.timings, isEmpty);
  }, overrides: <Type, Generator>{
    Usage: () => testUsage,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Fails non-fatally on vmservice response error for hot restart', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'hotRestart',
        jsonResponse: <String, Object>{
          'type': 'Failed',
        }
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 0);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Fails fatally on Vm Service error response', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'hotRestart',
        // Failed response,
        errorCode: RPCErrorCodes.kInternalError,
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 1);
    expect(result.message,
      contains(RPCErrorCodes.kInternalError.toString()));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('printHelp without details shows hot restart help message', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentWebRunner.printHelp(details: false);

    expect(logger.statusText, contains('To hot restart changes'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugDumpApp', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugDumpApp',
        args: <String, Object>{
          'isolateId': null,
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpApp();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugDumpLayerTree', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugDumpLayerTree',
        args: <String, Object>{
          'isolateId': null,
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpLayerTree();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugDumpRenderTree', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugDumpRenderTree',
        args: <String, Object>{
          'isolateId': null,
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpRenderTree();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugDumpSemanticsTreeInTraversalOrder', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugDumpSemanticsTreeInTraversalOrder',
        args: <String, Object>{
          'isolateId': null,
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpSemanticsTreeInTraversalOrder();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugDumpSemanticsTreeInInverseHitTestOrder', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder',
        args: <String, Object>{
          'isolateId': null,
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));

    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpSemanticsTreeInInverseHitTestOrder();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugToggleDebugPaintSizeEnabled', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugPaint',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'enabled': 'false'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.debugPaint',
        args: <String, Object>{
          'isolateId': null,
          'enabled': 'true',
        },
        jsonResponse: <String, Object>{
          'value': 'true'
        },
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugToggleDebugPaintSizeEnabled();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugTogglePerformanceOverlayOverride', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.showPerformanceOverlay',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'enabled': 'false'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.showPerformanceOverlay',
        args: <String, Object>{
          'isolateId': null,
          'enabled': 'true',
        },
        jsonResponse: <String, Object>{
          'enabled': 'true'
        },
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugTogglePerformanceOverlayOverride();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugToggleInvertOversizedImagesOverride', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.invertOversizedImages',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'enabled': 'false'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.invertOversizedImages',
        args: <String, Object>{
          'isolateId': null,
          'enabled': 'true',
        },
        jsonResponse: <String, Object>{
          'enabled': 'true'
        },
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugToggleInvertOversizedImages();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugToggleWidgetInspector', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.inspector.show',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'enabled': 'false'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.inspector.show',
        args: <String, Object>{
          'isolateId': null,
          'enabled': 'true',
        },
        jsonResponse: <String, Object>{
          'enabled': 'true'
        },
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugToggleWidgetInspector();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugToggleProfileWidgetBuilds', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.profileWidgetBuilds',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'enabled': 'false'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.profileWidgetBuilds',
        args: <String, Object>{
          'isolateId': null,
          'enabled': 'true',
        },
        jsonResponse: <String, Object>{
          'enabled': 'true'
        },
      )
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugToggleProfileWidgetBuilds();

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugTogglePlatform', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.platformOverride',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'value': 'iOS'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.platformOverride',
        args: <String, Object>{
          'isolateId': null,
          'value': 'fuchsia',
        },
        jsonResponse: <String, Object>{
          'value': 'fuchsia'
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugTogglePlatform();

    expect(logger.statusText,
      contains('Switched operating system to fuchsia'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debugToggleBrightness', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
      const FakeVmServiceRequest(
        method: 'ext.flutter.brightnessOverride',
        args: <String, Object>{
          'isolateId': null,
        },
        jsonResponse: <String, Object>{
          'value': 'Brightness.light'
        },
      ),
      const FakeVmServiceRequest(
        method: 'ext.flutter.brightnessOverride',
        args: <String, Object>{
          'isolateId': null,
          'value': 'Brightness.dark',
        },
        jsonResponse: <String, Object>{
          'value': 'Brightness.dark'
        },
      ),
    ]);
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.debugToggleBrightness();

    expect(logger.statusText,
      contains('Changed brightness to Brightness.dark.'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('cleanup of resources is safe to call multiple times', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
    ]);
    _setupMocks();
    bool debugClosed = false;
    when(mockDevice.stopApp(any, userIdentifier: anyNamed('userIdentifier'))).thenAnswer((Invocation invocation) async {
      if (debugClosed) {
        throw StateError('debug connection closed twice');
      }
      debugClosed = true;
      return true;
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    await residentWebRunner.exit();
    await residentWebRunner.exit();

    verifyNever(mockDebugConnection.close());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('cleans up Chrome if tab is closed', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
    ]);
    _setupMocks();
    final Completer<void> onDone = Completer<void>();
    when(mockDebugConnection.onDone).thenAnswer((Invocation invocation) {
      return onDone.future;
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Future<int> result = residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    );
    await connectionInfoCompleter.future;
    onDone.complete();

    await result;
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Prints target and device name on run', () async {
    final BufferLogger logger = BufferLogger.test();
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: logger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachExpectations,
    ]);
    _setupMocks();
    when(mockDevice.name).thenReturn('Chromez');
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(logger.statusText, contains(
      'Launching ${fileSystem.path.join('lib', 'main.dart')} on '
      'Chromez in debug mode',
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Sends launched app.webLaunchUrl event for Chrome device', () async {
    final BufferLogger logger = BufferLogger.test();
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachLogExpectations,
      ...kAttachIsolateExpectations,
    ]);
    _setupMocks();
    final MockChromeConnection mockChromeConnection = MockChromeConnection();
    final TestChromiumLauncher chromiumLauncher = TestChromiumLauncher();
    final Chromium chrome = Chromium(1, mockChromeConnection, chromiumLauncher: chromiumLauncher);
    chromiumLauncher.instance = chrome;

    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: fileSystem,
      chromiumLauncher: chromiumLauncher,
      logger: logger,
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    when(mockWebDevFS.create()).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:8765/app/');
    });
    final MockChromeTab mockChromeTab = MockChromeTab();
    final MockWipConnection mockWipConnection = MockWipConnection();
    when(mockChromeConnection.getTab(any)).thenAnswer((Invocation invocation) async {
      return mockChromeTab;
    });
    when(mockChromeTab.connect()).thenAnswer((Invocation invocation) async {
      return mockWipConnection;
    });

    final ResidentWebRunner runner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: logger,
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(runner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    // Ensure we got the URL and that it was already launched.
    expect(logger.eventText,
      contains(json.encode(<String, Object>{
        'name': 'app.webLaunchUrl',
        'args': <String, Object>{
          'url': 'http://localhost:8765/app/',
          'launched': true,
        },
      },
    )));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Logger: () => FakeStatusLogger(BufferLogger.test()),
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Sends unlaunched app.webLaunchUrl event for Web Server device', () async {
    final BufferLogger logger = BufferLogger.test();
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: logger,
    ));
    when(mockWebDevFS.create()).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:8765/app/');
    });

    final ResidentWebRunner runner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      fileSystem: fileSystem,
      logger: logger,
      usage: globals.flutterUsage,
      featureFlags: TestFeatureFlags(),
      systemClock: globals.systemClock,
    );

    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(runner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    // Ensure we got the URL and that it was not already launched.
    expect(logger.eventText,
      contains(json.encode(<String, Object>{
        'name': 'app.webLaunchUrl',
        'args': <String, Object>{
          'url': 'http://localhost:8765/app/',
          'launched': false,
        },
      },
    )));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Successfully turns WebSocketException into ToolExit', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(const WebSocketException());

    await expectLater(residentWebRunner.run, throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Successfully turns AppConnectionException into ToolExit', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(AppConnectionException(''));

    await expectLater(residentWebRunner.run, throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Successfully turns ChromeDebugError into ToolExit', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(ChromeDebugException(<String, dynamic>{}));

    await expectLater(residentWebRunner.run, throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Rethrows unknown Exception type from dwds', () async {
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockWebDevFS.connect(any)).thenThrow(Exception());

    await expectLater(residentWebRunner.run, throwsException);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('Rethrows unknown Error type from dwds tooling', () async {
    final BufferLogger logger = BufferLogger.test();
    final FakeStatusLogger fakeStatusLogger = FakeStatusLogger(logger);
    final ResidentRunner residentWebRunner = setUpResidentRunner(mockFlutterDevice, logger: fakeStatusLogger);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    final MockStatus mockStatus = MockStatus();
    fakeStatusLogger.status = mockStatus;

    when(mockWebDevFS.connect(any)).thenThrow(StateError(''));

    await expectLater(residentWebRunner.run, throwsStateError);
    verify(mockStatus.stop()).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });
}

ResidentRunner setUpResidentRunner(FlutterDevice flutterDevice, {
  Logger logger,
  SystemClock systemClock,
}) {
  return ResidentWebRunner(
    flutterDevice,
    flutterProject: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory),
    debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    ipv6: true,
    stayResident: true,
    urlTunneller: null,
    usage: globals.flutterUsage,
    systemClock: systemClock ?? SystemClock.fixed(DateTime.now()),
    fileSystem: globals.fs,
    logger: logger ?? BufferLogger.test(),
    featureFlags: TestFeatureFlags(),
  );
}

class MockChromeDevice extends Mock implements ChromiumDevice {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockAppConnection extends Mock implements AppConnection {}
class MockStatus extends Mock implements Status {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockWebDevFS extends Mock implements WebDevFS {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
class MockChrome extends Mock implements Chromium {}
class MockChromeConnection extends Mock implements ChromeConnection {}
class MockChromeTab extends Mock implements ChromeTab {}
class MockWipConnection extends Mock implements WipConnection {}
class MockWipDebugger extends Mock implements WipDebugger {}
class MockWebServerDevice extends Mock implements WebServerDevice {}
class MockDevice extends Mock implements Device {}

/// A test implementation of the [ChromiumLauncher] that launches a fixed instance.
class TestChromiumLauncher implements ChromiumLauncher {
  TestChromiumLauncher();

  set instance(Chromium chromium) {
    _hasInstance = true;
    currentCompleter.complete(chromium);
  }
  bool _hasInstance = false;

  @override
  Completer<Chromium> currentCompleter = Completer<Chromium>();

  @override
  bool canFindExecutable() {
    return true;
  }

  @override
  Future<Chromium> get connectedInstance => currentCompleter.future;

  @override
  String findExecutable() {
    return 'chrome';
  }

  @override
  bool get hasChromeInstance => _hasInstance;

  @override
  Future<Chromium> launch(String url, {bool headless = false, int debugPort, bool skipCheck = false, Directory cacheDir}) async {
    return currentCompleter.future;
  }
}
