// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/fakes.dart';
import '../../../src/test_build_system.dart';
import '../../../src/test_flutter_command_runner.dart';
import '../utils/project_testing_utils.dart';

class FakeWidgetPreviewScaffoldDtdServices extends Fake implements WidgetPreviewDtdServices {
  @override
  Future<void> connect({required Uri dtdWsUri}) async {
    dtdUri = dtdWsUri;
  }

  @override
  DtdLauncher get dtdLauncher => throw UnimplementedError();

  @override
  Uri? dtdUri;

  @override
  final String widgetPreviewService = WidgetPreviewDtdServices.kWidgetPreviewServiceRoot;

  @override
  final String widgetPreviewScaffoldStream =
      WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot;

  @override
  Future<void> launchAndConnect({required AnalysisServer analysisServer}) async {
    dtdUri = Uri.parse('ws://localhost:1234');
  }

  @override
  Future<void> waitForAnalysis({Duration delay = const Duration(milliseconds: 100)}) async {}

  @override
  void setDevToolsServerAddress({
    required Uri devToolsServerAddress,
    required Uri applicationUri,
  }) {}

  FlutterWidgetPreviews? nextUpdate;
  bool shouldThrow = false;

  @override
  Future<FlutterWidgetPreviews> getFlutterWidgetPreviews() async {
    if (shouldThrow) {
      throw RpcException(123, 'Fake RPC Exception');
    }
    return nextUpdate ??
        const FlutterWidgetPreviews(
          namespaces: <String, String>{},
          previews: <FlutterWidgetPreviewDetails>[],
          scriptUris: <Uri>[],
        );
  }
}

class FakeTerminal extends Fake implements AnsiTerminal {}

class FakeAnalysisServer extends Fake implements AnalysisServer {
  @override
  String get sdkPath => 'fake/sdk';

  @override
  List<String> get directories => <String>[];

  @override
  Future<void> start() async {}

  @override
  Future<void> connectToDtd({required Uri dtdUri}) async {}

  @override
  Future<bool?> dispose() async => true;

  @override
  Stream<bool> get onAnalyzing => const Stream<bool>.empty();

  bool waitForAnalysisCalled = false;

  @override
  Future<void> waitForAnalysis({Duration delay = const Duration(milliseconds: 100)}) async {
    waitForAnalysisCalled = true;
  }
}

class FakeGoogleChromeDevice extends Fake implements GoogleChromeDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  PlatformType? get platformType => PlatformType.web;

  @override
  String get displayName => GoogleChromeDevice.kChromeDeviceName;
}

class FakeMicrosoftEdgeDevice extends Fake implements MicrosoftEdgeDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  PlatformType? get platformType => PlatformType.web;

  @override
  String get displayName => MicrosoftEdgeDevice.kEdgeDeviceName;
}

class FakeCustomBrowserDevice extends Fake implements ChromiumDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  PlatformType? get platformType => PlatformType.web;

  @override
  String get displayName => 'Dartium';
}

class FakeResidentRunner extends Fake implements ResidentRunner {
  FakeResidentRunner({this.waitForAppToFinishCompleter});

  final Completer<int>? waitForAppToFinishCompleter;
  int restartCount = 0;
  int concurrentRestarts = 0;
  int maxConcurrentRestarts = 0;
  final fullRestartRequests = <bool>[];
  Completer<OperationResult>? currentRestartCompleter;
  Completer<void>? appStartedCompleter;
  Completer<DebugConnectionInfo>? connectionInfoCompleter;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    String? route,
  }) async {
    this.connectionInfoCompleter = connectionInfoCompleter;
    this.appStartedCompleter = appStartedCompleter;
    appStartedCompleter?.complete();
    return 0;
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool? pause = false,
    String? reason,
    bool benchmarkMode = false,
  }) async {
    restartCount++;
    fullRestartRequests.add(fullRestart);
    concurrentRestarts++;
    if (concurrentRestarts > maxConcurrentRestarts) {
      maxConcurrentRestarts = concurrentRestarts;
    }
    if (currentRestartCompleter != null) {
      await currentRestartCompleter!.future;
    }
    concurrentRestarts--;
    return OperationResult.ok;
  }

  @override
  Future<int> waitForAppToFinish() async {
    if (waitForAppToFinishCompleter != null) {
      return waitForAppToFinishCompleter!.future;
    }
    return 0;
  }

  @override
  Future<void> exitApp() async {}
}

