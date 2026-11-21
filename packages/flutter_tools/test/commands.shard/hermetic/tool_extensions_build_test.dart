// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart' show BuildInfo, BuildMode;
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
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;
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
    required BuildInfo buildInfo,
    required FileSystem fileSystem,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
    String? targetDeviceId,
    String? targetPlatform,
  }) async {
    lastBuildArgs = <String, Object?>{
      'buildInfo': buildInfo,
      'fileSystem': fileSystem,
      'flutterRoot': flutterRoot,
      'mainPath': mainPath,
      'outputDir': outputDir,
      'projectRoot': projectRoot,
      'resolvedArtifacts': resolvedArtifacts,
      'targetDeviceId': targetDeviceId,
      'targetName': targetName,
      'targetPlatform': targetPlatform,
    };
    return const ExtensionBuildResult(success: true);
  }
}

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget({
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
    this.errorMessage,
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  @override
  final List<String> dependencies;

  final String? errorMessage;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
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
      outputDir: '${BuiltInPlaceholders.outputDir}/hermetic/${BuiltInPlaceholders.buildMode}',
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
    extensionName: 'failing_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _InvalidTargetBuildService extends ToolExtensionService {
  @override
  String get namespace => BuildService.serviceNamespace;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getBuildTargets': (_) async => <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Target with invalid name',
          'name': 'Invalid-Name',
          'outputDir': '{OUTPUT_DIR}',
          'targetPlatform': 'linux-x64',
        },
      ],
    };
  }
}

void _invalidTargetBuildExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_InvalidTargetBuildService()],
    extensionName: 'invalid_target_extension',
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
    extensionName: 'first_extension',
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
    extensionName: 'second_extension',
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

final class _DomainErrorBuildTarget extends BuildTarget {
  const _DomainErrorBuildTarget()
    : super(
        description: 'Custom target throwing ToolExtensionException',
        outputDir: '${BuiltInPlaceholders.outputDir}/custom_os',
        targetPlatform: 'linux-x64',
      );

  @override
  String get name => 'custom-os-bundle';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    throw const ToolExtensionException('Custom compiler missing.');
  }
}

final class _DomainErrorBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_DomainErrorBuildTarget()];
}

void _domainErrorBuildExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_DomainErrorBuildService()],
    extensionName: 'custom_build_ext',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _WireRecordingBuildTarget extends BuildTarget {
  const _WireRecordingBuildTarget(this._sendPort)
    : super(
        description: 'Records parsed ExtensionBuildContext.',
        outputDir: '${BuiltInPlaceholders.outputDir}/custom_os',
        targetPlatform: 'linux-x64',
      );

  final SendPort _sendPort;

  @override
  String get name => 'wire-recorded-build';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    _sendPort.send(<String, Object?>{
      'kind': 'context',
      'buildMode': context.buildMode.cliName,
      'buildName': context.buildName,
      'buildNumber': context.buildNumber,
      'dartDefines': context.dartDefines,
      'dartObfuscation': context.dartObfuscation,
      'extraFrontEndOptions': context.extraFrontEndOptions,
      'extraGenSnapshotOptions': context.extraGenSnapshotOptions,
      'flavor': context.flavor,
      'mainPath': context.mainPath,
      'splitDebugInfo': context.splitDebugInfo?.toString(),
      'targetDeviceId': context.targetDeviceId,
      'targetPlatform': context.targetPlatform,
      'trackWidgetCreation': context.trackWidgetCreation,
      'treeShakeIcons': context.treeShakeIcons,
    });
    return ExtensionBuildResult(
      success: true,
      executableUri: Uri.parse('file:///project/build/custom_os/MyApp.app/'),
    );
  }
}

final class _WireRecordingAssembleTarget extends AssembleTarget {
  const _WireRecordingAssembleTarget(this._sendPort)
    : super(description: 'Records parsed ExtensionAssembleContext.', targetPlatform: 'linux-x64');

  final SendPort _sendPort;

  @override
  String get name => 'wire-recorded-assemble';

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    _sendPort.send(<String, Object?>{
      'kind': 'assemble_context',
      'buildDir': context.buildDir.toString(),
      'buildMode': context.buildMode.cliName,
      'trackWidgetCreation': context.trackWidgetCreation,
      'treeShakeIcons': context.treeShakeIcons,
    });
    return const ExtensionBuildResult(success: true);
  }
}

final class _WireRecordingBuildService extends BuildService {
  _WireRecordingBuildService(this._sendPort);

  final SendPort _sendPort;

  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[_WireRecordingBuildTarget(_sendPort)];

