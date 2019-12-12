// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_apk.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/android_common.dart';
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
          containsPair(CustomDimensions.commandBuildApkTargetPlatform, 'android-arm,android-arm64,android-x64'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

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
    });

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
    });
  });

  group('Gradle', () {
    Directory tempDir;
    ProcessManager mockProcessManager;
    String gradlew;
    AndroidSdk mockAndroidSdk;
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(true);

      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      gradlew = fs.path.join(tempDir.path, 'flutter_project', 'android',
          platform.isWindows ? 'gradlew.bat' : 'gradlew');

      mockProcessManager = MockProcessManager();
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

    group('AndroidSdk', () {
      FileSystem memoryFileSystem;
      setUp(() {
        memoryFileSystem = MemoryFileSystem();

        tempDir = memoryFileSystem.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
        memoryFileSystem.currentDirectory = tempDir;

        gradlew = memoryFileSystem.path.join(tempDir.path, 'flutter_project', 'android',
            platform.isWindows ? 'gradlew.bat' : 'gradlew');
      });
      testUsingContext('validateSdkWellFormed() not called, sdk reinitialized', () async {
        final Directory gradleCacheDir = memoryFileSystem
          .directory('/flutter_root/bin/cache/artifacts/gradle_wrapper')
          ..createSync(recursive: true);

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
''');
        tempDir.childFile('.packages').createSync(recursive: true);
        final Directory androidDir = tempDir.childDirectory('android');
        androidDir
          .childFile('build.gradle')
          .createSync(recursive: true);
        androidDir
          .childDirectory('app')
          .childFile('build.gradle')
          ..createSync(recursive: true)
          ..writeAsStringSync('apply from: irrelevant/flutter.gradle');
        androidDir
          .childFile('gradle.properties')
          .createSync(recursive: true);
        androidDir
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.properties')
          .createSync(recursive: true);
        tempDir
          .childDirectory('build')
          .childDirectory('outputs')
          .childDirectory('repo')
          .createSync(recursive: true);
        tempDir
          .childDirectory('lib')
          .childFile('main.dart')
          .createSync(recursive: true);
        when(mockProcessManager.run(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, 'any', '')));

        await expectLater(
          runBuildApkCommand(tempDir.path, arguments: <String>['--no-pub', '--flutter-root=/flutter_root']),
          throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'),
        );

        verifyNever(mockAndroidSdk.validateSdkWellFormed());
        verify(mockAndroidSdk.reinitialize()).called(1);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => mockProcessManager,
      });
    });

    testUsingContext('shrinking is enabled by default on release mode', () async {
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
          '-Ptrack-widget-creation=true',
          '-Pshrink=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('shrinking is disabled when --no-shrink is passed', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await expectLater(() async {
        await runBuildApkCommand(
          projectPath,
          arguments: <String>['--no-shrink'],
        );
      }, throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('guides the user when the shrinker fails', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=true',
          '-Pshrink=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        const String r8StdoutWarning =
            'Execution failed for task \':app:transformClassesAndResourcesWithR8ForStageInternal\'.'
            '> com.android.tools.r8.CompilationFailedException: Compilation failed to complete';
        return Future<Process>.value(
          createMockProcess(
            exitCode: 1,
            stdout: r8StdoutWarning,
          ),
        );
      });

      await expectLater(() async {
        await runBuildApkCommand(
          projectPath,
        );
      }, throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'));

      expect(testLogger.statusText,
          contains('The shrinker may have failed to optimize the Java bytecode.'));
      expect(testLogger.statusText,
          contains('To disable the shrinker, pass the `--no-shrink` flag to this command.'));
      expect(testLogger.statusText,
          contains('To learn more, see: https://developer.android.com/studio/build/shrink-code'));

      verify(mockUsage.sendEvent(
        'build',
        'apk',
        label: 'gradle-r8-failure',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('reports when the app isn\'t using AndroidX', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--no-androidx', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=true',
          '-Pshrink=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        return Future<Process>.value(
          createMockProcess(
            exitCode: 0,
            stdout: '',
          ),
        );
      });
      // The command throws a [ToolExit] because it expects an APK in the file system.
      await expectLater(() async {
        await runBuildApkCommand(
          projectPath,
        );
      }, throwsToolExit());

      expect(testLogger.statusText, contains('Your app isn\'t using AndroidX'));
      expect(testLogger.statusText, contains(
        'To avoid potential build failures, you can quickly migrate your app by '
        'following the steps on https://goo.gl/CP92wY'
        )
      );
      verify(mockUsage.sendEvent(
        'build',
        'apk',
        label: 'app-not-using-android-x',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('reports when the app is using AndroidX', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=true',
          '-Pshrink=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        return Future<Process>.value(
          createMockProcess(
            exitCode: 0,
            stdout: '',
          ),
        );
      });
      // The command throws a [ToolExit] because it expects an APK in the file system.
      await expectLater(() async {
        await runBuildApkCommand(
          projectPath,
        );
      }, throwsToolExit());

      expect(testLogger.statusText.contains('[!] Your app isn\'t using AndroidX'), isFalse);
      expect(
        testLogger.statusText.contains(
          'To avoid potential build failures, you can quickly migrate your app by '
          'following the steps on https://goo.gl/CP92wY'
        ),
        isFalse,
      );
      verify(mockUsage.sendEvent(
        'build',
        'apk',
        label: 'app-using-android-x',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });
  });
}

Future<BuildApkCommand> runBuildApkCommand(
  String target, {
  List<String> arguments,
}) async {
  final BuildApkCommand command = BuildApkCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'apk',
    ...?arguments,
    '--no-pub',
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
class MockUsage extends Mock implements Usage {}
