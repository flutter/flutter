// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Process, ProcessResult;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_aar.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  Cache.disableLocking();

  Future<BuildAarCommand> runCommandIn(String target, { List<String> arguments }) async {
    final BuildAarCommand command = BuildAarCommand(verboseHelp: false);
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>[
      'aar',
      '--no-pub',
      ...?arguments,
      target,
    ]);
    return command;
  }

  group('Usage', () {
    Directory tempDir;
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate that project is a module', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarProjectType, 'module'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('indicate that project is a plugin', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=plugin', '--project-name=aar_test']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarProjectType, 'plugin'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('indicate the target platform', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath,
          arguments: <String>['--target-platform=android-arm']);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarTargetPlatform, 'android-arm'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('logs success', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      await runCommandIn(projectPath,
          arguments: <String>['--target-platform=android-arm']);

      verify(mockUsage.sendEvent(
        'tool-command-result',
        'aar',
        label: 'success',
        value: anyNamed('value'),
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
      Usage: () => mockUsage,
    });
  });

  group('flag parsing', () {
    Directory tempDir;
    MockAndroidBuilder mockAndroidBuilder;

    setUp(() {
      mockAndroidBuilder = MockAndroidBuilder();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_build_aar_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('defaults', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      await runCommandIn(projectPath);

      final Set<AndroidBuildInfo> androidBuildInfos = verify(mockAndroidBuilder.buildAar(
        project: anyNamed('project'),
        target: anyNamed('target'),
        androidBuildInfo: captureAnyNamed('androidBuildInfo'),
        outputDirectoryPath: anyNamed('outputDirectoryPath'),
        buildNumber: '1.0',
      )).captured[0] as Set<AndroidBuildInfo>;

      expect(androidBuildInfos.length, 3);

      final List<BuildMode> buildModes = <BuildMode>[];
      for (final AndroidBuildInfo androidBuildInfo in androidBuildInfos) {
        final BuildInfo buildInfo = androidBuildInfo.buildInfo;
        buildModes.add(buildInfo.mode);
        if (buildInfo.mode.isPrecompiled) {
          expect(buildInfo.treeShakeIcons, isTrue);
          expect(buildInfo.trackWidgetCreation, isTrue);
        } else {
          expect(buildInfo.treeShakeIcons, isFalse);
          expect(buildInfo.trackWidgetCreation, isTrue);
        }
        expect(buildInfo.flavor, isNull);
        expect(buildInfo.splitDebugInfoPath, isNull);
        expect(buildInfo.dartObfuscation, isFalse);
        expect(androidBuildInfo.targetArchs, <AndroidArch>[AndroidArch.armeabi_v7a, AndroidArch.arm64_v8a, AndroidArch.x86_64]);
      }
      expect(buildModes.length, 3);
      expect(buildModes, containsAll(<BuildMode>[BuildMode.debug, BuildMode.profile, BuildMode.release]));
    }, overrides: <Type, Generator>{
      AndroidBuilder: () => mockAndroidBuilder,
    });

    testUsingContext('parses flags', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      await runCommandIn(
        projectPath,
        arguments: <String>[
          '--no-debug',
          '--no-profile',
          '--target-platform',
          'android-x86',
          '--tree-shake-icons',
          '--flavor',
          'free',
          '--build-number',
          '200',
          '--split-debug-info',
          '/project-name/v1.2.3/',
          '--obfuscate',
        ],
      );

      final Set<AndroidBuildInfo> androidBuildInfos = verify(mockAndroidBuilder.buildAar(
        project: anyNamed('project'),
        target: anyNamed('target'),
        androidBuildInfo: captureAnyNamed('androidBuildInfo'),
        outputDirectoryPath: anyNamed('outputDirectoryPath'),
        buildNumber: '200',
      )).captured[0] as Set<AndroidBuildInfo>;

      final AndroidBuildInfo androidBuildInfo = androidBuildInfos.single;
      expect(androidBuildInfo.targetArchs, <AndroidArch>[AndroidArch.x86]);

      final BuildInfo buildInfo = androidBuildInfo.buildInfo;
      expect(buildInfo.mode, BuildMode.release);
      expect(buildInfo.treeShakeIcons, isTrue);
      expect(buildInfo.flavor, 'free');
      expect(buildInfo.splitDebugInfoPath, '/project-name/v1.2.3/');
      expect(buildInfo.dartObfuscation, isTrue);
    }, overrides: <Type, Generator>{
      AndroidBuilder: () => mockAndroidBuilder,
    });
  });

  group('Gradle', () {
    ProcessManager mockProcessManager;
    Directory tempDir;
    AndroidSdk mockAndroidSdk;
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(true);

      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');

      mockProcessManager = MockProcessManager();
      when(mockProcessManager.run(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, 'assembleRelease', '')));
      // Fallback with error.
      final Process process = createMockProcess(exitCode: 1);
      when(mockProcessManager.start(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<Process>.value(process));
      when(mockProcessManager.canRun(any)).thenReturn(false);

      mockAndroidSdk = MockAndroidSdk();
      when(mockAndroidSdk.directory).thenReturn('irrelevant');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      testUsingContext('validateSdkWellFormed() not called, sdk reinitialized', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=module']);

        await expectLater(
          runBuildAarCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          ),
          throwsToolExit(),
        );

        verifyNever(mockAndroidSdk.validateSdkWellFormed());
        verify(mockAndroidSdk.reinitialize()).called(1);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('throws throwsToolExit if AndroidSdk is null', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=module']);

        await expectLater(() async {
          await runBuildAarCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          );
        }, throwsToolExit(
          message: 'No Android SDK found. Try setting the ANDROID_SDK_ROOT environment variable',
        ));
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => null,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => mockProcessManager,
      });
    });
  });
}

Future<BuildAarCommand> runBuildAarCommand(
  String target, {
  List<String> arguments,
}) async {
  final BuildAarCommand command = BuildAarCommand(verboseHelp: false);
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'aar',
    '--no-pub',
    ...?arguments,
    globals.fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class MockAndroidBuilder extends Mock implements AndroidBuilder {}
class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockUsage extends Mock implements Usage {}
