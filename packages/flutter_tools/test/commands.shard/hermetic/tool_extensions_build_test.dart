// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
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

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget({
    required super.description,
    required this.name,
    this.artifacts = const <ExtensionArtifact>{},
    this.errorMessage,
    super.outputDir,
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  @override
  final Set<ExtensionArtifact> artifacts;

  final String? errorMessage;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return shouldSucceed
        ? const ExtensionBuildResult(success: true)
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Build failed.');
  }
}

final class _TestAssembleTarget extends AssembleTarget {
  const _TestAssembleTarget({
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
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return shouldSucceed
        ? const ExtensionBuildResult(success: true)
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Assemble failed.');
  }
}

final class _SucceedingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[
    _TestBuildTarget(
      description: 'Hermetic custom build target.',
      name: 'custom-hermetic-build',
      outputDir:
          '${BuiltInPlaceholders.projectDir}/build/hermetic/${BuiltInPlaceholders.buildMode}',
    ),
  ];

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[
    _TestAssembleTarget(
      description: 'Hermetic assemble-only target.',
      name: 'custom-hermetic-assemble-only',
    ),
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
    _TestBuildTarget(
      description: 'Custom build target with custom embedder platform.',
      name: 'custom-platform-build',
      targetPlatform: 'custom-embedder-arm64',
      artifacts: <ExtensionArtifact>{BuiltInArtifacts.icuData},
    ),
    _TestBuildTarget(
      description: 'Custom build target with unsupported artifact.',
      name: 'unsupported-artifact-build',
      artifacts: <ExtensionArtifact>{ExtensionArtifact('unsupported-artifact')},
    ),
    _TestBuildTarget(description: 'Conflicting bundle target.', name: 'bundle'),
    _TestBuildTarget(description: 'Empty target name that should be skipped.', name: ''),
  ];

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[
    _TestAssembleTarget(description: 'Conflicting copy_assets target.', name: 'copy_assets'),
    _TestAssembleTarget(
      description: 'Succeeding custom assemble target.',
      name: 'custom-assemble-target',
    ),
    _TestAssembleTarget(
      description: 'Empty assemble target name that should be skipped.',
      name: '',
    ),
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

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[
    _TestAssembleTarget(
      description: 'First extension shared assemble target.',
      name: 'shared-assemble-target',
    ),
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

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[
    _TestAssembleTarget(
      description: 'Second extension shared assemble target.',
      name: 'shared-assemble-target',
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
    testWithoutContext('ExtensionBuildManager.getBuildTargets() and getAssembleTargets() return empty lists when feature flag disabled', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      final List<ExtensionBuildTarget> buildTargets = await buildManager.getBuildTargets();
      expect(buildTargets, isEmpty);
      final List<ExtensionAssembleTarget> assembleTargets = await buildManager.getAssembleTargets();
      expect(assembleTargets, isEmpty);

      await manager.dispose();
    });

    testWithoutContext(
      'ExtensionBuildManager.build() and assemble() return failure when feature flag disabled',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final ExtensionBuildResult buildResult = await buildManager.build(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-linux-build',
        );
        expect(buildResult.success, isFalse);
        expect(buildResult.errorMessage, 'Tool extensions are disabled.');

        final ExtensionBuildResult assembleResult = await buildManager.assemble(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-linux-assemble-only-debug',
        );
        expect(assembleResult.success, isFalse);
        expect(assembleResult.errorMessage, 'Tool extensions are disabled.');

        await manager.dispose();
      },
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

    testWithoutContext('ExtensionBuildManager.getBuildTargets() and getAssembleTargets() return custom targets when feature flag enabled', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      final List<ExtensionBuildTarget> buildTargets = await buildManager.getBuildTargets();
      expect(
        buildTargets.map((ExtensionBuildTarget t) => t.name),
        equals(<String>['custom-linux-build']),
      );
      expect(buildManager.cachedTargets, equals(buildTargets));

      final List<ExtensionAssembleTarget> assembleTargets = await buildManager.getAssembleTargets();
      expect(
        assembleTargets.map((ExtensionAssembleTarget t) => t.name),
        equals(<String>['custom-linux-assemble-only-debug']),
      );
      expect(buildManager.cachedAssembleTargets, equals(assembleTargets));
      expect(
        assembleTargets.single.dependencies,
        equals(<String>['copy_assets', 'kernel_snapshot_program']),
      );

      await manager.dispose();
    });

    testWithoutContext('ExtensionBuildManager.build() throws ArgumentError when projectRoot, outputDir, or buildDir is relative', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
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
    });

    testWithoutContext(
      'ExtensionBuildManager.build() and assemble() return failure for unknown target',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final ExtensionBuildResult buildResult = await buildManager.build(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'non-existent-target',
        );
        expect(buildResult.success, isFalse);
        expect(
          buildResult.errorMessage,
          'No extension found to handle build target non-existent-target.',
        );

        final ExtensionBuildResult assembleResult = await buildManager.assemble(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'non-existent-assemble-target',
        );
        expect(assembleResult.success, isFalse);
        expect(
          assembleResult.errorMessage,
          'No extension found to handle assemble target non-existent-assemble-target.',
        );

        await manager.dispose();
      },
    );