class FakeDevFS extends Fake implements DevFS {
  @override
  Uri get baseUri => Uri.parse('http://localhost:1234');
}

extension on String {
  String get stripScriptUris =>
      replaceAll(RegExp(r"scriptUri:\s*'file:\/\/\/\S*',"), "scriptUri: 'STRIPPED',");
}

void main() {
  late Directory originalCwd;
  late Directory tempDir;
  late LoggingProcessManager loggingProcessManager;
  late ShutdownHooks shutdownHooks;
  late FakeStdio mockStdio;
  late Logger logger;
  // We perform this initialization just so we can build the generated file path for test
  // descriptions.
  var fs = LocalFileSystem.test(signals: Signals.test());
  late BotDetector botDetector;
  late Platform platform;
  late FakeDeviceManager fakeDeviceManager;
  late FakeAnalytics fakeAnalytics;
  late FakeGoogleChromeDevice fakeGoogleChromeDevice;
  late FakeMicrosoftEdgeDevice fakeMicrosoftEdgeDevice;
  late FakeCustomBrowserDevice fakeCustomBrowserDevice;
  late FakeWidgetPreviewScaffoldDtdServices fakeDtdServices;
  late String flutterRoot;

  setUp(() async {
    Cache.disableLocking();
    fs = LocalFileSystem.test(signals: Signals.test());
    originalCwd = fs.currentDirectory;
    await ensureFlutterToolsSnapshot();
    loggingProcessManager = LoggingProcessManager();
    shutdownHooks = ShutdownHooks();
    mockStdio = FakeStdio();
    logger = WidgetPreviewMachineAwareLogger(
      BufferLogger.test(),
      machine: false,
      stdio: mockStdio,
      verbose: false,
    );
    flutterRoot = fs.path.absolute('..', '..');
    botDetector = const FakeBotDetector(false);
    tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
    platform = FakePlatform.fromPlatform(const LocalPlatform());

    fakeGoogleChromeDevice = FakeGoogleChromeDevice();
    fakeMicrosoftEdgeDevice = FakeMicrosoftEdgeDevice();
    fakeCustomBrowserDevice = FakeCustomBrowserDevice();
    fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();

    // Create a fake device manager which only contains a single Chrome device.
    fakeDeviceManager = FakeDeviceManager()
      ..addAttachedDevice(fakeGoogleChromeDevice)
      ..addAttachedDevice(fakeMicrosoftEdgeDevice)
      ..addAttachedDevice(fakeCustomBrowserDevice);

    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: MemoryFileSystem.test(),
      fakeFlutterVersion: FakeFlutterVersion(),
    );
  });

  tearDown(() async {
    await shutdownHooks.runShutdownHooks(logger);
    tryToDelete(tempDir);
    fs.currentDirectory = originalCwd;
    await fs.dispose();
  });

  FakeToolContext createToolContext() => FakeToolContext(
    artifacts: Artifacts.test(),
    botDetector: botDetector,
    cache: Cache.test(
      flutterRoot: flutterRoot,
      rootOverride: fs.directory(flutterRoot),
      fileSystem: fs,
      processManager: loggingProcessManager,
      platform: platform,
    ),
    fs: fs,
    logger: logger,
    os: OperatingSystemUtils(
      fileSystem: fs,
      processManager: loggingProcessManager,
      logger: logger,
      platform: platform,
    ),
    platform: platform,
    processManager: loggingProcessManager,
    projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs, config: FakeConfig()),
    shutdownHooks: shutdownHooks,
    stdio: mockStdio,
    terminal: FakeTerminal(),
  );

  Pub createPub() => Pub.test(
    flutterRoot: flutterRoot,
    fileSystem: fs,
    logger: logger,
    processManager: loggingProcessManager,
    botDetector: botDetector,
    platform: platform,
    stdio: mockStdio,
  );

  Future<Directory> createRootProject() async {
    return fs.directory(
      await createProject(tempDir, arguments: <String>['--pub'], toolContext: createToolContext()),
    );
  }

  WidgetPreviewCommand createWidgetPreviewCommand({
    required Pub pub,
    required FakeToolContext toolContext,
    DeviceManager? deviceManager,
    Future<AnalysisServer> Function()? analysisServerFactoryOverride,
    ResidentRunnerFactory? residentRunnerFactoryOverride,
  }) {
    return WidgetPreviewCommand(
      assetBundleFactory: AssetBundleFactory.defaultInstance(
        fileSystem: fs,
        flutterRoot: flutterRoot,
        logger: logger,
        platform: platform,
      ),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      buildTargets: const BuildTargetsImpl(),
      deviceManager: deviceManager ?? fakeDeviceManager,
      pub: pub,
      templatePathProvider: TemplatePathProvider(flutterRoot: flutterRoot),
      toolContext: toolContext,
      dtdServicesOverride: fakeDtdServices,
      analysisServerFactoryOverride:
          analysisServerFactoryOverride ?? () async => FakeAnalysisServer(),
      residentRunnerFactoryOverride: residentRunnerFactoryOverride,
    );
  }

  Future<void> runWidgetPreviewCommand(
    List<String> arguments, {
    FeatureFlags? featureFlags,
    Future<AnalysisServer> Function()? analysisServerFactoryOverride,
    ResidentRunnerFactory? residentRunnerFactoryOverride,
  }) async {
    final FakeToolContext toolContext = createToolContext();
    final Pub pub = createPub();
    final runner = TestFlutterCommandRunner(
      analytics: fakeAnalytics,
      deviceManager: fakeDeviceManager,
      featureFlags: featureFlags ?? TestFeatureFlags(isWebEnabled: true),
      pub: pub,
      templatePathProvider: TemplatePathProvider(flutterRoot: flutterRoot),
      toolContext: toolContext,
    );
    runner.addCommand(
      createWidgetPreviewCommand(
        deviceManager: runner.deviceManager,
        pub: pub,
        toolContext: toolContext,
        analysisServerFactoryOverride: analysisServerFactoryOverride,
        residentRunnerFactoryOverride: residentRunnerFactoryOverride,
      ),
    );
    await runner.run(<String>['widget-preview', ...arguments]);
  }

  void expectNPreviewLaunchTimingEvents(int n) {
    final Iterable<Event> launchTimingEvent = fakeAnalytics.sentEvents.where(
      (Event e) =>
          e.eventData['workflow'] == WidgetPreviewAnalytics.kWorkflow &&
          e.eventData['variableName'] == WidgetPreviewAnalytics.kLaunchTime,
    );
    expect(launchTimingEvent, hasLength(n));
  }

  void expectNoPreviewLaunchTimingEvents() => expectNPreviewLaunchTimingEvents(0);
  void expectSinglePreviewLaunchTimingEvent() => expectNPreviewLaunchTimingEvents(1);

  void expectDeviceSelected(Device device) {
    final BufferLogger bufferLogger = asLogger<BufferLogger>(logger);
    expect(
      bufferLogger.statusText,
      contains('Launching the Widget Preview Scaffold on ${device.displayName}...'),
    );
  }

  Future<void> startWidgetPreview({
    required Directory? rootProject,
    List<String>? arguments,
    FeatureFlags? featureFlags,
    bool legacyDetection = false,
    Future<AnalysisServer> Function()? analysisServerFactoryOverride,
  }) async {
    // This might get changed during the test, so keep track of the original directory.
    final Directory current = fs.currentDirectory;
    await runWidgetPreviewCommand(
      <String>[
        'start',
        if (legacyDetection) '--legacy-preview-detection',
        ...?arguments,
        '--no-launch-previewer',
        '--verbose',
        ?rootProject?.path,
      ],
      featureFlags: featureFlags,
      analysisServerFactoryOverride: analysisServerFactoryOverride,
    );
    final Directory projectDir = rootProject ?? current;
    final FlutterProject project = FlutterProjectFactory(
      logger: logger,
      fileSystem: fs,
      config: FakeConfig(),
    ).fromDirectory(projectDir);
    final Directory scaffoldDir = (project.workspaceRoot ?? project).widgetPreviewScaffold;
    await analyzeProject(scaffoldDir.path);
    fs.currentDirectory = current;
  }

  Future<void> cleanWidgetPreview({required Directory rootProject}) async {
    var retries = 5;
    var delay = const Duration(milliseconds: 100);
    while (true) {
      try {
        await runWidgetPreviewCommand(<String>['clean', rootProject.path]);
        break;
      } on Exception catch (_) {
        retries--;
        if (retries <= 0) {
          rethrow;
        }
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
    expect(fs.directory(rootProject).childDirectory('.widget_preview'), isNot(exists));
  }

  group('flutter widget-preview', () {
    group('start exits if', () {
      test('DTD fails to retrieve widget previews', () async {
        final Directory rootProject = await createRootProject();
        fakeDtdServices.shouldThrow = true;
        try {
          await startWidgetPreview(rootProject: rootProject);
          fail('Successfully executed despite DTD failure.');
        } on ToolExit catch (e) {
          expect(
            e.message,
            contains('Failed to retrieve widget previews from the Dart Tooling Daemon (DTD)'),
          );
        }
        expectNoPreviewLaunchTimingEvents();
      });

      test('given an invalid directory', () async {
        try {
          await runWidgetPreviewCommand(<String>['start', 'foo']);
          fail('Successfully executed with multiple project paths');
        } on ToolExit catch (e) {
          expect(e.message, contains('Could not find foo'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      test('more than one project directory is provided', () async {
        try {
          await runWidgetPreviewCommand(<String>['start', tempDir.path, tempDir.path]);
          fail('Successfully executed with multiple project paths');
        } on ToolExit catch (e) {
          expect(e.message, contains('Only one directory should be provided.'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      test('run outside of a Flutter project directory', () async {
        try {
          await startWidgetPreview(rootProject: tempDir);
          fail('Successfully executed outside of a Flutter project directory');
        } on ToolExit catch (e) {
          expect(e.message, contains('${tempDir.path} is not a valid Flutter project.'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      test('Flutter Web is disabled', () async {
        try {
          await startWidgetPreview(
            rootProject: await createRootProject(),
            featureFlags: TestFeatureFlags(),
          );
          fail('Successfully executed with Flutter Web disabled.');
        } on ToolExit catch (e) {
          expect(
            e.message,
            'Error: Widget Previews requires Flutter Web to be enabled. Please run '
            "'flutter config --enable-web' to enable Flutter Web and try again.",
          );
        }
        expectNoPreviewLaunchTimingEvents();
      });
    });

    group('workspaces', () {
      test('starts from workspace root when run from member package', () async {
        final File workspacePubspec = tempDir.childFile('pubspec.yaml');
        workspacePubspec.writeAsStringSync('''
name: my_workspace
environment:
  sdk: '>=3.0.0 <4.0.0'
workspace:
  - my_app
''');

        final String memberProjectPath = await createProject(
          tempDir,
          name: 'my_app',
          arguments: <String>['--pub'],
          toolContext: createToolContext(),
        );
        final Directory memberProjectDir = fs.directory(memberProjectPath);

        final File memberPubspec = memberProjectDir.childFile('pubspec.yaml');
        final String memberPubspecContent = memberPubspec.readAsStringSync();
        memberPubspec.writeAsStringSync('''
$memberPubspecContent
resolution: workspace
''');

        fs.currentDirectory = memberProjectDir;

        await startWidgetPreview(rootProject: null);
        final Directory workspaceScaffoldDir = tempDir.childDirectory('.widget_preview');
        final Directory memberScaffoldDir = memberProjectDir.childDirectory('.widget_preview');

        expect(workspaceScaffoldDir, exists);
        expect(memberScaffoldDir, isNot(exists));

        await cleanWidgetPreview(rootProject: tempDir);
      });
    });

    test('start succeeds when no .dart_tool/ directory exists', () async {
      // Regression test for https://github.com/flutter/flutter/issues/178052
      final Directory rootProject = await createRootProject();
      rootProject.childDirectory('.dart_tool').deleteSync(recursive: true);
      await startWidgetPreview(rootProject: rootProject);
      expectSinglePreviewLaunchTimingEvent();
    });

    test('start creates .widget_preview', () async {
      final Directory rootProject = await createRootProject();
      await startWidgetPreview(rootProject: rootProject);
      expectSinglePreviewLaunchTimingEvent();
    });

    test(
      'start copies host web directory to scaffold if it exists and removes stale files',
      () async {
        final Directory rootProject = await createRootProject();
        final Directory hostWebDir = rootProject.childDirectory('web')..createSync();
        hostWebDir.childFile('index.html').writeAsStringSync('<html>custom index</html>');
        final File staleFile = hostWebDir.childFile('stale.js')
          ..writeAsStringSync('console.log("stale");');

        await startWidgetPreview(rootProject: rootProject);

        final Directory scaffoldWebDir = rootProject
            .childDirectory('.widget_preview')
            .childDirectory('web');
        expect(scaffoldWebDir.existsSync(), true);
        expect(
          scaffoldWebDir.childFile('index.html').readAsStringSync(),
          '<html>custom index</html>',
        );
        expect(scaffoldWebDir.childFile('stale.js').readAsStringSync(), 'console.log("stale");');
        expectSinglePreviewLaunchTimingEvent();

        // Now remove stale.js from host, and add a new file.
        staleFile.deleteSync();
        hostWebDir.childFile('new.js').writeAsStringSync('console.log("new");');

        // Run again
        await startWidgetPreview(rootProject: rootProject);

        expect(scaffoldWebDir.childFile('stale.js').existsSync(), false);
        expect(scaffoldWebDir.childFile('new.js').readAsStringSync(), 'console.log("new");');
        expect(
          scaffoldWebDir.childFile('index.html').readAsStringSync(),
          '<html>custom index</html>',
        );
        expectNPreviewLaunchTimingEvents(2);
      },
    );

    test('start waits for analysis to complete', () async {
      final Directory rootProject = await createRootProject();
      final fakeAnalysisServer = FakeAnalysisServer();

      await startWidgetPreview(
        rootProject: rootProject,
        analysisServerFactoryOverride: () async => fakeAnalysisServer,
      );

      expect(fakeAnalysisServer.waitForAnalysisCalled, isTrue);
    });

    test('start creates .widget_preview in the CWD', () async {
      final Directory rootProject = await createRootProject();
      // Try to execute using the CWD.
      fs.currentDirectory = rootProject;
      await startWidgetPreview(rootProject: null);
      expectSinglePreviewLaunchTimingEvent();
    });

    const samplePreviewFile = '''
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

@Preview(name: 'preview')
Widget preview() => Text('Foo');''';

    const expectedGeneratedFileContents = '''
// ignore_for_file: implementation_imports
// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'widget_preview.dart' as _i1;
import 'utils.dart' as _i2;
import 'package:flutter_project/foo.dart' as _i3;
import 'package:flutter/src/widget_previews/widget_previews.dart' as _i4;

List<_i1.WidgetPreview> previews() => [
  _i2.buildWidgetPreview(
    packageName: 'flutter_project',
    scriptUri: 'STRIPPED',
    line: 4,
    column: 1,
    previewFunction: () => _i3.preview(),
    transformedPreview: const _i4.Preview(name: 'preview').transform(),
  ),
];
''';

    group('LSP-based preview detection', () {
      test(
        'start finds existing previews and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          fakeDtdServices.nextUpdate = FlutterWidgetPreviews(
            namespaces: <String, String>{
              'widget_preview.dart': '_i1',
              'utils.dart': '_i2',
              'package:flutter_project/foo.dart': '_i3',
              'package:flutter/src/widget_previews/widget_previews.dart': '_i4',
            },
            previews: <FlutterWidgetPreviewDetails>[
              FlutterWidgetPreviewDetails(
                functionName: 'preview',
                hasError: false,
                dependencyHasErrors: false,
                isBuilder: false,
                isMultiPreview: false,
                packageName: 'flutter_project',
                position: const Position(character: 1, line: 4),
                previewAnnotation: "const _i4.Preview(name: 'preview')",
                scriptUri: Uri.file('/user/flutter_project/lib/foo.dart'),
                libraryUri: Uri.parse('package:flutter_project/foo.dart'),
              ),
            ],
            scriptUris: <Uri>[rootProject.childDirectory('lib').childFile('foo.dart').uri],
          );

          await startWidgetPreview(rootProject: rootProject);

          final File generatedFile = rootProject
              .childDirectory('.widget_preview')
              .childFile(PreviewCodeGenerator.getGeneratedPreviewFilePath(fs));

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
      );

      test(
        'start finds existing previews in the CWD and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          fakeDtdServices.nextUpdate = FlutterWidgetPreviews(
            namespaces: <String, String>{
              'widget_preview.dart': '_i1',
              'utils.dart': '_i2',
              'package:flutter_project/foo.dart': '_i3',
              'package:flutter/src/widget_previews/widget_previews.dart': '_i4',
            },
            previews: <FlutterWidgetPreviewDetails>[
              FlutterWidgetPreviewDetails(
                functionName: 'preview',
                hasError: false,
                dependencyHasErrors: false,
                isBuilder: false,
                isMultiPreview: false,
                packageName: 'flutter_project',
                position: const Position(character: 1, line: 4),
                previewAnnotation: "const _i4.Preview(name: 'preview')",
                scriptUri: Uri.file('/user/flutter_project/lib/foo.dart'),
                libraryUri: Uri.parse('package:flutter_project/foo.dart'),
              ),
            ],
            scriptUris: <Uri>[rootProject.childDirectory('lib').childFile('foo.dart').uri],
          );

          // Try to execute using the CWD.
          fs.currentDirectory = rootProject;
          await startWidgetPreview(rootProject: null);

          final File generatedFile = rootProject
              .childDirectory('.widget_preview')
              .childFile(PreviewCodeGenerator.getGeneratedPreviewFilePath(fs));

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
      );

      test(
        'start finds existing previews in the provided directory and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          fakeDtdServices.nextUpdate = FlutterWidgetPreviews(
            namespaces: <String, String>{
              'widget_preview.dart': '_i1',
              'utils.dart': '_i2',
              'package:flutter_project/foo.dart': '_i3',
              'package:flutter/src/widget_previews/widget_previews.dart': '_i4',
            },
            previews: <FlutterWidgetPreviewDetails>[
              FlutterWidgetPreviewDetails(
                functionName: 'preview',
                hasError: false,
                dependencyHasErrors: false,
                isBuilder: false,
                isMultiPreview: false,
                packageName: 'flutter_project',
                position: const Position(character: 1, line: 4),
                previewAnnotation: "const _i4.Preview(name: 'preview')",
                scriptUri: Uri.file('/user/flutter_project/lib/foo.dart'),
                libraryUri: Uri.parse('package:flutter_project/foo.dart'),
              ),
            ],
            scriptUris: <Uri>[rootProject.childDirectory('lib').childFile('foo.dart').uri],
          );

          await startWidgetPreview(rootProject: rootProject);
          expectSinglePreviewLaunchTimingEvent();
        },
      );
    });

    group('Legacy preview detection', () {
      test(
        'start finds existing previews and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          await startWidgetPreview(rootProject: rootProject, legacyDetection: true);

          final File generatedFile = rootProject
              .childDirectory('.widget_preview')
              .childFile(PreviewCodeGenerator.getGeneratedPreviewFilePath(fs));

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
      );

      test(
        'start finds existing previews in the CWD and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          // Try to execute using the CWD.
          fs.currentDirectory = rootProject;
          await startWidgetPreview(rootProject: null, legacyDetection: true);

          final File generatedFile = rootProject
              .childDirectory('.widget_preview')
              .childFile(PreviewCodeGenerator.getGeneratedPreviewFilePath(fs));

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
      );

      test(
        'start finds existing previews in the provided directory and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          await startWidgetPreview(rootProject: rootProject, legacyDetection: true);

          final File generatedFile = rootProject
              .childDirectory('.widget_preview')
              .childFile(PreviewCodeGenerator.getGeneratedPreviewFilePath(fs));

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
      );
    });

    test('invokes pub in online and offline modes', () async {
      // Run pub online first in order to populate the pub cache.
      final Directory rootProject = await createRootProject();
      loggingProcessManager.clear();

      final dartCommand = RegExp(r'dart-sdk[\\/]bin[\\/]dart');

      await startWidgetPreview(rootProject: rootProject);
      expect(
        loggingProcessManager.commands,
        contains(
          predicate(
            (List<String> c) =>
                dartCommand.hasMatch(c[0]) && c[1].contains('pub') && !c.contains('--offline'),
          ),
        ),
      );

      await cleanWidgetPreview(rootProject: rootProject);

      // Run pub offline.
      loggingProcessManager.clear();
      await startWidgetPreview(rootProject: rootProject, arguments: <String>['--pub', '--offline']);

      expect(
        loggingProcessManager.commands,
        contains(
          predicate(
            (List<String> c) =>
                dartCommand.hasMatch(c[0]) && c[1].contains('pub') && c.contains('--offline'),
          ),
        ),
      );
    });

    test('start exits if no web target is available.', () async {
      // Regression test for https://github.com/flutter/flutter/issues/173960.
      fakeDeviceManager.attachedDevices.clear();
      final Directory rootProject = await createRootProject();
      await expectToolExitLater(
        startWidgetPreview(rootProject: rootProject),
        contains(WidgetPreviewStartCommand.kBrowserNotFoundErrorMessage),
      );
    });

    test('always starts with Chrome when available.', () async {
      fakeDeviceManager
        ..attachedDevices.clear()
        ..addAttachedDevice(fakeMicrosoftEdgeDevice)
        // Register the Chrome device second to ensure we're not just grabbing the first device.
        ..addAttachedDevice(fakeGoogleChromeDevice);
      final Directory rootProject = await createRootProject();
      await startWidgetPreview(rootProject: rootProject);
      expectDeviceSelected(fakeGoogleChromeDevice);
    });

    test('starts with Edge if Chrome is not available.', () async {
      fakeDeviceManager
        ..attachedDevices.clear()
        ..addAttachedDevice(fakeMicrosoftEdgeDevice);
      final Directory rootProject = await createRootProject();
      await startWidgetPreview(rootProject: rootProject);
      expectDeviceSelected(fakeMicrosoftEdgeDevice);
    });

    test('serializes, coalesces, and gates reloads across previewer lifecycle', () async {
      final Directory rootProject = await createRootProject();
      final fakeResidentRunner = FakeResidentRunner(waitForAppToFinishCompleter: Completer<int>());

      final FakeToolContext toolContext = createToolContext();
      final Pub pub = createPub();
      final CommandRunner<void> runner = createTestCommandRunner(
        createWidgetPreviewCommand(
          pub: pub,
          toolContext: toolContext,
          residentRunnerFactoryOverride:
              (
                FlutterDevice device, {
                required DebuggingOptions debuggingOptions,
                required FlutterProject flutterProject,
                required String projectRootPath,
                required String target,
              }) {
                device.devFS = FakeDevFS();
                return fakeResidentRunner;
              },
        ),
        fakeAnalytics,
        toolContext,
        TestFeatureFlags(isWebEnabled: true),
        pub,
      );

      final startCommand =
          runner.commands['widget-preview']!.subcommands['start']! as WidgetPreviewStartCommand;

      void triggerChange() {
        startCommand.onChangeDetected(
          FlutterWidgetPreviews(
            namespaces: const <String, String>{},
            previews: const <FlutterWidgetPreviewDetails>[],
            scriptUris: <Uri>[Uri.file(fs.path.join(rootProject.path, 'lib', 'main.dart'))],
          ),
        );
      }

      final Future<void> runFuture = runner.run(<String>[
        'widget-preview',
        'start',
        rootProject.path,
      ]);

      while (fakeResidentRunner.appStartedCompleter == null) {
        await pumpEventQueue();
      }
      await fakeResidentRunner.appStartedCompleter!.future;

      // 1. Trigger a change while the previewer is still waiting for the debug
      // connection. Reload must be gated until the connection is established.
      triggerChange();
      await pumpEventQueue();
      expect(fakeResidentRunner.restartCount, 0);

      fakeResidentRunner.connectionInfoCompleter!.complete(
        DebugConnectionInfo(
          wsUri: Uri.parse('ws://127.0.0.1:1234/ws'),
          devToolsUri: Uri.parse('http://127.0.0.1:1234/devtools'),
        ),
      );
      await pumpEventQueue();
      expect(fakeResidentRunner.restartCount, 1);

      // 2. Coalesce multiple rapid file changes while a reload is in flight.
      final inFlightRestartCompleter = Completer<OperationResult>();
      fakeResidentRunner.currentRestartCompleter = inFlightRestartCompleter;

      triggerChange();
      await pumpEventQueue();
      expect(fakeResidentRunner.restartCount, 2);
      expect(fakeResidentRunner.concurrentRestarts, 1);

      for (var i = 0; i < 3; i++) {
        triggerChange();
      }
      await pumpEventQueue();
      expect(fakeResidentRunner.maxConcurrentRestarts, 1);
      expect(fakeResidentRunner.restartCount, 2);

      fakeResidentRunner.currentRestartCompleter = null;
      inFlightRestartCompleter.complete(OperationResult.ok);
      await pumpEventQueue();

      expect(fakeResidentRunner.restartCount, 3);
      expect(fakeResidentRunner.maxConcurrentRestarts, 1);
      expect(fakeResidentRunner.fullRestartRequests, <bool>[false, false, false]);

      // 3. Upgrade a queued hot reload to a hot restart without downgrading on
      // a subsequent hot reload.
      final secondInFlightCompleter = Completer<OperationResult>();
      fakeResidentRunner.currentRestartCompleter = secondInFlightCompleter;

      triggerChange();
      await pumpEventQueue();
      expect(fakeResidentRunner.restartCount, 4);

      triggerChange();
      startCommand.onHotRestartRequest();
      triggerChange();

      fakeResidentRunner.currentRestartCompleter = null;
      secondInFlightCompleter.complete(OperationResult.ok);
      await pumpEventQueue();

      expect(fakeResidentRunner.restartCount, 5);
      expect(fakeResidentRunner.maxConcurrentRestarts, 1);
      expect(fakeResidentRunner.fullRestartRequests, <bool>[false, false, false, false, true]);

      // 4. Ignore reload requests after the previewer has finished.
      fakeResidentRunner.waitForAppToFinishCompleter!.complete(0);
      await runFuture;

      triggerChange();
      await pumpEventQueue();
      expect(fakeResidentRunner.restartCount, 5);
    });
  });
}
