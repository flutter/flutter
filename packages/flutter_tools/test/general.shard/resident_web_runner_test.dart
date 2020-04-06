// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/build_runner/devfs_web.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;
  ResidentWebRunner residentWebRunner;
  MockDebugConnection mockDebugConnection;
  MockVmService mockVmService;
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

  setUp(() {
    resetChromeForTesting();
    mockDebugConnection = MockDebugConnection();
    mockVmService = MockVmService();
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
      mainPath: anyNamed('mainPath'),
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
      trackWidgetCreation: true,
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: true,  syncedBytes: 0)..invalidatedModules = <String>[];
    });
    when(mockDebugConnection.vmService).thenReturn(mockVmService);
    when(mockDebugConnection.onDone).thenAnswer((Invocation invocation) {
      return Completer<void>().future;
    });
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return const Stream<Event>.empty();
    });
    when(mockVmService.onStderrEvent).thenAnswer((Invocation _) {
      return const Stream<Event>.empty();
    });
    when(mockVmService.onDebugEvent).thenAnswer((Invocation _) {
      return const Stream<Event>.empty();
    });
    when(mockVmService.onIsolateEvent).thenAnswer((Invocation _) {
      return Stream<Event>.fromIterable(<Event>[
        Event(kind: EventKind.kIsolateStart, timestamp: 1),
      ]);
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
    when(mockFlutterDevice.device).thenReturn(WebServerDevice());
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
  }));

  test('runner with web server device supports debugging with --start-paused', () => testbed.run(() {
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice());
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

  test('Exits on run if application does not support the web', () => testbed.run(() async {
    globals.fs.file('pubspec.yaml').createSync();

    expect(await residentWebRunner.run(), 1);
    expect(testLogger.errorText, contains('This application is not configured to build on the web'));
  }));

  test('Exits on run if target file does not exist', () => testbed.run(() async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file(globals.fs.path.join('web', 'index.html')).createSync(recursive: true);

    expect(await residentWebRunner.run(), 1);
    final String absoluteMain = globals.fs.path.absolute(globals.fs.path.join('lib', 'main.dart'));
    expect(testLogger.errorText, contains('Tried to run $absoluteMain, but that file does not exist.'));
  }));

  test('Can successfully run and connect to vmservice', () => testbed.run(() async {
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
    verify(mockVmService.registerService('reloadSources', 'FlutterTools')).called(1);
    verify(status.stop()).called(1);
    verify(pub.get(
      context: PubContext.pubGet,
      directory: globals.fs.path.join('packages', 'flutter_tools')
    )).called(1);

    expect(bufferLogger.statusText, contains('Debug service listening on ws://127.0.0.1/abcd/'));
    expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger(
      terminal: AnsiTerminal(
        stdio: null,
        platform: const LocalPlatform(),
      ),
      outputPreferences: OutputPreferences.test(),
    )),
  }));

  test('Can successfully run and disconnect with --no-resident', () => testbed.run(() async {
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
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final StreamController<Event> stdoutController = StreamController<Event>.broadcast();
    final StreamController<Event> stderrController = StreamController<Event>.broadcast();
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return stdoutController.stream;
    });
    when(mockVmService.onStderrEvent).thenAnswer((Invocation _) {
      return stderrController.stream;
    });
    when(mockAppConnection.runMain()).thenAnswer((Invocation invocation) {
      stdoutController.add(Event.parse(<String, Object>{
        'type': 'Event',
        'kind': 'WriteEvent',
        'timestamp': 1569473488296,
        'bytes': base64.encode('THIS MESSAGE IS IMPORTANT'.codeUnits),
      }));
       stderrController.add(Event.parse(<String, Object>{
        'type': 'Event',
        'kind': 'WriteEvent',
        'timestamp': 1569473488296,
        'bytes': base64.encode('SO IS THIS'.codeUnits),
      }));
    });
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(testLogger.statusText, contains('THIS MESSAGE IS IMPORTANT'));
    expect(testLogger.statusText, contains('SO IS THIS'));
  }));

  test('Does not run main with --start-paused', () => testbed.run(() async {
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
    final StreamController<Event> controller = StreamController<Event>.broadcast();
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return controller.stream;
    });
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    verifyNever(mockAppConnection.runMain());
  }));

  test('Can hot reload after attaching', () => testbed.run(() async {
    _setupMocks();
    launchChromeInstance(mockChrome);
    when(mockWebDevFS.update(
      mainPath: anyNamed('mainPath'),
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
    )).thenAnswer((Invocation invocation) async {
      // Generated entrypoint file in temp dir.
      expect(invocation.namedArguments[#mainPath], contains('entrypoint.dart'));
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
      containsPair('cd28', null),
      containsPair('cd29', 'false'),
      containsPair('cd30', 'true'),
    ]));
    verify(globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Can hot restart after attaching', () => testbed.run(() async {
    _setupMocks();
    launchChromeInstance(mockChrome);
    String entrypointFileName;
    when(mockWebDevFS.update(
      mainPath: anyNamed('mainPath'),
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
    )).thenAnswer((Invocation invocation) async {
      entrypointFileName = invocation.namedArguments[#mainPath] as String;
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
    expect(entrypointFileName, isNotNull);
    expect(globals.fs.file(entrypointFileName).readAsStringSync(), contains(
      'await ui.webOnlyInitializePlatform();'
    ));

    expect(testLogger.statusText, contains('Restarted application in'));
    expect(result.code, 0);
    verify(mockResidentCompiler.accept()).called(2);
	  // ensure that analytics are sent.
    final Map<String, String> config = verify(globals.flutterUsage.sendEvent('hot', 'restart',
      parameters: captureAnyNamed('parameters'))).captured.first as Map<String, String>;

    expect(config, allOf(<Matcher>[
      containsPair('cd27', 'web-javascript'),
      containsPair('cd28', null),
      containsPair('cd29', 'false'),
      containsPair('cd30', 'true'),
    ]));
    verify(globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Can hot restart after attaching with web-server device', () => testbed.run(() async {
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(mockWebServerDevice);
    when(mockWebDevFS.update(
      mainPath: anyNamed('mainPath'),
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
    expect(residentWebRunner.debuggingEnabled, true);
  }));

  test('web resident runner can toggle CanvasKit', () => testbed.run(() async {
    final WebAssetServer webAssetServer = WebAssetServer(null, null, null, null, null);
    when(mockWebDevFS.webAssetServer).thenReturn(webAssetServer);

    expect(residentWebRunner.supportsCanvasKit, true);
    expect(webAssetServer.canvasKitRendering, false);

    final bool toggleResult = await residentWebRunner.toggleCanvaskit();

    expect(webAssetServer.canvasKitRendering, true);
    expect(toggleResult, true);
  }));

  test('Exits when initial compile fails', () => testbed.run(() async {
    _setupMocks();
    when(mockWebDevFS.update(
      mainPath: anyNamed('mainPath'),
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
      trackWidgetCreation: true,
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
    _setupMocks();
    final StreamController<Event> stdoutController = StreamController<Event>();
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation invocation) {
      return stdoutController.stream;
    });
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    stdoutController.add(Event(
      timestamp: 0,
      kind: 'Stdout',
      bytes: base64.encode(utf8.encode('    This is a message with 4 leading and trailing spaces    '))),
    );
    // Wait one event loop for the stream listener to fire.
    await null;

    expect(testLogger.statusText,
      contains('    This is a message with 4 leading and trailing spaces    '));
  }));

  test('Fails on compilation errors in hot restart', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebDevFS.update(
      mainPath: anyNamed('mainPath'),
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
      trackWidgetCreation: true,
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
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callMethod('hotRestart')).thenAnswer((Invocation _) async {
      return Response.parse(<String, Object>{'type': 'Failed'});
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 0);
  }));

  test('Fails fatally on vmservice RpcError', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callMethod('hotRestart')).thenThrow(RPCError('Something went wrong', 2, '123'));
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 1);
    expect(result.message, contains('Something went wrong'));
  }));

  test('Fails fatally on vmservice WipError', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callMethod('hotRestart')).thenThrow(WipError(<String, String>{}));
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 1);
  }));

  test('Fails fatally on vmservice Exception', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callMethod('hotRestart')).thenThrow(Exception('Something went wrong'));
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 1);
    expect(result.message, contains('Something went wrong'));
  }));

  test('printHelp without details has web warning', () => testbed.run(() async {
    residentWebRunner.printHelp(details: false);

    expect(testLogger.statusText, contains('Warning'));
    expect(testLogger.statusText, contains('https://flutter.dev/web'));
    expect(testLogger.statusText, isNot(contains('https://flutter.dev/web.')));
  }));

  test('debugDumpApp', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpApp();

    verify(mockVmService.callServiceExtension('ext.flutter.debugDumpApp')).called(1);
  }));

  test('debugDumpLayerTree', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpLayerTree();

    verify(mockVmService.callServiceExtension('ext.flutter.debugDumpLayerTree')).called(1);
  }));

  test('debugDumpRenderTree', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpRenderTree();

    verify(mockVmService.callServiceExtension('ext.flutter.debugDumpRenderTree')).called(1);
  }));

  test('debugDumpSemanticsTreeInTraversalOrder', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpSemanticsTreeInTraversalOrder();

    verify(mockVmService.callServiceExtension('ext.flutter.debugDumpSemanticsTreeInTraversalOrder')).called(1);
  }));

  test('debugDumpSemanticsTreeInInverseHitTestOrder', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    await residentWebRunner.debugDumpSemanticsTreeInInverseHitTestOrder();

    verify(mockVmService.callServiceExtension('ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder')).called(1);
  }));

  test('debugToggleDebugPaintSizeEnabled', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callServiceExtension('ext.flutter.debugPaint'))
      .thenAnswer((Invocation _) async {
        return Response.parse(<String, Object>{'enabled': false});
    });
    await residentWebRunner.debugToggleDebugPaintSizeEnabled();

    verify(mockVmService.callServiceExtension('ext.flutter.debugPaint',
        args: <String, Object>{'enabled': true})).called(1);
  }));


  test('debugTogglePerformanceOverlayOverride', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callServiceExtension('ext.flutter.showPerformanceOverlay'))
      .thenAnswer((Invocation _) async {
        return Response.parse(<String, Object>{'enabled': false});
    });

    await residentWebRunner.debugTogglePerformanceOverlayOverride();

    verify(mockVmService.callServiceExtension('ext.flutter.showPerformanceOverlay',
        args: <String, Object>{'enabled': true})).called(1);
  }));

  test('debugToggleWidgetInspector', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callServiceExtension('ext.flutter.debugToggleWidgetInspector'))
      .thenAnswer((Invocation _) async {
        return Response.parse(<String, Object>{'enabled': false});
    });

    await residentWebRunner.debugToggleWidgetInspector();

    verify(mockVmService.callServiceExtension('ext.flutter.debugToggleWidgetInspector',
        args: <String, Object>{'enabled': true})).called(1);
  }));

  test('debugToggleProfileWidgetBuilds', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callServiceExtension('ext.flutter.profileWidgetBuilds'))
      .thenAnswer((Invocation _) async {
        return Response.parse(<String, Object>{'enabled': false});
    });

    await residentWebRunner.debugToggleProfileWidgetBuilds();

    verify(mockVmService.callServiceExtension('ext.flutter.profileWidgetBuilds',
        args: <String, Object>{'enabled': true})).called(1);
  }));

  test('debugTogglePlatform', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockVmService.callServiceExtension('ext.flutter.platformOverride'))
      .thenAnswer((Invocation _) async {
        return Response.parse(<String, Object>{'value': 'iOS'});
    });

    await residentWebRunner.debugTogglePlatform();

    expect(testLogger.statusText, contains('Switched operating system to fuchsia'));
    verify(mockVmService.callServiceExtension('ext.flutter.platformOverride',
        args: <String, Object>{'value': 'fuchsia'})).called(1);
  }));

  test('cleanup of resources is safe to call multiple times', () => testbed.run(() async {
    _setupMocks();
    bool debugClosed = false;
    when(mockDevice.stopApp(any)).thenAnswer((Invocation invocation) async {
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
  }));

  test('cleans up Chrome if tab is closed', () => testbed.run(() async {
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
  }));

  test('Prints target and device name on run', () => testbed.run(() async {
    _setupMocks();
    when(mockDevice.name).thenReturn('Chromez');
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(testLogger.statusText, contains('Launching ${globals.fs.path.join('lib', 'main.dart')} on Chromez in debug mode'));
  }));

  test('Sends launched app.webLaunchUrl event for Chrome device', () => testbed.run(() async {
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(ChromeDevice());
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
    launchChromeInstance(chrome);

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
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger.test()),
    ChromeLauncher: () => MockChromeLauncher(),
  }));

  test('Sends unlaunched app.webLaunchUrl event for Web Server device', () => testbed.run(() async {
    _setupMocks();
    when(mockFlutterDevice.device).thenReturn(WebServerDevice());
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
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger.test())
  }));

  test('Successfully turns WebSocketException into ToolExit', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
     when(mockWebDevFS.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw const WebSocketException();
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsToolExit());

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Successfully turns AppConnectionException into ToolExit', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebDevFS.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw AppConnectionException('Could not connect to application with appInstanceId: c0ae0750-ee91-11e9-cea6-35d95a968356');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsToolExit());

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Successfully turns ChromeDebugError into ToolExit', () => testbed.run(() async {
     _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
     when(mockWebDevFS.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw ChromeDebugException(<String, dynamic>{});
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsToolExit());

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Rethrows Exception type', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
     when(mockWebDevFS.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw Exception('Something went wrong');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsException);

    unhandledErrorCompleter.complete();
    await expectation;
  }));
  test('Rethrows unknown exception type from web tooling', () => testbed.run(() async {
    _setupMocks();
    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebDevFS.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw StateError('Something went wrong');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsStateError);

    unhandledErrorCompleter.complete();
    await expectation;
    verify(mockStatus.stop()).called(1);
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

class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockFlutterUsage extends Mock implements Usage {}
class MockChromeDevice extends Mock implements ChromeDevice {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockAppConnection extends Mock implements AppConnection {}
class MockVmService extends Mock implements VmService {}
class MockStatus extends Mock implements Status {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockWebDevFS extends Mock implements WebDevFS {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
class MockChrome extends Mock implements Chrome {}
class MockChromeConnection extends Mock implements ChromeConnection {}
class MockChromeTab extends Mock implements ChromeTab {}
class MockWipConnection extends Mock implements WipConnection {}
class MockWipDebugger extends Mock implements WipDebugger {}
class MockWebServerDevice extends Mock implements WebServerDevice {}
class MockDevice extends Mock implements Device {}
class MockPub extends Mock implements Pub {}