    testWithoutContext(
      'ExtensionBuildManager deduplicates targets across multiple extension entrypoints in order',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[
            _firstDuplicateExtensionEntryPoint,
            _secondDuplicateExtensionEntryPoint,
          ],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final List<ExtensionBuildTarget> buildTargets = await buildManager.getBuildTargets();
        expect(buildTargets, hasLength(1));
        expect(buildTargets.first.name, 'shared-target');
        expect(buildTargets.first.description, 'First extension shared target.');
        expect(
          logger.warningText,
          contains('Skipping duplicate build target "shared-target" from extension.'),
        );

        final ExtensionBuildResult buildResult = await buildManager.build(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'shared-target',
        );
        expect(buildResult.success, isTrue);

        final List<ExtensionAssembleTarget> assembleTargets = await buildManager
            .getAssembleTargets();
        expect(assembleTargets, hasLength(1));
        expect(assembleTargets.first.name, 'shared-assemble-target');
        expect(assembleTargets.first.description, 'First extension shared assemble target.');
        expect(
          logger.warningText,
          contains('Skipping duplicate assemble target "shared-assemble-target" from extension.'),
        );

        final ExtensionBuildResult assembleResult = await buildManager.assemble(
          buildDir: Uri.parse('/.dart_tool/flutter_build'),
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/build'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'shared-assemble-target',
        );
        expect(assembleResult.success, isTrue);

        await manager.dispose();
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

        await commandRunner.run(<String>['build', 'custom-hermetic-build', '--no-pub']);

        expect(command.subcommands.containsKey('custom-hermetic-build'), isTrue);
        expect(command.subcommands.containsKey('custom-hermetic-assemble-only'), isFalse);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testWithoutContext('AssembleCommand lazily queries extensions only for non-default targets and resolves dependencies', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      Target? builtTarget;
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(fileSystem: fs),
        cache: Cache.test(processManager: FakeProcessManager.any()),
        fs: fs,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      final defaultCommand = AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          builtTarget = target;
        }),
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: toolContext,
      );
      final CommandRunner<void> defaultRunner = createTestCommandRunner(defaultCommand);
      await defaultRunner.run(<String>[
        'assemble',
        '-o',
        '/out',
        '-d',
        'BuildMode=debug',
        'copy_assets',
      ]);
      expect(builtTarget?.name, equals('copy_assets'));
      // Built-in targets should not trigger extension isolate initialization.
      expect(buildManager.cachedTargets, isEmpty);
      expect(buildManager.cachedAssembleTargets, isEmpty);

      final customCommand = AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          builtTarget = target;
        }),
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: toolContext,
      );
      final CommandRunner<void> customRunner = createTestCommandRunner(customCommand);
      await customRunner.run(<String>[
        'assemble',
        '-o',
        '/out',
        '-d',
        'BuildMode=debug',
        'custom-linux-assemble-only-debug',
      ]);

      expect(builtTarget, isNotNull);
      expect(builtTarget!.name, equals('custom-linux-assemble-only-debug'));
      expect(
        builtTarget!.dependencies.map((Target t) => t.name),
        equals(<String>['copy_assets', 'kernel_snapshot_program']),
      );

      await manager.dispose();
    });

    testWithoutContext(
      'AssembleCommand executes extension target through FlutterBuildSystem',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[_succeedingBuildExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );
        final buildSystem = FlutterBuildSystem(
          fileSystem: fs,
          logger: logger,
          platform: FakePlatform(),
        );
        final command = AssembleCommand(
          buildSystem: buildSystem,
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: Cache.test(processManager: FakeProcessManager.any()),
            fs: fs,
            logger: logger,
            processManager: FakeProcessManager.any(),
          ),
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>[
          'assemble',
          '-o',
          '/out',
          '-d',
          'BuildMode=debug',
          'custom-hermetic-assemble-only',
        ]);

        expect(logger.traceText, contains('build succeeded.'));
        expect(fs.directory('/out').existsSync(), isTrue);

        await manager.dispose();
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

        await commandRunner.run(<String>['build', 'custom-platform-build', '--no-pub']);

        await expectLater(
          () => commandRunner.run(<String>['build', 'unsupported-artifact-build', '--no-pub']),
          throwsToolExit(
            message: 'Unsupported artifact "unsupported-artifact" requested by a tool extension.',
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

        final assembleCommand = AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: Cache.test(processManager: FakeProcessManager.any()),
            fs: fs,
            logger: testLogger,
            processManager: FakeProcessManager.any(),
          ),
        );
        final CommandRunner<void> assembleRunner = createTestCommandRunner(assembleCommand);
        await assembleRunner.run(<String>[
          'assemble',
          '-o',
          '/out',
          '-d',
          'BuildMode=debug',
          'copy_assets',
          'custom-assemble-target',
        ]);
        expect(
          testLogger.warningText,
          contains(
            'Skipping custom assemble target "copy_assets" because a target with that name already exists.',
          ),
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
