// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
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
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';
import '../../../src/test_flutter_command_runner.dart';
import '../utils/project_testing_utils.dart';

class FakeWidgetPreviewScaffoldDtdServices extends Fake implements WidgetPreviewDtdServices {
  @override
  Future<void> connect({required Uri dtdWsUri}) async {}

  @override
  DtdLauncher get dtdLauncher => throw UnimplementedError();

  @override
  Uri? get dtdUri => Uri.parse('ws://localhost:1234');

  @override
  bool get lspServiceAvailable => false;

  @override
  final String widgetPreviewService = WidgetPreviewDtdServices.kWidgetPreviewServiceRoot;

  @override
  final String widgetPreviewScaffoldStream =
      WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot;

  @override
  Future<void> launchAndConnect({required AnalysisServer analysisServer}) async {}

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

class FakeTerminal extends Fake implements Terminal {}

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

  setUp(() async {
    Cache.disableLocking();
    originalCwd = globals.fs.currentDirectory;
    await ensureFlutterToolsSnapshot();
    loggingProcessManager = LoggingProcessManager();
    shutdownHooks = ShutdownHooks();
    logger = WidgetPreviewMachineAwareLogger(BufferLogger.test(), machine: false, verbose: false);
    fs = LocalFileSystem.test(signals: Signals.test());
    botDetector = const FakeBotDetector(false);
    tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
    mockStdio = FakeStdio();
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

    // Most, but not all, tests will run some variant of "pub get" after creation,
    // which in turn will check for the presence of the Flutter SDK root. Without
    // this field set consistently, the order of the tests becomes important *or*
    // you need to remember to set it everywhere.
    Cache.flutterRoot = fs.path.absolute('..', '..');
  });

  tearDown(() async {
    await shutdownHooks.runShutdownHooks(logger);
    tryToDelete(tempDir);
    await fs.dispose();
    globals.fs.currentDirectory = originalCwd;
  });

  Future<Directory> createRootProject() async {
    return fs.directory(await createProject(tempDir, arguments: <String>['--pub']));
  }

