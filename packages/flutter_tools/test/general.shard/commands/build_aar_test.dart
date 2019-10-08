// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Process, ProcessResult;

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_aar.dart';
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

    Future<BuildAarCommand> runCommandIn(String target, { List<String> arguments }) async {
      final BuildAarCommand command = BuildAarCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'aar',
        '--no-pub',
        ...?arguments,
        target,
      ]);
      return command;
    }

    testUsingContext('indicate that project is a module', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarProjectType, 'module'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate that project is a plugin', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=plugin', '--project-name=aar_test']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarProjectType, 'plugin'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate the target platform', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath,
          arguments: <String>['--target-platform=android-arm']);
      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAarTargetPlatform, 'android-arm'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);
  });

  group('Gradle', () {
    ProcessManager mockProcessManager;
    Directory tempDir;
    AndroidSdk mockAndroidSdk;
    Usage mockUsage;
    FileSystem memoryFileSystem;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(true);

      memoryFileSystem = MemoryFileSystem();
      tempDir = memoryFileSystem.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      memoryFileSystem.currentDirectory = tempDir;

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

    group('AndroidSdk', () {
      testUsingContext('validateSdkWellFormed() not called, sdk reinitialized', () async {
        final Directory gradleCacheDir = memoryFileSystem.directory('/flutter_root/bin/cache/artifacts/gradle_wrapper')..createSync(recursive: true);
        gradleCacheDir.childFile(platform.isWindows ? 'gradlew.bat' : 'gradlew').createSync();

        tempDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''name: test
environment:
  sdk: ">=2.1.0 <3.0.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  plugin:
    androidPackage: com.example.blah
    pluginClass: BlahPlugin
''');
        tempDir.childFile('.packages').createSync(recursive: true);
        final Directory androidDir = tempDir.childDirectory('android');
        androidDir.childFile('build.gradle').createSync(recursive: true);
        androidDir.childFile('gradle.properties').createSync(recursive: true);
        androidDir.childDirectory('gradle').childDirectory('wrapper').childFile('gradle-wrapper.properties').createSync(recursive: true);
        tempDir.childDirectory('build').childDirectory('outputs').childDirectory('repo').createSync(recursive: true);
        tempDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
        await runBuildAarCommand(tempDir.path);

        verifyNever(mockAndroidSdk.validateSdkWellFormed());
        verify(mockAndroidSdk.reinitialize()).called(1);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        GradleUtils: () => GradleUtils(),
        ProcessManager: () => mockProcessManager,
        FileSystem: () => memoryFileSystem,
      });
    });
  });
}

Future<BuildAarCommand> runBuildAarCommand(
  String target, {
  List<String> arguments,
}) async {
  final BuildAarCommand command = BuildAarCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'aar',
    '--no-pub',
    '--flutter-root=/flutter_root',
    ...?arguments,
    fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockUsage extends Mock implements Usage {}
