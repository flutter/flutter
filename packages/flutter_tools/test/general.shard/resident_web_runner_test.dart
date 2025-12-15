// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/resident_web_runner.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:package_config/package_config.dart';
import 'package:package_config/package_config_types.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_process_manager.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart' as test_fakes;
import '../src/package_config.dart';
import '../src/test_build_system.dart';
import '../src/throwing_pub.dart';
import 'resident_runner_helpers.dart';

const kSetPauseIsolatesOnStartExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(
    method: 'setFlag',
    args: <String, Object>{'name': 'pause_isolates_on_start', 'value': 'true'},
  ),
];

const kAttachLogExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Stdout'}),
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Stderr'}),
];

const kAttachIsolateExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Service'}),
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Isolate'}),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{'service': kReloadSourcesServiceName, 'alias': kFlutterToolAlias},
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{'service': kFlutterVersionServiceName, 'alias': kFlutterToolAlias},
  ),
  FakeVmServiceRequest(
    method: 'registerService',
    args: <String, Object>{'service': kFlutterMemoryInfoServiceName, 'alias': kFlutterToolAlias},
  ),
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Extension'}),
];

const kAttachExpectations = <VmServiceExpectation>[
  ...kAttachLogExpectations,
  ...kAttachIsolateExpectations,
];

const kStartPausedAndAttachExpectations = <VmServiceExpectation>[
  ...kSetPauseIsolatesOnStartExpectations,
  ...kAttachLogExpectations,
  ...kAttachIsolateExpectations,
];

const kDdcLibraryBundleFlags = <String>['--dartdevc-module-format=ddc', '--dartdevc-canary'];

