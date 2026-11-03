// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
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
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

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
    Map<String, bool> buildFlags = const <String, bool>{},
    String? buildName,
    String? buildNumber,
    Map<String, String?> buildOptions = const <String, String?>{},
    Uri? codeSizeDirectory,
    Map<String, String?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetDeviceId,
    String? targetPlatform,
    bool? trackWidgetCreation,
    bool? treeShakeIcons,
  }) async {
    lastBuildArgs = <String, Object?>{
      'buildFlags': buildFlags,
      'buildMode': buildMode,
      'buildName': buildName,
      'buildNumber': buildNumber,
      'buildOptions': buildOptions,
      'codeSizeDirectory': codeSizeDirectory,
      'configuration': configuration,
      'dartDefines': dartDefines,
      'dartObfuscation': dartObfuscation,
      'extraFrontEndOptions': extraFrontEndOptions,
      'extraGenSnapshotOptions': extraGenSnapshotOptions,
      'flavor': flavor,
      'flutterRoot': flutterRoot,
      'mainPath': mainPath,
      'outputDir': outputDir,
      'projectRoot': projectRoot,
      'resolvedArtifacts': resolvedArtifacts,
      'splitDebugInfo': splitDebugInfo,
      'targetDeviceId': targetDeviceId,
      'targetName': targetName,
      'targetPlatform': targetPlatform,
      'trackWidgetCreation': trackWidgetCreation,
      'treeShakeIcons': treeShakeIcons,
    };
    return const ExtensionBuildResult(success: true);
  }
}

