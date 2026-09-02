// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();
  late MemoryFileSystem fileSystem;
  late FakeBundleBuilder fakeBundleBuilder;
  late FakeAnalytics fakeAnalytics;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory('/flutter/bin/cache').createSync(recursive: true);
    fakeBundleBuilder = FakeBundleBuilder();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
  });

  void setUpMockProjectFiles({bool isModule = false}) {
    fileSystem
        .file('pubspec.yaml')
        .writeAsStringSync(
          isModule
              ? '''
name: my_app
flutter:
  module:
    androidPackage: com.example.my_app
'''
              : '''
name: my_app
flutter:
  uses-material-design: true
''',
        );
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  BuildBundleCommand createBuildBundleCommand({
    Analytics? analytics,
    BuildSystem? buildSystem,
    BundleBuilder? bundleBuilder,
    FeatureFlags? featureFlags,
    BufferLogger? logger,
    Platform? platform,
    ProcessManager? processManager,
    bool verboseHelp = false,
  }) {
    final BufferLogger effectiveLogger = logger ?? BufferLogger.test();
    final ToolContext toolContext = FakeToolContext(
      cache: Cache.test(
        rootOverride: fileSystem.directory('/flutter'),
        logger: effectiveLogger,
        processManager: processManager ?? FakeProcessManager.any(),
      ),
      fs: fileSystem,
      logger: effectiveLogger,
      platform: platform ?? FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/flutter'}),
      processManager: processManager ?? FakeProcessManager.any(),
      projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: effectiveLogger),
    );
    return BuildBundleCommand(
      analytics: analytics ?? fakeAnalytics,
      buildSystem: buildSystem ?? TestBuildSystem.all(BuildResult(success: true)),
      bundleBuilder: bundleBuilder ?? fakeBundleBuilder,
      featureFlags: featureFlags ?? TestFeatureFlags(),
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    );
  }

  Future<BuildBundleCommand> runCommandIn(
    String projectPath, {
    List<String>? arguments,
    BuildBundleCommand? command,
  }) async {
    final BuildBundleCommand effectiveCommand = command ?? createBuildBundleCommand();
    final CommandRunner<void> runner = createTestCommandRunner(effectiveCommand);
    await runner.run(<String>[
      'bundle',
      ...?arguments,
      '--target=$projectPath/lib/main.dart',
      '--no-pub',
    ]);
    return effectiveCommand;
  }

  testWithoutContext('bundle getUsage indicate that project is a module', () async {
    setUpMockProjectFiles(isModule: true);

    await runCommandIn(fileSystem.currentDirectory.path);

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.commandUsageValues(
          workflow: 'bundle',
          commandHasTerminal: false,
          buildBundleTargetPlatform: 'android-arm',
          buildBundleIsModule: true,
        ),
      ),
    );
  });

  testWithoutContext('bundle getUsage indicate that project is not a module', () async {
    setUpMockProjectFiles();

    await runCommandIn(fileSystem.currentDirectory.path);

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.commandUsageValues(
          workflow: 'bundle',
          commandHasTerminal: false,
          buildBundleTargetPlatform: 'android-arm',
          buildBundleIsModule: false,
        ),
      ),
    );
  });

  testWithoutContext('bundle getUsage indicate the target platform', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = await runCommandIn(fileSystem.currentDirectory.path);

    expect(
      (await command.unifiedAnalyticsUsageValues('bundle')).eventData['buildBundleTargetPlatform'],
      'android-arm',
    );
  });

  testWithoutContext('bundle fails to build for Windows if feature is disabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(featureFlags: TestFeatureFlags());
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      () => runner.run(<String>['bundle', '--no-pub', '--target-platform=windows-x64']),
      throwsToolExit(message: 'Windows is not a supported target platform.'),
    );
  });

  testWithoutContext('bundle fails to build for Linux if feature is disabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(featureFlags: TestFeatureFlags());
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      () => runner.run(<String>['bundle', '--no-pub', '--target-platform=linux-x64']),
      throwsToolExit(message: 'Linux is not a supported target platform.'),
    );
  });

  testWithoutContext('bundle fails to build for macOS if feature is disabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(featureFlags: TestFeatureFlags());
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      () => runner.run(<String>['bundle', '--no-pub', '--target-platform=darwin']),
      throwsToolExit(message: 'macOS is not a supported target platform.'),
    );
  });

  testWithoutContext('bundle --tree-shake-icons fails', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      () => runner.run(<String>['bundle', '--no-pub', '--release', '--tree-shake-icons']),
      throwsToolExit(message: 'tree-shake-icons'),
    );
  });

  testWithoutContext('bundle can build for Windows if feature is enabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(
      featureFlags: TestFeatureFlags(isWindowsEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['bundle', '--no-pub', '--target-platform=windows-x64']);
  });

  testWithoutContext('bundle can build for Linux if feature is enabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['bundle', '--no-pub', '--target-platform=linux-x64']);
  });

  testWithoutContext('bundle can build for macOS if feature is enabled', () async {
    setUpMockProjectFiles();
    final BuildBundleCommand command = createBuildBundleCommand(
      featureFlags: TestFeatureFlags(isMacOSEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['bundle', '--no-pub', '--target-platform=darwin']);
  });

  testWithoutContext('passes track widget creation through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--track-widget-creation',
    ]);
  });

  testWithoutContext('passes dart-define through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kDartDefines:
              'Zm9vPWJhcg==,RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--dart-define=foo=bar',
    ]);
  });

  testWithoutContext('passes filesystem-scheme through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--filesystem-scheme=org-dartlang-root2',
    ]);
  });

  testWithoutContext('passes filesystem-roots through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kFileSystemRoots: 'test1,test2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--filesystem-root=test1,test2',
    ]);
  });

  testWithoutContext('passes extra frontend-options through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kExtraFrontEndOptions: '--testflag,--testflag2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--extra-front-end-options=--testflag,--testflag2',
    ]);
  });

  testWithoutContext('passes extra gen_snapshot-options through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'debug',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kExtraGenSnapshotOptions: '--testflag,--testflag2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--debug',
      '--target-platform=android-arm',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
    ]);
  });

  testWithoutContext('passes profile options through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'profile',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'Zm9vPWJhcg==,RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kFileSystemRoots: 'test1,test2',
          kExtraGenSnapshotOptions: '--testflag,--testflag2',
          kExtraFrontEndOptions: '--testflagFront,--testflagFront2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--profile',
      '--dart-define=foo=bar',
      '--target-platform=android-arm',
      '--track-widget-creation',
      '--filesystem-scheme=org-dartlang-root',
      '--filesystem-root=test1,test2',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
      '--extra-front-end-options=--testflagFront,--testflagFront2',
    ]);
  });

  testWithoutContext('passes release options through', () async {
    setUpMockProjectFiles();

    final BuildBundleCommand command = createBuildBundleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          kBuildMode: 'release',
          kTargetPlatform: 'android-arm',
          kTargetFile: fileSystem.path.join('lib', 'main.dart'),
          kDartDefines:
              'Zm9vPWJhcg==,RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          kTrackWidgetCreation: 'true',
          kFileSystemScheme: 'org-dartlang-root',
          kFileSystemRoots: 'test1,test2',
          kExtraGenSnapshotOptions: '--testflag,--testflag2',
          kExtraFrontEndOptions: '--testflagFront,--testflagFront2',
          kIconTreeShakerFlag: 'false',
          kDeferredComponents: 'false',
          kDartObfuscation: 'false',
        });
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--release',
      '--dart-define=foo=bar',
      '--target-platform=android-arm',
      '--track-widget-creation',
      '--filesystem-scheme=org-dartlang-root',
      '--filesystem-root=test1,test2',
      '--extra-gen-snapshot-options=--testflag,--testflag2',
      '--extra-front-end-options=--testflagFront,--testflagFront2',
    ]);
  });
}

class FakeBundleBuilder extends Fake implements BundleBuilder {
  @override
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    bool buildNativeAssets = true,
    @visibleForTesting BuildSystem? buildSystem,
  }) async {}
}
