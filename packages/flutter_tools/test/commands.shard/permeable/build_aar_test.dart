// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_aar.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:process/process.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' hide FakeFlutterProjectFactory;
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

final localFs = LocalFileSystem.test(signals: FakeSignals());
const Platform localPlatform = LocalPlatform();

void main() {
  Cache.disableLocking();

  tearDownAll(() async {
    await localFs.dispose();
  });

  FakeToolContext createLocalToolContext({
    Logger? logger,
    OperatingSystemUtils? os,
    ProcessManager? processManager,
    FlutterProjectFactory? projectFactory,
  }) {
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
    return FakeToolContext(
      cache: cache,
      fs: localFs,
      logger: resolvedLogger,
      os: os ?? FakeOperatingSystemUtils(),
      platform: localPlatform,
      processManager: resolvedProcessManager,
      projectFactory: projectFactory,
    );
  }

  Future<String> createModuleProject(Directory tempDir) {
    return createProject(
      tempDir,
      arguments: <String>['--no-pub', '--template=module'],
      toolContext: createLocalToolContext(),
    );
  }

  /// Runs the equivalent of `flutter build aar`.
  ///
  /// If [arguments] are provided, they are appended to the end, i.e.:
  /// ```sh
  /// flutter build aar [arguments]
  /// ```
  ///
  /// If [androidSdk] is provided, it is used, otherwise defaults to [_FakeAndroidSdk].
  Future<BuildAarCommand> runBuildAar(
    String target, {
    Analytics? analytics,
    AndroidBuilder? androidBuilder,
    AndroidSdk? androidSdk = const _FakeAndroidSdk(),
    AndroidStudio? androidStudio,
    List<String>? arguments,
    FeatureFlags? featureFlags,
    Logger? logger,
    ProcessManager? processManager,
    FlutterProjectFactory? projectFactory,
    Pub? pub,
  }) async {
    final Analytics resolvedAnalytics = analytics ?? const NoOpAnalytics();
    final Logger resolvedLogger = logger ?? BufferLogger.test();
    final os = FakeOperatingSystemUtils();
    final FakeToolContext toolContext = createLocalToolContext(
      logger: resolvedLogger,
      os: os,
      processManager: processManager,
      projectFactory: projectFactory,
    );
    final androidContext = FakeAndroidContext(
      androidSdk: androidSdk,
      androidStudio: androidStudio,
      gradleUtils: GradleUtils(
        cache: toolContext.cache,
        logger: resolvedLogger,
        operatingSystemUtils: os,
        platform: localPlatform,
      ),
    );
    final command = BuildAarCommand(
      androidBuilder:
          androidBuilder ??
          AndroidGradleBuilder.fromContexts(
            analytics: resolvedAnalytics,
            androidContext: androidContext,
            toolContext: toolContext,
          ),
      androidContext: androidContext,
      buildSystem: FlutterBuildSystem(
        fileSystem: localFs,
        logger: resolvedLogger,
        platform: localPlatform,
      ),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = createTestCommandRunner(
      command,
      resolvedAnalytics,
      null,
      featureFlags,
      pub,
    );
    await runner.run(<String>['aar', ...?arguments, target]);
    return command;
  }

  group('Usage', () {
    late Directory tempDir;
    late FakeAnalytics analytics;

    setUp(() {
      analytics = getInitializedFakeAnalyticsInstance(
        fs: MemoryFileSystem.test(),
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      tempDir = localFs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    test('indicate that project is a module', () async {
      final String projectPath = await createModuleProject(tempDir);

      await runBuildAar(
        projectPath,
        analytics: analytics,
        androidBuilder: _CapturingFakeAndroidBuilder(),
        arguments: <String>['--no-pub'],
      );
      expect(
        analytics.sentEvents,
        contains(
          Event.commandUsageValues(
            workflow: 'aar',
            buildAarProjectType: 'module',
            buildAarTargetPlatform: 'android-arm,android-arm64,android-x64',
            commandHasTerminal: false,
          ),
        ),
      );
    });

    test('indicate the target platform', () async {
      final String projectPath = await createModuleProject(tempDir);

      await runBuildAar(
        projectPath,
        analytics: analytics,
        androidBuilder: _CapturingFakeAndroidBuilder(),
        arguments: <String>['--no-pub', '--target-platform=android-arm'],
      );
      expect(
        analytics.sentEvents,
        contains(
          Event.commandUsageValues(
            workflow: 'aar',
            buildAarProjectType: 'module',
            buildAarTargetPlatform: 'android-arm',
            commandHasTerminal: false,
          ),
        ),
      );
    });

    // Regression test for https://github.com/flutter/flutter/issues/162649.
    test('triggers builds even with --pub', () async {
      final String projectPath = await createModuleProject(tempDir);

      await runBuildAar(
        projectPath,
        analytics: analytics,
        androidBuilder: _CapturingFakeAndroidBuilder(),
        arguments: <String>['--target-platform=android-arm'],
        pub: FakePub(),
        // If we use --no-pub, it bypasses validation that occurs only on a
        // build with --pub, which as a consequence means that we aren't
        // testing every code branch.
      );
    });

    test('logs success', () async {
      final String projectPath = await createModuleProject(tempDir);

      await runBuildAar(
        projectPath,
        analytics: analytics,
        androidBuilder: _CapturingFakeAndroidBuilder(),
        arguments: <String>['--no-pub', '--target-platform=android-arm'],
      );

      final Iterable<Event> successEvent = analytics.sentEvents.where(
        (Event e) =>
            e.eventName == DashEvent.flutterCommandResult &&
            e.eventData['commandPath'] == 'aar' &&
            e.eventData['result'] == 'success',
      );
      expect(successEvent, isNotEmpty, reason: 'Tool should send aar success event');
    });
  });

  group('flag parsing', () {
    late Directory tempDir;
    late _CapturingFakeAndroidBuilder fakeAndroidBuilder;

    setUp(() {
      fakeAndroidBuilder = _CapturingFakeAndroidBuilder();
      tempDir = localFs.systemTempDirectory.createTempSync('flutter_tools_build_aar_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    test('defaults', () async {
      final String projectPath = await createModuleProject(tempDir);
      await runBuildAar(
        projectPath,
        arguments: <String>['--no-pub'],
        androidBuilder: fakeAndroidBuilder,
      );

      expect(
        fakeAndroidBuilder.capturedBuildAarCalls,
        hasLength(1),
        reason: 'A single call to buildAar was expected.',
      );
      final Invocation buildAarCall = fakeAndroidBuilder.capturedBuildAarCalls.single;
      expect(buildAarCall.namedArguments[#buildNumber], '1.0');

      final buildModes = <BuildMode>[];
      for (final androidBuildInfo
          in buildAarCall.namedArguments[#androidBuildInfo] as Set<AndroidBuildInfo>) {
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
        expect(androidBuildInfo.targetArchs, <CpuArch>[CpuArch.armv7, CpuArch.arm64, CpuArch.x64]);
      }
      expect(buildModes, hasLength(3));
      expect(
        buildModes,
        containsAll(<BuildMode>[BuildMode.debug, BuildMode.profile, BuildMode.release]),
      );
    });

    test('parses flags', () async {
      final String projectPath = await createModuleProject(tempDir);
      await runBuildAar(
        projectPath,
        arguments: <String>[
          '--no-pub',
          '--no-debug',
          '--no-profile',
          '--target-platform',
          'android-x64',
          '--tree-shake-icons',
          '--flavor',
          'free',
          '--build-number',
          '200',
          '--split-debug-info',
          '/project-name/v1.2.3/',
          '--obfuscate',
          '--dart-define=foo=bar',
        ],
        androidBuilder: fakeAndroidBuilder,
      );

      expect(
        fakeAndroidBuilder.capturedBuildAarCalls,
        hasLength(1),
        reason: 'A single call to buildAar was expected.',
      );
      final Invocation buildAarCall = fakeAndroidBuilder.capturedBuildAarCalls.single;
      expect(buildAarCall.namedArguments[#buildNumber], '200');

      final AndroidBuildInfo androidBuildInfo =
          (buildAarCall.namedArguments[#androidBuildInfo] as Set<AndroidBuildInfo>).single;
      expect(androidBuildInfo.targetArchs, <CpuArch>[CpuArch.x64]);

      final BuildInfo buildInfo = androidBuildInfo.buildInfo;
      expect(buildInfo.mode, BuildMode.release);
      expect(buildInfo.treeShakeIcons, isTrue);
      expect(buildInfo.flavor, 'free');
      expect(buildInfo.splitDebugInfoPath, '/project-name/v1.2.3/');
      expect(buildInfo.dartObfuscation, isTrue);
      expect(buildInfo.dartDefines.contains('foo=bar'), isTrue);
    });

    test(
      'pipes the enable-hcpp feature flag through, but the plugin ignores it for aars',
      () async {
        final String projectPath = await createModuleProject(tempDir);
        await runBuildAar(
          projectPath,
          arguments: <String>['--no-pub'],
          androidBuilder: fakeAndroidBuilder,
          featureFlags: TestFeatureFlags(isHcppEnabled: true),
        );

        final Invocation buildAarCall = fakeAndroidBuilder.capturedBuildAarCalls.single;
        for (final androidBuildInfo
            in buildAarCall.namedArguments[#androidBuildInfo] as Set<AndroidBuildInfo>) {
          // The property is piped to the aar gradle build for consistency, but the Flutter
          // Gradle Plugin only consumes it for application projects: injecting into a module
          // (aar) manifest would conflict with an explicit value in the add-to-app host's
          // manifest and fail the host build in the manifest merger.
          expect(androidBuildInfo.buildInfo.androidGradleConfig.enableHcpp, isTrue);
        }
      },
    );

    test('does not define --enable-hcpp', () async {
      final String projectPath = await createModuleProject(tempDir);
      // HCPP for add-to-app is controlled by the host app's manifest; an aar
      // level flag would be a silent no-op, so the command must reject it.
      await expectLater(
        runBuildAar(
          projectPath,
          arguments: <String>['--no-pub', '--no-enable-hcpp'],
          androidBuilder: fakeAndroidBuilder,
        ),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('Gradle', () {
    late Directory tempDir;
    late String gradlew;
    late FakeProcessManager processManager;
    late String flutterRoot;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      tempDir = localFs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: MemoryFileSystem.test(),
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      gradlew = localFs.path.join(
        tempDir.path,
        'flutter_project',
        '.android',
        localPlatform.isWindows ? 'gradlew.bat' : 'gradlew',
      );
      processManager = FakeProcessManager.empty();
      flutterRoot = getFlutterRoot();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      test('throws throwsToolExit if AndroidSdk is null', () async {
        final String projectPath = await createModuleProject(tempDir);

        await expectLater(
          () async {
            await runBuildAar(
              projectPath,
              androidSdk: null,
              arguments: <String>['--no-pub'],
              processManager: FakeProcessManager.any(),
              projectFactory: FakeFlutterProjectFactory(tempDir),
            );
          },
          throwsToolExit(
            message: 'No Android SDK found. Try setting the ANDROID_HOME environment variable',
          ),
        );
      });
    });

    group('throws ToolExit', () {
      test('main.dart not found', () async {
        await expectLater(() async {
          await runBuildAar(
            'missing_project',
            arguments: <String>[
              '--no-pub',
              localFs.path.join('missing_project', 'lib', 'main.dart'),
            ],
          );
        }, throwsToolExit(message: 'main.dart does not exist'));
      });

      test('flutter project not valid', () async {
        await expectLater(() async {
          await runBuildAar(tempDir.path, arguments: <String>['--no-pub']);
        }, throwsToolExit(message: 'is not a valid flutter project'));
      });
    });

    late AndroidSdk androidSdk;
    test('support ExtraDartFlagOptions', () async {
      final String projectPath = await createModuleProject(tempDir);
      final Directory sdkDir = tempDir.childDirectory('android-sdk');
      sdkDir
          .childDirectory('ndk')
          .childDirectory('21.1.6352462')
          .childFile('source.properties')
          .createSync(recursive: true);
      androidSdk = FakeAndroidSdk(sdkDir);
      final List<String> installedNdkVersions =
          androidSdk.directory
              .childDirectory('ndk')
              .listSync()
              .whereType<Directory>()
              .map((Directory dir) => dir.basename)
              .where(
                (String version) => androidSdk.directory
                    .childDirectory('ndk')
                    .childDirectory(version)
                    .childFile('source.properties')
                    .existsSync(),
              )
              .toList()
            ..sort();
      final ndkProvisioningProperties = <String>[
        '-Pflutter.androidSdkRoot=${androidSdk.directory.path}',
        '-Pflutter.installedNdkVersions=${installedNdkVersions.join(',')}',
        if (androidSdk.sdkManagerPath != null &&
            androidSdk.cmdlineToolsAvailable &&
            androidSdk.licensesAvailable)
          '-Pflutter.sdkManagerPath=${androidSdk.sdkManagerPath!}',
      ];

      processManager.addCommand(
        FakeCommand(
          command: <String>[
            gradlew,
            '-I=${localFs.path.join(flutterRoot, 'packages', 'flutter_tools', 'gradle', 'aar_init_script.gradle')}',
            '-Pflutter-root=$flutterRoot',
            '-Poutput-dir=${localFs.path.join(tempDir.path, 'flutter_project', 'build', 'host')}',
            '-Pis-plugin=false',
            '-PbuildNumber=1.0',
            '-q',
            '-Ptarget=${localFs.path.join('lib', 'main.dart')}',
            '-Pdart-defines=${encodeDartDefinesMap(<String, String>{
              'FLUTTER_BUILD_NAME': '1.0.0',
              'FLUTTER_BUILD_NUMBER': '1',
              'FLUTTER_VERSION': '0.0.0', //
              'FLUTTER_CHANNEL': 'master',
              'FLUTTER_GIT_URL': 'https://github.com/flutter/flutter.git',
              'FLUTTER_FRAMEWORK_REVISION': '11111',
              'FLUTTER_ENGINE_REVISION': 'abcde',
              'FLUTTER_DART_VERSION': '12',
            })}',
            '-Pdart-obfuscation=false',
            '-Pextra-front-end-options=foo,bar',
            '-Ptrack-widget-creation=true',
            '-Ptree-shake-icons=true',
            '-Penable-hcpp=false',
            ...ndkProvisioningProperties,
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            'assembleAarRelease',
          ],
          exitCode: 1,
        ),
      );

      await expectLater(
        () => runBuildAar(
          projectPath,
          androidSdk: androidSdk,
          androidStudio: _FakeAndroidStudio(),
          featureFlags: TestFeatureFlags(isIOSEnabled: false),
          processManager: processManager,
          projectFactory: FakeFlutterProjectFactory(tempDir),
          arguments: <String>[
            '--no-pub',
            '--no-debug',
            '--no-profile',
            '--extra-front-end-options=foo',
            '--extra-front-end-options=bar',
          ],
        ),
        throwsToolExit(message: 'Gradle task assembleAarRelease failed with exit code 1'),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

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
          '.android',
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

      test('a default AAR build reports Impeller as enabled', () async {
        final String projectPath = await createModuleProject(tempDir);

        await runBuildAar(
          projectPath,
          analytics: fakeAnalytics,
          androidBuilder: _CapturingFakeAndroidBuilder(),
          arguments: <String>['--no-pub'],
          projectFactory: FakeFlutterProjectFactory(tempDir),
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterBuildInfo(label: 'manifest-aar-impeller-enabled', buildType: 'android'),
          ),
        );
      });

      test('EnableImpeller="true" reports an enabled event', () async {
        final logger = BufferLogger.test();
        final os = FakeOperatingSystemUtils();
        final projectFactory = FakeFlutterProjectFactory(tempDir);
        final FakeToolContext toolContext = createLocalToolContext(
          logger: logger,
          os: os,
          processManager: processManager,
          projectFactory: projectFactory,
        );
        final String projectPath = await createModuleProject(tempDir);
        final FlutterProject project = FlutterProject.fromDirectory(
          localFs.directory(projectPath),
          logger: logger,
        );
        await project.android.ensureReadyForPlatformSpecificTooling(
          toolContext: toolContext,
          gradleUtils: GradleUtils(
            cache: toolContext.cache,
            logger: logger,
            operatingSystemUtils: os,
            platform: localPlatform,
          ),
          templatePathProvider: TemplatePathProvider(flutterRoot: flutterRoot),
          templateRenderer: const MustacheTemplateRenderer(),
        );

        writeManifestMetadata(
          projectPath: projectPath,
          name: 'io.flutter.embedding.android.EnableImpeller',
          value: 'true',
        );

        await runBuildAar(
          projectPath,
          analytics: fakeAnalytics,
          androidBuilder: _CapturingFakeAndroidBuilder(),
          arguments: <String>['--no-pub'],
          logger: logger,
          processManager: processManager,
          projectFactory: projectFactory,
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterBuildInfo(label: 'manifest-aar-impeller-enabled', buildType: 'android'),
          ),
        );
      });

      test('EnableImpeller="false" reports a disabled event', () async {
        final logger = BufferLogger.test();
        final os = FakeOperatingSystemUtils();
        final projectFactory = FakeFlutterProjectFactory(tempDir);
        final FakeToolContext toolContext = createLocalToolContext(
          logger: logger,
          os: os,
          processManager: processManager,
          projectFactory: projectFactory,
        );
        final String projectPath = await createModuleProject(tempDir);
        final FlutterProject project = FlutterProject.fromDirectory(
          localFs.directory(projectPath),
          logger: logger,
        );
        await project.android.ensureReadyForPlatformSpecificTooling(
          toolContext: toolContext,
          gradleUtils: GradleUtils(
            cache: toolContext.cache,
            logger: logger,
            operatingSystemUtils: os,
            platform: localPlatform,
          ),
          templatePathProvider: TemplatePathProvider(flutterRoot: flutterRoot),
          templateRenderer: const MustacheTemplateRenderer(),
        );

        writeManifestMetadata(
          projectPath: projectPath,
          name: 'io.flutter.embedding.android.EnableImpeller',
          value: 'false',
        );

        await runBuildAar(
          projectPath,
          analytics: fakeAnalytics,
          androidBuilder: _CapturingFakeAndroidBuilder(),
          arguments: <String>['--no-pub'],
          logger: logger,
          processManager: processManager,
          projectFactory: projectFactory,
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterBuildInfo(label: 'manifest-aar-impeller-disabled', buildType: 'android'),
          ),
        );
      });
    });
  });
}

/// A fake implementation of [AndroidBuilder] that allows [buildAar] calls.
///
/// Calls to [buildAar] are stored as [capturedBuildAarCalls], other calls are rejected.
final class _CapturingFakeAndroidBuilder extends Fake implements AndroidBuilder {
  final capturedBuildAarCalls = <Invocation>[];

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #buildAar) {
      return super.noSuchMethod(invocation);
    }
    capturedBuildAarCalls.add(invocation);
    return Future<void>.value();
  }
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  FakeAndroidSdk(this.directory, {this.sdkManagerPath});

  @override
  final Directory directory;

  @override
  final String? sdkManagerPath;

  @override
  bool get cmdlineToolsAvailable => true;

  @override
  bool get licensesAvailable => true;
}

final class _FakeAndroidSdk with Fake implements AndroidSdk {
  const _FakeAndroidSdk();
}

final class _FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String get javaPath => 'java';
}

class FakePub extends Fake implements Pub {
  @override
  Future<void> get({
    PubContext? context,
    required FlutterProject project,
    bool upgrade = false,
    bool offline = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool enforceLockfile = false,
    PubOutputMode outputMode = PubOutputMode.all,
  }) async {}
}
