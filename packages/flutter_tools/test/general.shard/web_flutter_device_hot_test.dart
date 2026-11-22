// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dwds/dwds.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/bundle.dart' hide defaultManifestPath;
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/web_flutter_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart' hide FakeProcess;
import '../src/package_config.dart';
import '../src/test_build_system.dart';
import 'hot_shared.dart' as hot_shared;
import 'resident_runner_helpers.dart' show fakeVM, listViews;

const _kDefaultWsUri = 'ws://127.0.0.1/abcd/';
const _kDefaultDevToolsUri = 'http://127.0.0.1/abcd/';
const _kDefaultDtdUri = 'ws://127.0.0.1/efgh/';
const _kIsolateId = '1';
const _kViewId = 'a';

const _kAttachLogExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Stdout'}),
  FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{'streamId': 'Stderr'}),
];

const _kAttachIsolateExpectations = <VmServiceExpectation>[
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

const _kAttachExpectations = <VmServiceExpectation>[
  ..._kAttachLogExpectations,
  ..._kAttachIsolateExpectations,
];

const _kStartPausedAttachExpectations = <VmServiceExpectation>[
  FakeVmServiceRequest(
    method: 'setFlag',
    args: <String, Object>{'name': 'pause_isolates_on_start', 'value': 'true'},
  ),
  ..._kAttachExpectations,
];

void main() {
  late FakeAppConnection appConnection;
  late Config config;
  late FakeDebugConnection debugConnection;
  late FakeAnalytics fakeAnalytics;
  late FakeVmServiceHost fakeVmServiceHost;
  late FakeWebDevFS fakeWebDevFS;
  late FakeWebDevice fakeWebDevice;
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late FakeResidentCompiler residentCompiler;

  setUp(() {
    config = Config.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    appConnection = FakeAppConnection();
    debugConnection = FakeDebugConnection()
      ..fakeVmServiceHost = (() => fakeVmServiceHost)
      ..uri = _kDefaultWsUri
      ..devToolsUri = _kDefaultDevToolsUri
      ..dtdUri = _kDefaultDtdUri;
    fakeWebDevFS = FakeWebDevFS(
      defaultResultBuilder: () =>
          ConnectionResult(appConnection, debugConnection, debugConnection.vmService),
    )..report = UpdateFSReport(success: true);
    fakeWebDevice = FakeWebDevice();
    residentCompiler = FakeResidentCompiler();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );

    fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app\n');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('web', 'index.html')).createSync(recursive: true);
  });

  FakeToolContext createToolContext() {
    return FakeToolContext(
      config: config,
      fs: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
      systemClock: SystemClock.fixed(DateTime(2001)),
    );
  }

  (HotRunner, WebFlutterDevice) createWebHotRunner({
    List<FlutterDevice>? additionalDevices,
    AssetBundleFactory? assetBundleFactory,
    BuildSystem? buildSystem,
    DebuggingOptions? debuggingOptions,
    Device? device,
    FlutterProject? flutterProject,
    bool hotMode = true,
    HotRunnerConfig? hotRunnerConfig,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prePopulateDevFS = true,
    String? projectRootPath,
    bool stayResident = true,
    String? target,
  }) {
    final DebuggingOptions options = debuggingOptions ?? DebuggingOptions.enabled(BuildInfo.debug);
    final FakeToolContext toolContext = createToolContext();
    final FlutterProject project =
        flutterProject ?? toolContext.projectFactory.fromDirectory(fileSystem.currentDirectory);
    final webFlutterDevice = WebFlutterDevice(
      device ?? fakeWebDevice,
      buildInfo: options.buildInfo,
      developmentShaderCompiler: const FakeShaderCompiler(),
      flutterProject: project,
      generator: residentCompiler,
      platformArgs: platformArgs,
      targetPlatform: TargetPlatform.web_javascript,
      toolContext: toolContext,
    );
    if (prePopulateDevFS) {
      webFlutterDevice.devFS = fakeWebDevFS;
    }
    final runner = HotRunner(
      <FlutterDevice>[webFlutterDevice, ...?additionalDevices],
      analytics: fakeAnalytics,
      applicationPackageFactory: FlutterApplicationPackageFactory(
        androidSdkBuilder: () => null,
        plistParserBuilder: FakePlistParser.new,
        templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
        toolContext: toolContext,
      ),
      assetBundleFactory:
          assetBundleFactory ??
          AssetBundleFactory.defaultInstance(
            fileSystem: fileSystem,
            flutterRoot: '',
            logger: logger,
            platform: FakePlatform(),
          ),
      buildSystem: buildSystem ?? TestBuildSystem.all(BuildResult(success: true)),
      buildTargets: const BuildTargetsImpl(),
      debuggingOptions: options,
      featureFlags: TestFeatureFlags(),
      hotMode: hotMode,
      hotRunnerConfig: hotRunnerConfig,
      projectRootPath: projectRootPath,
      stayResident: stayResident,
      stopwatchFactory: FakeStopwatchFactory(),
      target: target ?? fileSystem.path.join('lib', 'main.dart'),
      toolContext: toolContext,
      xcode: null,
    );
    return (runner, webFlutterDevice);
  }

  group('startup and attach', () {
    testWithoutContext('marks WebDevFS ready before startApp, completes appStartedCompleter before '
        'connectionInfoCompleter, and wires logs, DTD, and vmserviceOutFile', () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachLogExpectations,
          FakeVmServiceStreamResponse(
            streamId: 'Stdout',
            event: vm_service.Event(
              timestamp: 0,
              kind: vm_service.EventStreams.kStdout,
              bytes: base64.encode(utf8.encode('    leading and trailing spaces    ')),
            ),
          ),
          FakeVmServiceStreamResponse(
            streamId: 'Stderr',
            event: vm_service.Event(
              timestamp: 0,
              kind: vm_service.EventStreams.kStderr,
              bytes: base64.encode(utf8.encode('stderr line')),
            ),
          ),
          ..._kAttachIsolateExpectations,
          FakeVmServiceStreamResponse(
            streamId: 'Extension',
            event: vm_service.Event(
              timestamp: 0,
              extensionKind: 'Flutter.Error',
              extensionData: vm_service.ExtensionData.parse(<String, Object?>{
                'errorsSinceReload': 0,
                'renderedErrorText': 'structured error text',
              }),
              kind: vm_service.EventStreams.kExtension,
            ),
          ),
        ],
      );
      fakeWebDevFS.autoConnect = false;
      fakeWebDevice.onStartApp = () {
        expect(fakeWebDevFS.wasMarkedReady, isTrue);
        expect(fakeWebDevFS.connectCalled, isTrue);
      };

      final (HotRunner runner, _) = createWebHotRunner(
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.debug,
          printDtd: true,
          vmserviceOutFile: 'out/vmservice.txt',
        ),
      );

      expect(runner.canHotReload, isTrue);
      expect(runner.supportsRestart, isTrue);
      expect(runner.reloadIsRestart, isFalse);

      final appStartedCompleter = Completer<void>();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(
        appStartedCompleter: appStartedCompleter,
        connectionInfoCompleter: connectionInfoCompleter,
      );

      await appStartedCompleter.future;
      expect(connectionInfoCompleter.isCompleted, isFalse);
      expect(fakeAnalytics.sentEvents, isEmpty);

      fakeWebDevFS.resultCompleter.complete(
        ConnectionResult(appConnection, debugConnection, debugConnection.vmService),
      );
      final DebugConnectionInfo info = await connectionInfoCompleter.future;
      await pumpEventQueue();

      expect(appConnection.ranMain, isTrue);
      expect(info.wsUri.toString(), _kDefaultWsUri);
      expect(info.devToolsUri.toString(), _kDefaultDevToolsUri);
      expect(info.dtdUri.toString(), _kDefaultDtdUri);
      expect(fileSystem.file('out/vmservice.txt').readAsStringSync(), _kDefaultWsUri);
      expect(logger.statusText, contains('Debug service listening on $_kDefaultWsUri'));
      expect(
        logger.statusText,
        contains('The Dart Tooling Daemon is available at: $_kDefaultDtdUri'),
      );
      expect(logger.statusText, contains('    leading and trailing spaces    '));
      expect(logger.statusText, contains('stderr line'));
      expect(logger.statusText, contains('structured error text'));
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });

    testWithoutContext(
      'sets pause_isolates_on_start and gates runMain on kResume with --start-paused',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ..._kStartPausedAttachExpectations,
            const FakeVmServiceRequest(
              method: 'streamListen',
              args: <String, Object>{'streamId': 'Debug'},
            ),
            FakeVmServiceStreamResponse(
              streamId: 'Debug',
              event: vm_service.Event(kind: vm_service.EventKind.kResume, timestamp: 0),
            ),
          ],
        );
        final webServerDevice = WebServerDevice(logger: logger);
        final (HotRunner runner, _) = createWebHotRunner(
          device: webServerDevice,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, startPaused: true),
        );

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
        await connectionInfoCompleter.future;

        expect(fakeWebDevFS.lastUseDebugExtension, isTrue);
        expect(appConnection.ranMain, isFalse);

        await runner.flutterDevices.single.vmService!.service.streamListen(
          vm_service.EventStreams.kDebug,
        );
        await pumpEventQueue();

        expect(appConnection.ranMain, isTrue);
        expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext(
      'logs missing web/ hint, respects no-launch-chrome, skips dart_plugin_registrant.dart, '
      'and forwards projectRootPath manifestPath and flavor to assetBundle',
      () async {
        fileSystem.directory('web').deleteSync(recursive: true);
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final Directory projectDir = fileSystem.directory('/custom_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: custom_project\n');
        projectDir.childFile('lib/main.dart').createSync(recursive: true);
        writePackageConfigFiles(
          directory: projectDir,
          mainLibName: 'custom_project',
          packages: <String, String>{'path_provider_linux': '../../path_provider_linux'},
        );
        final File dartPluginRegistrant =
            projectDir
                .childDirectory('.dart_tool')
                .childDirectory('flutter_build')
                .childFile('dart_plugin_registrant.dart')
              ..createSync(recursive: true);

        final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);
        final chromeDevice = FakeChromeDevice();
        final assetBundleFactory = FakeAssetBundleFactory();

        final (HotRunner runner, WebFlutterDevice webDevice) = createWebHotRunner(
          assetBundleFactory: assetBundleFactory,
          device: chromeDevice,
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo(
              .debug,
              'staging',
              treeShakeIcons: false,
              packageConfigPath: projectDir
                  .childDirectory('.dart_tool')
                  .childFile('package_config.json')
                  .path,
            ),
            webConfig: const WebDebugConfig(
              devServerConfig: WebDevServerConfig(
                https: HttpsConfig(certPath: 'cert.pem', certKeyPath: 'key.pem'),
              ),
            ),
          ),
          flutterProject: project,
          platformArgs: const <String, Object?>{'no-launch-chrome': true},
          projectRootPath: projectDir.path,
          stayResident: false,
          target: projectDir.childDirectory('lib').childFile('main.dart').path,
        );

        expect(webDevice.useDwdsWebSocketConnection, isTrue);
        expect(runner.generateDartPluginRegistry, isFalse);

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        expect(await runner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
        await connectionInfoCompleter.future;

        expect(
          logger.statusText,
          contains('This application is not configured to build on the web.'),
        );
        expect(chromeDevice.lastPlatformArgs!['no-launch-chrome'], isTrue);
        expect(chromeDevice.lastPlatformArgs!['uri'], 'https://localhost:12345');
        expect(dartPluginRegistrant.existsSync(), isTrue);
        expect(assetBundleFactory.bundle.lastNeedsBuildManifestPath, project.pubspecFile.path);
        expect(assetBundleFactory.bundle.lastBuildManifestPath, project.pubspecFile.path);
        expect(assetBundleFactory.bundle.lastFlavor, 'staging');
      },
    );

    for (final invalidPort in <int>[65536, -1]) {
      testWithoutContext('throws ToolExit on invalid devServerConfig port $invalidPort', () async {
        final (HotRunner runner, _) = createWebHotRunner(
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo.debug,
            webConfig: WebDebugConfig(devServerConfig: WebDevServerConfig(port: invalidPort)),
          ),
          stayResident: false,
        );

        await expectToolExitLater(runner.run(), matches('Invalid port: $invalidPort.*'));
        expect(await runner.waitForAppToFinish(), 1);
      });
    }

    for (final deprecatedJsInterop in <bool?>[true, false, null]) {
      testWithoutContext('caches initial app.dill and sends DDC compile analytics when '
          'deprecatedJsInterop is $deprecatedJsInterop', () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final buildInfo = BuildInfo(
          .debug,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
          deprecatedJsInterop: deprecatedJsInterop,
        );
        final (HotRunner runner, _) = createWebHotRunner(
          debuggingOptions: DebuggingOptions.enabled(buildInfo),
          stayResident: false,
        );
        runner.artifactDirectory.childFile('app.dill').writeAsStringSync('KERNEL_BYTES');

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        expect(await runner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
        await connectionInfoCompleter.future;

        final String expectedCachePath = getDefaultCachedKernelPath(
          trackWidgetCreation: false,
          dartDefines: const <String>[],
          config: config,
          fileSystem: fileSystem,
          targetModel: TargetModel.dartdevc,
          extraFrontEndOptions: ddcFrontEndOptions(buildInfo),
        );
        expect(fileSystem.file(expectedCachePath).readAsStringSync(), 'KERNEL_BYTES');

        if (deprecatedJsInterop == null) {
          expect(fakeAnalytics.sentEvents, isEmpty);
        } else {
          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterBuildInfo(
                label: 'web-compile',
                buildType: 'web',
                command: 'run',
                settings: 'deprecatedJsInterop: $deprecatedJsInterop; web-compiler: ddc;',
              ),
            ),
          );
        }

        final compiler = const ResidentCompilerFactory().create(
          targetPlatform: TargetPlatform.web_javascript,
          buildInfo: buildInfo,
          logger: BufferLogger.test(),
          processManager: FakeProcessManager.any(),
          artifacts: Artifacts.test(),
          platform: FakePlatform(),
          fileSystem: fileSystem,
          shutdownHooks: FakeShutdownHooks(),
          config: config,
        ) as DefaultResidentCompiler;
        expect(fileSystem.file(compiler.initializeFromDill).readAsStringSync(), 'KERNEL_BYTES');
      });
    }

    testWithoutContext(
      'caches initial app.dill with kDdcLibraryBundleFlags when trackWidgetCreation is true',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner(stayResident: false);
        runner.artifactDirectory.childFile('app.dill').writeAsStringSync('TRACKED_KERNEL');

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        expect(await runner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
        await connectionInfoCompleter.future;

        final String expectedPath = getDefaultCachedKernelPath(
          trackWidgetCreation: true,
          dartDefines: const <String>[],
          config: config,
          fileSystem: fileSystem,
          targetModel: TargetModel.dartdevc,
          extraFrontEndOptions: kDdcLibraryBundleFlags,
        );
        expect(fileSystem.file(expectedPath).readAsStringSync(), 'TRACKED_KERNEL');
      },
    );

    for (final deprecatedJsInterop in <bool?>[true, false, null]) {
      testWithoutContext(
        'calls appFailedToStart and sends failure analytics on initial DDC compile failure '
        'when deprecatedJsInterop is $deprecatedJsInterop',
        () async {
          fakeWebDevFS.report = UpdateFSReport();
          final (HotRunner runner, _) = createWebHotRunner(
            debuggingOptions: DebuggingOptions.enabled(
              BuildInfo(
                .debug,
                null,
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
                deprecatedJsInterop: deprecatedJsInterop,
              ),
            ),
          );

          expect(await runner.run(), 1);
          expect(await runner.waitForAppToFinish(), 1);
          expect(logger.errorText, contains('Failed to compile application.'));
          if (deprecatedJsInterop == null) {
            expect(fakeAnalytics.sentEvents, isEmpty);
          } else {
            expect(fakeAnalytics.sentEvents, <Event>[
              Event.flutterBuildInfo(
                label: 'web-compile',
                buildType: 'web',
                command: 'run',
                settings: 'deprecatedJsInterop: $deprecatedJsInterop; web-compiler: ddc;',
                error: 'ddc-compile-failure',
              ),
            ]);
          }
        },
      );
    }

    testWithoutContext('formats Flutter.Error extension events and logs invalid Flutter.Error payloads', () async {
      fakeWebDevice.name = 'Chromez';
      final requests = <VmServiceExpectation>[
        ..._kAttachExpectations,
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
        FakeVmServiceStreamResponse(
          streamId: 'Extension',
          event: vm_service.Event(
            timestamp: 0,
            extensionKind: 'Flutter.Error',
            extensionData: vm_service.ExtensionData.parse(<String, Object?>{'other': 'bad stuff'}),
            kind: vm_service.EventStreams.kExtension,
          ),
        ),
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
      ];
      fakeVmServiceHost = FakeVmServiceHost(requests: requests.toList());

      final (HotRunner runner, _) = createWebHotRunner();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;
      await pumpEventQueue();

      expect(
        logger.statusText,
        'Launching lib/main.dart on Chromez in debug mode...\n'
        'Waiting for connection from debug service on Chromez...\n'
        'Debug service listening on $_kDefaultWsUri\n'
        'A Dart VM Service on Chromez is available at: $_kDefaultDevToolsUri\n'
        'The Flutter DevTools debugger and profiler on Chromez is available at: $_kDefaultDevToolsUri\n'
        '\n'
        'first\n'
        '\n'
        'second\n'
        'third\n'
        '\n'
        '\n'
        '\n'
        '\n'
        'error text\n'
        '\n',
      );
      expect(
        logger.errorText,
        'Received an invalid Flutter.Error message from app: {other: bad stuff}\n',
      );

      await runner.exit();
      expect(await runFuture, 0);
    });

    testWithoutContext(
      'sends app.webLaunchUrl events and sets useDwdsWebSocketConnection for Chrome vs WebServer',
      () async {
        fakeWebDevFS.baseUri = Uri.parse('http://localhost:8765/app/');
        final chromeConnection = FakeChromeConnection()..tabs.add(FakeChromeTab('index.html'));
        final chromiumLauncher = TestChromiumLauncher();
        chromiumLauncher.setInstance(
          Chromium(
            1,
            chromeConnection,
            chromiumLauncher: chromiumLauncher,
            process: FakeProcess(),
            logger: logger,
          ),
        );
        final chromeDevice = GoogleChromeDevice(
          fileSystem: fileSystem,
          chromiumLauncher: chromiumLauncher,
          logger: logger,
          platform: FakePlatform(),
          processManager: FakeProcessManager.any(),
        );

        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner chromeRunner, WebFlutterDevice chromeWebDevice) = createWebHotRunner(
          device: chromeDevice,
          stayResident: false,
        );
        expect(chromeWebDevice.useDwdsWebSocketConnection, isFalse);
        expect(chromeRunner.debuggingEnabled, isTrue);

        final chromeConn = Completer<DebugConnectionInfo>();
        expect(await chromeRunner.run(connectionInfoCompleter: chromeConn), 0);
        await chromeConn.future;
        expect(
          logger.eventText,
          contains(
            json.encode(<String, Object>{
              'name': 'app.webLaunchUrl',
              'args': <String, Object>{'url': 'http://localhost:8765/app/', 'launched': true},
            }),
          ),
        );

        logger.clear();
        fakeWebDevFS =
            FakeWebDevFS(
                defaultResultBuilder: () =>
                    ConnectionResult(appConnection, debugConnection, debugConnection.vmService),
              )
              ..baseUri = Uri.parse('http://localhost:8765/app/')
              ..report = UpdateFSReport(success: true);
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final webServerDevice = WebServerDevice(logger: logger);
        final (HotRunner serverRunner, WebFlutterDevice serverWebDevice) = createWebHotRunner(
          device: webServerDevice,
          stayResident: false,
        );
        expect(serverWebDevice.useDwdsWebSocketConnection, isTrue);
        expect(serverRunner.debuggingEnabled, isTrue);
        expect(serverRunner.uri, fakeWebDevFS.baseUri);

        final serverConn = Completer<DebugConnectionInfo>();
        expect(await serverRunner.run(connectionInfoCompleter: serverConn), 0);
        await serverConn.future;
        expect(
          logger.eventText,
          contains(
            json.encode(<String, Object>{
              'name': 'app.webLaunchUrl',
              'args': <String, Object>{'url': 'http://localhost:8765/app/', 'launched': false},
            }),
          ),
        );
      },
    );

    testWithoutContext('generates localizations when l10n.yaml exists without generating dart_plugin_registrant.dart', () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
      fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      fileSystem.file('l10n.yaml').createSync();
      fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
flutter:
  generate: true
''');
      writePackageConfigFiles(
        directory: fileSystem.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'path_provider_linux': '../../path_provider_linux'},
      );
      final File dartPluginRegistrant =
          fileSystem
              .directory('.dart_tool')
              .childDirectory('flutter_build')
              .childFile('dart_plugin_registrant.dart')
            ..createSync(recursive: true);

      final (HotRunner runner, _) = createWebHotRunner(
        buildSystem: FlutterBuildSystem(
          fileSystem: fileSystem,
          platform: FakePlatform(),
          logger: logger,
        ),
        stayResident: false,
      );

      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      expect(await runner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
      await connectionInfoCompleter.future;

      expect(
        fileSystem
            .directory('lib')
            .childDirectory('l10n')
            .childFile('app_localizations.dart')
            .existsSync(),
        isTrue,
      );
      // Had DartPluginRegistrantTarget run, the empty file would have been deleted
      // since path_provider_linux has no pubspec here.
      expect(dartPluginRegistrant.existsSync(), isTrue);
      expect(dartPluginRegistrant.readAsStringSync(), isEmpty);
    });

    testWithoutContext(
      'respects hotMode: false (--debug --no-hot) in printHelp and service registration',
      () async {
        final (HotRunner defaultRunner, _) = createWebHotRunner();
        defaultRunner.printHelp(details: false);
        expect(logger.statusText, contains('Hot reload'));
        expect(logger.statusText, contains('Hot restart'));

        logger.clear();
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ..._kAttachLogExpectations,
            const FakeVmServiceRequest(
              method: 'streamListen',
              args: <String, Object>{'streamId': 'Service'},
            ),
            const FakeVmServiceRequest(
              method: 'streamListen',
              args: <String, Object>{'streamId': 'Isolate'},
            ),
            const FakeVmServiceRequest(
              method: 'registerService',
              args: <String, Object>{
                'service': kFlutterVersionServiceName,
                'alias': kFlutterToolAlias,
              },
            ),
            const FakeVmServiceRequest(
              method: 'registerService',
              args: <String, Object>{
                'service': kFlutterMemoryInfoServiceName,
                'alias': kFlutterToolAlias,
              },
            ),
            const FakeVmServiceRequest(
              method: 'streamListen',
              args: <String, Object>{'streamId': 'Extension'},
            ),
          ],
        );

        final (HotRunner noHotRunner, _) = createWebHotRunner(hotMode: false, stayResident: false);
        expect(noHotRunner.canHotReload, isFalse);
        expect(noHotRunner.supportsRestart, isFalse);

        noHotRunner.printHelp(details: false);
        expect(logger.statusText, isNot(contains('Hot reload')));
        expect(logger.statusText, isNot(contains('Hot restart')));

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        expect(await noHotRunner.run(connectionInfoCompleter: connectionInfoCompleter), 0);
        await connectionInfoCompleter.future;
        expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);
      },
    );

    testWithoutContext(
      'throws StateError on attach() when device defers service protocol connection',
      () async {
        final (HotRunner runner, _) = createWebHotRunner();
        await expectLater(runner.attach(), throwsStateError);
      },
    );

    testWithoutContext(
      'throws StateError on mixed or multi-web device lists with deferred connections',
      () async {
        final nativeDevice = hot_shared.FakeFlutterDevice(hot_shared.FakeDevice());
        final (HotRunner mixedRunner, _) = createWebHotRunner(
          additionalDevices: <FlutterDevice>[nativeDevice],
        );
        await expectLater(mixedRunner.run(), throwsStateError);
        await expectLater(mixedRunner.restart(), throwsStateError);

        final secondWebDevice = WebFlutterDevice(
          FakeWebDevice(),
          buildInfo: BuildInfo.debug,
          developmentShaderCompiler: const FakeShaderCompiler(),
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          generator: residentCompiler,
          targetPlatform: TargetPlatform.web_javascript,
          toolContext: createToolContext(),
        )..devFS = fakeWebDevFS;
        final (HotRunner multiWebRunner, _) = createWebHotRunner(
          additionalDevices: <FlutterDevice>[secondWebDevice],
        );
        await expectLater(multiWebRunner.run(), throwsStateError);
        await expectLater(multiWebRunner.restart(fullRestart: true), throwsStateError);
      },
    );
  });

  group('deferred connection exception mapping', () {
    final connectionCases = <(String, Exception Function(), String, String?)>[
      (
        'WebSocketException',
        () => const WebSocketException('ws failed'),
        kExitMessage,
        'WebSocketException',
      ),
      (
        'ChromeDebugException',
        () => ChromeDebugException(<String, Object?>{'text': 'cdp failed'}),
        kExitMessage,
        'cdp failed',
      ),
      (
        'AppConnectionException',
        () => AppConnectionException('app failed'),
        kExitMessage,
        'AppConnectionException',
      ),
      (
        'SocketException',
        () => const SocketException('socket failed'),
        kExitMessage,
        'SocketException',
      ),
      ('HttpException', () => const HttpException('http failed'), kExitMessage, 'HttpException'),
      (
        'TimeoutException',
        () => TimeoutException('timed out'),
        'Failed to connect to the web debug service.',
        'Failed to establish connection with the web debug service: TimeoutException: timed out',
      ),
      (
        'DartDevelopmentServiceException.failedToStart',
        DartDevelopmentServiceException.failedToStart,
        kExitMessage,
        null,
      ),
      (
        'DartDevelopmentServiceException.connectionIssue',
        () => DartDevelopmentServiceException.connectionIssue('upgrade failed'),
        kExitMessage,
        'upgrade failed',
      ),
    ];

    for (final (
          String name,
          Exception Function() buildError,
          String expectedExitMessage,
          String? expectedLoggedError,
        )
        in connectionCases) {
      testWithoutContext('maps $name to ToolExit', () async {
        fakeWebDevFS.exception = buildError();
        final (HotRunner runner, _) = createWebHotRunner();

        await expectLater(runner.run(), throwsToolExit(message: expectedExitMessage));
        expect(await runner.waitForAppToFinish(), 1);
        if (expectedLoggedError == null) {
          expect(logger.errorText, isEmpty);
        } else {
          expect(logger.errorText, contains(expectedLoggedError));
        }
      });
    }

    testWithoutContext('rethrows unknown Exception after marking appFailedToStart', () async {
      fakeWebDevFS.exception = Exception('unexpected dwds exception');
      final (HotRunner runner, _) = createWebHotRunner();

      await expectLater(runner.run(), throwsException);
      expect(await runner.waitForAppToFinish(), 1);
    });

    testWithoutContext('rethrows non-Exception Error untouched', () async {
      fakeWebDevFS.error = StateError('unexpected state error');
      final (HotRunner runner, _) = createWebHotRunner();

      await expectLater(runner.run(), throwsStateError);
    });
  });

  group('hot reload', () {
    testWithoutContext(
      'reloads sources, evicts dirty assets without setAssetDirectory or shader eviction, '
      'reassembles isolate, and reports timing analytics',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ..._kAttachExpectations,
            FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
            const FakeVmServiceRequest(
              method: kReloadSourcesServiceName,
              args: <String, Object>{'isolateId': _kIsolateId},
              jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
            ),
            listViews,
            const FakeVmServiceRequest(
              method: '_flutter.reloadAssetFonts',
              args: <String, Object>{'isolateId': _kIsolateId, 'viewId': _kViewId},
              jsonResponse: <String, Object>{'type': 'Success'},
            ),
            const FakeVmServiceRequest(
              method: 'ext.flutter.evict',
              args: <String, Object>{'isolateId': _kIsolateId, 'value': 'assets/logo.png'},
              jsonResponse: <String, Object>{'type': 'Success'},
            ),
            listViews,
            const FakeVmServiceRequest(
              method: 'ext.flutter.reassemble',
              args: <String, Object>{'isolateId': _kIsolateId},
              jsonResponse: <String, Object>{'type': 'Success'},
            ),
          ],
        );

        fakeWebDevFS.assetPathsToEvict.add('assets/logo.png');
        fakeWebDevFS.shaderPathsToEvict.add('shaders/ink.frag');
        fakeWebDevFS.didUpdateFontManifest = true;

        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
        await connectionInfoCompleter.future;

        expect(fakeWebDevFS.resetCompilerHistory, <bool>[true]);

        final OperationResult reloadOk = await runner.restart();
        expect(reloadOk.isOk, isTrue);
        expect(fakeWebDevFS.resetCompilerHistory, <bool>[true, false]);
        expect(fakeWebDevFS.assetPathsToEvict, isEmpty);
        expect(fakeWebDevFS.shaderPathsToEvict, isEmpty);
        expect(fakeWebDevFS.didUpdateFontManifest, isFalse);
        expect(logger.statusText, matches(r'Reloaded application in \d+ms'));
        expect(
          fakeAnalytics.sentEvents,
          containsAll(<Event>[
            Event.timing(workflow: 'hot', variableName: 'reload', elapsedMilliseconds: 0),
            Event.hotRunnerInfo(
              label: 'reload',
              targetPlatform: 'web-javascript',
              sdkName: 'Flutter Tools',
              emulator: false,
              fullRestart: false,
              overallTimeInMs: 0,
              finalLibraryCount: 0,
              syncedLibraryCount: 0,
              syncedClassesCount: 0,
              syncedProceduresCount: 0,
              syncedBytes: 0,
              invalidatedSourcesCount: 0,
              transferTimeInMs: 0,
              compileTimeInMs: 0,
              findInvalidatedTimeInMs: 0,
              scannedSourcesCount: 0,
              reassembleTimeInMs: 0,
              reloadVMTimeInMs: 0,
            ),
          ]),
        );
        expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext(
      'skips getIsolatePauseEvent and proceeds directly to flutterReassemble on web',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ..._kAttachExpectations,
            FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
            const FakeVmServiceRequest(
              method: kReloadSourcesServiceName,
              args: <String, Object>{'isolateId': _kIsolateId},
              jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
            ),
            listViews,
            const FakeVmServiceRequest(
              method: 'ext.flutter.reassemble',
              args: <String, Object>{'isolateId': _kIsolateId},
              jsonResponse: <String, Object>{'type': 'Success'},
            ),
          ],
        );

        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
        await connectionInfoCompleter.future;

        final OperationResult reloadResult = await runner.restart();
        expect(reloadResult.isOk, isTrue);
        expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext(
      'rejects compiler and sends reload-reject analytics on compile-time hot reload rejection',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
        await connectionInfoCompleter.future;

        fakeWebDevFS.report = UpdateFSReport(hotReloadRejected: true);
        final OperationResult compileRejected = await runner.restart();
        expect(compileRejected.code, 1);
        expect(residentCompiler.rejectCount, 1);
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.hotRunnerInfo(
              label: 'reload-reject',
              targetPlatform: 'web-javascript',
              sdkName: 'Flutter Tools',
              emulator: false,
              fullRestart: false,
            ),
          ),
        );

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext('surfaces runtime ReloadReport rejection notices', () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachExpectations,
          FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
          const FakeVmServiceRequest(
            method: kReloadSourcesServiceName,
            args: <String, Object>{'isolateId': _kIsolateId},
            jsonResponse: <String, Object>{
              'type': 'ReloadReport',
              'success': false,
              'notices': <Object>[
                <String, Object>{'message': 'Const field changed'},
              ],
            },
          ),
        ],
      );

      final (HotRunner runner, _) = createWebHotRunner();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      final OperationResult runtimeRejected = await runner.restart();
      expect(runtimeRejected.code, 1);
      expect(runtimeRejected.message, contains('Const field changed'));
      expect(residentCompiler.rejectCount, 1);
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });

    testWithoutContext('returns non-zero OperationResult when flutterReassemble fails', () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachExpectations,
          FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
          const FakeVmServiceRequest(
            method: kReloadSourcesServiceName,
            args: <String, Object>{'isolateId': _kIsolateId},
            jsonResponse: <String, Object>{'type': 'ReloadReport', 'success': true},
          ),
          listViews,
          FakeVmServiceRequest(
            method: 'ext.flutter.reassemble',
            args: const <String, Object>{'isolateId': _kIsolateId},
            error: FakeRPCError(code: vm_service.RPCErrorKind.kInternalError.code),
          ),
        ],
      );

      final (HotRunner runner, _) = createWebHotRunner();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      final OperationResult reassembleFailed = await runner.restart();
      expect(reassembleFailed.code, 1);
      expect(logger.errorText, contains('Reassembling test failed:'));
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });
  });

  group('hot restart', () {
    testWithoutContext('restarts without resetting compiler, honors registered service method, '
        'supports non-lib entrypoints, and cleans up generated entrypoint dir on exit', () async {
      fileSystem.file(fileSystem.path.join('web', 'custom_main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachLogExpectations,
          FakeVmServiceStreamResponse(
            streamId: 'Service',
            event: vm_service.Event(
              timestamp: 0,
              kind: vm_service.EventKind.kServiceRegistered,
              service: kHotRestartServiceName,
              method: 's0.hotRestart',
            ),
          ),
          ..._kAttachIsolateExpectations,
          const FakeVmServiceRequest(
            method: 's0.hotRestart',
            jsonResponse: <String, Object>{'type': 'Success'},
          ),
        ],
      );

      final (HotRunner runner, _) = createWebHotRunner(
        target: fileSystem.path.join('web', 'custom_main.dart'),
      );
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      expect(
        residentCompiler.addedFileSystemRoots,
        containsAll(<String>[
          fileSystem.file(fileSystem.path.join('web', 'custom_main.dart')).absolute.parent.path,
          fileSystem.directory('test').absolute.path,
        ]),
      );
      final File generatedEntrypoint = fileSystem.file(fakeWebDevFS.mainUri);
      expect(generatedEntrypoint.existsSync(), isTrue);
      final String entrypointContents = generatedEntrypoint.readAsStringSync();
      expect(entrypointContents, contains('// Flutter web bootstrap script'));
      expect(entrypointContents, contains("import 'dart:ui_web' as ui_web;"));
      expect(entrypointContents, contains('await ui_web.bootstrapEngine('));
      expect(entrypointContents, contains("import 'org-dartlang-app:///custom_main.dart'"));

      final OperationResult restartOk = await runner.restart(fullRestart: true);
      expect(restartOk.isOk, isTrue);
      expect(fakeWebDevFS.resetCompilerHistory, <bool>[true, false]);
      expect(fakeWebDevFS.fullRestartHistory, <bool>[true, true]);
      expect(logger.statusText, matches(r'Restarted application in \d+ms\.'));
      expect(
        fakeAnalytics.sentEvents,
        containsAll(<Object>[
          isA<Event>()
              .having((Event e) => e.eventName.label, 'eventName', 'timing')
              .having((Event e) => e.eventData['workflow'], 'workflow', 'hot')
              .having(
                (Event e) => e.eventData['variableName'],
                'variableName',
                'web-incremental-restart',
              ),
          Event.hotRunnerInfo(
            label: 'restart',
            targetPlatform: 'web-javascript',
            sdkName: 'Flutter Tools',
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
        ]),
      );
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
      expect(generatedEntrypoint.parent.existsSync(), isFalse);
    });

    testWithoutContext('honors HotRunnerConfig setup and shutdown hooks', () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
      final configHooks = hot_shared.TestHotRunnerConfig(
        successfulHotReloadSetup: false,
        successfulHotRestartSetup: false,
      );
      final (HotRunner runner, _) = createWebHotRunner(hotRunnerConfig: configHooks);
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      final OperationResult reloadAborted = await runner.restart();
      expect(reloadAborted.code, 1);
      expect(reloadAborted.message, 'setupHotReload failed');

      final OperationResult restartAborted = await runner.restart(fullRestart: true);
      expect(restartAborted.code, 1);
      expect(restartAborted.message, 'setupHotRestart failed');

      await runner.exit();
      expect(await runFuture, 0);
      expect(configHooks.shutdownHookCalled, isTrue);
    });

    testWithoutContext(
      'rejects compiler without emitting restart-failed analytics when hot restart recompile fails',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
        await connectionInfoCompleter.future;

        fakeWebDevFS.report = UpdateFSReport();
        final OperationResult compileFailed = await runner.restart(fullRestart: true);
        expect(compileFailed.code, 1);
        expect(residentCompiler.rejectCount, 1);
        expect(fakeAnalytics.sentEvents, isEmpty);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext('treats non-RPCError Failed hotRestart response as non-fatal and recovers after failed recompile', () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachExpectations,
          const FakeVmServiceRequest(
            method: kHotRestartServiceName,
            jsonResponse: <String, Object>{'type': 'Failed'},
          ),
          const FakeVmServiceRequest(
            method: kHotRestartServiceName,
            jsonResponse: <String, Object>{'type': 'Success'},
          ),
        ],
      );
      final webServerDevice = WebServerDevice(logger: logger);
      final (HotRunner runner, _) = createWebHotRunner(device: webServerDevice);
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      final OperationResult nonFatal = await runner.restart(fullRestart: true);
      expect(nonFatal.code, 0);
      expect(nonFatal.fatal, isFalse);

      // Failed recompile resets _isRestarting so subsequent restarts proceed.
      fakeWebDevFS.report = UpdateFSReport();
      final OperationResult failedCompile = await runner.restart(fullRestart: true);
      expect(failedCompile.code, 1);

      fakeWebDevFS.report = UpdateFSReport(success: true);
      final OperationResult recovered = await runner.restart(fullRestart: true);
      expect(recovered.code, 0);
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });

    testWithoutContext('marks internal RPCError during hot restart as fatal', () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachExpectations,
          FakeVmServiceRequest(
            method: kHotRestartServiceName,
            error: FakeRPCError(code: vm_service.RPCErrorKind.kInternalError.code),
          ),
        ],
      );

      final (HotRunner runner, _) = createWebHotRunner();
      final connectionInfoCompleter = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfoCompleter);
      await connectionInfoCompleter.future;

      final OperationResult fatalError = await runner.restart(fullRestart: true);
      expect(fatalError.code, 1);
      expect(fatalError.fatal, isTrue);
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });
  });

  group('zero connected clients and concurrency', () {
    testWithoutContext(
      'prints kNoClientConnectedMessage before any client attaches and guards concurrent restarts',
      () async {
        fakeWebDevFS.autoConnect = false;
        final (HotRunner runner, _) = createWebHotRunner();
        final appStarted = Completer<void>();
        final Future<int> runFuture = runner.run(appStartedCompleter: appStarted);
        await appStarted.future;

        final Future<OperationResult> firstRestart = runner.restart(fullRestart: true);
        final OperationResult concurrentRestart = await runner.restart();
        expect(concurrentRestart.code, 1);
        expect(concurrentRestart.message, 'A restart is already in progress.');

        final OperationResult firstResult = await firstRestart;
        expect(firstResult.isOk, isTrue);
        expect(logger.statusText, contains(kNoClientConnectedMessage));
        expect(fakeAnalytics.sentEvents, isEmpty);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    testWithoutContext('tolerates empty isolates on hot reload', () async {
      final emptyIsolatesVM = vm_service.VM(
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
      );
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          ..._kAttachExpectations,
          FakeVmServiceRequest(method: 'getVM', jsonResponse: emptyIsolatesVM.toJson()),
        ],
      );

      final (HotRunner runner, _) = createWebHotRunner();
      final connectionInfo = Completer<DebugConnectionInfo>();
      final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
      await connectionInfo.future;

      final OperationResult result = await runner.restart();
      expect(result.isOk, isTrue);
      expect(logger.statusText, contains(kNoClientConnectedMessage));
      expect(fakeAnalytics.sentEvents, isEmpty);
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

      await runner.exit();
      expect(await runFuture, 0);
    });

    testWithoutContext(
      'tolerates kIsolateCannotReload on hot reload when no client is connected',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            ..._kAttachExpectations,
            FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
            FakeVmServiceRequest(
              method: kReloadSourcesServiceName,
              args: const <String, Object>{'isolateId': _kIsolateId},
              error: FakeRPCError(code: vm_service.RPCErrorKind.kIsolateCannotReload.code),
            ),
          ],
        );

        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfo = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
        await connectionInfo.future;

        final OperationResult result = await runner.restart();
        expect(result.isOk, isTrue);
        expect(logger.statusText, contains(kNoClientConnectedMessage));
        expect(fakeAnalytics.sentEvents, isEmpty);
        expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

        await runner.exit();
        expect(await runFuture, 0);
      },
    );

    for (final (String errorName, int errorCode) in <(String, int)>[
      ('kIsolateCannotReload', vm_service.RPCErrorKind.kIsolateCannotReload.code),
      ('kServerError', vm_service.RPCErrorKind.kServerError.code),
    ]) {
      testWithoutContext(
        'tolerates $errorName on hot restart when no client is connected',
        () async {
          fakeVmServiceHost = FakeVmServiceHost(
            requests: <VmServiceExpectation>[
              ..._kAttachExpectations,
              FakeVmServiceRequest(
                method: kHotRestartServiceName,
                error: FakeRPCError(code: errorCode),
              ),
            ],
          );

          final (HotRunner runner, _) = createWebHotRunner();
          final connectionInfo = Completer<DebugConnectionInfo>();
          final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
          await connectionInfo.future;

          final OperationResult result = await runner.restart(fullRestart: true);
          expect(result.isOk, isTrue);
          expect(logger.statusText, contains(kNoClientConnectedMessage));
          expect(fakeAnalytics.sentEvents, isEmpty);
          expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);

          await runner.exit();
          expect(await runFuture, 0);
        },
      );
    }
  });

  group('shutdown and detach', () {
    testWithoutContext(
      'cleans up Chrome tab and DevFS when debugConnection.onDone completes',
      () async {
        final chromeConnection = FakeChromeConnection();
        final chromeTab = FakeChromeTab('http://localhost:8080/index.html');
        chromeConnection.tabs.add(chromeTab);
        final chromiumLauncher = TestChromiumLauncher();
        chromiumLauncher.setInstance(
          Chromium(
            1,
            chromeConnection,
            chromiumLauncher: chromiumLauncher,
            process: FakeProcess(),
            logger: logger,
          ),
        );
        final chromeDevice = GoogleChromeDevice(
          fileSystem: fileSystem,
          chromiumLauncher: chromiumLauncher,
          logger: logger,
          platform: FakePlatform(),
          processManager: FakeProcessManager.any(),
        );

        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner(device: chromeDevice);
        final connectionInfo = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
        await connectionInfo.future;

        debugConnection.completer.complete();
        expect(await runFuture, 0);
        expect(chromeTab.connection.wasClosed, isTrue);
        expect(fakeWebDevFS.wasDestroyed, isTrue);
      },
    );

    testWithoutContext(
      'keeps exit() idempotent without closing debugConnection and rejects post-exit restarts',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfo = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
        await connectionInfo.future;

        await runner.exit();
        await runner.exit();
        expect(await runFuture, 0);
        expect(fakeWebDevice.stopCount, 1);
        expect(debugConnection.didClose, isFalse);

        final OperationResult afterExit = await runner.restart();
        expect(afterExit.code, 1);
        expect(afterExit.message, 'Application has exited.');
      },
    );

    testWithoutContext(
      'leaves application running when detach() is followed by debugConnection.onDone or exit()',
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: _kAttachExpectations.toList());
        final (HotRunner runner, _) = createWebHotRunner();
        final connectionInfo = Completer<DebugConnectionInfo>();
        final Future<int> runFuture = runner.run(connectionInfoCompleter: connectionInfo);
        await connectionInfo.future;

        expect(fakeWebDevice.isRunning, isTrue);
        await runner.detach();
        expect(runner.stopAppDuringCleanup, isFalse);
        debugConnection.completer.complete();
        await runner.exit();
        await runner.cleanupAtFinish();

        expect(await runFuture, 0);
        expect(fakeWebDevice.isRunning, isTrue);
        expect(fakeWebDevice.stopCount, 0);
      },
    );
  });
}

class FakeWebDevice extends Fake implements WebDevice {
  @override
  String name = 'FakeWebDevice';

  @override
  String get displayName => name;

  @override
  Uri? devToolsUri;

  @override
  final DartDevelopmentService dds = FakeDartDevelopmentService();

  @override
  bool get supportsHotRestart => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get sdkNameAndVersion async => 'Flutter Tools';

  bool isRunning = false;
  int stopCount = 0;
  Map<String, Object?>? lastPlatformArgs;
  void Function()? onStartApp;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    onStartApp?.call();
    isRunning = true;
    lastPlatformArgs = platformArgs;
    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    if (stopCount > 0) {
      throw StateError('stopApp called more than once.');
    }
    stopCount += 1;
    isRunning = false;
    return true;
  }

  @override
  Future<void> dispose() async {}
}

class FakeChromeDevice extends FakeWebDevice implements ChromiumDevice {
  @override
  final ChromiumLauncher chromeLauncher = TestChromiumLauncher();
}

class FakeDebugConnection extends Fake implements DebugConnection {
  late FakeVmServiceHost Function() fakeVmServiceHost;

  @override
  vm_service.VmService get vmService => fakeVmServiceHost().vmService.service;

  @override
  late String uri;

  @override
  String? devToolsUri;

  @override
  String? dtdUri;

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

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  int rejectCount = 0;
  final addedFileSystemRoots = <String>[];

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
    rejectCount += 1;
    return const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void addFileSystemRoot(String root) {
    addedFileSystemRoots.add(root);
  }
}

class FakeWebDevFS extends Fake implements WebDevFS {
  FakeWebDevFS({this.defaultResultBuilder});

  final ConnectionResult Function()? defaultResultBuilder;
  bool autoConnect = true;
  Exception? exception;
  Error? error;
  final resultCompleter = Completer<ConnectionResult?>();
  ConnectionResult? result;
  late UpdateFSReport report;

  Uri? mainUri;
  bool wasMarkedReady = false;
  bool wasDestroyed = false;
  bool connectCalled = false;
  bool? lastUseDebugExtension;
  final resetCompilerHistory = <bool>[];
  final fullRestartHistory = <bool>[];

  @override
  List<Uri> sources = <Uri>[];

  @override
  Uri baseUri = Uri.parse('http://localhost:12345');

  @override
  DateTime? lastCompiled = DateTime(2000);

  @override
  PackageConfig? lastPackageConfig = PackageConfig.empty;

  @override
  final assetPathsToEvict = <String>{};

  @override
  final shaderPathsToEvict = <String>{};

  @override
  bool didUpdateFontManifest = false;

  @override
  bool hasSetAssetDirectory = false;

  @override
  bool useDwdsWebSocketConnection = false;

  @override
  Future<Uri> create() async => baseUri;

  @override
  void markReady() {
    wasMarkedReady = true;
  }

  @override
  Future<void> destroy() async {
    wasDestroyed = true;
  }

  @override
  void resetLastCompiled() {
    lastCompiled = null;
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
    resetCompilerHistory.add(resetCompiler);
    fullRestartHistory.add(fullRestart);
    return report;
  }

  @override
  Future<ConnectionResult?> connect(
    bool useDebugExtension, {
    VmServiceFactory vmServiceFactory = createVmServiceDelegate,
  }) async {
    connectCalled = true;
    lastUseDebugExtension = useDebugExtension;
    if (exception != null) {
      throw exception!;
    }
    if (error != null) {
      throw error!;
    }
    if (autoConnect && !resultCompleter.isCompleted) {
      final ConnectionResult? resolved = result ?? defaultResultBuilder?.call();
      if (resolved != null) {
        resultCompleter.complete(resolved);
      }
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
  Future<List<ChromeTab>> getTabs({Duration? retryFor}) async => tabs;

  @override
  void close() {}
}

class FakeChromeTab extends Fake implements ChromeTab {
  FakeChromeTab(this.url);

  @override
  final String url;

  final connection = FakeWipConnection();

  @override
  Future<WipConnection> connect({Function? onError}) async => connection;
}

class FakeWipConnection extends Fake implements WipConnection {
  bool wasClosed = false;

  @override
  Future<void> close() async {
    wasClosed = true;
  }
}

class TestChromiumLauncher implements ChromiumLauncher {
  var _hasInstance = false;

  void setInstance(Chromium chromium) {
    _hasInstance = true;
    currentCompleter.complete(chromium);
  }

  @override
  Completer<Chromium> currentCompleter = Completer<Chromium>();

  @override
  bool canFindExecutable() => true;

  @override
  Future<Chromium> get connectedInstance => currentCompleter.future;

  @override
  String findExecutable() => 'chrome';

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
  Future<Chromium> connect(Chromium chrome, bool skipCheck) => currentCompleter.future;
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(TargetPlatform? platform) {}

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }

  @override
  bool areDependenciesModified(DevFSContent shaderContent) => false;
}

class FakeDartDevelopmentService extends Fake implements DartDevelopmentService {
  int handleHotRestartCount = 0;

  @override
  Future<void> handleHotRestart(FlutterDevice? device) async {
    handleHotRestartCount += 1;
  }

  @override
  Future<void> shutdown() async {}
}

class FakeCapturingAssetBundle extends Fake implements AssetBundle {
  String? lastNeedsBuildManifestPath;
  String? lastBuildManifestPath;
  String? lastFlavor;

  @override
  bool wasBuiltOnce() => false;

  @override
  bool needsBuild({String manifestPath = defaultManifestPath}) {
    lastNeedsBuildManifestPath = manifestPath;
    return true;
  }

  @override
  Future<int> build({
    FlutterHookResult? flutterHookResult,
    String manifestPath = defaultManifestPath,
    required String packageConfigPath,
    bool deferredComponentsEnabled = false,
    required TargetPlatform targetPlatform,
    String? flavor,
    bool includeAssetsFromDevDependencies = false,
  }) async {
    lastBuildManifestPath = manifestPath;
    lastFlavor = flavor;
    return 0;
  }
}

class FakeAssetBundleFactory implements AssetBundleFactory {
  final bundle = FakeCapturingAssetBundle();

  @override
  AssetBundle createBundle() => bundle;
}
