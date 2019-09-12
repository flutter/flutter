// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_appbundle.dart';
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
      final BuildAppBundleCommand command = await runBuildAppBundleCommand(projectPath);

      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleTargetPlatform, 'android-arm,android-arm64'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('build type', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildAppBundleCommand commandDefault = await runBuildAppBundleCommand(projectPath);
      expect(await commandDefault.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'release'));

      final BuildAppBundleCommand commandInRelease = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--release']);
      expect(await commandInRelease.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'release'));

      final BuildAppBundleCommand commandInDebug = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--debug']);
      expect(await commandInDebug.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'debug'));

      final BuildAppBundleCommand commandInProfile = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--profile']);
      expect(await commandInProfile.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'profile'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    }, timeout: allowForCreateFlutterProject);
  });

  group('Flags', () {
    Directory tempDir;
    ProcessManager mockProcessManager;
    MockAndroidSdk mockAndroidSdk;
    String gradlew;
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
      when(mockAndroidSdk.validateSdkWellFormed()).thenReturn(const <String>[]);
      when(mockAndroidSdk.directory).thenReturn('irrelevant');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('proguard is enabled by default on release mode', () async {
      final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

      await expectLater(() async {
        await runBuildAppBundleCommand(projectPath);
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pproguard=true',
          '-Ptarget-platform=android-arm,android-arm64',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      GradleUtils: () => GradleUtils(),
      ProcessManager: () => mockProcessManager,
    },
    skip: true,
    timeout: allowForCreateFlutterProject);

    testUsingContext('proguard is disabled when --no-proguard is passed', () async {
      final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
          arguments: <String>['--no-proguard'],
        );
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Ptarget-platform=android-arm,android-arm64',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      GradleUtils: () => GradleUtils(),
      ProcessManager: () => mockProcessManager,
    },
    skip: true,
    timeout: allowForCreateFlutterProject);

    testUsingContext('guides the user when proguard fails', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget=${fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pproguard=true',
          '-Ptarget-platform=android-arm,android-arm64',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        const String proguardStdoutWarning =
            'Warning: there were 6 unresolved references to program class members.'
            'Your input classes appear to be inconsistent.'
            'You may need to recompile the code.'
            '(http://proguard.sourceforge.net/manual/troubleshooting.html#unresolvedprogramclassmember)';
        return Future<Process>.value(
          createMockProcess(
            exitCode: 1,
            stdout: proguardStdoutWarning,
          )
        );
      });

      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
        );
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      expect(testLogger.statusText,
          contains('Proguard may have failed to optimize the Java bytecode.'));
      expect(testLogger.statusText,
          contains('To disable proguard, pass the `--no-proguard` flag to this command.'));
      expect(testLogger.statusText,
          contains('To learn more about Proguard, see: https://flutter.dev/docs/deployment/android#enabling-proguard'));

      verify(mockUsage.sendEvent(
        'build-appbundle',
        'proguard-failure',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      GradleUtils: () => GradleUtils(),
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    },
    skip: true,
    timeout: allowForCreateFlutterProject);
  });
}

Future<BuildAppBundleCommand> runBuildAppBundleCommand(
  String target,
  { List<String> arguments }
) async {
  final BuildAppBundleCommand command = BuildAppBundleCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'appbundle',
    ...?arguments,
    fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class FakeFlutterProjectFactory extends FlutterProjectFactory {
  FakeFlutterProjectFactory(this._directoryOverride) :
    assert(_directoryOverride != null);

  final Directory _directoryOverride;

  @override
  FlutterProject fromDirectory(Directory _) {
    return super.fromDirectory(_directoryOverride.childDirectory('flutter_project'));
  }
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockUsage extends Mock implements Usage {}
