// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_appbundle.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();

  group('Usage', () {
    Directory tempDir;
    TestUsage testUsage;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      testUsage = TestUsage();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate the default target platforms', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      final BuildAppBundleCommand command = await runBuildAppBundleCommand(projectPath);

      expect((await command.usageValues).commandBuildAppBundleTargetPlatform, 'android-arm,android-arm64,android-x64');

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('build type', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildAppBundleCommand commandDefault = await runBuildAppBundleCommand(projectPath);
      expect((await commandDefault.usageValues).commandBuildAppBundleBuildMode, 'release');

      final BuildAppBundleCommand commandInRelease = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--release']);
      expect((await commandInRelease.usageValues).commandBuildAppBundleBuildMode, 'release');

      final BuildAppBundleCommand commandInDebug = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--debug']);
      expect((await commandInDebug.usageValues).commandBuildAppBundleBuildMode, 'debug');

      final BuildAppBundleCommand commandInProfile = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--profile']);
      expect((await commandInProfile.usageValues).commandBuildAppBundleBuildMode, 'profile');

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('logs success', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await runBuildAppBundleCommand(projectPath);

      expect(testUsage.events, contains(
        const TestUsageEvent('tool-command-result', 'appbundle', label: 'success'),
      ));
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
      Usage: () => testUsage,
    });
  });

  group('Gradle', () {
    Directory tempDir;
    FakeProcessManager processManager;
    FakeAndroidSdk fakeAndroidSdk;
    TestUsage testUsage;

    setUp(() {
      testUsage = TestUsage();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      processManager = FakeProcessManager.any();
      fakeAndroidSdk = FakeAndroidSdk(globals.fs.directory('irrelevant'));
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
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
        ProcessManager: () => processManager,
      });
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'app-not-using-android-x',
          parameters: CustomDimensions(),
        ),
      ));
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => fakeAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      Usage: () => testUsage,
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
        isNot(containsIgnoringWhitespace("Your app isn't using AndroidX")),
      );
      expect(
        testLogger.statusText,
        isNot(
          containsIgnoringWhitespace(
            'To avoid potential build failures, you can quickly migrate your app by '
            'following the steps on https://goo.gl/CP92wY'),
        )
      );

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'app-using-android-x',
          parameters: CustomDimensions(),
        ),
      ));
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => fakeAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      Usage: () => testUsage,
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

class FakeAndroidSdk extends Fake implements AndroidSdk {
  FakeAndroidSdk(this.directory);

  @override
  final Directory directory;
}