void main() {
  late FakeDebugConnection debugConnection;
  late FakeChromeDevice chromeDevice;
  late FakeAppConnection appConnection;
  late FakeFlutterDevice flutterDevice;
  late FakeWebDevFS webDevFS;
  late FakeResidentCompiler residentCompiler;
  late FakeChromeConnection chromeConnection;
  late FakeChromeTab chromeTab;
  late FakeWebServerDevice webServerDevice;
  late FakeDevice mockDevice;
  late FakeVmServiceHost fakeVmServiceHost;
  late MemoryFileSystem fileSystem;
  late ProcessManager processManager;
  late FakeAnalytics fakeAnalytics;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.any();
    debugConnection = FakeDebugConnection();
    mockDevice = FakeDevice();
    appConnection = FakeAppConnection();
    webDevFS = FakeWebDevFS();
    residentCompiler = FakeResidentCompiler();
    chromeDevice = FakeChromeDevice();
    chromeConnection = FakeChromeConnection();
    chromeTab = FakeChromeTab('index.html');
    webServerDevice = FakeWebServerDevice();
    flutterDevice = FakeFlutterDevice()
      .._devFS = webDevFS
      ..device = mockDevice
      ..generator = residentCompiler;
    fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
''');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: test_fakes.FakeFlutterVersion(),
    );
  });

  void setupMocks() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('web/index.html').createSync(recursive: true);
    webDevFS.report = UpdateFSReport(success: true);
    debugConnection.fakeVmServiceHost = () => fakeVmServiceHost;
    webDevFS.result = ConnectionResult(appConnection, debugConnection, debugConnection.vmService);
    debugConnection.uri = 'ws://127.0.0.1/abcd/';
    debugConnection.devToolsUri = 'http://127.0.0.1/abcd/';
    debugConnection.dtdUri = 'ws://127.0.0.1/efgh/';
    chromeConnection.tabs.add(chromeTab);
  }

  testUsingContext(
    'runner with web server device supports debugging without --start-paused',
    () {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      flutterDevice.device = WebServerDevice(logger: BufferLogger.test());
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(profileResidentWebRunner.debuggingEnabled, true);

      flutterDevice.device = chromeDevice;

      expect(residentWebRunner.debuggingEnabled, true);
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'runner with web server device supports debugging with --start-paused',
    () {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      flutterDevice.device = WebServerDevice(logger: BufferLogger.test());
      final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(profileResidentWebRunner.uri, webDevFS.baseUri);
      expect(profileResidentWebRunner.debuggingEnabled, true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );
  testUsingContext(
    'profile does not supportsServiceProtocol',
    () {
      final ResidentRunner residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      flutterDevice.device = chromeDevice;
      final ResidentRunner profileResidentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(profileResidentWebRunner.supportsServiceProtocol, false);
      expect(residentWebRunner.supportsServiceProtocol, true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'Can successfully run and connect to vmservice',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

      expect(appConnection.ranMain, true);
      expect(logger.statusText, contains('Debug service listening on ws://127.0.0.1/abcd/'));
      expect(debugConnectionInfo.wsUri.toString(), 'ws://127.0.0.1/abcd/');
      expect(debugConnectionInfo.dtdUri.toString(), 'ws://127.0.0.1/efgh/');
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'WebRunner copies compiled app.dill to cache during startup',
    () async {
      final debuggingOptions = DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      );
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        debuggingOptions: debuggingOptions,
      );
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();

      residentWebRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(
        await fileSystem.file(fileSystem.path.join('build', 'cache.dill')).readAsString(),
        'ABC',
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'WebRunner copies compiled app.dill to cache during startup with track-widget-creation',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();

      residentWebRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(
        await fileSystem
            .file(fileSystem.path.join('build', 'cache.dill.track.dill'))
            .readAsString(),
        'ABC',
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext(
    'ResidentWebRunner calls appFailedToStart if initial compilation fails',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fileSystem.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      webDevFS.report = UpdateFSReport();

      expect(await residentWebRunner.run(), 1);
      // Completing this future ensures that the daemon can exit correctly.
      expect(await residentWebRunner.waitForAppToFinish(), 1);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Can successfully run without an index.html including status warning',
    () async {
      final logger = BufferLogger.test();
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      fileSystem.directory('web').deleteSync(recursive: true);
      final residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        stayResident: false,
        fileSystem: fileSystem,
        logger: logger,
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(await residentWebRunner.run(), 0);
      expect(logger.statusText, contains('This application is not configured to build on the web'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Can successfully run and disconnect with --no-resident',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      final ResidentRunner residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        stayResident: false,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(await residentWebRunner.run(), 0);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Detach keeps device running',
    () async {
      final logger = BufferLogger.test();
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      fileSystem.directory('web').deleteSync(recursive: true);
      final residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: logger,
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(mockDevice.isRunning, false);
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      expect(mockDevice.isRunning, true);
      await residentWebRunner.detach();
      expect(residentWebRunner.stopAppDuringCleanup, false);
      await residentWebRunner.exit();
      await residentWebRunner.cleanupAtFinish();
      expect(mockDevice.isRunning, true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Quit stops device',
    () async {
      final logger = BufferLogger.test();
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      fileSystem.directory('web').deleteSync(recursive: true);
      final residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: logger,
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      expect(mockDevice.isRunning, false);
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      expect(mockDevice.isRunning, true);
      expect(residentWebRunner.stopAppDuringCleanup, true);
      await residentWebRunner.cleanupAtFinish();
      expect(mockDevice.isRunning, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Listens to stdout and stderr streams before running main',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachLogExpectations,
          FakeVmServiceStreamResponse(
            streamId: 'Stdout',
            event: vm_service.Event(
              timestamp: 0,
              kind: vm_service.EventStreams.kStdout,
              bytes: base64.encode(utf8.encode('THIS MESSAGE IS IMPORTANT')),
            ),
          ),
          FakeVmServiceStreamResponse(
            streamId: 'Stderr',
            event: vm_service.Event(
              timestamp: 0,
              kind: vm_service.EventStreams.kStderr,
              bytes: base64.encode(utf8.encode('SO IS THIS')),
            ),
          ),
          ...kAttachIsolateExpectations,
        ],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(logger.statusText, contains('THIS MESSAGE IS IMPORTANT'));
      expect(logger.statusText, contains('SO IS THIS'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Listens to extension events with structured errors',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: testLogger,
      );
      final requests = <VmServiceExpectation>[
        ...kAttachExpectations,
        // This is the first error message of a session.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'errorsSinceReload': 0,
              'renderedErrorText': 'first',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // This is the second error message of a session.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'errorsSinceReload': 1,
              'renderedErrorText': 'second',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // This is not Flutter.Error kind data, so it should not be logged, even though it has a renderedErrorText field.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Other',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'errorsSinceReload': 2,
              'renderedErrorText': 'not an error',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // This is the third error message of a session.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'errorsSinceReload': 2,
              'renderedErrorText': 'third',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // This is bogus error data.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{'other': 'bad stuff'}),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // Empty error text should not break anything.
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'test': 'data',
              'renderedErrorText': '',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // Messages without errorsSinceReload should act as if errorsSinceReload: 0
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{
              'test': 'data',
              'renderedErrorText': 'error text',
            }),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
        // When adding things here, make sure the last one is supposed to output something
        // to the statusLog, otherwise you won't be able to distinguish the absence of output
        // due to it passing the test from absence due to it not running the test.
      ];
      // We use requests below, so make a copy of it here (FakeVmServiceHost will
      // clear its copy internally, which would affect our pumping below).
      fakeVmServiceHost = FakeVmServiceHost(requests: requests.toList());

      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      assert(requests.length > 5, 'requests was modified');
      for (final Object _ in requests) {
        // pump the task queue once for each message
        await null;
      }

      expect(
        testLogger.statusText,
        'Launching lib/main.dart on FakeDevice in debug mode...\n'
        'Waiting for connection from debug service on FakeDevice...\n'
        'Debug service listening on ws://127.0.0.1/abcd/\n'
        'A Dart VM Service on FakeDevice is available at: http://127.0.0.1/abcd/\n'
        'The Flutter DevTools debugger and profiler on FakeDevice is available at: http://127.0.0.1/abcd/\n'
        '\n'
        'first\n'
        '\n'
        'second\n'
        'third\n'
        '\n'
        '\n' // the empty message
        '\n'
        '\n'
        'error text\n'
        '\n',
      );

      expect(
        testLogger.errorText,
        'Received an invalid Flutter.Error message from app: {other: bad stuff}\n',
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Does not run main with --start-paused',
    () async {
      final ResidentRunner residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );
      fakeVmServiceHost = FakeVmServiceHost(requests: kStartPausedAndAttachExpectations.toList());
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();

      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(appConnection.ranMain, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Can hot reload after attaching',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        systemClock: SystemClock.fixed(DateTime(2001)),
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            null,
            trackWidgetCreation: true,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
            // TODO(nshahan): Remove when hot reload can no longer be disabled.
            webEnableHotReload: true,
            extraFrontEndOptions: kDdcLibraryBundleFlags,
          ),
        ),
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
          const FakeVmServiceRequest(
            method: kReloadSourcesServiceName,
            args: <String, Object>{'isolateId': '1'},
            jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
          ),
          const FakeVmServiceRequest(
            method: 'ext.flutter.reassemble',
            jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
          ),
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
          ),
        ],
      );
      setupMocks();
      final chromiumLauncher = TestChromiumLauncher();
      final process = FakeProcess();
      final chrome = Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: process,
        logger: logger,
      );
      chromiumLauncher.setInstance(chrome);

      flutterDevice.device = GoogleChromeDevice(
        fileSystem: fileSystem,
        chromiumLauncher: chromiumLauncher,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
      );
      webDevFS.report = UpdateFSReport(success: true);

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

      expect(debugConnectionInfo, isNotNull);

      final OperationResult result = await residentWebRunner.restart();

      expect(logger.statusText, contains('Reloaded application in'));
      expect(result.code, 0);
      expect(webDevFS.mainUri.toString(), contains('entrypoint.dart'));

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.hotRunnerInfo(
            label: 'reload',
            targetPlatform: 'web-javascript',
            sdkName: '',
            emulator: false,
            fullRestart: false,
            overallTimeInMs: 0,
            syncedBytes: 0,
            invalidatedSourcesCount: 0,
            transferTimeInMs: 0,
            compileTimeInMs: 0,
            findInvalidatedTimeInMs: 0,
            scannedSourcesCount: 0,
            reassembleTimeInMs: 0,
            reloadVMTimeInMs: 0,
          ),
        ),
      );
      expect(
        fakeAnalytics.sentEvents,
        contains(Event.timing(workflow: 'hot', variableName: 'reload', elapsedMilliseconds: 0)),
      );
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Hot reload reject reports correct analytics',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        systemClock: SystemClock.fixed(DateTime(2001)),
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            null,
            trackWidgetCreation: true,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
            // TODO(nshahan): Remove when hot reload can no longer be disabled.
            webEnableHotReload: true,
            extraFrontEndOptions: kDdcLibraryBundleFlags,
          ),
        ),
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
          ),
        ],
      );
      setupMocks();
      final chromiumLauncher = TestChromiumLauncher();
      final process = FakeProcess();
      final chrome = Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: process,
        logger: logger,
      );
      chromiumLauncher.setInstance(chrome);

      flutterDevice.device = GoogleChromeDevice(
        fileSystem: fileSystem,
        chromiumLauncher: chromiumLauncher,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
      );
      webDevFS.report = UpdateFSReport(success: true);

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

      expect(debugConnectionInfo, isNotNull);

      webDevFS.report = UpdateFSReport(hotReloadRejected: true);
      final OperationResult result = await residentWebRunner.restart();

      expect(result.code, 1);
      expect(webDevFS.mainUri.toString(), contains('entrypoint.dart'));

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.hotRunnerInfo(
            label: 'reload-reject',
            targetPlatform: 'web-javascript',
            sdkName: '',
            emulator: false,
            fullRestart: false,
          ),
        ),
      );
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/167887.
  testUsingContext(
    'WASM builds report analysis without crashing',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        systemClock: SystemClock.fixed(DateTime(2001)),
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            null,
            trackWidgetCreation: true,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
            // TODO(nshahan): Remove when hot reload can no longer be disabled.
            webEnableHotReload: true,
            extraFrontEndOptions: kDdcLibraryBundleFlags,
          ),
          webUseWasm: true,
        ),
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          const FakeVmServiceRequest(
            method: kReloadSourcesServiceName,
            args: <String, Object>{'isolateId': ''},
            jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
          ),
          const FakeVmServiceRequest(
            method: 'ext.flutter.reassemble',
            jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
          ),
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
          ),
        ],
      );
      setupMocks();
      final chromiumLauncher = TestChromiumLauncher();
      final process = FakeProcess();
      final chrome = Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: process,
        logger: logger,
      );
      chromiumLauncher.setInstance(chrome);

      flutterDevice.device = GoogleChromeDevice(
        fileSystem: fileSystem,
        chromiumLauncher: chromiumLauncher,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
      );
      webDevFS.report = UpdateFSReport(success: true);

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

      expect(debugConnectionInfo, isNotNull);

      final OperationResult result = await residentWebRunner.restart();
      expect(logger.statusText, contains(kNoClientConnectedMessage));
      expect(result.code, 0);
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // Hot restart is available with and without the DDC library bundle format.
  // Test one extra config where `fullRestart` is false without the DDC library
  // bundle format - we should do a hot restart in this case because hot reload
  // is not available.
  for (final (bool webEnableHotReload, bool fullRestart) in <(bool, bool)>[
    (true, true),
    (false, true),
    (false, false),
  ]) {
    testUsingContext(
      'Can hot restart after attaching with '
      'webEnableHotReload: $webEnableHotReload fullRestart: $fullRestart',
      () async {
        final logger = BufferLogger.test();
        final ResidentRunner residentWebRunner = setUpResidentRunner(
          flutterDevice,
          logger: logger,
          systemClock: SystemClock.fixed(DateTime(2001)),
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo(
              BuildMode.debug,
              null,
              trackWidgetCreation: true,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
              extraFrontEndOptions: webEnableHotReload ? kDdcLibraryBundleFlags : const <String>[],
              webEnableHotReload: webEnableHotReload,
            ),
          ),
        );
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ...kAttachExpectations,
            const FakeVmServiceRequest(
              method: kHotRestartServiceName,
              jsonResponse: <String, Object>{'type': 'Success'},
            ),
          ],
        );
        setupMocks();
        final chromiumLauncher = TestChromiumLauncher();
        final process = FakeProcess();
        final chrome = Chromium(
          1,
          chromeConnection,
          chromiumLauncher: chromiumLauncher,
          process: process,
          logger: logger,
        );
        chromiumLauncher.setInstance(chrome);

        flutterDevice.device = GoogleChromeDevice(
          fileSystem: fileSystem,
          chromiumLauncher: chromiumLauncher,
          logger: BufferLogger.test(),
          platform: FakePlatform(),
          processManager: FakeProcessManager.any(),
        );
        webDevFS.report = UpdateFSReport(success: true);

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
        await connectionInfoCompleter.future;
        final OperationResult result = await residentWebRunner.restart(fullRestart: fullRestart);

        // Ensure that generated entrypoint is generated correctly.
        expect(webDevFS.mainUri, isNotNull);
        final String entrypointContents = fileSystem.file(webDevFS.mainUri).readAsStringSync();
        expect(entrypointContents, contains('// Flutter web bootstrap script'));
        expect(entrypointContents, contains("import 'dart:ui_web' as ui_web;"));
        expect(entrypointContents, contains('await ui_web.bootstrapEngine('));

        expect(logger.statusText, contains('Restarted application in'));
        expect(result.code, 0);

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.hotRunnerInfo(
              label: 'restart',
              targetPlatform: 'web-javascript',
              sdkName: '',
              emulator: false,
              fullRestart: true,
              overallTimeInMs: 0,
              syncedBytes: 0,
              invalidatedSourcesCount: 0,
              transferTimeInMs: 0,
              compileTimeInMs: 0,
              findInvalidatedTimeInMs: 0,
              scannedSourcesCount: 0,
            ),
          ),
        );
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.timing(
              workflow: 'hot',
              variableName: 'web-incremental-restart',
              elapsedMilliseconds: 0,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Pub: ThrowingPub.new,
      },
    );
  }

  testUsingContext(
    'Can hot restart after attaching with web-server device',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        systemClock: SystemClock.fixed(DateTime(2001)),
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: [
          ...kAttachExpectations,
          const FakeVmServiceRequest(method: 'hotRestart'),
        ],
      );
      setupMocks();
      flutterDevice.device = webServerDevice;
      webDevFS.report = UpdateFSReport(success: true);

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      final OperationResult result = await residentWebRunner.restart(fullRestart: true);

      expect(logger.statusText, contains('Restarted application in'));
      expect(result.code, 0);

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.timing(
            workflow: 'hot',
            variableName: 'web-incremental-restart',
            elapsedMilliseconds: 0,
          ),
        ),
      );
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Does not fail hot restart when not attached',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        systemClock: SystemClock.fixed(DateTime(2001)),
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          const FakeVmServiceRequest(method: 'hotRestart'),
        ],
      );
      flutterDevice.device = WebServerDevice(logger: logger);
      webDevFS.report = UpdateFSReport(success: true);

      final appStartedCompleter = Completer<void>();
      unawaited(residentWebRunner.run(appStartedCompleter: appStartedCompleter));

      await appStartedCompleter.future;

      late final OperationResult result;

      await expectReturnsNormallyLater(() async {
        result = await residentWebRunner.restart(fullRestart: true);
      }());

      expect(result.code, 0);
      expect(result.isOk, isTrue);
      expect(logger.statusText, contains(kNoClientConnectedMessage));
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'web resident runner is debuggable',
    () {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());

      expect(residentWebRunner.debuggingEnabled, true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'Exits when initial compile fails',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      webDevFS.report = UpdateFSReport();

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));

      expect(await residentWebRunner.run(), 1);
      expect(fakeAnalytics.sentEvents, isEmpty);
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Faithfully displays stdout messages with leading/trailing spaces',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
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
        ],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(
        logger.statusText,
        contains('    This is a message with 4 leading and trailing spaces    '),
      );
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Fails on compilation errors in hot restart',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      webDevFS.report = UpdateFSReport();

      final OperationResult result = await residentWebRunner.restart(fullRestart: true);

      expect(result.code, 1);
      expect(result.message, contains('Failed to recompile application.'));
      expect(fakeAnalytics.sentEvents, isEmpty);
    },
    overrides: <Type, Generator>{
      Analytics: () => fakeAnalytics,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // TODO(nshahan): Delete this test case when hot reload can no longer be disabled.
  testUsingContext(
    'Fails non-fatally on vmservice response error for hot restart (legacy default case)',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          const FakeVmServiceRequest(
            method: kHotRestartServiceName,
            jsonResponse: <String, Object>{'type': 'Failed'},
          ),
        ],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      // Historically the .restart() would perform a hot restart even without
      // passing fullRestart: true.
      final OperationResult result = await residentWebRunner.restart();

      expect(result.code, 0);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // TODO(nshahan): Delete this test case when hot reload can no longer be disabled.
  testUsingContext(
    'Fails fatally on Vm Service error response (legacy default case)',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ...kAttachExpectations,
          FakeVmServiceRequest(
            method: kHotRestartServiceName,
            // Failed response,
            error: FakeRPCError(code: vm_service.RPCErrorKind.kInternalError.code),
          ),
        ],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;
      final OperationResult result = await residentWebRunner.restart();

      expect(result.code, 1);
      expect(result.message, contains(vm_service.RPCErrorKind.kInternalError.code.toString()));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  for (final webEnableHotReload in <bool>[true, false]) {
    testUsingContext(
      'Fails non-fatally on vmservice response error for hot restart with webEnableHotReload: $webEnableHotReload',
      () async {
        final ResidentRunner residentWebRunner = setUpResidentRunner(
          flutterDevice,
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo(
              BuildMode.debug,
              null,
              trackWidgetCreation: true,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
              webEnableHotReload: webEnableHotReload,
              extraFrontEndOptions: webEnableHotReload ? kDdcLibraryBundleFlags : <String>[],
            ),
          ),
        );
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ...kAttachExpectations,
            const FakeVmServiceRequest(
              method: kHotRestartServiceName,
              jsonResponse: <String, Object>{'type': 'Failed'},
            ),
          ],
        );
        setupMocks();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
        await connectionInfoCompleter.future;

        final OperationResult result = await residentWebRunner.restart(fullRestart: true);

        expect(result.code, 0);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Pub: ThrowingPub.new,
      },
    );

    testUsingContext(
      'Fails fatally on Vm Service error response with webEnableHotReload: $webEnableHotReload',
      () async {
        final ResidentRunner residentWebRunner = setUpResidentRunner(
          flutterDevice,
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo(
              BuildMode.debug,
              null,
              trackWidgetCreation: true,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
              webEnableHotReload: webEnableHotReload,
              extraFrontEndOptions: webEnableHotReload ? kDdcLibraryBundleFlags : <String>[],
            ),
          ),
        );
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ...kAttachExpectations,
            FakeVmServiceRequest(
              method: kHotRestartServiceName,
              // Failed response,
              error: FakeRPCError(code: vm_service.RPCErrorKind.kInternalError.code),
            ),
          ],
        );
        setupMocks();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
        await connectionInfoCompleter.future;
        final OperationResult result = await residentWebRunner.restart(fullRestart: true);

        expect(result.code, 1);
        expect(result.message, contains(vm_service.RPCErrorKind.kInternalError.code.toString()));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Pub: ThrowingPub.new,
      },
    );
  }
  testUsingContext(
    'printHelp without details shows only hot restart help message',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentWebRunner.printHelp(details: false);

      expect(logger.statusText, contains('Hot restart'));
      expect(logger.statusText.contains('Hot reload'), false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'printHelp without details shows hot restart and hot reload help message '
    'if using DDC library bundle format',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            null,
            trackWidgetCreation: true,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
            // TODO(nshahan): Remove when hot reload can no longer be disabled.
            webEnableHotReload: true,
            extraFrontEndOptions: kDdcLibraryBundleFlags,
          ),
        ),
      );
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentWebRunner.printHelp(details: false);

      expect(logger.statusText, contains('Hot restart'));
      expect(logger.statusText, contains('Hot reload'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'cleanup of resources is safe to call multiple times',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[...kAttachExpectations],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      await residentWebRunner.exit();
      await residentWebRunner.exit();

      expect(debugConnection.didClose, false);
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'cleans up Chrome if tab is closed',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[...kAttachExpectations],
      );
      setupMocks();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int?> result = residentWebRunner.run(
        connectionInfoCompleter: connectionInfoCompleter,
      );
      await connectionInfoCompleter.future;
      debugConnection.completer.complete();

      await result;
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Prints target and device name on run',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[...kAttachExpectations],
      );
      setupMocks();
      mockDevice.name = 'Chromez';
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      expect(
        logger.statusText,
        contains(
          'Launching ${fileSystem.path.join('lib', 'main.dart')} on '
          'Chromez in debug mode',
        ),
      );
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Sends launched app.webLaunchUrl event for Chrome device',
    () async {
      final logger = BufferLogger.test();
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[...kAttachLogExpectations, ...kAttachIsolateExpectations],
      );
      setupMocks();
      final chromeConnection = FakeChromeConnection();
      final chromiumLauncher = TestChromiumLauncher();
      final process = FakeProcess();
      final chrome = Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: process,
        logger: logger,
      );
      chromiumLauncher.setInstance(chrome);

      flutterDevice.device = GoogleChromeDevice(
        fileSystem: fileSystem,
        chromiumLauncher: chromiumLauncher,
        logger: logger,
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
      );
      webDevFS.baseUri = Uri.parse('http://localhost:8765/app/');

      final chromeTab = FakeChromeTab('index.html');
      chromeConnection.tabs.add(chromeTab);

      final runner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: logger,
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(runner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      // Ensure we got the URL and that it was already launched.
      expect(
        logger.eventText,
        contains(
          json.encode(<String, Object>{
            'name': 'app.webLaunchUrl',
            'args': <String, Object>{'url': 'http://localhost:8765/app/', 'launched': true},
          }),
        ),
      );
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Sends unlaunched app.webLaunchUrl event for Web Server device',
    () async {
      final logger = BufferLogger.test();
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      flutterDevice.device = WebServerDevice(logger: logger);
      webDevFS.baseUri = Uri.parse('http://localhost:8765/app/');

      final runner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        fileSystem: fileSystem,
        logger: logger,
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      unawaited(runner.run(connectionInfoCompleter: connectionInfoCompleter));
      await connectionInfoCompleter.future;

      // Ensure we got the URL and that it was not already launched.
      expect(
        logger.eventText,
        contains(
          json.encode(<String, Object>{
            'name': 'app.webLaunchUrl',
            'args': <String, Object>{'url': 'http://localhost:8765/app/', 'launched': false},
          }),
        ),
      );
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'ResidentWebRunner generates files when l10n.yaml exists',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: kAttachExpectations.toList());
      setupMocks();
      final ResidentRunner residentWebRunner = ResidentWebRunner(
        flutterDevice,
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        stayResident: false,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
        platform: FakePlatform(),
        outputPreferences: OutputPreferences.test(),
        analytics: globals.analytics,
        systemClock: globals.systemClock,
      );

      // Create necessary files.
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      globals.fs.file('l10n.yaml').createSync();
      globals.fs.file('pubspec.yaml').writeAsStringSync('''
name: my_app
flutter:
  generate: true
''');
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'path_provider_linux': '../../path_provider_linux'},
      );
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      expect(await residentWebRunner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
      await connectionInfoCompleter.future;
      final File generatedLocalizationsFile = globals.fs
          .directory('lib')
          .childDirectory('l10n')
          .childFile('app_localizations.dart');
      expect(generatedLocalizationsFile.existsSync(), isTrue);
      // Completing this future ensures that the daemon can exit correctly.
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  // While this file should be ignored on web, generating it here will cause a
  // perf regression in hot restart.
  testUsingContext(
    'Does not generate dart_plugin_registrant.dart',
    () async {
      // Create necessary files for [DartPluginRegistrantTarget]
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'path_provider_linux': '../../path_provider_linux'},
      );

      // Start with a dart_plugin_registrant.dart file.
      globals.fs
          .directory('.dart_tool')
          .childDirectory('flutter_build')
          .childFile('dart_plugin_registrant.dart')
          .createSync(recursive: true);

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      await residentWebRunner.runSourceGenerators();

      // dart_plugin_registrant.dart should be untouched, indicating that its
      // generation didn't run. If it had run, the file would have been removed as
      // there are no plugins in the project.
      expect(project.dartPluginRegistrant.existsSync(), true);
      expect(project.dartPluginRegistrant.readAsStringSync(), '');
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );

  testUsingContext(
    'Successfully turns WebSocketException into ToolExit',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      webDevFS.exception = const WebSocketException();

      await expectLater(residentWebRunner.run, throwsToolExit());
      expect(logger.errorText, contains('WebSocketException'));
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Turns HttpException from ChromeTab::connect into ToolExit',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      final chromeConnection = FakeChromeConnection();
      final chromiumLauncher = TestChromiumLauncher();
      final process = FakeProcess();
      final chrome = Chromium(
        1,
        chromeConnection,
        chromiumLauncher: chromiumLauncher,
        process: process,
        logger: logger,
      );
      chromiumLauncher.setInstance(chrome);

      flutterDevice.device = GoogleChromeDevice(
        fileSystem: fileSystem,
        chromiumLauncher: chromiumLauncher,
        logger: logger,
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
      );
      webDevFS.baseUri = Uri.parse('http://localhost:8765/app/');

      final chromeTab = FakeChromeTab(
        'index.html',
        connectException: HttpException(
          'Connection closed before full header was received',
          uri: Uri(path: 'http://localhost:50094/devtools/page/3036A94908353E86E183B6A40F54104B'),
        ),
      );
      chromeConnection.tabs.add(chromeTab);

      await expectLater(
        residentWebRunner.run,
        throwsToolExit(
          message: 'Failed to establish connection with the application instance in Chrome.',
        ),
      );
      expect(logger.errorText, contains('HttpException'));
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Successfully turns AppConnectionException into ToolExit',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      webDevFS.exception = AppConnectionException('');

      await expectLater(residentWebRunner.run, throwsToolExit());
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Successfully turns ChromeDebugError into ToolExit',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();

      webDevFS.exception = ChromeDebugException(<String, Object?>{'text': 'error'});

      await expectLater(residentWebRunner.run, throwsToolExit());
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Rethrows unknown Exception type from dwds',
    () async {
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      webDevFS.exception = Exception();

      await expectLater(residentWebRunner.run, throwsException);
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'Rethrows unknown Error type from dwds tooling',
    () async {
      final logger = BufferLogger.test();
      final ResidentRunner residentWebRunner = setUpResidentRunner(flutterDevice, logger: logger);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      setupMocks();
      webDevFS.exception = StateError('');

      await expectLater(residentWebRunner.run, throwsStateError);
      expect(fakeVmServiceHost.hasRemainingExpectations, false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: ThrowingPub.new,
    },
  );

  testUsingContext(
    'throws when port is an integer outside the valid TCP range',
    () async {
      final logger = BufferLogger.test();
      const webDevServerConfig = WebDevServerConfig(port: 65536);
      const webDevServerConfig2 = WebDevServerConfig(port: -1);

      var debuggingOptions = DebuggingOptions.enabled(
        BuildInfo.debug,
        webDevServerConfig: webDevServerConfig,
      );
      ResidentRunner residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        debuggingOptions: debuggingOptions,
      );
      await expectToolExitLater(residentWebRunner.run(), matches('Invalid port: 65536.*'));

      debuggingOptions = DebuggingOptions.enabled(
        BuildInfo.debug,
        webDevServerConfig: webDevServerConfig2,
      );
      residentWebRunner = setUpResidentRunner(
        flutterDevice,
        logger: logger,
        debuggingOptions: debuggingOptions,
      );
      await expectToolExitLater(residentWebRunner.run(), matches('Invalid port: -1.*'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    },
  );
}

ResidentRunner setUpResidentRunner(
  FlutterDevice flutterDevice, {
  Logger? logger,
  SystemClock? systemClock,
  DebuggingOptions? debuggingOptions,
}) {
  return ResidentWebRunner(
    flutterDevice,
    flutterProject: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory),
    debuggingOptions: debuggingOptions ?? DebuggingOptions.enabled(BuildInfo.debug),
    analytics: globals.analytics,
    systemClock: systemClock ?? SystemClock.fixed(DateTime.now()),
    fileSystem: globals.fs,
    logger: logger ?? BufferLogger.test(),
    terminal: Terminal.test(),
    platform: FakePlatform(),
    outputPreferences: OutputPreferences.test(),
  );
}

class FakeWebServerDevice extends FakeDevice implements WebServerDevice {}

class FakeDevice extends Fake implements WebDevice {
  @override
  String name = 'FakeDevice';

  @override
  String get displayName => name;

  @override
  Uri? devToolsUri;

  int count = 0;

  bool isRunning = false;

  @override
  Future<String> get sdkNameAndVersion async => 'SDK Name and Version';

  @override
  final dds = DartDevelopmentService(logger: test_fakes.FakeLogger());

  @override
  bool get supportsHotRestart => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, dynamic>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    isRunning = true;
    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    if (count > 0) {
      throw StateError('stopApp called more than once.');
    }
    count += 1;
    isRunning = false;
    return true;
  }
}

class FakeDebugConnection extends Fake implements DebugConnection {
  late FakeVmServiceHost Function() fakeVmServiceHost;

  @override
  vm_service.VmService get vmService => fakeVmServiceHost.call().vmService.service;

  @override
  late String uri;

  @override
  late String devToolsUri;

  @override
  late String dtdUri;

  final completer = Completer<void>();
  bool didClose = false;

  @override
  Future<void> get onDone => completer.future;

  @override
  Future<void> close() async {
    didClose = true;
  }
}

class FakeAppConnection extends Fake implements AppConnection {
  bool ranMain = false;

  @override
  void runMain() {
    ranMain = true;
  }
}

class FakeChromeDevice extends Fake implements ChromiumDevice {}

class FakeWipDebugger extends Fake implements WipDebugger {}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  @override
  Future<CompilerOutput> recompile(
    Uri mainUri,
    List<Uri>? invalidatedFiles, {
    required String outputPath,
    required PackageConfig packageConfig,
    required FileSystem fs,
    String? projectRootPath,
    bool suppressErrors = false,
    bool checkDartPluginRegistry = false,
    File? dartPluginRegistrant,
    Uri? nativeAssetsYaml,
    bool recompileRestart = false,
  }) async {
    return const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void accept() {}

  @override
  void reset() {}

  @override
  Future<CompilerOutput> reject() async {
    return const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void addFileSystemRoot(String root) {}
}

class FakeWebDevFS extends Fake implements WebDevFS {
  Object? exception;

  final resultCompleter = Completer<ConnectionResult?>();
  ConnectionResult? result;
  late UpdateFSReport report;

  Uri? mainUri;

  @override
  List<Uri> sources = <Uri>[];

  @override
  Uri baseUri = Uri.parse('http://localhost:12345');

  @override
  DateTime? lastCompiled = DateTime.now();

  @override
  PackageConfig? lastPackageConfig = PackageConfig.empty;

  @override
  bool useDwdsWebSocketConnection = false;

  @override
  Future<Uri> create() async {
    return baseUri;
  }

  @override
  Future<UpdateFSReport> update({
    required Uri mainUri,
    required ResidentCompiler generator,
    required bool trackWidgetCreation,
    required String pathToReload,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
    required String dillOutputPath,
    required DevelopmentShaderCompiler shaderCompiler,
    DevFSWriter? devFSWriter,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool fullRestart = false,
    bool resetCompiler = false,
    String? projectRootPath,
    File? dartPluginRegistrant,
  }) async {
    this.mainUri = mainUri;
    return report;
  }

  @override
  Future<ConnectionResult?> connect(
    bool useDebugExtension, {
    VmServiceFactory vmServiceFactory = createVmServiceDelegate,
  }) async {
    if (exception != null) {
      assert(exception is Exception || exception is Error);
      // ignore: only_throw_errors, exception is either Error or Exception here.
      throw exception!;
    }
    // Automatically complete the future if a non-null result has been set.
    if (result != null) {
      resultCompleter.complete(result);
    }
    return resultCompleter.future;
  }
}

class FakeChromeConnection extends Fake implements ChromeConnection {
  final tabs = <ChromeTab>[];

  @override
  Future<ChromeTab> getTab(bool Function(ChromeTab tab) accept, {Duration? retryFor}) async {
    return tabs.firstWhere(accept);
  }

  @override
  Future<List<ChromeTab>> getTabs({Duration? retryFor}) async {
    return tabs;
  }
}

class FakeChromeTab extends Fake implements ChromeTab {
  FakeChromeTab(this.url, {Exception? connectException}) : _connectException = connectException;

  @override
  final String url;

  final Exception? _connectException;
  final connection = FakeWipConnection();

  @override
  Future<WipConnection> connect({Function? onError}) async {
    if (_connectException != null) {
      throw _connectException;
    }
    return connection;
  }
}

class FakeWipConnection extends Fake implements WipConnection {
  @override
  final WipDebugger debugger = FakeWipDebugger();

  @override
  Future<WipResponse> sendCommand(String method, [Map<String, dynamic>? params]) async {
    return WipResponse(<String, dynamic>{'id': 0, 'result': <String, dynamic>{}});
  }
}

/// A test implementation of the [ChromiumLauncher] that launches a fixed instance.
class TestChromiumLauncher implements ChromiumLauncher {
  TestChromiumLauncher();

  var _hasInstance = false;
  void setInstance(Chromium chromium) {
    _hasInstance = true;
    currentCompleter.complete(chromium);
  }

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
  Future<Chromium> launch(
    String url, {
    bool headless = false,
    int? debugPort,
    bool skipCheck = false,
    Directory? cacheDir,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    return currentCompleter.future;
  }

  @override
  Future<Chromium> connect(Chromium chrome, bool skipCheck) {
    return currentCompleter.future;
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  Uri? testUri;
  UpdateFSReport report = UpdateFSReport(success: true, invalidatedSourcesCount: 1);
  Exception? reportError;

  @override
  ResidentCompiler? generator;

  @override
  Stream<Uri?> get vmServiceUris => Stream<Uri?>.value(testUri);

  @override
  DevelopmentShaderCompiler get developmentShaderCompiler => const FakeShaderCompiler();

  @override
  FlutterVmService? vmService;

  DevFS? _devFS;

  @override
  DevFS? get devFS => _devFS;

  @override
  set devFS(DevFS? value) {}

  @override
  Device? device;

  @override
  Future<void> stopEchoingDeviceLog() async {}

  @override
  Future<Uri?> setupDevFS(String fsName, Directory rootDirectory) async {
    return testUri;
  }

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {}

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    FlutterProject? flutterProject,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    required DebuggingOptions debuggingOptions,
    int? hostVmServicePort,
    bool? ipv6 = false,
    bool enableDevTools = false,
  }) async {}

  @override
  Future<UpdateFSReport> updateDevFS({
    Uri? mainUri,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    String? pathToReload,
    String? dillOutputPath,
    List<Uri>? invalidatedFiles,
    PackageConfig? packageConfig,
    File? dartPluginRegistrant,
  }) async {
    if (reportError != null) {
      throw reportError!;
    }
    return report;
  }

  @override
  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {}

  @override
  Future<void> handleHotRestart() async {}
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(TargetPlatform? platform) {}

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }
}