  Future<void> runWidgetPreviewCommand(
    List<String> arguments, {
    Future<AnalysisServer> Function()? analysisServerFactoryOverride,
    ResidentRunnerFactory? residentRunnerFactoryOverride,
  }) async {
    final CommandRunner<void> runner = createTestCommandRunner(
      WidgetPreviewCommand(
        verboseHelp: false,
        logger: logger,
        fs: fs,
        projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs),
        cache: Cache.test(processManager: loggingProcessManager, platform: platform),
        platform: platform,
        shutdownHooks: shutdownHooks,
        os: OperatingSystemUtils(
          fileSystem: fs,
          processManager: loggingProcessManager,
          logger: logger,
          platform: platform,
        ),
        artifacts: Artifacts.test(),
        processManager: loggingProcessManager,
        terminal: FakeTerminal(),
        dtdServicesOverride: fakeDtdServices,
        analysisServerFactoryOverride:
            analysisServerFactoryOverride ?? () async => FakeAnalysisServer(),
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
    bool legacyDetection = false,
    Future<AnalysisServer> Function()? analysisServerFactoryOverride,
  }) async {
    // This might get changed during the test, so keep track of the original directory.
    final Directory current = fs.currentDirectory;
    await runWidgetPreviewCommand(<String>[
      'start',
      if (legacyDetection) '--legacy-preview-detection',
      ...?arguments,
      '--no-launch-previewer',
      '--verbose',
      ?rootProject?.path,
    ], analysisServerFactoryOverride: analysisServerFactoryOverride);
    await analyzeProject(WidgetPreviewStartCommand.widgetPreviewScaffold.path);
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
      testUsingContext(
        'DTD fails to retrieve widget previews',
        () async {
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
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext('given an invalid directory', () async {
        try {
          await runWidgetPreviewCommand(<String>['start', 'foo']);
          fail('Successfully executed with multiple project paths');
        } on ToolExit catch (e) {
          expect(e.message, contains('Could not find foo'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      testUsingContext('more than one project directory is provided', () async {
        try {
          await runWidgetPreviewCommand(<String>['start', tempDir.path, tempDir.path]);
          fail('Successfully executed with multiple project paths');
        } on ToolExit catch (e) {
          expect(e.message, contains('Only one directory should be provided.'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      testUsingContext('run outside of a Flutter project directory', () async {
        try {
          await startWidgetPreview(rootProject: tempDir);
          fail('Successfully executed outside of a Flutter project directory');
        } on ToolExit catch (e) {
          expect(e.message, contains('${tempDir.path} is not a valid Flutter project.'));
        }
        expectNoPreviewLaunchTimingEvents();
      });

      testUsingContext(
        'Flutter Web is disabled',
        () async {
          try {
            await startWidgetPreview(rootProject: await createRootProject());
            fail('Successfully executed with Flutter Web disabled.');
          } on ToolExit catch (e) {
            expect(
              e.message,
              'Error: Widget Previews requires Flutter Web to be enabled. Please run '
              "'flutter config --enable-web' to enable Flutter Web and try again.",
            );
          }
          expectNoPreviewLaunchTimingEvents();
        },
        overrides: {
          FeatureFlags: () => TestFeatureFlags(
            // ignore: avoid_redundant_argument_values, readability
            isWebEnabled: false,
          ),
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );
    });

    group('workspaces', () {
      testUsingContext(
        'starts from workspace root when run from member package',
        () async {
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
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );
    });

    testUsingContext(
      'start succeeds when no .dart_tool/ directory exists',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/178052
        final Directory rootProject = await createRootProject();
        rootProject.childDirectory('.dart_tool').deleteSync(recursive: true);
        await startWidgetPreview(rootProject: rootProject);
        expectSinglePreviewLaunchTimingEvent();
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'start creates .dart_tool/widget_preview_scaffold',
      () async {
        final Directory rootProject = await createRootProject();
        await startWidgetPreview(rootProject: rootProject);
        expectSinglePreviewLaunchTimingEvent();
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'start copies host web directory to scaffold if it exists and removes stale files',
      () async {
        final Directory rootProject = await createRootProject();
        final Directory hostWebDir = rootProject.childDirectory('web')..createSync();
        hostWebDir.childFile('index.html').writeAsStringSync('<html>custom index</html>');
        final File staleFile = hostWebDir.childFile('stale.js')
          ..writeAsStringSync('console.log("stale");');

        await startWidgetPreview(rootProject: rootProject);

        final Directory scaffoldWebDir = WidgetPreviewStartCommand.widgetPreviewScaffold
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
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'start waits for analysis to complete',
      () async {
        final Directory rootProject = await createRootProject();
        final fakeAnalysisServer = FakeAnalysisServer();

        await startWidgetPreview(
          rootProject: rootProject,
          analysisServerFactoryOverride: () async => fakeAnalysisServer,
        );

        expect(fakeAnalysisServer.waitForAnalysisCalled, isTrue);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'start creates .dart_tool/widget_preview_scaffold in the CWD',
      () async {
        final Directory rootProject = await createRootProject();
        // Try to execute using the CWD.
        fs.currentDirectory = rootProject;
        await startWidgetPreview(rootProject: null);
        expectSinglePreviewLaunchTimingEvent();
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    const samplePreviewFile = '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

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
      testUsingContext(
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

          final File generatedFile = WidgetPreviewStartCommand.widgetPreviewScaffold.childFile(
            PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
          );

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
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

          final File generatedFile = WidgetPreviewStartCommand.widgetPreviewScaffold.childFile(
            PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
          );

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
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
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );
    });

    group('Legacy preview detection', () {
      testUsingContext(
        'start finds existing previews and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          await startWidgetPreview(rootProject: rootProject, legacyDetection: true);

          final File generatedFile = WidgetPreviewStartCommand.widgetPreviewScaffold.childFile(
            PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
          );

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
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

          final File generatedFile = WidgetPreviewStartCommand.widgetPreviewScaffold.childFile(
            PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
          );

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
        'start finds existing previews in the provided directory and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
        () async {
          final Directory rootProject = await createRootProject();
          rootProject
              .childDirectory('lib')
              .childFile('foo.dart')
              .writeAsStringSync(samplePreviewFile);

          await startWidgetPreview(rootProject: rootProject, legacyDetection: true);

          final File generatedFile = WidgetPreviewStartCommand.widgetPreviewScaffold.childFile(
            PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
          );

          expect(generatedFile.readAsStringSync().stripScriptUris, expectedGeneratedFileContents);
          expectSinglePreviewLaunchTimingEvent();
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );
    });

    testUsingContext(
      'invokes pub in online and offline modes',
      () async {
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
        await startWidgetPreview(
          rootProject: rootProject,
          arguments: <String>['--pub', '--offline'],
        );

        expect(
          loggingProcessManager.commands,
          contains(
            predicate(
              (List<String> c) =>
                  dartCommand.hasMatch(c[0]) && c[1].contains('pub') && c.contains('--offline'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'start exits if no web target is available.',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/173960.
        final Directory rootProject = await createRootProject();
        await expectToolExitLater(
          startWidgetPreview(rootProject: rootProject),
          contains(WidgetPreviewStartCommand.kBrowserNotFoundErrorMessage),
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager..attachedDevices.clear(),
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'always starts with Chrome when available.',
      () async {
        final Directory rootProject = await createRootProject();
        await startWidgetPreview(rootProject: rootProject);
        expectDeviceSelected(fakeGoogleChromeDevice);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager
          ..attachedDevices.clear()
          ..addAttachedDevice(fakeMicrosoftEdgeDevice)
          // Register the Chrome device second to ensure we're not just grabbing the first device.
          ..addAttachedDevice(fakeGoogleChromeDevice),
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    testUsingContext(
      'starts with Edge if Chrome is not available.',
      () async {
        final Directory rootProject = await createRootProject();
        await startWidgetPreview(rootProject: rootProject);
        expectDeviceSelected(fakeMicrosoftEdgeDevice);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        DeviceManager: () => fakeDeviceManager
          ..attachedDevices.clear()
          ..addAttachedDevice(fakeMicrosoftEdgeDevice),
        FileSystem: () => fs,
        ProcessManager: () => loggingProcessManager,
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: loggingProcessManager,
          botDetector: botDetector,
          platform: platform,
          stdio: mockStdio,
        ),
      },
    );

    group('hot reload and restart orchestration', () {
      testUsingContext(
        'does not perform reload until preview app connection is established',
        () async {
          final Directory rootProject = await createRootProject();
          final fakeResidentRunner = FakeResidentRunner(
            waitForAppToFinishCompleter: Completer<int>(),
          );

          final CommandRunner<void> runner = createTestCommandRunner(
            WidgetPreviewCommand(
              verboseHelp: false,
              logger: logger,
              fs: fs,
              projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs),
              cache: Cache.test(processManager: loggingProcessManager, platform: platform),
              platform: platform,
              shutdownHooks: shutdownHooks,
              os: OperatingSystemUtils(
                fileSystem: fs,
                processManager: loggingProcessManager,
                logger: logger,
                platform: platform,
              ),
              artifacts: Artifacts.test(),
              processManager: loggingProcessManager,
              terminal: FakeTerminal(),
              dtdServicesOverride: fakeDtdServices,
              analysisServerFactoryOverride: () async => FakeAnalysisServer(),
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
          );

          final startCommand =
              runner.commands['widget-preview']!.subcommands['start']! as WidgetPreviewStartCommand;

          final Future<void> runFuture = runner.run(<String>[
            'widget-preview',
            'start',
            rootProject.path,
          ]);

          while (fakeResidentRunner.appStartedCompleter == null) {
            await pumpEventQueue();
          }
          await fakeResidentRunner.appStartedCompleter!.future;

          // Trigger a change while the previewer is still waiting for debug connection.
          startCommand.onChangeDetected(
            FlutterWidgetPreviews(
              namespaces: const <String, String>{},
              previews: const <FlutterWidgetPreviewDetails>[],
              scriptUris: <Uri>[Uri.file(fs.path.join(rootProject.path, 'lib', 'main.dart'))],
            ),
          );

          // On unfixed code, restart() is immediately invoked on the unconnected runner.
          // With the fix, restart() is deferred until connection is ready.
          expect(fakeResidentRunner.restartCount, 0);

          // Now complete the connection info completer.
          fakeResidentRunner.connectionInfoCompleter!.complete(
            DebugConnectionInfo(
              wsUri: Uri.parse('ws://127.0.0.1:1234/ws'),
              devToolsUri: Uri.parse('http://127.0.0.1:1234/devtools'),
            ),
          );

          await pumpEventQueue();

          // After connection is established, the deferred reload should execute.
          expect(fakeResidentRunner.restartCount, 1);

          fakeResidentRunner.waitForAppToFinishCompleter!.complete(0);
          await runFuture;
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
        'coalesces multiple rapid file changes and serializes restarts',
        () async {
          final Directory rootProject = await createRootProject();
          final fakeResidentRunner = FakeResidentRunner(
            waitForAppToFinishCompleter: Completer<int>(),
          );

          final CommandRunner<void> runner = createTestCommandRunner(
            WidgetPreviewCommand(
              verboseHelp: false,
              logger: logger,
              fs: fs,
              projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs),
              cache: Cache.test(processManager: loggingProcessManager, platform: platform),
              platform: platform,
              shutdownHooks: shutdownHooks,
              os: OperatingSystemUtils(
                fileSystem: fs,
                processManager: loggingProcessManager,
                logger: logger,
                platform: platform,
              ),
              artifacts: Artifacts.test(),
              processManager: loggingProcessManager,
              terminal: FakeTerminal(),
              dtdServicesOverride: fakeDtdServices,
              analysisServerFactoryOverride: () async => FakeAnalysisServer(),
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
          );

          final startCommand =
              runner.commands['widget-preview']!.subcommands['start']! as WidgetPreviewStartCommand;

          final Future<void> runFuture = runner.run(<String>[
            'widget-preview',
            'start',
            rootProject.path,
          ]);

          while (fakeResidentRunner.appStartedCompleter == null) {
            await pumpEventQueue();
          }
          await fakeResidentRunner.appStartedCompleter!.future;

          // Complete debug connection so previewer is ready.
          fakeResidentRunner.connectionInfoCompleter!.complete(
            DebugConnectionInfo(
              wsUri: Uri.parse('ws://127.0.0.1:1234/ws'),
              devToolsUri: Uri.parse('http://127.0.0.1:1234/devtools'),
            ),
          );
          await pumpEventQueue();

          // Make the first restart block in flight.
          final inFlightRestartCompleter = Completer<OperationResult>();
          fakeResidentRunner.currentRestartCompleter = inFlightRestartCompleter;

          // Trigger first reload.
          startCommand.onChangeDetected(
            FlutterWidgetPreviews(
              namespaces: const <String, String>{},
              previews: const <FlutterWidgetPreviewDetails>[],
              scriptUris: <Uri>[Uri.file(fs.path.join(rootProject.path, 'lib', 'main.dart'))],
            ),
          );

          await pumpEventQueue();
          expect(fakeResidentRunner.restartCount, 1);
          expect(fakeResidentRunner.concurrentRestarts, 1);

          // Trigger 3 more rapid file changes while the first restart is still in flight.
          for (var i = 0; i < 3; i++) {
            startCommand.onChangeDetected(
              FlutterWidgetPreviews(
                namespaces: const <String, String>{},
                previews: const <FlutterWidgetPreviewDetails>[],
                scriptUris: <Uri>[Uri.file(fs.path.join(rootProject.path, 'lib', 'main.dart'))],
              ),
            );
          }

          await pumpEventQueue();

          // Restarts must NOT execute concurrently on the runner.
          expect(fakeResidentRunner.maxConcurrentRestarts, 1);
          expect(fakeResidentRunner.restartCount, 1);

          // Complete the in-flight restart and let the follow-up restart execute.
          fakeResidentRunner.currentRestartCompleter = null;
          inFlightRestartCompleter.complete(OperationResult.ok);

          await pumpEventQueue();

          // The 3 rapid changes must be coalesced into exactly one follow-up restart (total 2).
          expect(fakeResidentRunner.restartCount, 2);
          expect(fakeResidentRunner.maxConcurrentRestarts, 1);

          fakeResidentRunner.waitForAppToFinishCompleter!.complete(0);
          await runFuture;
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );

      testUsingContext(
        'does not trigger reload after previewer has finished',
        () async {
          final Directory rootProject = await createRootProject();
          final fakeResidentRunner = FakeResidentRunner(
            waitForAppToFinishCompleter: Completer<int>(),
          );

          final CommandRunner<void> runner = createTestCommandRunner(
            WidgetPreviewCommand(
              verboseHelp: false,
              logger: logger,
              fs: fs,
              projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs),
              cache: Cache.test(processManager: loggingProcessManager, platform: platform),
              platform: platform,
              shutdownHooks: shutdownHooks,
              os: OperatingSystemUtils(
                fileSystem: fs,
                processManager: loggingProcessManager,
                logger: logger,
                platform: platform,
              ),
              artifacts: Artifacts.test(),
              processManager: loggingProcessManager,
              terminal: FakeTerminal(),
              dtdServicesOverride: fakeDtdServices,
              analysisServerFactoryOverride: () async => FakeAnalysisServer(),
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
          );

          final startCommand =
              runner.commands['widget-preview']!.subcommands['start']! as WidgetPreviewStartCommand;

          final Future<void> runFuture = runner.run(<String>[
            'widget-preview',
            'start',
            rootProject.path,
          ]);

          while (fakeResidentRunner.appStartedCompleter == null) {
            await pumpEventQueue();
          }
          await fakeResidentRunner.appStartedCompleter!.future;

          fakeResidentRunner.connectionInfoCompleter!.complete(
            DebugConnectionInfo(
              wsUri: Uri.parse('ws://127.0.0.1:1234/ws'),
              devToolsUri: Uri.parse('http://127.0.0.1:1234/devtools'),
            ),
          );
          await pumpEventQueue();

          // Finish the app.
          fakeResidentRunner.waitForAppToFinishCompleter!.complete(0);
          await runFuture;

          final int restartCountBeforeExit = fakeResidentRunner.restartCount;

          // Trigger change after app finished.
          startCommand.onChangeDetected(
            FlutterWidgetPreviews(
              namespaces: const <String, String>{},
              previews: const <FlutterWidgetPreviewDetails>[],
              scriptUris: <Uri>[Uri.file(fs.path.join(rootProject.path, 'lib', 'main.dart'))],
            ),
          );

          await pumpEventQueue();

          expect(fakeResidentRunner.restartCount, restartCountBeforeExit);
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          DeviceManager: () => fakeDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => loggingProcessManager,
          Pub: () => Pub.test(
            fileSystem: fs,
            logger: logger,
            processManager: loggingProcessManager,
            botDetector: botDetector,
            platform: platform,
            stdio: mockStdio,
          ),
        },
      );
    });
  });
}
