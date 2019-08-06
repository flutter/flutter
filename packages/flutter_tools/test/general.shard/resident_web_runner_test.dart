// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/resident_web_runner.dart';
import 'package:flutter_tools/src/web/web_fs.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;
  MockFlutterWebFs mockWebFs;
  ResidentWebRunner residentWebRunner;
  MockDebugConnection mockDebugConnection;
  MockVmService mockVmService;

  setUp(() {
    mockWebFs = MockFlutterWebFs();
    mockDebugConnection = MockDebugConnection();
    mockVmService = MockVmService();
    final MockWebDevice mockWebDevice = MockWebDevice();
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
      }) async {
        return mockWebFs;
      },
    });
  });

   void _setupMocks() {
    fs.file('pubspec.yaml').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
    when(mockWebFs.runAndDebug()).thenAnswer((Invocation _) async {
      return mockDebugConnection;
    });
    when(mockDebugConnection.vmService).thenReturn(mockVmService);
    when(mockVmService.onStdoutEvent).thenAnswer((Invocation _) {
      return const Stream<Event>.empty();
    });
    when(mockDebugConnection.wsUri).thenReturn('ws://127.0.0.1/abcd/');
  }

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
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
  }));

  test('Can not hot reload after attaching', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
     unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: false);

    expect(result.code, 1);
    expect(result.message, contains('hot reload not supported on the web.'));
  }));

  test('Can hot restart after attaching', () => testbed.run(() async {
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
      return Response.parse(<String, Object>{'type': 'Success'});
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
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
}


class MockWebDevice extends Mock implements Device {}
class MockBuildDaemonCreator extends Mock implements BuildDaemonCreator {}
class MockFlutterWebFs extends Mock implements WebFs {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockVmService extends Mock implements VmService {}
