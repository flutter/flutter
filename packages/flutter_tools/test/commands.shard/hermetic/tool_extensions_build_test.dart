// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart'
    hide Artifact, HostArtifact, Source, Target;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

final class _TestExtensionTarget extends ExtensionTarget {
  const _TestExtensionTarget({
    required super.description,
    required this.name,
    this.errorMessage,
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  final String? errorMessage;
  final bool shouldSucceed;

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  Future<Map<String, Object?>> build(ExtensionBuildContext context) async {
    return <String, Object?>{'success': shouldSucceed, 'errorMessage': ?errorMessage};
  }
}

final class _FailingAndConflictingBuildService extends BuildService {
  @override
  List<ExtensionTarget> get targets => const <ExtensionTarget>[
    _TestExtensionTarget(
      description: 'Failing custom build target.',
      name: 'failing-build',
      shouldSucceed: false,
      errorMessage: 'Custom build compilation error.',
    ),
    _TestExtensionTarget(
      description: 'Custom build target with invalid platform.',
      name: 'invalid-platform-build',
      targetPlatform: 'invalid-platform',
    ),
    _TestExtensionTarget(description: 'Conflicting bundle target.', name: 'bundle'),
    _TestExtensionTarget(description: 'Empty target name that should be skipped.', name: ''),
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
  List<ExtensionTarget> get targets => const <ExtensionTarget>[
    _TestExtensionTarget(description: 'First extension shared target.', name: 'shared-target'),
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
  List<ExtensionTarget> get targets => const <ExtensionTarget>[
    _TestExtensionTarget(
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

void main() {
  setUpAll(() {
    Cache.disableLocking();
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
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
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
      fs = MemoryFileSystem.test();
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
        expect(targets, hasLength(6));
        expect(buildManager.cachedTargets, equals(targets));

        expect(targets[0].name, equals('custom-linux-build'));
        expect(targets[0].targetPlatform, equals('linux-x64'));
        expect(targets[0].isTopLevel, isTrue);
        expect(targets[0].dependencies, isEmpty);

        expect(targets[1].name, equals('custom-linux-assemble-only-debug'));
        expect(targets[1].targetPlatform, equals('linux-x64'));
        expect(targets[1].isTopLevel, isFalse);
        expect(targets[1].dependencies, equals(<String>['copy_assets', 'kernel_snapshot_program']));

        expect(targets[2].name, equals('custom-linux-aot-elf-profile'));
        expect(targets[2].targetPlatform, equals('linux-x64'));
        expect(targets[2].isTopLevel, isFalse);
        expect(targets[2].dependencies, isEmpty);

        expect(targets[3].name, equals('custom-linux-assemble-only-profile'));
        expect(targets[3].targetPlatform, equals('linux-x64'));
        expect(targets[3].isTopLevel, isFalse);
        expect(
          targets[3].dependencies,
          equals(<String>['copy_assets', 'custom-linux-aot-elf-profile']),
        );

        expect(targets[4].name, equals('custom-linux-aot-elf-release'));
        expect(targets[4].targetPlatform, equals('linux-x64'));
        expect(targets[4].isTopLevel, isFalse);
        expect(targets[4].dependencies, isEmpty);

        expect(targets[5].name, equals('custom-linux-assemble-only-release'));
        expect(targets[5].targetPlatform, equals('linux-x64'));
        expect(targets[5].isTopLevel, isFalse);
        expect(
          targets[5].dependencies,
          equals(<String>['copy_assets', 'custom-linux-aot-elf-release']),
        );

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionBuildManager.build() throws ArgumentError when projectRoot, outputDir, or buildDir is relative',
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
            buildDir: Uri.parse('/.dart_tool/flutter_build'),
            buildMode: .debug,
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('/build'),
            projectRoot: Uri.parse('relative/path'),
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-linux-build',
          ),
          throwsArgumentError,
        );

        await expectLater(
          () => buildManager.build(
            buildDir: Uri.parse('/.dart_tool/flutter_build'),
            buildMode: .debug,
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('relative/output'),
            projectRoot: Uri.parse('/project'),
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-linux-build',
          ),
          throwsArgumentError,
        );

        await expectLater(
          () => buildManager.build(
            buildDir: Uri.parse('relative/build'),
            buildMode: .debug,
            mainPath: 'lib/main.dart',
            outputDir: Uri.parse('/build'),
            projectRoot: Uri.parse('/project'),
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
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
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
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
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
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            fs: fs,
            logger: testLogger,
          ),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await commandRunner.run(<String>['build', 'custom-linux-build', '--no-pub']);

        expect(command.subcommands.containsKey('custom-linux-build'), isTrue);
        expect(command.subcommands.containsKey('custom-linux-assemble-only-debug'), isFalse);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'AssembleCommand includes custom targets and can run them when feature flag enabled',
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

        final command = AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            fs: fs,
            logger: testLogger,
          ),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await commandRunner.run(<String>[
          'assemble',
          '-o',
          '/out',
          '-d',
          'BuildMode=debug',
          'custom-linux-assemble-only-debug',
        ]);

        // Verify that the targets were created and dependencies can be resolved.
        final List<Target> targets = command.createTargets();
        expect(targets, hasLength(1));
        final Target target = targets.first;
        expect(target.name, equals('custom-linux-assemble-only-debug'));
        expect(target.dependencies, hasLength(2));
        expect(
          target.dependencies.map((Target t) => t.name),
          containsAll(<String>['copy_assets', 'kernel_snapshot_program']),
        );

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
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
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            fs: fs,
            logger: testLogger,
          ),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await expectLater(
          () => commandRunner.run(<String>['build', 'failing-build', '--no-pub']),
          throwsToolExit(message: 'Build failed: Custom build compilation error.'),
        );

        await expectLater(
          () => commandRunner.run(<String>['build', 'invalid-platform-build', '--no-pub']),
          throwsToolExit(
            message: 'Invalid target platform "invalid-platform" for extension build target "invalid-platform-build".',
          ),
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
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            fs: fs,
            logger: testLogger,
          ),
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
