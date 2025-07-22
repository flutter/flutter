// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_devices.dart';
import '../../../src/fakes.dart';
import '../../../src/test_flutter_command_runner.dart';
import '../utils/project_testing_utils.dart';

class FakeWidgetPreviewScaffoldDtdServices extends Fake implements WidgetPreviewDtdServices {
  @override
  Future<void> connect({required Uri dtdWsUri}) async {}

  @override
  DtdLauncher get dtdLauncher => throw UnimplementedError();

  @override
  Uri? get dtdUri => Uri();

  @override
  Future<void> launchAndConnect() async {}
}

void main() {
  late Directory originalCwd;
  late Directory tempDir;
  late LoggingProcessManager loggingProcessManager;
  late FakeStdio mockStdio;
  late Logger logger;
  // We perform this initialization just so we can build the generated file path for test
  // descriptions.
  var fs = LocalFileSystem.test(signals: Signals.test());
  late BotDetector botDetector;
  late Platform platform;
  late FakeDeviceManager fakeDeviceManager;
  late FakeAnalytics fakeAnalytics;

  setUp(() async {
    originalCwd = globals.fs.currentDirectory;
    await ensureFlutterToolsSnapshot();
    loggingProcessManager = LoggingProcessManager();
    logger = BufferLogger.test();
    fs = LocalFileSystem.test(signals: Signals.test());
    botDetector = const FakeBotDetector(false);
    tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
    mockStdio = FakeStdio();
    platform = FakePlatform.fromPlatform(const LocalPlatform());

    // Create a fake device manager which only contains a single Chrome device.
    const kChromeDeviceId = 'chrome-id';
    final fakeChromeDevice = FakeDevice('chrome', kChromeDeviceId)
      ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.web_javascript);
    fakeDeviceManager = FakeDeviceManager()
      ..addAttachedDevice(fakeChromeDevice)
      ..specifiedDeviceId = kChromeDeviceId;

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

  tearDown(() {
    tryToDelete(tempDir);
    fs.dispose();
    globals.fs.currentDirectory = originalCwd;
  });

  Future<Directory> createRootProject() async {
    return fs.directory(await createProject(tempDir, arguments: <String>['--pub']));
  }

  Directory widgetPreviewScaffoldFromRootProject({required Directory rootProject}) {
    return rootProject.childDirectory('.dart_tool').childDirectory('widget_preview_scaffold');
  }

  Future<void> runWidgetPreviewCommand(List<String> arguments) async {
    final CommandRunner<void> runner = createTestCommandRunner(
      WidgetPreviewCommand(
        verboseHelp: false,
        logger: logger,
        fs: fs,
        projectFactory: FlutterProjectFactory(logger: logger, fileSystem: fs),
        cache: Cache.test(processManager: loggingProcessManager, platform: platform),
        platform: platform,
        shutdownHooks: ShutdownHooks(),
        os: OperatingSystemUtils(
          fileSystem: fs,
          processManager: loggingProcessManager,
          logger: logger,
          platform: platform,
        ),
        artifacts: Artifacts.test(),
        processManager: loggingProcessManager,
        dtdServicesOverride: FakeWidgetPreviewScaffoldDtdServices(),
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

  Future<void> startWidgetPreview({
    required Directory? rootProject,
    List<String>? arguments,
  }) async {
    // This might get changed during the test, so keep track of the original directory.
    final Directory current = fs.currentDirectory;
    await runWidgetPreviewCommand(<String>[
      'start',
      ...?arguments,
      '--no-launch-previewer',
      '--verbose',
      if (rootProject != null) rootProject.path,
    ]);
    final Directory widgetPreviewScaffoldDir = widgetPreviewScaffoldFromRootProject(
      rootProject: rootProject ?? current,
    );
    // Don't perform analysis on Windows since `dart pub add` will use '\' for
    // path dependencies and cause analysis to fail.
    // TODO(bkonyi): enable analysis on Windows once https://github.com/dart-lang/pub/issues/4520
    // is resolved.
    if (!platform.isWindows) {
      await analyzeProject(widgetPreviewScaffoldDir.path);
    }
    fs.currentDirectory = current;
  }

  Future<void> cleanWidgetPreview({required Directory rootProject}) async {
    await runWidgetPreviewCommand(<String>['clean', rootProject.path]);
    expect(
      fs
          .directory(rootProject)
          .childDirectory('.dart_tool')
          .childDirectory('widget_preview_scaffold'),
      isNot(exists),
    );
  }

  group('flutter widget-preview', () {
    group('start exits if', () {
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
    });

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
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;
import 'package:flutter_project/foo.dart' as _i2;

List<_i1.WidgetPreview> previews() => [
      _i1.WidgetPreview(
        packageName: 'flutter_project',
        name: 'preview',
        builder: () => _i2.preview(),
      )
    ];
''';

    testUsingContext(
      'start finds existing previews and injects them into ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
      () async {
        final Directory rootProject = await createRootProject();
        final Directory widgetPreviewScaffoldDir = widgetPreviewScaffoldFromRootProject(
          rootProject: rootProject,
        );
        rootProject
            .childDirectory('lib')
            .childFile('foo.dart')
            .writeAsStringSync(samplePreviewFile);

        final File generatedFile = widgetPreviewScaffoldDir.childFile(
          PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
        );

        await startWidgetPreview(rootProject: rootProject);
        expect(generatedFile.readAsStringSync(), expectedGeneratedFileContents);
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
        final Directory widgetPreviewScaffoldDir = widgetPreviewScaffoldFromRootProject(
          rootProject: rootProject,
        );
        rootProject
            .childDirectory('lib')
            .childFile('foo.dart')
            .writeAsStringSync(samplePreviewFile);

        final File generatedFile = widgetPreviewScaffoldDir.childFile(
          PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
        );

        // Try to execute using the CWD.

        fs.currentDirectory = rootProject;
        await startWidgetPreview(rootProject: null);

        expect(generatedFile.readAsStringSync(), expectedGeneratedFileContents);
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
  });
}
