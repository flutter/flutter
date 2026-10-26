// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/experimental/extension_artifact_manager.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

final class _RecordingExtensionBuildManager extends ExtensionBuildManager {
  _RecordingExtensionBuildManager()
    : super(
        extensionManager: ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          hostPlatform: HostPlatform.linux_x64,
          logger: BufferLogger.test(),
        ),
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        logger: BufferLogger.test(),
      );

  Map<String, Object?>? lastBuildArgs;

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) async {
    lastBuildArgs = <String, Object?>{
      'buildMode': buildMode,
      'flutterRoot': flutterRoot,
      'mainPath': mainPath,
      'outputDir': outputDir,
      'projectRoot': projectRoot,
      'resolvedArtifacts': resolvedArtifacts,
      'targetName': targetName,
    };
    return const ExtensionBuildResult(success: true);
  }
}

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget({
    required super.description,
    required this.name,
    this.errorMessage,
    super.outputDir = '${BuiltInPlaceholders.outputDir}/custom',
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  final String? errorMessage;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return shouldSucceed
        ? const ExtensionBuildResult(success: true)
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Build failed.');
  }
}

final class _SucceedingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[
    _TestBuildTarget(description: 'Hermetic custom build target.', name: 'custom-hermetic-build'),
  ];
}

void _succeedingBuildExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_SucceedingBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _FailingAndConflictingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[
    _TestBuildTarget(
      description: 'Failing custom build target.',
      name: 'failing-build',
      shouldSucceed: false,
      errorMessage: 'Custom build compilation error.',
    ),
    _TestBuildTarget(description: 'Conflicting bundle target.', name: 'bundle'),
    _TestBuildTarget(description: 'Empty target name that should be skipped.', name: ''),
  ];
}

void _failingBuildExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_FailingAndConflictingBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _FirstDuplicateBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[
    _TestBuildTarget(description: 'First extension shared target.', name: 'shared-target'),
  ];
}

void _firstDuplicateExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_FirstDuplicateBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _SecondDuplicateBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[
    _TestBuildTarget(
      description: 'Second extension shared target.',
      name: 'shared-target',
      shouldSucceed: false,
      errorMessage: 'Second connection should have been skipped.',
    ),
  ];
}

void _secondDuplicateExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_SecondDuplicateBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _ThrowingQueryBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => throw StateError('Simulated getBuildTargets failure');
}

void _throwingQueryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_ThrowingQueryBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

