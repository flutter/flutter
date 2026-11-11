// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart'
    show templateAndroidGradlePluginVersion;
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_appbundle.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:process/process.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart'
    show
        FakeAndroidContext,
        FakeBuildSystem,
        FakeFlutterVersion,
        FakeOperatingSystemUtils,
        FakeToolContext,
        TestFeatureFlags;
import '../../src/test_flutter_command_runner.dart';

final localFs = LocalFileSystem.test(signals: FakeSignals());
const Platform localPlatform = LocalPlatform();

void main() {
  Cache.disableLocking();

  tearDownAll(() async {
    await localFs.dispose();
  });

  group('analytics', () {
    late Directory tempDir;
    late FakeAnalytics fakeAnalytics;
    late FakeProcessInfo processInfo;

    setUp(() {
      tempDir = localFs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: MemoryFileSystem.test(),
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      processInfo = FakeProcessInfo();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext(
      'indicate the default target platforms',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        await runBuildAppBundleCommand(projectPath);

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: false,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(),
      },
    );

    testUsingContext(
      'reports hcpp analytics false when the manifest is silent and the feature flag is off',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        await runBuildAppBundleCommand(
          projectPath,
          projectFactory: FakeFlutterProjectFactory(tempDir),
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: false,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(),
      },
    );

    testUsingContext(
      'reports hcpp analytics from the enable-hcpp feature flag when the manifest is silent',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        // The manifest does not set EnableHcpp, so the build injects the feature flag value
        // and the packaged app has HCPP on.
        await runBuildAppBundleCommand(
          projectPath,
          projectFactory: FakeFlutterProjectFactory(tempDir),
        );
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: true,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(isHcppEnabled: true),
      },
    );

    testUsingContext(
      'reports hcpp analytics from an explicit --enable-hcpp flag when not in the manifest',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        // The manifest does not set EnableHcpp, so the build injects the flag value and the
        // packaged app has HCPP on. Analytics has to report what was packaged, not what the
        // source manifest happened to say.
        await runBuildAppBundleCommand(
          projectPath,
          arguments: <String>['--enable-hcpp'],
          projectFactory: FakeFlutterProjectFactory(tempDir),
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: true,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(),
      },
    );

    testUsingContext(
      'reports hcpp analytics from an explicit --no-enable-hcpp flag',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        await runBuildAppBundleCommand(
          projectPath,
          arguments: <String>['--no-enable-hcpp'],
          projectFactory: FakeFlutterProjectFactory(tempDir),
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: false,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(),
      },
    );

    testUsingContext('alias aab', () async {
      final command = BuildAppBundleCommand(
        androidBuilder: FakeAndroidBuilder(),
        androidContext: FakeAndroidContext(),
        buildSystem: FakeBuildSystem(),
        templateRenderer: const MustacheTemplateRenderer(),
        toolContext: FakeToolContext(logger: BufferLogger.test()),
      );
      expect(command.aliases, contains('aab'));
    });

    testUsingContext(
      'build type',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        await runBuildAppBundleCommand(projectPath);
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: false,
            ),
          ),
        );

        fakeAnalytics.sentEvents.clear();
        await runBuildAppBundleCommand(projectPath, arguments: <String>['--release']);
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'release',
              buildBundleEnableHcpp: false,
            ),
          ),
        );

        fakeAnalytics.sentEvents.clear();
        await runBuildAppBundleCommand(projectPath, arguments: <String>['--debug']);
        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'debug',
              buildBundleEnableHcpp: false,
            ),
          ),
        );

        fakeAnalytics.sentEvents.clear();
        await runBuildAppBundleCommand(projectPath, arguments: <String>['--profile']);

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.commandUsageValues(
              workflow: 'appbundle',
              commandHasTerminal: false,
              buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
              buildAppBundleBuildMode: 'profile',
              buildBundleEnableHcpp: false,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        FeatureFlags: () => TestFeatureFlags(),
      },
    );

    testUsingContext(
      'logs success',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        await runBuildAppBundleCommand(projectPath);

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterCommandResult(
              commandPath: 'create',
              result: 'success',
              commandHasTerminal: false,
              hostArch: FakeOperatingSystemUtils().hostPlatform.cliName,
              maxRss: processInfo.maxRss,
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        ProcessInfo: () => processInfo,
      },
    );

    group('Impeller AndroidManifest.xml setting', () {
      // Adds a key-value `<meta-data>` pair to the `<application>` tag in the
      // corresponding `AndroidManifest.xml` file, right before the closing
      // `</application>` tag.
      void writeManifestMetadata({
        required String projectPath,
        required String name,
        required String value,
      }) {
        final String manifestPath = localFs.path.join(
          projectPath,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        );

        // It would be unnecessarily complicated to parse this XML file and
        // insert the key-value pair, so we just insert it right before the
        // closing </application> tag.
        final String oldManifest = localFs.file(manifestPath).readAsStringSync();
        final String newManifest = oldManifest.replaceFirst(
          '</application>',
          '    <meta-data\n'
              '        android:name="$name"\n'
              '        android:value="$value" />\n'
              '    </application>',
        );
        localFs.file(manifestPath).writeAsStringSync(newManifest);
      }

      testUsingContext(
        'a default appbundle build reports Impeller as enabled',
        () async {
          final String projectPath = await createProject(
            tempDir,
            arguments: <String>['--empty', '--no-pub', '--template=app'],
          );

          final Directory oldCwd = localFs.currentDirectory;
          try {
            localFs.currentDirectory = localFs.directory(projectPath);
            await runBuildAppBundleCommand(projectPath);
          } finally {
            localFs.currentDirectory = oldCwd;
          }

          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterBuildInfo(label: 'manifest-impeller-enabled', buildType: 'android'),
            ),
          );
        },
        overrides: <Type, Generator>{
          AndroidBuilder: () => FakeAndroidBuilder(),
          Analytics: () => fakeAnalytics,
          ProcessInfo: () => processInfo,
        },
      );

      testUsingContext(
        'EnableImpeller="true" reports an enabled event',
        () async {
          final String projectPath = await createProject(
            tempDir,
            arguments: <String>['--empty', '--no-pub', '--template=app'],
          );

          writeManifestMetadata(
            projectPath: projectPath,
            name: 'io.flutter.embedding.android.EnableImpeller',
            value: 'true',
          );

          final Directory oldCwd = localFs.currentDirectory;
          try {
            localFs.currentDirectory = localFs.directory(projectPath);
            await runBuildAppBundleCommand(projectPath);
          } finally {
            localFs.currentDirectory = oldCwd;
          }

          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterBuildInfo(label: 'manifest-impeller-enabled', buildType: 'android'),
            ),
          );
        },
        overrides: <Type, Generator>{
          AndroidBuilder: () => FakeAndroidBuilder(),
          Analytics: () => fakeAnalytics,
          ProcessInfo: () => processInfo,
        },
      );

      testUsingContext(
        'EnableImpeller="false" reports a disabled event',
        () async {
          final String projectPath = await createProject(
            tempDir,
            arguments: <String>['--empty', '--no-pub', '--template=app'],
          );

          writeManifestMetadata(
            projectPath: projectPath,
            name: 'io.flutter.embedding.android.EnableImpeller',
            value: 'false',
          );

          final Directory oldCwd = localFs.currentDirectory;
          try {
            localFs.currentDirectory = localFs.directory(projectPath);
            await runBuildAppBundleCommand(projectPath);
          } finally {
            localFs.currentDirectory = oldCwd;
          }

          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterBuildInfo(label: 'manifest-impeller-disabled', buildType: 'android'),
            ),
          );
        },
        overrides: <Type, Generator>{
          AndroidBuilder: () => FakeAndroidBuilder(),
          Analytics: () => fakeAnalytics,
          ProcessInfo: () => processInfo,
        },
      );
    });

    testUsingContext(
      'use of the deferred components feature sends a build info event indicating so',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--empty', '--no-pub', '--template=app'],
        );

        // Add deferred manifest.
        final File pubspec = localFs.directory(projectPath).childFile('pubspec.yaml');
        final String modifiedContents = pubspec.readAsStringSync().replaceAll(
          'flutter:',
          'flutter:\n  deferred-components:',
        );
        pubspec.writeAsStringSync(modifiedContents);
        printOnFailure(pubspec.readAsStringSync());

        final Directory oldCwd = localFs.currentDirectory;
        try {
          localFs.currentDirectory = localFs.directory(projectPath);
          await runBuildAppBundleCommand(projectPath);
        } finally {
          localFs.currentDirectory = oldCwd;
        }

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterBuildInfo(
              label: 'build-appbundle-deferred-components',
              buildType: 'android',
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => FakeAndroidBuilder(),
        Analytics: () => fakeAnalytics,
        ProcessInfo: () => processInfo,
      },
    );
  });

  group('Gradle', () {
    late Directory tempDir;
    late FakeProcessManager processManager;
    late FakeAndroidSdk androidSdk;
    late FakeAnalytics analytics;
    late BufferLogger logger;

    setUp(() {
      analytics = getInitializedFakeAnalyticsInstance(
        fs: MemoryFileSystem.test(),
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      tempDir = localFs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      processManager = FakeProcessManager.any();
      androidSdk = FakeAndroidSdk(localFs.directory('irrelevant'));
      logger = BufferLogger.test();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      testUsingContext(
        'throws throwsToolExit if AndroidSdk is null',
        () async {
          final String projectPath = await createProject(
            tempDir,
            arguments: <String>['--no-pub', '--template=app'],
          );

          await expectLater(
            () async {
              await runBuildAppBundleCommand(
                projectPath,
                androidSdk: null,
                arguments: <String>['--no-pub'],
                logger: logger,
                processManager: processManager,
                projectFactory: FakeFlutterProjectFactory(tempDir),
              );
            },
            throwsToolExit(
              message: 'No Android SDK found. Try setting the ANDROID_HOME environment variable',
            ),
          );
        },
        overrides: <Type, Generator>{
          FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
          ProcessManager: () => processManager,
        },
      );
    });

    testUsingContext(
      "reports when the app isn't using AndroidX",
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );
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
            androidSdk: androidSdk,
            logger: logger,
            processManager: processManager,
            projectFactory: FakeFlutterProjectFactory(tempDir),
          );
        }, throwsToolExit());

        expect(
          logger.statusText,
          isNot(containsIgnoringWhitespace("Your app isn't using AndroidX")),
        );

        expect(
          analytics.sentEvents,
          contains(
            Event.flutterBuildInfo(
              label: 'app-not-using-android-x',
              buildType: 'gradle',
              settings: 'androidGradlePluginVersion: $templateAndroidGradlePluginVersion',
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => androidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        Logger: () => logger,
        ProcessManager: () => processManager,
        Analytics: () => analytics,
      },
    );

    testUsingContext(
      'reports when the app is using AndroidX',
      () async {
        final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

        // The command throws a [ToolExit] because it expects an AAB in the file system.
        await expectLater(() async {
          await runBuildAppBundleCommand(
            projectPath,
            androidSdk: androidSdk,
            logger: logger,
            processManager: processManager,
            projectFactory: FakeFlutterProjectFactory(tempDir),
          );
        }, throwsToolExit());

        expect(
          logger.statusText,
          isNot(containsIgnoringWhitespace("Your app isn't using AndroidX")),
        );
        expect(
          logger.statusText,
          isNot(
            containsIgnoringWhitespace(
              'To avoid potential build failures, you can quickly migrate your app by '
              'following the steps on https://goo.gl/CP92wY',
            ),
          ),
        );

        expect(
          analytics.sentEvents,
          contains(
            Event.flutterBuildInfo(
              label: 'app-using-android-x',
              buildType: 'gradle',
              settings: 'androidGradlePluginVersion: $templateAndroidGradlePluginVersion',
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => androidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        Logger: () => logger,
        ProcessManager: () => processManager,
        Analytics: () => analytics,
      },
    );
  });
}

Future<BuildAppBundleCommand> runBuildAppBundleCommand(
  String target, {
  AndroidBuilder? androidBuilder,
  AndroidSdk? androidSdk = const _FakeAndroidSdk(),
  List<String>? arguments,
  Logger? logger,
  ProcessManager? processManager,
  FlutterProjectFactory? projectFactory,
}) async {
  final Logger resolvedLogger = logger ?? BufferLogger.test();
  final ProcessManager resolvedProcessManager = processManager ?? const LocalProcessManager();
  final String flutterRoot = getFlutterRoot();
  final cache = Cache.test(
    flutterRoot: flutterRoot,
    rootOverride: localFs.directory(flutterRoot),
    fileSystem: localFs,
    logger: resolvedLogger,
    platform: localPlatform,
    processManager: resolvedProcessManager,
  );
  final command = BuildAppBundleCommand(
    androidBuilder: androidBuilder ?? context.get<AndroidBuilder>()!,
    androidContext: FakeAndroidContext(androidSdk: androidSdk),
    buildSystem: FlutterBuildSystem(
      fileSystem: localFs,
      logger: resolvedLogger,
      platform: localPlatform,
    ),
    templateRenderer: const MustacheTemplateRenderer(),
    toolContext: FakeToolContext(
      cache: cache,
      fs: localFs,
      logger: resolvedLogger,
      platform: localPlatform,
      processManager: resolvedProcessManager,
      projectFactory: projectFactory,
    ),
  );
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'appbundle',
    ...?arguments,
    '--no-pub',
    localFs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  FakeAndroidSdk(this.directory);

  @override
  final Directory directory;
}

final class _FakeAndroidSdk with Fake implements AndroidSdk {
  const _FakeAndroidSdk();
}

class FakeProcessInfo extends Fake implements ProcessInfo {
  @override
  int maxRss = 123456789;
}
