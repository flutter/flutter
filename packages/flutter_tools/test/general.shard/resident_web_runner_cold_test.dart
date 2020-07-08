// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_runner/devfs_web.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;
  ResidentWebRunner residentWebRunner;
  MockFlutterDevice mockFlutterDevice;
  MockWebDevFS mockWebDevFS;
  MockBuildSystem mockBuildSystem;

  setUp(() {
    mockWebDevFS = MockWebDevFS();
    mockBuildSystem = MockBuildSystem();
    final MockWebDevice mockWebDevice = MockWebDevice();
    mockFlutterDevice = MockFlutterDevice();
    when(mockFlutterDevice.device).thenReturn(mockWebDevice);
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockWebDevFS.sources).thenReturn(<Uri>[]);
    when(mockBuildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: true);
    });
    testbed = Testbed(
      setup: () {
        residentWebRunner = residentWebRunner = DwdsWebRunnerFactory().createWebRunner(
          mockFlutterDevice,
          flutterProject: FlutterProject.current(),
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          ipv6: true,
          stayResident: true,
          urlTunneller: null,
        ) as ResidentWebRunner;
      }, overrides: <Type, Generator>{
        Pub: () => MockPub(),
      }
    );
  });

  void _setupMocks() {
    globals.fs.file('.packages').writeAsStringSync('\n');
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file(globals.fs.path.join('web', 'index.html')).createSync(recursive: true);
  }

  test('Can successfully run and connect without vmservice', () => testbed.run(() async {
    _setupMocks();
    final DelegateLogger delegateLogger = globals.logger as DelegateLogger;
    final MockStatus mockStatus = MockStatus();
    delegateLogger.status = mockStatus;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo.wsUri, null);
    verify(mockStatus.stop()).called(1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
    Logger: () => DelegateLogger(BufferLogger(
      terminal: AnsiTerminal(
        stdio: null,
        platform: const LocalPlatform(),
      ),
      outputPreferences: OutputPreferences.test(),
    )),
  }));

  // Regression test for https://github.com/flutter/flutter/issues/60613
  test('ResidentWebRunner calls appFailedToStart if initial compilation fails', () => testbed.run(() async {
    _setupMocks();
    when(mockBuildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: false);
    });
    expect(() async => await residentWebRunner.run(), throwsToolExit());
    expect(await residentWebRunner.waitForAppToFinish(), 1);

  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
  }));

  // Regression test for https://github.com/flutter/flutter/issues/60613
  test('ResidentWebRunner calls appFailedToStart if error is thrown during startup', () => testbed.run(() async {
    _setupMocks();
    when(mockBuildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      throw Exception('foo');
    });
    expect(() async => await residentWebRunner.run(), throwsA(isA<Exception>()));
    expect(await residentWebRunner.waitForAppToFinish(), 1);

  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
  }));

  test('Can full restart after attaching', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
  }));

  test('Fails on compilation errors in hot restart', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockBuildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: false);
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
  }));

  test('Correctly performs a full refresh on attached chrome device.', () => testbed.run(() async {
    _setupMocks();
    final MockChromeDevice chromeDevice = MockChromeDevice();
    final MockChrome chrome = MockChrome();
    final MockChromeConnection mockChromeConnection = MockChromeConnection();
    final MockChromeTab mockChromeTab = MockChromeTab();
    final MockWipConnection mockWipConnection = MockWipConnection();
    final MockChromiumLauncher chromiumLauncher = MockChromiumLauncher();
    when(mockChromeConnection.getTab(any)).thenAnswer((Invocation invocation) async {
      return mockChromeTab;
    });
    when(mockChromeTab.connect()).thenAnswer((Invocation invocation) async {
      return mockWipConnection;
    });
    when(chromiumLauncher.connectedInstance).thenAnswer((Invocation invocation) async {
      return chrome;
    });
    when(chrome.chromeConnection).thenReturn(mockChromeConnection);
    when(chromeDevice.chromeLauncher).thenReturn(chromiumLauncher);
    when(mockFlutterDevice.device).thenReturn(chromeDevice);
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
    verify(mockWipConnection.sendCommand('Page.reload', <String, Object>{
      'ignoreCache': true,
    })).called(1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => mockBuildSystem,
  }));

}

class MockWebDevFS extends Mock implements WebDevFS {}
class MockWebDevice extends Mock implements Device {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockVmService extends Mock implements VmService {}
class MockStatus extends Mock implements Status {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockChromeDevice extends Mock implements ChromiumDevice {}
class MockChrome extends Mock implements Chromium {}
class MockChromeConnection extends Mock implements ChromeConnection {}
class MockChromeTab extends Mock implements ChromeTab {}
class MockWipConnection extends Mock implements WipConnection {}
class MockBuildSystem extends Mock implements BuildSystem {}
class MockPub extends Mock implements Pub {}
class MockChromiumLauncher extends Mock implements ChromiumLauncher {}
