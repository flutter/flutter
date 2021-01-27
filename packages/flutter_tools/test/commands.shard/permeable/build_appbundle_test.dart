// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_appbundle.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  Cache.disableLocking();

  group('Usage', () {
    Directory tempDir;
    Usage mockUsage;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      mockUsage = MockUsage();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate the default target platforms', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      final BuildAppBundleCommand command = await runBuildAppBundleCommand(projectPath);

      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleTargetPlatform, 'android-arm,android-arm64,android-x64'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

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
    });

    testUsingContext('logs success', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await runBuildAppBundleCommand(projectPath);

      verify(mockUsage.sendEvent(
        'tool-command-result',
        'appbundle',
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

  group('Gradle', () {
    Directory tempDir;
    FakeProcessManager fakeProcessManager;
    MockAndroidSdk mockAndroidSdk;
    String gradlew;
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      gradlew = globals.fs.path.join(tempDir.path, 'flutter_project', 'android',
          globals.platform.isWindows ? 'gradlew.bat' : 'gradlew');

      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>[
          '/Applications/Android Studio.app/Contents/jre/jdk/Contents/Home/bin/java',
          '-version'
        ], stdout: 'java version "13.0.1" 2019-10-15'),
      ]);

      mockAndroidSdk = MockAndroidSdk();
      when(mockAndroidSdk.licensesAvailable).thenReturn(true);
      when(mockAndroidSdk.platformToolsAvailable).thenReturn(true);
      when(mockAndroidSdk.validateSdkWellFormed()).thenReturn(const <String>[]);
      when(mockAndroidSdk.directory).thenReturn('irrelevant');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      testUsingContext('validateSdkWellFormed() not called, sdk reinitialized', () async {
        fakeProcessManager.addCommand(
          FakeCommand(command: <String>[
            gradlew,
            '-q',
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
            '-Ptrack-widget-creation=true',
            '-Ptree-shake-icons=true',
            'bundleRelease',
          ], exitCode: 1),
        );
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);

        await expectLater(
          runBuildAppBundleCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          ),
          throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'),
        );

        verifyNever(mockAndroidSdk.validateSdkWellFormed());
        verify(mockAndroidSdk.reinitialize()).called(1);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => fakeProcessManager,
      });

      testUsingContext('throws throwsToolExit if AndroidSdk is null', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);

        await expectLater(() async {
          await runBuildAppBundleCommand(
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
        ProcessManager: () => fakeProcessManager,
      });
    });

    group('AndroidX', () {
      setUp(() {
        fakeProcessManager.addCommand(
          FakeCommand(command: <String>[
            gradlew,
            '-q',
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
            '-Ptrack-widget-creation=true',
            '-Ptree-shake-icons=true',
            'bundleRelease',
          ]),
        );
      });
      testUsingContext("reports when the app isn't using AndroidX", () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);
        // Simulate a non-androidx project.
        tempDir
          .childDirectory('flutter_project')
          .childDirectory('android')
          .childFile('gradle.properties')
          .writeAsStringSync('android.useAndroidX=false');

        // The command throws a [ToolExit] because it expects an AAB in the file system.
        await expectLater(() async {
          await runBuildAppBundleCommand(
            projectPath,
          );
        }, throwsToolExit());

        expect(
          testLogger.statusText,
          containsIgnoringWhitespace("Your app isn't using AndroidX"),
        );
        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(
          'To avoid potential build failures, you can quickly migrate your app by '
          'following the steps on https://goo.gl/CP92wY'
          ),
        );
        verify(mockUsage.sendEvent(
          'build',
          'appbundle',
          label: 'app-not-using-android-x',
          parameters: anyNamed('parameters'),
        )).called(1);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => fakeProcessManager,
        Usage: () => mockUsage,
      });

      testUsingContext('reports when the app is using AndroidX', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);

        // The command throws a [ToolExit] because it expects an AAB in the file system.
        await expectLater(() async {
          await runBuildAppBundleCommand(
            projectPath,
          );
        }, throwsToolExit());

        expect(
          testLogger.statusText,
          not(containsIgnoringWhitespace("Your app isn't using AndroidX")),
        );
        expect(
          testLogger.statusText,
          not(
            containsIgnoringWhitespace(
              'To avoid potential build failures, you can quickly migrate your app by '
              'following the steps on https://goo.gl/CP92wY'),
          )
        );
        verify(mockUsage.sendEvent(
          'build',
          'appbundle',
          label: 'app-using-android-x',
          parameters: anyNamed('parameters'),
        )).called(1);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => fakeProcessManager,
        Usage: () => mockUsage,
      });
    });
  });
}

Future<BuildAppBundleCommand> runBuildAppBundleCommand(
  String target, {
  List<String> arguments,
}) async {
  final BuildAppBundleCommand command = BuildAppBundleCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'appbundle',
    ...?arguments,
    '--no-pub',
    globals.fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

Matcher not(Matcher target){
  return isNot(target);
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockUsage extends Mock implements Usage {}