final class _TestBuildTarget extends BuildTarget {
  _TestBuildTarget({
    required super.description,
    required this.name,
    this.artifacts = const <ExtensionArtifact>{},
    this.errorMessage,
    super.outputDir = '${BuiltInPlaceholders.outputDir}/custom',
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
    this.dependencies = const <String>[],
    this.depfiles = const <String>[],
    this.errorMessage,
    this.extraDefines = const <String, String>{},
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  @override
  final List<String> dependencies;

  @override
  final List<String> depfiles;

  final String? errorMessage;
  final Map<String, String> extraDefines;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    return shouldSucceed
        ? ExtensionBuildResult(success: true, extraDefines: extraDefines)
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Assemble failed.');
  }
}

final class _SucceedingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[
    _TestBuildTarget(
      description: 'Hermetic custom build target.',
      name: 'custom-hermetic-build',
      outputDir: '${BuiltInPlaceholders.outputDir}/hermetic/${BuiltInPlaceholders.buildMode}',
    ),
    _TestBuildTarget(
      description: 'Hermetic platform-agnostic build target.',
      name: 'custom-agnostic-build',
      outputDir: '${BuiltInPlaceholders.outputDir}/agnostic/${BuiltInPlaceholders.buildMode}',
      targetPlatform: null,
    ),
  ];

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[
    _TestAssembleTarget(
      description: 'Hermetic assemble-only target.',
      name: 'custom-hermetic-assemble-only',
      depfiles: <String>['custom_hermetic.d'],
      extraDefines: <String, String>{'HermeticDefine': 'enabled'},
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
  List<BuildTarget> get buildTargets => <BuildTarget>[
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
      artifacts: const <ExtensionArtifact>{BuiltInArtifacts.icuData},
    ),
    _TestBuildTarget(
      description: 'Custom build target with unsupported artifact.',
      name: 'unsupported-artifact-build',
      artifacts: const <ExtensionArtifact>{ExtensionArtifact('unsupported-artifact')},
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
      description: 'Assemble target with unknown dependency.',
      name: 'unknown-dep-assemble-target',
      dependencies: <String>['non-existent-dep'],
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
  List<BuildTarget> get buildTargets => <BuildTarget>[
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
  List<BuildTarget> get buildTargets => <BuildTarget>[
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

final class _ThrowingQueryBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => throw StateError('Simulated getBuildTargets failure');

  @override
  List<AssembleTarget> get assembleTargets =>
      throw StateError('Simulated getAssembleTargets failure');
}

void _throwingQueryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_ThrowingQueryBuildService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _TestConfigService extends ConfigurationExtension {
  @override
  String get title => 'Test Custom Embedder Configuration';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async => const <FeatureFlag>[
    FeatureFlag(
      help: 'Enable custom embedder support.',
      enabledByDefault: true,
      name: 'enable-custom-embedder',
    ),
  ];

  @override
  Future<List<ConfigOption>> getConfigurations() async => const <ConfigOption>[
    ConfigOption(
      help: 'Path to custom embedder SDK.',
      name: 'custom-embedder-sdk',
      value: '/default/sdk',
    ),
  ];
}

final class _SecondaryConfigService extends ConfigurationExtension {
  @override
  String get title => 'Secondary Embedder Configuration';

  @override
  Future<List<ConfigOption>> getConfigurations() async => const <ConfigOption>[
    ConfigOption(
      help: 'Path to secondary embedder SDK.',
      name: 'secondary-embedder-sdk',
      value: '/default/secondary-sdk',
    ),
  ];
}

final class _CapturingBuildTarget extends BuildTarget {
  _CapturingBuildTarget(this._capturePort)
    : super(
        description: 'Capturing build target.',
        outputDir:
            '${BuiltInPlaceholders.outputDir}/captured/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
        targetPlatform: 'linux-x64',
        targetPlatforms: const <String>{'linux-x64', 'linux-arm64'},
      );

  final SendPort _capturePort;

  @override
  String get name => 'capturing-build';

  @override
  List<BuildFlag> get buildFlags => const <BuildFlag>[
    BuildFlag(help: 'Sign the output bundle.', name: 'sign-bundle', abbr: 's'),
    BuildFlag(help: 'Collides with built-in --pub.', name: 'pub'),
    BuildFlag(help: 'Collides with built-in -t.', name: 'collide-abbr', abbr: 't'),
  ];

  @override
  List<BuildOption> get buildOptions => const <BuildOption>[
    BuildOption(
      help: 'Select bundle format.',
      name: 'bundle-format',
      allowed: <String>['ipk', 'tar'],
      defaultsTo: 'ipk',
    ),
    BuildOption(help: 'Collides with built-in --flavor.', name: 'flavor'),
  ];

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    _capturePort.send(context.toMap());
    return const ExtensionBuildResult(success: true);
  }
}

final class _CapturingAssembleTarget extends AssembleTarget {
  const _CapturingAssembleTarget(this._capturePort, {this.targetName = 'capturing-assemble'})
    : super(description: 'Capturing assemble target.', targetPlatform: 'linux-x64');

  final SendPort _capturePort;
  final String targetName;

  @override
  String get name => targetName;

  @override
  List<ExtensionSource> get inputs => <ExtensionSource>[
    ExtensionSource.pattern('${BuiltInPlaceholders.projectDir}/pubspec.yaml'),
  ];

  @override
  List<ExtensionSource> get outputs => <ExtensionSource>[
    ExtensionSource.pattern('${BuiltInPlaceholders.outputDir}/captured.out'),
  ];

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    _capturePort.send(context.toMap());
    return const ExtensionBuildResult(success: true);
  }
}

final class _CapturingBuildService extends BuildService {
  _CapturingBuildService(this._capturePort, {this.assembleTargetName = 'capturing-assemble'});

  final SendPort _capturePort;
  final String assembleTargetName;

  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[_CapturingBuildTarget(_capturePort)];

  @override
  List<AssembleTarget> get assembleTargets => <AssembleTarget>[
    _CapturingAssembleTarget(_capturePort, targetName: assembleTargetName),
  ];
}

ExtensionEntryPoint _createCapturingExtensionEntryPoint(SendPort capturePort) {
  return (SendPort sendPort) {
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_TestConfigService(), _CapturingBuildService(capturePort)],
      supportedPlatforms: const <String>{'linux'},
    );
  };
}

ExtensionEntryPoint _createSecondaryCapturingExtensionEntryPoint(SendPort capturePort) {
  return (SendPort sendPort) {
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[
        _SecondaryConfigService(),
        _CapturingBuildService(capturePort, assembleTargetName: 'secondary-capturing-assemble'),
      ],
      supportedPlatforms: const <String>{'linux'},
    );
  };
}

final class _DeviceIdExtensionBuildSubCommand extends ExtensionBuildSubCommand {
  _DeviceIdExtensionBuildSubCommand({
    required super.buildManager,
    required super.target,
    required super.toolContext,
    required super.verboseHelp,
  });

  static final ArgResults _deviceGlobalResults = (ArgParser()..addOption('device-id', abbr: 'd'))
      .parse(<String>['-d', 'custom-device-1']);

  @override
  ArgResults? get globalResults => _deviceGlobalResults;
}

