// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/resident_web_runner.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  ResidentWebRunner residentWebRunner;
  MockFlutterDevice mockFlutterDevice;
  MockWebDevFS mockWebDevFS;

  setUp(() {
    mockWebDevFS = MockWebDevFS();
    final MockWebDevice mockWebDevice = MockWebDevice();
    mockFlutterDevice = MockFlutterDevice();
    when(mockFlutterDevice.device).thenReturn(mockWebDevice);
    when(mockFlutterDevice.devFS).thenReturn(mockWebDevFS);
    when(mockWebDevFS.sources).thenReturn(<Uri>[]);
  });

  void _setupMocks() {
    globals.fs.file('.packages').writeAsStringSync('\n');
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    globals.fs.file(globals.fs.path.join('web', 'index.html')).createSync(recursive: true);
    final FlutterProject project = FlutterProject.fromDirectoryTest(globals.fs.currentDirectory);
    residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      stayResident: true,
      urlTunneller: null,
      featureFlags: TestFeatureFlags(),
      fileSystem: globals.fs,
      logger: globals.logger,
      systemClock: globals.systemClock,
      usage: globals.flutterUsage,
    );
  }

  testUsingContext('Can successfully run and connect without vmservice', () async {
    _setupMocks();
    final FakeStatusLogger fakeStatusLogger = globals.logger as FakeStatusLogger;
    final MockStatus mockStatus = MockStatus();
    fakeStatusLogger.status = mockStatus;
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo.wsUri, null);
    verify(mockStatus.stop()).called(1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    Logger: () => FakeStatusLogger(BufferLogger.test()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentWebRunner calls appFailedToStart if initial compilation fails', () async {
    _setupMocks();

    expect(() async => residentWebRunner.run(), throwsToolExit());
    expect(await residentWebRunner.waitForAppToFinish(), 1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: false)),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentWebRunner calls appFailedToStart if error is thrown during startup', () async {
    _setupMocks();

    expect(() async => residentWebRunner.run(), throwsA(isA<Exception>()));
    expect(await residentWebRunner.waitForAppToFinish(), 1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.error(Exception('foo')),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can full restart after attaching', () async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Fails on compilation errors in hot restart', () async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.list(<BuildResult>[
      BuildResult(success: true),
      BuildResult(success: false),
    ]),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Correctly performs a full refresh on attached chrome device.', () async {
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
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockWebDevFS extends Mock implements WebDevFS {}
class MockWebDevice extends Mock implements Device {}
class MockStatus extends Mock implements Status {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockChromeDevice extends Mock implements ChromiumDevice {}
class MockChrome extends Mock implements Chromium {}
class MockChromeConnection extends Mock implements ChromeConnection {}
class MockChromeTab extends Mock implements ChromeTab {}
class MockWipConnection extends Mock implements WipConnection {}
class MockChromiumLauncher extends Mock implements ChromiumLauncher {}
