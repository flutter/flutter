// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_runner/devfs_web.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
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
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

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
    method: 'streamListen',
    args: <String, Object>{
      'streamId': 'Extension',
    },
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{
      'service': 'reloadSources',
      'alias': 'FlutterTools',
    }
  )
];

const List<VmServiceExpectation> kAttachExpectations = <VmServiceExpectation>[
  ...kAttachLogExpectations,
  ...kAttachIsolateExpectations,
];

void main() {
  Testbed testbed;
  ResidentWebRunner residentWebRunner;
  MockDebugConnection mockDebugConnection;
  MockChromeDevice mockChromeDevice;
  MockAppConnection mockAppConnection;
  MockFlutterDevice mockFlutterDevice;
  MockWebDevFS mockWebDevFS;
  MockResidentCompiler mockResidentCompiler;
  MockChrome mockChrome;
  MockChromeConnection mockChromeConnection;
  MockChromeTab mockChromeTab;
  MockWipConnection mockWipConnection;
  MockWipDebugger mockWipDebugger;
  MockWebServerDevice mockWebServerDevice;
  MockDevice mockDevice;
  FakeVmServiceHost fakeVmServiceHost;

  setUp(() {
    mockDebugConnection = MockDebugConnection();
    mockDevice = MockDevice();
    mockAppConnection = MockAppConnection();
    mockFlutterDevice = MockFlutterDevice();
    mockWebDevFS = MockWebDevFS();
    mockResidentCompiler = MockResidentCompiler();
    mockChrome = MockChrome();
    mockChromeConnection = MockChromeConnection();
    mockChromeTab = MockChromeTab();
    mockWipConnection = MockWipConnection();
    mockWipDebugger = MockWipDebugger();
    mockWebServerDevice = MockWebServerDevice();
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockFlutterDevice.device).thenReturn(mockDevice);
    when(mockWebDevFS.connect(any)).thenAnswer((Invocation invocation) async {
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });
    testbed = Testbed(
      setup: () {
        residentWebRunner = DwdsWebRunnerFactory().createWebRunner(
          mockFlutterDevice,
          flutterProject: FlutterProject.current(),
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          ipv6: true,
          stayResident: true,
          urlTunneller: null,
        ) as ResidentWebRunner;
        globals.fs.currentDirectory.childFile('.packages')
          .writeAsStringSync('\n');
      },
      overrides: <Type, Generator>{
        Pub: () => MockPub(),
      }
    );
  });

  void _setupMocks() {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file(globals.fs.path.join('web', 'index.html')).createSync(recursive: true);
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
      return UpdateFSReport(success: true,  syncedBytes: 0)..invalidatedModules = <String>[];
    });
    when(mockDebugConnection.vmService).thenAnswer((Invocation invocation) {
      return fakeVmServiceHost.vmService;
    });
    when(mockDebugConnection.onDone).thenAnswer((Invocation invocation) {
      return Completer<void>().future;
    });
    when(mockDebugConnection.uri).thenReturn('ws://127.0.0.1/abcd/');
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockWebDevFS.sources).thenReturn(<Uri>[]);
    when(mockWebDevFS.baseUri).thenReturn(Uri.parse('http://localhost:12345'));
    when(mockFlutterDevice.generator).thenReturn(mockResidentCompiler);
    when(mockChrome.chromeConnection).thenReturn(mockChromeConnection);
    when(mockChromeConnection.getTab(any)).thenAnswer((Invocation invocation) async {
      return mockChromeTab;
    });
    when(mockChromeTab.connect()).thenAnswer((Invocation invocation) async {
      return mockWipConnection;
    });
    when(mockWipConnection.debugger).thenReturn(mockWipDebugger);
  }

  test('runner with web server device does not support debugging without --start-paused', () => testbed.run(() {
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: BufferLogger.test(),
    ));
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final ResidentRunner profileResidentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    ) as ResidentWebRunner;

    expect(profileResidentWebRunner.debuggingEnabled, false);

    when(mockFlutterDevice.device).thenReturn(MockChromeDevice());
    expect(residentWebRunner.debuggingEnabled, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('runner with web server device supports debugging with --start-paused', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: BufferLogger.test(),
    ));
    final ResidentRunner profileResidentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    );

    expect(profileResidentWebRunner.uri, mockWebDevFS.baseUri);
    expect(profileResidentWebRunner.debuggingEnabled, true);
  }));

  test('profile does not supportsServiceProtocol', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    when(mockFlutterDevice.device).thenReturn(mockChromeDevice);
    final ResidentRunner profileResidentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    );

    expect(profileResidentWebRunner.supportsServiceProtocol, false);
    expect(residentWebRunner.supportsServiceProtocol, true);
  }));

  test('Exits on run if target file does not exist', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file(globals.fs.path.join('web', 'index.html'))
      .createSync(recursive: true);

    expect(await residentWebRunner.run(), 1);
    final String absoluteMain = globals.fs.path.absolute(globals.fs.path.join('lib', 'main.dart'));
    expect(testLogger.errorText, contains('Tried to run $absoluteMain, but that file does not exist.'));
  }));

  test('Can successfully run and connect to vmservice', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final BufferLogger bufferLogger = delegateLogger.delegate as BufferLogger;
    final MockStatus status = MockStatus();
    delegateLogger.status = status;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    verify(mockAppConnection.runMain()).called(1);
    verify(status.stop()).called(1);
    verify(pub.get(
      context: PubContext.pubGet,
      directory: globals.fs.path.join('packages', 'flutter_tools')
    )).called(1);

    expect(bufferLogger.statusText, contains('Debug service listening on ws://127.0.0.1/abcd/'));
    expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger.test()),
  }));

  test('WebRunner copies compiled app.dill to cache during startup', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();

    residentWebRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(), 'ABC');
  }));

  test('Can successfully run without an index.html including status warning', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    globals.fs.file(globals.fs.path.join('web', 'index.html'))
      .deleteSync();
    residentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: false,
      urlTunneller: null,
    ) as ResidentWebRunner;

    expect(await residentWebRunner.run(), 0);
    expect(testLogger.statusText,
      contains('This application is not configured to build on the web'));
  }));

  test('Can successfully run and disconnect with --no-resident', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    _setupMocks();
    residentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: false,
      urlTunneller: null,
    ) as ResidentWebRunner;

    expect(await residentWebRunner.run(), 0);
  }));

  test('Listens to stdout and stderr streams before running main', () => testbed.run(() async {
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

    expect(testLogger.statusText, contains('THIS MESSAGE IS IMPORTANT'));
    expect(testLogger.statusText, contains('SO IS THIS'));
  }));

  test('Listens to extension events with structured errors', () => testbed.run(() async {
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

    // Need these to run events, otherwise expect statements below run before
    // structured errors are processed.
    await null;
    await null;
    await null;

    expect(testLogger.statusText, contains('\nerror text'));
    expect(testLogger.statusText, isNot(contains('other stuff')));
  }));

  test('Does not run main with --start-paused', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
    residentWebRunner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    ) as ResidentWebRunner;
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();

    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    verifyNever(mockAppConnection.runMain());
  }));

  test('Can hot reload after attaching', () => testbed.run(() async {
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
    final ChromiumLauncher chromiumLauncher = MockChromeLauncher();
    when(chromiumLauncher.launch(any, cacheDir: anyNamed('cacheDir')))
      .thenAnswer((Invocation invocation) async {
        return mockChrome;
      });
    when(chromiumLauncher.connectedInstance).thenAnswer((Invocation invocation) async {
      return mockChrome;
    });
    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: globals.fs,
      chromiumLauncher: chromiumLauncher,
      logger: globals.logger,
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    when(chromiumLauncher.canFindExecutable()).thenReturn(true);
    chromiumLauncher.testLaunchChromium(mockChrome);
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
      return UpdateFSReport(success: true)
        ..invalidatedModules = <String>['example'];
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo, isNotNull);

    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(testLogger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);
	  // ensure that analytics are sent.
    final Map<String, String> config = verify(globals.flutterUsage.sendEvent('hot', 'restart',
      parameters: captureAnyNamed('parameters'))).captured.first as Map<String, String>;

    expect(config, allOf(<Matcher>[
      containsPair('cd27', 'web-javascript'),
      containsPair('cd28', ''),
      containsPair('cd29', 'false'),
      containsPair('cd30', 'true'),
    ]));
    verify(globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Can hot restart after attaching', () => testbed.run(() async {
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
    final ChromiumLauncher chromiumLauncher = MockChromeLauncher();
    when(chromiumLauncher.launch(any, cacheDir: anyNamed('cacheDir')))
      .thenAnswer((Invocation invocation) async {
        return mockChrome;
      });
    when(chromiumLauncher.connectedInstance).thenAnswer((Invocation invocation) async {
      return mockChrome;
    });
    when(chromiumLauncher.canFindExecutable()).thenReturn(true);
    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: globals.fs,
      chromiumLauncher: chromiumLauncher,
      logger: globals.logger,
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    chromiumLauncher.testLaunchChromium(mockChrome);
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
      return UpdateFSReport(success: true)
        ..invalidatedModules = <String>['example'];
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    // Ensure that generated entrypoint is generated correctly.
    expect(entrypointFileUri, isNotNull);
    final String entrypointContents = globals.fs.file(entrypointFileUri).readAsStringSync();
    expect(entrypointContents, contains('// Flutter web bootstrap script'));
    expect(entrypointContents, contains("import 'dart:ui' as ui;"));
    expect(entrypointContents, contains('await ui.webOnlyInitializePlatform();'));

    expect(testLogger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);
	  // ensure that analytics are sent.
    final Map<String, String> config = verify(globals.flutterUsage.sendEvent('hot', 'restart',
      parameters: captureAnyNamed('parameters'))).captured.first as Map<String, String>;

    expect(config, allOf(<Matcher>[
      containsPair('cd27', 'web-javascript'),
      containsPair('cd28', ''),
      containsPair('cd29', 'false'),
      containsPair('cd30', 'true'),
    ]));
    verify(globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Can hot restart after attaching with web-server device', () => testbed.run(() async {
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
      return UpdateFSReport(success: true)
        ..invalidatedModules = <String>['example'];
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(testLogger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);
    // ensure that analytics are sent.
    verifyNever(globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', any));
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('web resident runner is debuggable', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());

    expect(residentWebRunner.debuggingEnabled, true);
  }));

  test('web resident runner can toggle CanvasKit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final WebAssetServer webAssetServer = WebAssetServer(null, null, null, null, null);
    when(mockWebDevFS.webAssetServer).thenReturn(webAssetServer);

    expect(residentWebRunner.supportsCanvasKit, true);
    expect(webAssetServer.canvasKitRendering, false);

    final bool toggleResult = await residentWebRunner.toggleCanvaskit();

    expect(webAssetServer.canvasKitRendering, true);
    expect(toggleResult, true);
  }));

  test('Exits when initial compile fails', () => testbed.run(() async {
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
      return UpdateFSReport(success: false,  syncedBytes: 0)..invalidatedModules = <String>[];
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));

    expect(await residentWebRunner.run(), 1);
    verifyNever(globals.flutterUsage.sendTiming('hot', 'web-restart', any));
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Faithfully displays stdout messages with leading/trailing spaces', () => testbed.run(() async {
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

    expect(testLogger.statusText,
      contains('    This is a message with 4 leading and trailing spaces    '));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Fails on compilation errors in hot restart', () => testbed.run(() async {
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
      return UpdateFSReport(success: false,  syncedBytes: 0)..invalidatedModules = <String>[];
    });

    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
    verifyNever(globals.flutterUsage.sendTiming('hot', 'web-restart', any));
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Fails non-fatally on vmservice response error for hot restart', () => testbed.run(() async {
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
  }));

  test('Fails fatally on Vm Service error response', () => testbed.run(() async {
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
  }));

  test('printHelp without details has web warning', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentWebRunner.printHelp(details: false);

    expect(testLogger.statusText, contains('Warning'));
    expect(testLogger.statusText, contains('https://flutter.dev/web'));
    expect(testLogger.statusText, isNot(contains('https://flutter.dev/web.')));
  }));

  test('debugDumpApp', () => testbed.run(() async {
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
  }));

  test('debugDumpLayerTree', () => testbed.run(() async {
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
  }));

  test('debugDumpRenderTree', () => testbed.run(() async {
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
  }));

  test('debugDumpSemanticsTreeInTraversalOrder', () => testbed.run(() async {
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
  }));

  test('debugDumpSemanticsTreeInInverseHitTestOrder', () => testbed.run(() async {
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
  }));

  test('debugToggleDebugPaintSizeEnabled', () => testbed.run(() async {
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
  }));


  test('debugTogglePerformanceOverlayOverride', () => testbed.run(() async {
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
  }));

  test('debugToggleWidgetInspector', () => testbed.run(() async {
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
  }));

  test('debugToggleProfileWidgetBuilds', () => testbed.run(() async {
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
  }));

  test('debugTogglePlatform', () => testbed.run(() async {
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

    expect(testLogger.statusText,
      contains('Switched operating system to fuchsia'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('cleanup of resources is safe to call multiple times', () => testbed.run(() async {
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
  }));

  test('cleans up Chrome if tab is closed', () => testbed.run(() async {
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
  }));

  test('Prints target and device name on run', () => testbed.run(() async {
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

    expect(testLogger.statusText, contains(
      'Launching ${globals.fs.path.join('lib', 'main.dart')} on '
      'Chromez in debug mode',
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Sends launched app.webLaunchUrl event for Chrome device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      ...kAttachLogExpectations,
      ...kAttachIsolateExpectations,
    ]);
    _setupMocks();
    final ChromiumLauncher chromiumLauncher = MockChromeLauncher();
    when(chromiumLauncher.launch(any, cacheDir: anyNamed('cacheDir')))
      .thenAnswer((Invocation invocation) async {
        return mockChrome;
      });
    when(chromiumLauncher.connectedInstance).thenAnswer((Invocation invocation) async {
      return mockChrome;
    });
    when(mockFlutterDevice.device).thenReturn(GoogleChromeDevice(
      fileSystem: globals.fs,
      chromiumLauncher: chromiumLauncher,
      logger: globals.logger,
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    ));
    when(chromiumLauncher.canFindExecutable()).thenReturn(true);
    when(mockWebDevFS.create()).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:8765/app/');
    });
    final MockChrome chrome = MockChrome();
    final MockChromeConnection mockChromeConnection = MockChromeConnection();
    final MockChromeTab mockChromeTab = MockChromeTab();
    final MockWipConnection mockWipConnection = MockWipConnection();
    when(mockChromeConnection.getTab(any)).thenAnswer((Invocation invocation) async {
      return mockChromeTab;
    });
    when(mockChromeTab.connect()).thenAnswer((Invocation invocation) async {
      return mockWipConnection;
    });
    when(chrome.chromeConnection).thenReturn(mockChromeConnection);
    chromiumLauncher.testLaunchChromium(chrome);

    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;
    final ResidentWebRunner runner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    ) as ResidentWebRunner;

    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(runner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    // Ensure we got the URL and that it was already launched.
    expect((delegateLogger.delegate as BufferLogger).eventText,
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
    Logger: () => DelegateLogger(BufferLogger.test()),
  }));

  test('Sends unlaunched app.webLaunchUrl event for Web Server device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice(
      logger: globals.logger,
    ));
    when(mockWebDevFS.create()).thenAnswer((Invocation invocation) async {
      return Uri.parse('http://localhost:8765/app/');
    });

    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;
    final ResidentWebRunner runner = DwdsWebRunnerFactory().createWebRunner(
      mockFlutterDevice,
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
    ) as ResidentWebRunner;

    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(runner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    // Ensure we got the URL and that it was not already launched.
    expect((delegateLogger.delegate as BufferLogger).eventText,
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
    Logger: () => DelegateLogger(BufferLogger.test())
  }));

  test('Successfully turns WebSocketException into ToolExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(const WebSocketException());

    await expectLater(() => residentWebRunner.run(), throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Successfully turns AppConnectionException into ToolExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(AppConnectionException(''));

    await expectLater(() => residentWebRunner.run(), throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Successfully turns ChromeDebugError into ToolExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();

    when(mockWebDevFS.connect(any))
      .thenThrow(ChromeDebugException(<String, dynamic>{}));

    await expectLater(() => residentWebRunner.run(), throwsToolExit());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Rethrows unknown Exception type from dwds', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    when(mockWebDevFS.connect(any)).thenThrow(Exception());

    await expectLater(() => residentWebRunner.run(), throwsException);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('Rethrows unknown Error type from dwds tooling', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    _setupMocks();
    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;

    when(mockWebDevFS.connect(any)).thenThrow(StateError(''));

    await expectLater(() => residentWebRunner.run(), throwsStateError);
    verify(mockStatus.stop()).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger(
      terminal: AnsiTerminal(
        stdio: null,
        platform: const LocalPlatform(),
      ),
      outputPreferences: OutputPreferences.test(),
    ))
  }));
}

class MockChromeLauncher extends Mock implements ChromiumLauncher {}
class MockFlutterUsage extends Mock implements Usage {}
class MockChromeDevice extends Mock implements ChromiumDevice {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockAppConnection extends Mock implements AppConnection {}
class MockVmService extends Mock implements VmService {}
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
class MockPub extends Mock implements Pub {}
