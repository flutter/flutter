// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_apk.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' show FakeFlutterVersion;
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();

  group('Usage', () {
    late Directory tempDir;
    late TestUsage testUsage;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      testUsage = TestUsage();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: MemoryFileSystem.test(),
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate the default target platforms', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      final BuildApkCommand command = await runBuildApkCommand(projectPath);

      expect((await command.usageValues).commandBuildApkTargetPlatform, 'android-arm,android-arm64,android-x64');

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.commandUsageValues(
            workflow: 'apk',
            commandHasTerminal: false,
            buildApkTargetPlatform: 'android-arm,android-arm64,android-x64',
            buildApkBuildMode: 'release',
            buildApkSplitPerAbi: false,
          ),
        ),
      );
    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
      Analytics: () => fakeAnalytics,
    });

    testUsingContext('split per abi', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildApkCommand commandWithFlag = await runBuildApkCommand(projectPath,
          arguments: <String>['--split-per-abi']);
      expect((await commandWithFlag.usageValues).commandBuildApkSplitPerAbi, true);

      final BuildApkCommand commandWithoutFlag = await runBuildApkCommand(projectPath);
      expect((await commandWithoutFlag.usageValues).commandBuildApkSplitPerAbi, false);

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('build type', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildApkCommand commandDefault = await runBuildApkCommand(projectPath);
      expect((await commandDefault.usageValues).commandBuildApkBuildMode, 'release');

      final BuildApkCommand commandInRelease = await runBuildApkCommand(projectPath,
          arguments: <String>['--release']);
      expect((await commandInRelease.usageValues).commandBuildApkBuildMode, 'release');

      final BuildApkCommand commandInDebug = await runBuildApkCommand(projectPath,
          arguments: <String>['--debug']);
      expect((await commandInDebug.usageValues).commandBuildApkBuildMode, 'debug');

      final BuildApkCommand commandInProfile = await runBuildApkCommand(projectPath,
          arguments: <String>['--profile']);
      expect((await commandInProfile.usageValues).commandBuildApkBuildMode, 'profile');

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('logs success', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await runBuildApkCommand(projectPath);

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'tool-command-result',
          'apk',
          label: 'success',
        ),
      ));
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
      Usage: () => testUsage,
    });
  });

  group('Gradle', () {
    late Directory tempDir;
    late FakeProcessManager processManager;
    late String gradlew;
    late AndroidSdk mockAndroidSdk;
    late TestUsage testUsage;

    setUp(() {
      testUsage = TestUsage();
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      gradlew = globals.fs.path.join(tempDir.path, 'flutter_project', 'android',
          globals.platform.isWindows ? 'gradlew.bat' : 'gradlew');
      processManager = FakeProcessManager.empty();
      mockAndroidSdk = FakeAndroidSdk(globals.fs.directory('irrelevant'));
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      testUsingContext('throws throwsToolExit if AndroidSdk is null', () async {
        final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);

        await expectLater(
          () => runBuildApkCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          ),
          throwsToolExit(
            message: 'No Android SDK found. Try setting the ANDROID_SDK_ROOT environment variable',
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => null,
        Java: () => null,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => processManager,
        AndroidStudio: () => FakeAndroidStudio(),
      });
    });

    testUsingContext('shrinking is enabled by default on release mode', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
        exitCode: 1,
      ));

      await expectLater(
        () => runBuildApkCommand(projectPath),
        throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Java: () => null,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('--split-debug-info is enabled when an output directory is provided', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Psplit-debug-info=${tempDir.path}',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
        exitCode: 1,
      ));

      await expectLater(
        () => runBuildApkCommand(projectPath, arguments: <String>['--split-debug-info=${tempDir.path}']),
        throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Java: () => null,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('--extra-front-end-options are provided to gradle project', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Pextra-front-end-options=foo,bar',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
        exitCode: 1,
      ));

      await expectLater(() => runBuildApkCommand(projectPath, arguments: <String>[
        '--extra-front-end-options=foo',
        '--extra-front-end-options=bar',
      ]), throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'));
       expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Java: () => null,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('shrinking is disabled when --no-shrink is passed', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
        exitCode: 1,
      ));

      await expectLater(
        () => runBuildApkCommand(
          projectPath,
          arguments: <String>['--no-shrink'],
        ),
        throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Java: () => null,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('guides the user when the shrinker fails', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      const String r8StdoutWarning =
        "Execution failed for task ':app:transformClassesAndResourcesWithR8ForStageInternal'.\n"
        '> com.android.tools.r8.CompilationFailedException: Compilation failed to complete';
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
        exitCode: 1,
        stdout: r8StdoutWarning,
      ));

      await expectLater(
        () => runBuildApkCommand(
          projectPath,
        ),
        throwsToolExit(message: 'Gradle task assembleRelease failed with exit code 1'),
      );
      expect(
        testLogger.statusText, allOf(
          containsIgnoringWhitespace('The shrinker may have failed to optimize the Java bytecode.'),
          containsIgnoringWhitespace('To disable the shrinker, pass the `--no-shrink` flag to this command.'),
          containsIgnoringWhitespace('To learn more, see: https://developer.android.com/studio/build/shrink-code'),
        )
      );
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'gradle-r8-failure',
          parameters: CustomDimensions(),
        ),
      ));
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Java: () => null,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => processManager,
      Usage: () => testUsage,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext("reports when the app isn't using AndroidX", () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      // Simulate a non-androidx project.
      tempDir
        .childDirectory('flutter_project')
        .childDirectory('android')
        .childFile('gradle.properties')
        .writeAsStringSync('android.useAndroidX=false');
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
      ));

      // The command throws a [ToolExit] because it expects an APK in the file system.
      await expectLater(() =>  runBuildApkCommand(projectPath), throwsToolExit());

      expect(
        testLogger.statusText,
        allOf(
          containsIgnoringWhitespace("Your app isn't using AndroidX"),
          containsIgnoringWhitespace(
            'To avoid potential build failures, you can quickly migrate your app by '
            'following the steps on https://goo.gl/CP92wY'
          ),
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
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      Java: () => null,
      ProcessManager: () => processManager,
      Usage: () => testUsage,
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('reports when the app is using AndroidX', () async {
      final String projectPath = await createProject(tempDir, arguments: <String>['--no-pub', '--template=app', '--platform=android']);
      processManager.addCommand(FakeCommand(
        command: <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Pbase-application-name=android.app.Application',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=true',
          '-Ptree-shake-icons=true',
          'assembleRelease',
        ],
      ));

      // The command throws a [ToolExit] because it expects an APK in the file system.
      await expectLater(() => runBuildApkCommand(projectPath), throwsToolExit());

      expect(
        testLogger.statusText, allOf(
          isNot(contains("[!] Your app isn't using AndroidX")),
          isNot(contains(
            'To avoid potential build failures, you can quickly migrate your app by '
            'following the steps on https://goo.gl/CP92wY'
          ))
        ),
      );
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'app-using-android-x',
          parameters: CustomDimensions(),
        ),
      ));
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      Java: () => null,
      ProcessManager: () => processManager,
      Usage: () => testUsage,
      AndroidStudio: () => FakeAndroidStudio(),
    });
  });
}

Future<BuildApkCommand> runBuildApkCommand(
  String target, {
  List<String>? arguments,
}) async {
  final BuildApkCommand command = BuildApkCommand(logger: BufferLogger.test());
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'apk',
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

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String get javaPath => 'java';

  @override
  Version get version => Version(2021, 3, 1);
}
