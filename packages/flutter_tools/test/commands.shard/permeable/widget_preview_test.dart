// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show IOOverrides;

import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';
import 'utils/project_testing_utils.dart';

void main() {
  late Directory tempDir;
  late LoggingProcessManager loggingProcessManager;
  late FakeStdio mockStdio;
  late Logger logger;
  late LocalFileSystem fs;
  late BotDetector botDetector;
  late Platform platform;

  setUp(() async {
    await ensureFlutterToolsSnapshot();
    loggingProcessManager = LoggingProcessManager();
    logger = BufferLogger.test();
    fs = LocalFileSystem.test(signals: Signals.test());
    botDetector = const FakeBotDetector(false);
    tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
    mockStdio = FakeStdio();
    platform = FakePlatform.fromPlatform(const LocalPlatform());
    // Most, but not all, tests will run some variant of "pub get" after creation,
    // which in turn will check for the presence of the Flutter SDK root. Without
    // this field set consistently, the order of the tests becomes important *or*
    // you need to remember to set it everywhere.
    Cache.flutterRoot = fs.path.absolute('..', '..');
  });

  tearDown(() {
    tryToDelete(tempDir);
    fs.dispose();
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
      ),
    );
    await runner.run(<String>['widget-preview', ...arguments]);
  }

  Future<void> startWidgetPreview({
    required Directory? rootProject,
    List<String>? arguments,
  }) async {
    await runWidgetPreviewCommand(<String>[
      'start',
      ...?arguments,
      '--no-launch-previewer',
      if (rootProject != null) rootProject.path,
    ]);
    final Directory widgetPreviewScaffoldDir = widgetPreviewScaffoldFromRootProject(
      rootProject: rootProject ?? fs.currentDirectory,
    );
    // Don't perform analysis on Windows since `dart pub add` will use '\' for
    // path dependencies and cause analysis to fail.
    // TODO(bkonyi): enable analysis on Windows once https://github.com/dart-lang/pub/issues/4520
    // is resolved.
    if (!platform.isWindows) {
      await analyzeProject(widgetPreviewScaffoldDir.path);
    }
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
      });

      testUsingContext('more than one project directory is provided', () async {
        try {
          await runWidgetPreviewCommand(<String>['start', tempDir.path, tempDir.path]);
          fail('Successfully executed with multiple project paths');
        } on ToolExit catch (e) {
          expect(e.message, contains('Only one directory should be provided.'));
        }
      });

      testUsingContext('run outside of a Flutter project directory', () async {
        try {
          await startWidgetPreview(rootProject: tempDir);
          fail('Successfully executed outside of a Flutter project directory');
        } on ToolExit catch (e) {
          expect(e.message, contains('${tempDir.path} is not a valid Flutter project.'));
        }
      });
    });

    testUsingContext(
      'start creates .dart_tool/widget_preview_scaffold',
      () async {
        final Directory rootProject = await createRootProject();
        await startWidgetPreview(rootProject: rootProject);
      },
      overrides: <Type, Generator>{
        Pub:
            () => Pub.test(
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
        await io.IOOverrides.runZoned<Future<void>>(() async {
          // Try to execute using the CWD.
          await startWidgetPreview(rootProject: null);
        }, getCurrentDirectory: () => rootProject);
      },
      overrides: <Type, Generator>{
        Pub:
            () => Pub.test(
              fileSystem: fs,
              logger: logger,
              processManager: loggingProcessManager,
              botDetector: botDetector,
              platform: platform,
              stdio: mockStdio,
            ),
      },
    );

    const String samplePreviewFile = '''
@Preview()
WidgetPreview preview() => const WidgetPreview(child: Text('Foo'));''';

    const String expectedGeneratedFileContents = '''
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_project/foo.dart' as _i1;import 'package:flutter/widgets.dart';List<WidgetPreview> previews() => [_i1.preview()];''';

    testUsingContext(
      'start finds existing previews and injects them into ${PreviewCodeGenerator.generatedPreviewFilePath}',
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
          PreviewCodeGenerator.generatedPreviewFilePath,
        );

        await startWidgetPreview(rootProject: rootProject);
        expect(generatedFile.readAsStringSync(), expectedGeneratedFileContents);
      },
      overrides: <Type, Generator>{
        Pub:
            () => Pub.test(
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
      'start finds existing previews in the CWD and injects them into ${PreviewCodeGenerator.generatedPreviewFilePath}',
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
          PreviewCodeGenerator.generatedPreviewFilePath,
        );

        await io.IOOverrides.runZoned<Future<void>>(() async {
          // Try to execute using the CWD.
          await startWidgetPreview(rootProject: null);
          expect(generatedFile.readAsStringSync(), expectedGeneratedFileContents);
        }, getCurrentDirectory: () => fs.directory(rootProject));
      },
      overrides: <Type, Generator>{
        Pub:
            () => Pub.test(
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
      'start finds existing previews in the CWD and injects them into ${PreviewCodeGenerator.generatedPreviewFilePath}',
      () async {
        final Directory rootProject = await createRootProject();
        await startWidgetPreview(rootProject: rootProject);
        await cleanWidgetPreview(rootProject: rootProject);
      },
      overrides: <Type, Generator>{
        Pub:
            () => Pub.test(
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

        final RegExp dartCommand = RegExp(r'dart-sdk[\\/]bin[\\/]dart');

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
        ProcessManager: () => loggingProcessManager,
        Pub:
            () => Pub.test(
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