  @override
  List<AssembleTarget> get assembleTargets => <AssembleTarget>[
    _WireRecordingAssembleTarget(_sendPort),
  ];

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    final Map<String, ExtensionRpcHandler> handlers = await super.initialize();
    final ExtensionRpcHandler originalBuild = handlers['build']!;
    final ExtensionRpcHandler originalAssemble = handlers['assemble']!;
    return <String, ExtensionRpcHandler>{
      ...handlers,
      'build': (Map<String, Object?> params) {
        _sendPort.send(<String, Object?>{'kind': 'wire', 'params': params});
        return originalBuild(params);
      },
      'assemble': (Map<String, Object?> params) {
        _sendPort.send(<String, Object?>{'kind': 'assemble_wire', 'params': params});
        return originalAssemble(params);
      },
    };
  }
}

ExtensionEntryPoint _createWireRecordingBuildEntryPoint(SendPort eventSendPort) {
  return (SendPort sendPort) {
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_WireRecordingBuildService(eventSendPort)],
      extensionName: 'wire_build_ext',
      supportedPlatforms: const <String>{'linux'},
    );
  };
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
          buildInfo: BuildInfo.debug,
          fileSystem: MemoryFileSystem.test(),
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
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
    late Cache cache;

    setUp(() {
      fs = MemoryFileSystem.test();
      fs.directory('/flutter').createSync(recursive: true);
      fs.file('/pubspec.yaml').createSync();
      fs.file('/lib/main.dart').createSync(recursive: true);
      cache = FakeCache(fileSystem: fs, flutterRoot: '/flutter');
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
          buildInfo: BuildInfo.debug,
          fileSystem: fs,
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
          buildInfo: BuildInfo.debug,
          fileSystem: fs,
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
          buildInfo: BuildInfo.debug,
          fileSystem: fs,
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
          buildInfo: BuildInfo.debug,
          fileSystem: fs,
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
            'Skipping duplicate build target "shared-target" from extension "second_extension" '
            '(already registered by extension "first_extension").',
          ),
        );

        final ExtensionBuildResult buildResult = await buildManager.build(
          buildInfo: BuildInfo.debug,
          fileSystem: fs,
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
            'Skipping duplicate assemble target "shared-assemble-target" from extension "second_extension" '
            '(already registered by extension "first_extension").',
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
        );
        expect(assembleResult.success, isTrue);

        await manager.dispose();
      },
    );

    testWithoutContext(
      'ExtensionBuildManager logs warning when extension returns invalid build target name',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[_invalidTargetBuildExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final List<ExtensionBuildTarget> targets = await buildManager.getBuildTargets();
        expect(targets, isEmpty);
        expect(
          logger.warningText,
          contains(
            'Failed to query build targets from extension "invalid_target_extension": FormatException: Invalid "name" field: "Invalid-Name".',
          ),
        );

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
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: cache,
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
        androidContext: FakeAndroidContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          builtTarget = target;
        }),
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: toolContext,
        xcode: null,
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
        androidContext: FakeAndroidContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          builtTarget = target;
        }),
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: toolContext,
        xcode: null,
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
          androidContext: FakeAndroidContext(),
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
          xcode: null,
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
      'ExtensionBuildSubCommand forwards flutterRoot, outputDir, and resolvedArtifacts in build parameters',
      () async {
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
          toolContext: FakeToolContext(cache: cache, fs: fs, logger: testLogger),
          verboseHelp: false,
        );

        final FlutterCommandResult result = await subCommand.runCommand();
        expect(result.exitStatus, ExitStatus.success);

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
        expect(fakeBuildManager.lastBuildArgs!['resolvedArtifacts'], isA<Map<String, String>>());
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

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
        toolContext: FakeToolContext(
          cache: cache,
          config: config,
          fs: fs,
          logger: BufferLogger.test(),
        ),
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
          toolContext: FakeToolContext(cache: cache, fs: fs, logger: BufferLogger.test()),
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
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: cache,
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
            'Skipping custom build target "bundle" from extension "failing_extension" because a subcommand with that name already exists.',
          ),
        );
        expect(command.subcommands['bundle'], isA<BuildBundleCommand>());

        final assembleCommand = AssembleCommand(
          androidContext: FakeAndroidContext(),
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
          xcode: null,
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
            'Skipping custom assemble target "copy_assets" from extension "failing_extension" because a target with that name already exists.',
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
                'Target "non-existent-dep" required by "unknown-dep-assemble-target" from extension "failing_extension" not found. '
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
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(fileSystem: fs),
            cache: cache,
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

    testWithoutContext('ExtensionBuildManager.build returns failed ExtensionBuildResult when build target throws ToolExtensionException', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[_domainErrorBuildExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      addTearDown(manager.dispose);

      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );

      final ExtensionBuildResult result = await buildManager.build(
        buildInfo: BuildInfo.debug,
        fileSystem: fs,
        flutterRoot: Uri.directory('/flutter'),
        mainPath: 'lib/main.dart',
        outputDir: Uri.directory('/project/build/custom_os'),
        projectRoot: Uri.directory('/project'),
        resolvedArtifacts: const <String, String>{},
        targetName: 'custom-os-bundle',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Custom compiler missing.');
    });

    testWithoutContext('ExtensionBuildManager.build serializes BuildInfo parameters over RPC and resolves splitDebugInfoPath', () async {
      final eventPort = ReceivePort();
      addTearDown(eventPort.close);

      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[_createWireRecordingBuildEntryPoint(eventPort.sendPort)],
        featureFlags: featureFlags,
      );
      addTearDown(manager.dispose);

      final buildManager = ExtensionBuildManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        logger: logger,
      );
      final projectFs = MemoryFileSystem.test();
      projectFs.currentDirectory = projectFs.directory('/project')..createSync(recursive: true);

      final ExtensionBuildResult result = await buildManager.build(
        buildInfo: const BuildInfo(
          BuildMode.release,
          'production',
          buildName: '4.0.0',
          buildNumber: '12',
          dartDefines: <String>['API_KEY=secret=1', 'BARE_KEY'],
          dartObfuscation: true,
          extraFrontEndOptions: <String>['--fe-flag'],
          extraGenSnapshotOptions: <String>['--gs-flag'],
          packageConfigPath: '.dart_tool/package_config.json',
          splitDebugInfoPath: 'symbols',
          trackWidgetCreation: true,
          treeShakeIcons: false,
        ),
        fileSystem: projectFs,
        flutterRoot: Uri.directory('/flutter'),
        mainPath: '/project/lib/main.dart',
        outputDir: Uri.directory('/project/build/custom_os'),
        projectRoot: Uri.directory('/project'),
        resolvedArtifacts: const <String, String>{'icuData': '/flutter/icudtl.dat'},
        targetDeviceId: 'custom-device-1',
        targetName: 'wire-recorded-build',
        targetPlatform: 'custom-os-arm64',
      );
      expect(result.success, isTrue);
      expect(result.executableUri, Uri.parse('file:///project/build/custom_os/MyApp.app/'));

      final List<Map<String, Object?>> events = await eventPort
          .cast<Map<String, Object?>>()
          .take(2)
          .toList();
      final wireParams =
          events.firstWhere((Map<String, Object?> e) => e['kind'] == 'wire')['params']!
              as Map<String, Object?>;
      expect(wireParams[BuildService.buildModeParam], 'release');
      expect(wireParams[BuildService.buildNameParam], '4.0.0');
      expect(wireParams[BuildService.buildNumberParam], '12');
      expect(wireParams[BuildService.dartDefinesParam], const <String, Object?>{
        'API_KEY': 'secret=1',
        'BARE_KEY': '',
      });
      expect(wireParams[BuildService.dartObfuscationParam], isTrue);
      expect(wireParams[BuildService.extraFrontEndOptionsParam], const <Object?>['--fe-flag']);
      expect(wireParams[BuildService.extraGenSnapshotOptionsParam], const <Object?>['--gs-flag']);
      expect(wireParams[BuildService.flavorParam], 'production');
      expect(wireParams[BuildService.mainPathParam], '/project/lib/main.dart');
      expect(wireParams[BuildService.splitDebugInfoParam], 'file:///project/symbols/');
      expect(wireParams[BuildService.targetDeviceIdParam], 'custom-device-1');
      expect(wireParams[BuildService.targetPlatformParam], 'custom-os-arm64');
      expect(wireParams[BuildService.trackWidgetCreationParam], isTrue);
      expect(wireParams[BuildService.treeShakeIconsParam], isFalse);

      final Map<String, Object?> parsedContext = events.firstWhere(
        (Map<String, Object?> e) => e['kind'] == 'context',
      );
      expect(parsedContext['buildMode'], 'release');
      expect(parsedContext['buildName'], '4.0.0');
      expect(parsedContext['buildNumber'], '12');
      expect(parsedContext['dartDefines'], const <String, String>{
        'API_KEY': 'secret=1',
        'BARE_KEY': '',
      });
      expect(parsedContext['dartObfuscation'], isTrue);
      expect(parsedContext['extraFrontEndOptions'], const <String>['--fe-flag']);
      expect(parsedContext['extraGenSnapshotOptions'], const <String>['--gs-flag']);
      expect(parsedContext['flavor'], 'production');
      expect(parsedContext['mainPath'], '/project/lib/main.dart');
      expect(parsedContext['splitDebugInfo'], 'file:///project/symbols/');
      expect(parsedContext['targetDeviceId'], 'custom-device-1');
      expect(parsedContext['targetPlatform'], 'custom-os-arm64');
      expect(parsedContext['trackWidgetCreation'], isTrue);
      expect(parsedContext['treeShakeIcons'], isFalse);
    });

    testWithoutContext(
      'AssembleCommand forwards TrackWidgetCreation and TreeShakeIcons defines over RPC',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);

        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[
            _createWireRecordingBuildEntryPoint(eventPort.sendPort),
          ],
          featureFlags: featureFlags,
        );
        addTearDown(manager.dispose);

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
          androidContext: FakeAndroidContext(),
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
          xcode: null,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>[
          'assemble',
          '-o',
          '/out',
          '-d',
          'BuildMode=debug',
          '-d',
          'TrackWidgetCreation=false',
          '-d',
          'TreeShakeIcons=true',
          'wire-recorded-assemble',
        ]);

        final List<Map<String, Object?>> events = await eventPort
            .cast<Map<String, Object?>>()
            .take(2)
            .toList();
        final wireParams =
            events.firstWhere((Map<String, Object?> e) => e['kind'] == 'assemble_wire')['params']!
                as Map<String, Object?>;
        expect(wireParams[BuildService.buildModeParam], 'debug');
        expect(wireParams[BuildService.trackWidgetCreationParam], isFalse);
        expect(wireParams[BuildService.treeShakeIconsParam], isTrue);

        final Map<String, Object?> parsedContext = events.firstWhere(
          (Map<String, Object?> e) => e['kind'] == 'assemble_context',
        );
        expect(parsedContext['buildMode'], 'debug');
        expect(parsedContext['trackWidgetCreation'], isFalse);
        expect(parsedContext['treeShakeIcons'], isTrue);
      },
    );

    testWithoutContext('ExtensionBuildSubCommand forwards CLI BuildInfo flags to ExtensionBuildManager.build', () async {
      fs.file('/pubspec.yaml').writeAsStringSync('name: test_app\nversion: 1.0.0+1\n');
      fs.file('/lib/custom_entry.dart').createSync(recursive: true);
      fs.file('/defines.json').writeAsStringSync('{"FILE_KEY": "file_val"}');

      final buildManager = _RecordingExtensionBuildManager();
      final target = ExtensionBuildTarget(
        description: 'Custom hermetic build target.',
        name: 'custom-hermetic-build',
        outputDir:
            '${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}',
        targetPlatform: 'custom-os-arm64',
      );
      final subCommand = ExtensionBuildSubCommand(
        buildManager: buildManager,
        target: target,
        toolContext: FakeToolContext(
          artifacts: Artifacts.test(fileSystem: fs),
          cache: cache,
          fs: fs,
          logger: BufferLogger.test(),
          processManager: FakeProcessManager.any(),
        ),
        verboseHelp: false,
      );
      expect(subCommand.argParser.options.containsKey('enable-experiment'), isFalse);

      final CommandRunner<void> runner = createTestCommandRunner(subCommand);
      await expectLater(
        () => runner.run(<String>['custom-hermetic-build', '--enable-experiment=variance']),
        throwsA(isA<UsageException>()),
      );

      await runner.run(<String>[
        'custom-hermetic-build',
        '--no-pub',
        '--release',
        '--target=lib/custom_entry.dart',
        '--no-tree-shake-icons',
        '--track-widget-creation',
        '--flavor=staging',
        '--build-name=2.0.0',
        '--build-number=5',
        '--dart-define=MY_KEY=my=val',
        '--dart-define=BARE_KEY',
        '--dart-define-from-file=defines.json',
        '--split-debug-info=out/symbols',
        '--obfuscate',
        '--extra-front-end-options=--fe-arg',
        '--extra-gen-snapshot-options=--gs-arg',
      ]);

      final Map<String, Object?> args = buildManager.lastBuildArgs!;
      final buildInfo = args['buildInfo']! as BuildInfo;
      expect(buildInfo.mode, BuildMode.release);
      expect(buildInfo.buildName, '2.0.0');
      expect(buildInfo.buildNumber, '5');
      expect(
        buildInfo.dartDefines,
        containsAll(<String>[
          'MY_KEY=my=val',
          'BARE_KEY',
          'FILE_KEY=file_val',
          'FLUTTER_APP_FLAVOR=staging',
        ]),
      );
      expect(buildInfo.dartObfuscation, isTrue);
      expect(buildInfo.extraFrontEndOptions, const <String>['--fe-arg']);
      expect(buildInfo.extraGenSnapshotOptions, const <String>['--gs-arg']);
      expect(buildInfo.flavor, 'staging');
      expect(buildInfo.splitDebugInfoPath, 'out/symbols');
      expect(buildInfo.trackWidgetCreation, isTrue);
      expect(buildInfo.treeShakeIcons, isFalse);
      expect(args['fileSystem'], same(fs));
      expect(args['mainPath'], fs.file('/lib/custom_entry.dart').path);
      expect(args['targetDeviceId'], isNull);
      expect(args['targetName'], 'custom-hermetic-build');
      expect(args['targetPlatform'], 'custom-os-arm64');
    });
  });
}
