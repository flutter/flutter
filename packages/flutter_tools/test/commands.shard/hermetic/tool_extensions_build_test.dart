// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

final class _FailingAndConflictingBuildService extends BuildService {
  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(description: 'Failing custom build target.', name: 'failing-build'),
      ExtensionBuildTarget(description: 'Conflicting bundle target.', name: 'bundle'),
      ExtensionBuildTarget(description: 'Empty target name that should be skipped.', name: ''),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    return const ExtensionBuildResult(
      success: false,
      errorMessage: 'Custom build compilation error.',
    );
  }
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
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(description: 'First extension shared target.', name: 'shared-target'),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    return const ExtensionBuildResult(success: true);
  }
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
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(description: 'Second extension shared target.', name: 'shared-target'),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    return const ExtensionBuildResult(
      success: false,
      errorMessage: 'Second connection should have been skipped.',
    );
  }
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
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('/'),
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
        expect(targets, hasLength(1));
        expect(targets.first.name, equals('custom-linux-build'));
        expect(buildManager.cachedTargets, equals(targets));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionBuildManager.build() throws ArgumentError when projectRoot is relative',
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
            mainPath: 'lib/main.dart',
            projectRoot: Uri.parse('relative/path'),
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
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('/'),
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
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('/'),
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
          toolContext: FakeToolContext(fs: fs, logger: testLogger),
        );

        final CommandRunner<void> commandRunner = createTestCommandRunner(command);

        await commandRunner.run(<String>['build', 'custom-linux-build', '--no-pub']);

        expect(command.subcommands.containsKey('custom-linux-build'), isTrue);

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
