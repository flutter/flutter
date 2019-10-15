// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;
  MockFlutterWebFs mockWebFs;
  ResidentWebRunner residentWebRunner;
  MockDebugConnection mockDebugConnection;
  MockVmService mockVmService;
  MockWebDevice mockWebDevice;
  MockAppConnection mockAppConnection;

  setUp(() {
    mockWebFs = MockFlutterWebFs();
    mockDebugConnection = MockDebugConnection();
    mockVmService = MockVmService();
    mockWebDevice = MockWebDevice();
    mockAppConnection = MockAppConnection();
    testbed = Testbed(
      setup: () {
        residentWebRunner = ResidentWebRunner(
          mockWebDevice,
          flutterProject: FlutterProject.current(),
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          ipv6: true,
        );
      },
      overrides: <Type, Generator>{
        WebFsFactory: () => ({
          @required String target,
          @required FlutterProject flutterProject,
          @required BuildInfo buildInfo,
          @required bool skipDwds,
          @required bool initializePlatform,
          @required String hostname,
          @required String port,
        }) async {
          return mockWebFs;
        },
      },
    );
  });

  void _setupMocks() {
    fs.file('pubspec.yaml').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
    when(mockWebFs.connect(any)).thenAnswer((Invocation _) async {
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });
    when(mockWebFs.recompile()).thenAnswer((Invocation _) {
      return Future<bool>.value(false);
    });
    when(mockDebugConnection.vmService).thenReturn(mockVmService);
    when(mockDebugConnection.onDone).thenAnswer((Invocation invocation) {
      return Completer<void>().future;
    });
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return const Stream<Event>.empty();
    });
    when(mockDebugConnection.uri).thenReturn('ws://127.0.0.1/abcd/');
  }

  test('runner with web server device does not support debugging', () => testbed.run(() {
    final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
      WebServerDevice(),
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ipv6: true,
    );

    expect(profileResidentWebRunner.debuggingEnabled, false);
    expect(residentWebRunner.debuggingEnabled, true);
  }));

  test('profile does not supportsServiceProtocol', () => testbed.run(() {
    final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
      MockWebDevice(),
      flutterProject: FlutterProject.current(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
      ipv6: true,
    );

    expect(profileResidentWebRunner.supportsServiceProtocol, false);
    expect(residentWebRunner.supportsServiceProtocol, true);
  }));

  test('Exits on run if application does not support the web', () => testbed.run(() async {
    fs.file('pubspec.yaml').createSync();
    final BufferLogger bufferLogger = logger;

    expect(await residentWebRunner.run(), 1);
    expect(bufferLogger.errorText, contains('No application found for TargetPlatform.web_javascript'));
  }));

  test('Exits on run if target file does not exist', () => testbed.run(() async {
    fs.file('pubspec.yaml').createSync();
    fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
    final BufferLogger bufferLogger = logger;

    expect(await residentWebRunner.run(), 1);
    final String absoluteMain = fs.path.absolute(fs.path.join('lib', 'main.dart'));
    expect(bufferLogger.errorText, contains('Tried to run $absoluteMain, but that file does not exist.'));
  }));

  test('Can successfully run and connect to vmservice', () => testbed.run(() async {
    _setupMocks();
    final DelegateLogger delegateLogger = logger;
    final BufferLogger bufferLogger = delegateLogger.delegate;
    final MockStatus status = MockStatus();
    delegateLogger.status = status;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    verify(mockAppConnection.runMain()).called(1);
    verify(mockVmService.registerService('reloadSources', 'FlutterTools')).called(1);
    verify(status.stop()).called(2);

    expect(bufferLogger.statusText, contains('Debug service listening on ws://127.0.0.1/abcd/'));
    expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger()),
  }));

  test('Listens to stdout streams before running main', () => testbed.run(() async {
    _setupMocks();
    final BufferLogger bufferLogger = logger;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final StreamController<Event> controller = StreamController<Event>.broadcast();
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return controller.stream;
    });
    when(mockAppConnection.runMain()).thenAnswer((Invocation invocation) {
      controller.add(Event.parse(<String, Object>{
        'type': 'Event',
        'kind': 'WriteEvent',
        'timestamp': 1569473488296,
        'bytes': base64.encode('THIS MESSAGE IS IMPORTANT'.codeUnits),
      }));
    });
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    expect(bufferLogger.statusText, contains('THIS MESSAGE IS IMPORTANT'));
  }));

  test('Can hot reload after attaching', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation invocation) async {
      return true;
    });
    when(mockVmService.callServiceExtension('hotRestart')).thenAnswer((Invocation _) async {
      return Response.parse(<String, Object>{'type': 'Success'});
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 0);
	  // ensure that analytics are sent.
    verify(Usage.instance.sendEvent('hot', 'restart', parameters: <String, String>{
      'cd27': 'web-javascript',
      'cd28': null,
      'cd29': 'false',
      'cd30': 'true',
    })).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-restart', any)).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-refresh', any)).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-recompile', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Can hot restart after attaching', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation invocation) async {
      return true;
    });
    when(mockVmService.callServiceExtension('hotRestart')).thenAnswer((Invocation _) async {
      return Response.parse(<String, Object>{'type': 'Success'});
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
	  // ensure that analytics are sent.
    verify(Usage.instance.sendEvent('hot', 'restart', parameters: <String, String>{
      'cd27': 'web-javascript',
      'cd28': null,
      'cd29': 'false',
      'cd30': 'true',
    })).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-restart', any)).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-refresh', any)).called(1);
    verify(Usage.instance.sendTiming('hot', 'web-recompile', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Fails on compilation errors in hot restart', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation _) async {
      return false;
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
    verifyNever(Usage.instance.sendTiming('hot', 'web-restart', any));
    verifyNever(Usage.instance.sendTiming('hot', 'web-refresh', any));
    verifyNever(Usage.instance.sendTiming('hot', 'web-recompile', any));
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Fails on vmservice response error', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation _) async {
      return true;
    });
    when(mockVmService.callServiceExtension('hotRestart')).thenAnswer((Invocation _) async {
      return Response.parse(<String, Object>{'type': 'Failed'});
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed'));
    verifyNever(Usage.instance.sendTiming('hot', 'web-restart', any));
    verifyNever(Usage.instance.sendTiming('hot', 'web-refresh', any));
    verify(Usage.instance.sendTiming('hot', 'web-recompile', any)).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockFlutterUsage(),
  }));

  test('Fails on vmservice RpcError', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation _) async {
      return true;
    });
    when(mockVmService.callServiceExtension('hotRestart')).thenThrow(RPCError('', 2, '123'));
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Page requires refresh'));
  }));

  test('printHelp without details is spoopy', () => testbed.run(() async {
    residentWebRunner.printHelp(details: false);
    final BufferLogger bufferLogger = logger;

    expect(bufferLogger.statusText, contains('👻'));
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

  test('cleanup of resources is safe to call multiple times', () => testbed.run(() async {
    _setupMocks();
    bool debugClosed = false;
    when(mockWebDevice.stopApp(any)).thenAnswer((Invocation invocation) async {
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

  test('Prints target and device name on run', () => testbed.run(() async {
    _setupMocks();
    when(mockWebDevice.name).thenReturn('Chromez');
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;

    final BufferLogger bufferLogger = logger;

    expect(bufferLogger.statusText, contains('Launching ${fs.path.join('lib', 'main.dart')} on Chromez in debug mode'));
  }));

  test('Successfully turns WebSocketException into ToolExit', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebFs.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw const WebSocketException();
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsA(isInstanceOf<ToolExit>()));

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Successfully turns AppInstanceId error into ToolExit', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebFs.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw StateError('Could not connect to application with appInstanceId: c0ae0750-ee91-11e9-cea6-35d95a968356');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsA(isInstanceOf<ToolExit>()));

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Rethrows Exception type', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebFs.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw Exception('Something went wrong');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsA(isInstanceOf<Exception>()));

    unhandledErrorCompleter.complete();
    await expectation;
  }));

  test('Rethrows unknown exception type from web tooling', () => testbed.run(() async {
    _setupMocks();
    final DelegateLogger delegateLogger = logger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    final Completer<void> unhandledErrorCompleter = Completer<void>();
    when(mockWebFs.connect(any)).thenAnswer((Invocation _) async {
      unawaited(unhandledErrorCompleter.future.then((void value) {
        throw StateError('Something went wrong');
      }));
      return ConnectionResult(mockAppConnection, mockDebugConnection);
    });

    final Future<void> expectation = expectLater(() => residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ), throwsA(isInstanceOf<StateError>()));

    unhandledErrorCompleter.complete();
    await expectation;
    verify(mockStatus.stop()).called(2);
  }, overrides: <Type, Generator>{
    Logger: () => DelegateLogger(BufferLogger())
  }));
}

class MockFlutterUsage extends Mock implements Usage {}
class MockWebDevice extends Mock implements ChromeDevice {}
class MockBuildDaemonCreator extends Mock implements BuildDaemonCreator {}
class MockFlutterWebFs extends Mock implements WebFs {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockAppConnection extends Mock implements AppConnection {}
class MockVmService extends Mock implements VmService {}
class MockStatus extends Mock implements Status {}
class DelegateLogger implements Logger {
  DelegateLogger(this.delegate);

  final Logger delegate;
  Status status;

  @override
  bool get quiet => delegate.quiet;

  @override
  set quiet(bool value) => delegate.quiet;

  @override
  bool get hasTerminal => delegate.hasTerminal;

  @override
  bool get isVerbose => delegate.isVerbose;

  @override
  void printError(String message, {StackTrace stackTrace, bool emphasis, TerminalColor color, int indent, int hangingIndent, bool wrap}) {
    delegate.printError(
      message,
      stackTrace: stackTrace,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printStatus(String message, {bool emphasis, TerminalColor color, bool newline, int indent, int hangingIndent, bool wrap}) {
    delegate.printStatus(message,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printTrace(String message) {
    delegate.printTrace(message);
  }

  @override
  void sendNotification(String message, {String progressId}) {
    delegate.sendNotification(message, progressId: progressId);
  }

  @override
  Status startProgress(String message, {Duration timeout, String progressId, bool multilineOutput = false, int progressIndicatorPadding = kDefaultStatusPadding}) {
    return status;
  }

  @override
  bool get supportsColor => delegate.supportsColor;
}