void main() {
  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '/flutter';
  });

  group('Tool Extensions Build Integration - Disabled', () {
    testUsingContext(
      'ExtensionBuildManager.getBuildTargets() returns empty list when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final targets = <ExtensionBuildTarget>[...await buildManager.getBuildTargets()];
        expect(targets, isEmpty);

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'ExtensionBuildManager.build() returns failure when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-linux-build',
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, 'Tool extensions are disabled.');

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'BuildCommand does not include custom subcommands when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final command = BuildCommand(
          androidContext: FakeAndroidContext(),
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionArtifactManager: _FakeExtensionArtifactManager(),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(fs: MemoryFileSystem.test(), logger: testLogger),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);
        try {
          await commandRunner.run(<String>['build', '-h']);
        } on ToolExit {
          // Expected to exit or print help.
        }

        expect(command.subcommands.containsKey('custom-linux-build'), isFalse);

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );
  });

  group('Tool Extensions Build Integration - Enabled', () {
    late MemoryFileSystem fs;

    setUp(() {
      final String? oldFlutterRoot = Cache.flutterRoot;
      addTearDown(() => Cache.flutterRoot = oldFlutterRoot);
      Cache.flutterRoot = '/flutter';

      fs = MemoryFileSystem.test();
      fs.directory('/flutter').createSync(recursive: true);
      fs.file('/pubspec.yaml').createSync();
      fs.file('/lib/main.dart').createSync(recursive: true);
    });

    testUsingContext(
      'ExtensionBuildManager.getBuildTargets() returns custom targets when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final targets = <ExtensionBuildTarget>[...await buildManager.getBuildTargets()];
        expect(targets, hasLength(1));
        expect(targets.first.name, equals('custom-linux-build'));
        expect(buildManager.cachedTargets, equals(targets));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testWithoutContext('ExtensionBuildManager.getBuildTargets() logs warning when querying targets from extension fails', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[_throwingQueryExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      final List<ExtensionBuildTarget> targets = await buildManager.getBuildTargets();
      expect(targets, isEmpty);
      expect(logger.warningText, contains('Failed to query build targets from extension:'));

      await manager.dispose();
    });

    testUsingContext(
      'ExtensionBuildManager.build() throws ArgumentError when directories are relative',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        await expectLater(
          () => buildManager.build(
            buildMode: .debug,
            flutterRoot: Uri.parse('/flutter'),
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('/out'),
            projectRoot: Uri.parse('relative/path'),
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-linux-build',
          ),
          throwsArgumentError,
        );

        await expectLater(
          () => buildManager.build(
            buildMode: .debug,
            flutterRoot: Uri.parse('relative/flutter'),
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('/out'),
            projectRoot: Uri.parse('/'),
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-linux-build',
          ),
          throwsArgumentError,
        );

        await expectLater(
          () => buildManager.build(
            buildMode: .debug,
            flutterRoot: Uri.parse('/flutter'),
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('relative/out'),
            projectRoot: Uri.parse('/'),
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-linux-build',
          ),
          throwsArgumentError,
        );

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionBuildManager.build() returns failure for unknown target',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'non-existent-target',
        );
        expect(result.success, isFalse);
        expect(
          result.errorMessage,
          'No extension found to handle build target non-existent-target.',
        );

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionBuildManager deduplicates targets across multiple extension entrypoints in order',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[
            _firstDuplicateExtensionEntryPoint,
            _secondDuplicateExtensionEntryPoint,
          ],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final List<ExtensionBuildTarget> targets = await buildManager.getBuildTargets();
        expect(targets, hasLength(1));
        expect(targets.first.name, 'shared-target');
        expect(targets.first.description, 'First extension shared target.');
        expect(
          testLogger.warningText,
          contains('Skipping duplicate build target "shared-target" from extension.'),
        );

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'shared-target',
        );
        expect(result.success, isTrue);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'BuildCommand includes custom subcommand and can run it when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[_succeedingBuildExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );
        final fakeArtifactManager = _FakeExtensionArtifactManager();

        final command = BuildCommand(
          androidContext: FakeAndroidContext(),
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionArtifactManager: fakeArtifactManager,
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(fs: fs, logger: testLogger),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await commandRunner.run(<String>['build', 'custom-hermetic-build', '--no-pub']);

        expect(command.subcommands.containsKey('custom-hermetic-build'), isTrue);
        expect(fakeArtifactManager.ensureArtifactsDownloadedCalled, isTrue);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'ExtensionBuildSubCommand forwards flutterRoot, outputDir, and resolvedArtifacts in build parameters',
      () async {
        final fakeBuildManager = _RecordingExtensionBuildManager();
        final fakeArtifactManager = _FakeExtensionArtifactManager(
          downloadedArtifacts: const <String, String>{
            'custom-ext-artifact': '/cache/custom-ext-artifact',
          },
        );
        const target = ExtensionBuildTarget(
          artifacts: <ExtensionArtifact>{ExtensionArtifact('custom-ext-artifact')},
          description: 'Custom hermetic build target.',
          name: 'custom-hermetic-build',
          outputDir:
              '${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
          targetPlatform: 'linux-x64',
        );

        final subCommand = ExtensionBuildSubCommand(
          artifactManager: fakeArtifactManager,
          buildManager: fakeBuildManager,
          target: target,
          toolContext: FakeToolContext(fs: fs, logger: testLogger),
          verboseHelp: false,
        );

        final FlutterCommandResult result = await subCommand.runCommand();
        expect(result.exitStatus, ExitStatus.success);
        expect(fakeArtifactManager.ensureArtifactsDownloadedCalled, isTrue);
        expect(fakeArtifactManager.requestedTargetPlatforms, equals(const <String>{'linux-x64'}));

        expect(fakeBuildManager.lastBuildArgs, isNotNull);
        expect(fakeBuildManager.lastBuildArgs!['targetName'], equals('custom-hermetic-build'));
        expect(
          fakeBuildManager.lastBuildArgs!['flutterRoot'],
          equals(fs.directory('/flutter').uri),
        );
        expect(
          fakeBuildManager.lastBuildArgs!['outputDir'],
          equals(fs.directory('/build/custom/linux-x64/release').uri),
        );
        expect(
          fakeBuildManager.lastBuildArgs!['resolvedArtifacts'],
          equals(const <String, String>{'custom-ext-artifact': '/cache/custom-ext-artifact'}),
        );
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testWithoutContext('ExtensionBuildSubCommand resolves {OUTPUT_DIR} using custom build-dir from Config', () async {
      final buildManager = _RecordingExtensionBuildManager();
      const target = ExtensionBuildTarget(
        description: 'Custom hermetic build target.',
        name: 'custom-hermetic-build',
        outputDir:
            '${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
        targetPlatform: 'linux-x64',
      );
      final config = Config.test()..setValue('build-dir', 'custom_build_root');
      final subCommand = ExtensionBuildSubCommand(
        artifactManager: _FakeExtensionArtifactManager(),
        buildManager: buildManager,
        target: target,
        toolContext: FakeToolContext(config: config, fs: fs, logger: BufferLogger.test()),
        verboseHelp: false,
      );

      final FlutterCommandResult result = await subCommand.runCommand();
      expect(result.exitStatus, ExitStatus.success);
      expect(
        buildManager.lastBuildArgs!['outputDir'],
        equals(fs.directory('/custom_build_root/custom/linux-x64/release').uri),
      );
    });

    testWithoutContext(
      'ExtensionBuildSubCommand throws ToolExit when outputDir contains unsupported placeholder',
      () async {
        final buildManager = _RecordingExtensionBuildManager();
        const target = ExtensionBuildTarget(
          description: 'Custom hermetic build target.',
          name: 'custom-hermetic-build',
          outputDir: '${BuiltInPlaceholders.buildDir}/custom',
          targetPlatform: 'linux-x64',
        );
        final subCommand = ExtensionBuildSubCommand(
          artifactManager: _FakeExtensionArtifactManager(),
          buildManager: buildManager,
          target: target,
          toolContext: FakeToolContext(fs: fs, logger: BufferLogger.test()),
          verboseHelp: false,
        );

        await expectLater(
          subCommand.runCommand(),
          throwsToolExit(
            message: 'Unsupported placeholder "{BUILD_DIR}" in outputDir "{BUILD_DIR}/custom" for build target "custom-hermetic-build".',
          ),
        );
      },
    );

    testUsingContext(
      'BuildCommand preserves built-in subcommands on collision and throws ToolExit on failed extension build',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[_failingBuildExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final command = BuildCommand(
          androidContext: FakeAndroidContext(),
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionArtifactManager: _FakeExtensionArtifactManager(),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(fs: fs, logger: testLogger),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await expectLater(
          () => commandRunner.run(<String>['build', 'failing-build', '--no-pub']),
          throwsToolExit(message: 'Build failed: Custom build compilation error.'),
        );

        expect(
          testLogger.warningText,
          contains(
            'Skipping custom build target "bundle" because a subcommand with that name already exists.',
          ),
        );
        expect(command.subcommands['bundle'], isA<BuildBundleCommand>());
        expect(command.subcommands.containsKey(''), isFalse);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'BuildCommand includes custom subcommand in help when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: testLogger,
        );

        final command = BuildCommand(
          androidContext: FakeAndroidContext(),
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionArtifactManager: _FakeExtensionArtifactManager(),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(fs: fs, logger: testLogger),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await commandRunner.run(<String>['build', '-h']);

        expect(command.subcommands.containsKey('custom-linux-build'), isTrue);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}

class _FakeExtensionArtifactManager extends Fake implements ExtensionArtifactManager {
  _FakeExtensionArtifactManager({this.downloadedArtifacts = const <String, String>{}});

  final Map<String, String> downloadedArtifacts;
  bool ensureArtifactsDownloadedCalled = false;
  Set<String>? requestedTargetPlatforms;

  @override
  Future<Map<String, String>> ensureArtifactsDownloaded({
    bool force = false,
    Set<String>? targetPlatforms,
  }) async {
    ensureArtifactsDownloadedCalled = true;
    requestedTargetPlatforms = targetPlatforms;
    return downloadedArtifacts;
  }
}
