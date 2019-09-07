// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_apk.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  Cache.disableLocking();

  group('getUsage', () {
    Directory tempDir;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate the default target platforms', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      final BuildApkCommand command = await runBuildApkCommand(projectPath);

      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildApkTargetPlatform, 'android-arm,android-arm64'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('split per abi', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildApkCommand commandWithFlag = await runBuildApkCommand(projectPath,
          arguments: <String>['--split-per-abi']);
      expect(await commandWithFlag.usageValues,
          containsPair(CustomDimensions.commandBuildApkSplitPerAbi, 'true'));

      final BuildApkCommand commandWithoutFlag = await runBuildApkCommand(projectPath);
      expect(await commandWithoutFlag.usageValues,
          containsPair(CustomDimensions.commandBuildApkSplitPerAbi, 'false'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('build type', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildApkCommand commandDefault = await runBuildApkCommand(projectPath);
      expect(await commandDefault.usageValues,
          containsPair(CustomDimensions.commandBuildApkBuildMode, 'release'));

      final BuildApkCommand commandInRelease = await runBuildApkCommand(projectPath,
          arguments: <String>['--release']);
      expect(await commandInRelease.usageValues,
          containsPair(CustomDimensions.commandBuildApkBuildMode, 'release'));

      final BuildApkCommand commandInDebug = await runBuildApkCommand(projectPath,
          arguments: <String>['--debug']);
      expect(await commandInDebug.usageValues,
          containsPair(CustomDimensions.commandBuildApkBuildMode, 'debug'));

      final BuildApkCommand commandInProfile = await runBuildApkCommand(projectPath,
          arguments: <String>['--profile']);
      expect(await commandInProfile.usageValues,
          containsPair(CustomDimensions.commandBuildApkBuildMode, 'profile'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);
  });

  group('Flags', () {
    Directory tempDir;
    ProcessManager mockProcessManager;
    String gradlew;
    AndroidSdk mockAndroidSdk;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');

      mockProcessManager = MockProcessManager();
      gradlew = fs.path.join(tempDir.path, 'flutter_project', 'android', 'gradlew');

      when(mockProcessManager.run(<String>[gradlew, '-v'],
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, '', '')));

      when(mockProcessManager.run(<String>[gradlew, 'app:properties'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, 'buildDir: irrelevant', '')));

      when(mockProcessManager.run(<String>[gradlew, 'app:tasks', '--all', '--console=auto'],
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

    testUsingContext('proguard is enabled by default on release mode', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await expectLater(() async {
        await runBuildApkCommand(projectPath);
      }, throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pproguard=true',
          '-Ptarget-platform=android-arm,android-arm64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      GradleUtils: () => GradleUtils(),
      ProcessManager: () => mockProcessManager,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
    },
    timeout: allowForCreateFlutterProject);

    testUsingContext('proguard is disabled when --no-proguard is passed', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await expectLater(() async {
        await runBuildApkCommand(
          projectPath,
          arguments: <String>['--no-proguard'],
        );
      }, throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Ptarget-platform=android-arm,android-arm64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      GradleUtils: () => GradleUtils(),
      ProcessManager: () => mockProcessManager,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
    },
    timeout: allowForCreateFlutterProject);
  });
}

Future<BuildApkCommand> runBuildApkCommand(
  String target,
  { List<String> arguments }
) async {
  final BuildApkCommand command = BuildApkCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'apk',
    ...?arguments,
    fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class FakeFlutterProjectFactory extends FlutterProjectFactory {
  FakeFlutterProjectFactory(this.directoryOverride) :
    assert(directoryOverride != null);

  final Directory directoryOverride;

  @override
  FlutterProject fromDirectory(Directory _) {
    return super.fromDirectory(directoryOverride.childDirectory('flutter_project'));
  }
}

class MockAndroidSdk extends Mock implements AndroidSdk {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}