void main() {
  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '/flutter';
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
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
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
          flutterRoot: Uri.parse('/flutter'),
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
      final String? oldFlutterRoot = Cache.flutterRoot;
      addTearDown(() => Cache.flutterRoot = oldFlutterRoot);
      Cache.flutterRoot = '/flutter';

      fs = MemoryFileSystem.test();
      fs.directory('/flutter').createSync(recursive: true);
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

    testWithoutContext('ExtensionBuildManager.getBuildTargets() and getAssembleTargets() log warnings when querying targets from extension fails', () async {
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

      final List<ExtensionBuildTarget> buildTargets = await buildManager.getBuildTargets();
      expect(buildTargets, isEmpty);
      expect(
        logger.warningText,
        contains('Failed to query build targets from extension "unknown_extension":'),
      );

      final List<ExtensionAssembleTarget> assembleTargets = await buildManager.getAssembleTargets();
      expect(assembleTargets, isEmpty);
      expect(
        logger.warningText,
        contains('Failed to query assemble targets from extension "unknown_extension":'),
      );

      await manager.dispose();
    });

    testWithoutContext('ExtensionBuildManager.build() and assemble() throw ArgumentError when directories are relative', () async {
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

      await expectLater(
        () => buildManager.assemble(
          buildDir: Uri.parse('relative/build'),
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-linux-assemble-only-debug',
        ),
        throwsArgumentError,
      );

      await expectLater(
        () => buildManager.assemble(
          buildDir: Uri.parse('/build'),
          buildMode: .debug,
          flutterRoot: Uri.parse('relative/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
          projectRoot: Uri.parse('/'),
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-linux-assemble-only-debug',
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
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
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
          buildDir: Uri.parse('/build'),
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
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
          contains(
            'Skipping duplicate build target "shared-target" from extension "unknown_extension".',
          ),
        );

        final ExtensionBuildResult buildResult = await buildManager.build(
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
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
          contains(
            'Skipping duplicate assemble target "shared-assemble-target" from extension "unknown_extension".',
          ),
        );

        final ExtensionBuildResult assembleResult = await buildManager.assemble(
          buildDir: Uri.parse('/build'),
          buildMode: .debug,
          flutterRoot: Uri.parse('/flutter'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('/out'),
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
        await commandRunner.run(<String>['build', 'custom-agnostic-build', '--no-pub']);

        expect(command.subcommands.containsKey('custom-hermetic-build'), isTrue);
        expect(command.subcommands.containsKey('custom-agnostic-build'), isTrue);
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
        expect(
          buildManager.cachedAssembleTargets.single.depfiles,
          equals(<String>['custom_hermetic.d']),
        );

        await manager.dispose();
      },
    );

    testWithoutContext('ExtensionBuildSubCommand forwards flutterRoot, outputDir, and resolvedArtifacts in build parameters', () async {
      final fakeBuildManager = _RecordingExtensionBuildManager();
      final target = ExtensionBuildTarget(
        description: 'Custom hermetic build target.',
        name: 'custom-hermetic-build',
        outputDir:
            '${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
        targetPlatform: 'linux-x64',
      );

      final subCommand = ExtensionBuildSubCommand(
        buildManager: fakeBuildManager,
        target: target,
        toolContext: FakeToolContext(fs: fs, logger: BufferLogger.test()),
        verboseHelp: false,
      );

      final FlutterCommandResult result = await subCommand.runCommand();
      expect(result.exitStatus, ExitStatus.success);

      expect(fakeBuildManager.lastBuildArgs, isNotNull);
      expect(fakeBuildManager.lastBuildArgs!['targetName'], equals('custom-hermetic-build'));
      expect(fakeBuildManager.lastBuildArgs!['flutterRoot'], equals(fs.directory('/flutter').uri));
      expect(
        fakeBuildManager.lastBuildArgs!['outputDir'],
        equals(fs.directory('/build/custom/linux-x64/release').uri),
      );
      expect(fakeBuildManager.lastBuildArgs!['resolvedArtifacts'], isA<Map<String, String>>());
    });

    testWithoutContext('ExtensionBuildSubCommand resolves {OUTPUT_DIR} using custom build-dir from Config', () async {
      final buildManager = _RecordingExtensionBuildManager();
      final target = ExtensionBuildTarget(
        description: 'Custom hermetic build target.',
        name: 'custom-hermetic-build',
        outputDir:
            '${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
        targetPlatform: 'linux-x64',
      );
      final config = Config.test()..setValue('build-dir', 'custom_build_root');
      final subCommand = ExtensionBuildSubCommand(
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
        final target = ExtensionBuildTarget(
          description: 'Custom hermetic build target.',
          name: 'custom-hermetic-build',
          outputDir: '${BuiltInPlaceholders.buildDir}/custom',
          targetPlatform: 'linux-x64',
        );
        final subCommand = ExtensionBuildSubCommand(
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
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            target.dependencies;
          }),
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

        await expectLater(
          () => assembleRunner.run(<String>[
            'assemble',
            '-o',
            '/out',
            '-d',
            'BuildMode=debug',
            'unknown-dep-assemble-target',
          ]),
          throwsToolExit(
            message:
                'Target "non-existent-dep" required by "unknown-dep-assemble-target" not found. '
                'It might not be registered.',
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

    testWithoutContext('ExtensionBuildSubCommand registers custom flags, options, and multi-arch --target-platform and forwards full ExtensionBuildContext', () async {
      final captureReceivePort = ReceivePort();
      addTearDown(captureReceivePort.close);
      final capturedContexts = <ExtensionBuildContext>[];
      captureReceivePort.listen((Object? message) {
        if (message case final Map<String, Object?> map) {
          capturedContexts.add(ExtensionBuildContext.fromJson(map));
        }
      });

      final logger = BufferLogger.test();
      final config = Config.test()..setValue('custom-embedder-sdk', '/opt/custom-sdk');
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[
          _createCapturingExtensionEntryPoint(captureReceivePort.sendPort),
        ],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        config: config,
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(fileSystem: fs),
        cache: Cache.test(processManager: FakeProcessManager.any()),
        config: config,
        fs: fs,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      final ExtensionBuildTarget target = (await buildManager.getBuildTargets()).singleWhere(
        (ExtensionBuildTarget t) => t.name == 'capturing-build',
      );
      final subCommand = ExtensionBuildSubCommand(
        buildManager: buildManager,
        target: target,
        toolContext: toolContext,
        verboseHelp: false,
      );

      final CommandRunner<void> commandRunner = createTestCommandRunner(
        subCommand,
        null,
        toolContext,
        featureFlags,
      );
      await commandRunner.run(<String>[
        'capturing-build',
        '--no-pub',
        '--release',
        '--target-platform=linux-arm64',
        '--sign-bundle',
        '--bundle-format=tar',
        '--flavor=production',
        '--build-name=3.4.5',
        '--build-number=12',
        '--dart-define=ENV=prod',
        '--obfuscate',
        '--split-debug-info=rel_symbols',
        '--extra-front-end-options=--fe1,--fe2',
        '--extra-gen-snapshot-options=--gs1',
        '--no-tree-shake-icons',
        '--no-track-widget-creation',
      ]);

      expect(
        logger.warningText,
        allOf(
          contains('Skipping custom build flag "--pub" on build target "capturing-build"'),
          contains('Skipping custom build flag "--collide-abbr" on build target "capturing-build"'),
          contains('Skipping custom build option "--flavor" on build target "capturing-build"'),
        ),
      );

      expect(capturedContexts, hasLength(1));
      final ExtensionBuildContext captured = capturedContexts.single;
      expect(captured.buildMode, BuildMode.release);
      expect(captured.targetPlatform, 'linux-arm64');
      expect(captured.outputDir, fs.directory('/build/captured/linux-arm64/release').uri);
      expect(captured.buildFlags, equals(const <String, bool>{'sign-bundle': true}));
      expect(captured.buildOptions, equals(const <String, String?>{'bundle-format': 'tar'}));
      expect(captured.flavor, 'production');
      expect(captured.buildName, '3.4.5');
      expect(captured.buildNumber, '12');
      expect(captured.dartDefines, containsPair('ENV', 'prod'));
      expect(captured.dartDefines, containsPair('FLUTTER_APP_FLAVOR', 'production'));
      expect(captured.dartObfuscation, isTrue);
      expect(captured.splitDebugInfo, Uri.parse('file:///rel_symbols/'));
      expect(captured.codeSizeDirectory, isNull);
      expect(captured.extraFrontEndOptions, equals(const <String>['--fe1', '--fe2']));
      expect(captured.extraGenSnapshotOptions, equals(const <String>['--gs1']));
      expect(captured.treeShakeIcons, isFalse);
      expect(captured.trackWidgetCreation, isFalse);
      expect(captured.targetDeviceId, isNull);
      expect(
        captured.configuration,
        equals(const <String, String?>{
          'enable-custom-embedder': 'true',
          'custom-embedder-sdk': '/opt/custom-sdk',
        }),
      );

      await commandRunner.run(<String>[
        'capturing-build',
        '--no-pub',
        '--release',
        '--analyze-size',
        '--code-size-directory=rel_code_size',
      ]);
      expect(capturedContexts, hasLength(2));
      expect(capturedContexts[1].codeSizeDirectory, Uri.parse('file:///rel_code_size/'));
      expect(capturedContexts[1].trackWidgetCreation, isTrue);
      expect(capturedContexts[1].treeShakeIcons, isTrue);

      final deviceSubCommand = _DeviceIdExtensionBuildSubCommand(
        buildManager: buildManager,
        target: target,
        toolContext: toolContext,
        verboseHelp: false,
      );
      await createTestCommandRunner(
        deviceSubCommand,
        null,
        toolContext,
        featureFlags,
      ).run(<String>['capturing-build', '--no-pub']);
      expect(capturedContexts, hasLength(3));
      expect(capturedContexts[2].targetDeviceId, 'custom-device-1');

      await manager.dispose();
    });

    testWithoutContext('AssembleCommand hashes extension configuration into Environment.defines and isolates configurations across multiple extensions', () async {
      final captureReceivePort = ReceivePort();
      addTearDown(captureReceivePort.close);
      final capturedAssembleContexts = <ExtensionAssembleContext>[];
      captureReceivePort.listen((Object? message) {
        if (message case final Map<String, Object?> map) {
          capturedAssembleContexts.add(ExtensionAssembleContext.fromJson(map));
        }
      });

      final logger = BufferLogger.test();
      final config = Config.test()
        ..setValue('custom-embedder-sdk', '/sdk/v1')
        ..setValue('secondary-embedder-sdk', '/secondary/v1');
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[
          _createCapturingExtensionEntryPoint(captureReceivePort.sendPort),
          _createSecondaryCapturingExtensionEntryPoint(captureReceivePort.sendPort),
        ],
        featureFlags: featureFlags,
      );
      final buildManager = ExtensionBuildManager(
        config: config,
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      final recordedBuildDirs = <String>[];
      final pendingTargetBuilds = <Future<void>>[];
      Future<void> runAssemble(List<String> targetNames) async {
        final command = AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            recordedBuildDirs.add(environment.buildDir.path);
            if (target is CompositeTarget) {
              for (final Target dep in target.dependencies) {
                pendingTargetBuilds.add(dep.build(environment));
              }
            } else {
              pendingTargetBuilds.add(target.build(environment));
            }
          }),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: Cache.test(processManager: FakeProcessManager.any()),
            config: config,
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
          '-d',
          'CustomKey=CustomVal',
          ...targetNames,
        ]);
        await Future.wait(pendingTargetBuilds);
        pendingTargetBuilds.clear();
        await pumpEventQueue();
      }

      await runAssemble(<String>['capturing-assemble']);
      config.setValue('custom-embedder-sdk', '/sdk/v2');
      await runAssemble(<String>['capturing-assemble']);

      expect(recordedBuildDirs, hasLength(2));
      expect(recordedBuildDirs[0], isNot(equals(recordedBuildDirs[1])));
      expect(capturedAssembleContexts, hasLength(2));
      expect(capturedAssembleContexts[0].configuration['custom-embedder-sdk'], equals('/sdk/v1'));
      expect(capturedAssembleContexts[1].configuration['custom-embedder-sdk'], equals('/sdk/v2'));
      expect(
        capturedAssembleContexts[0].extraDefines,
        equals(const <String, String>{'CustomKey': 'CustomVal'}),
      );

      // Multi-extension assemble run: CompositeTarget wraps both ExtensionTargets,
      // and each extension receives only its own ConfigurationExtension keys.
      capturedAssembleContexts.clear();
      await runAssemble(<String>['capturing-assemble', 'secondary-capturing-assemble']);
      expect(capturedAssembleContexts, hasLength(2));
      expect(
        capturedAssembleContexts.map((ExtensionAssembleContext c) => c.configuration),
        unorderedEquals(<Map<String, String?>>[
          const <String, String?>{
            'enable-custom-embedder': 'true',
            'custom-embedder-sdk': '/sdk/v2',
          },
          const <String, String?>{'secondary-embedder-sdk': '/secondary/v1'},
        ]),
      );

      await manager.dispose();
    });
  });
}
