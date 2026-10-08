// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/extension.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' as core;
import 'package:flutter_tools_core/flutter_tools_core.dart'
    hide Artifact, BuildMode, HostArtifact, Source, Target;
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';

final class FakeExtensionManager extends Fake implements ExtensionManager {}

final class FakeExtensionBuildManager extends ExtensionBuildManager {
  FakeExtensionBuildManager({this.buildResult})
    : super(
        extensionManager: FakeExtensionManager(),
        featureFlags: TestFeatureFlags(),
        logger: BufferLogger.test(),
      );

  final ExtensionBuildResult? buildResult;

  Uri? invokedBuildDir;
  BuildMode? invokedBuildMode;
  String? invokedMainPath;
  Uri? invokedOutputDir;
  Uri? invokedProjectRoot;
  Map<String, String>? invokedResolvedArtifacts;
  String? invokedTargetName;

  @override
  Future<ExtensionBuildResult> build({
    required Uri buildDir,
    required BuildMode buildMode,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) async {
    invokedBuildDir = buildDir;
    invokedBuildMode = buildMode;
    invokedMainPath = mainPath;
    invokedOutputDir = outputDir;
    invokedProjectRoot = projectRoot;
    invokedResolvedArtifacts = resolvedArtifacts;
    invokedTargetName = targetName;
    return buildResult ?? const ExtensionBuildResult.success();
  }
}

void main() {
  late FileSystem fileSystem;
  late Environment environment;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      inputs: <String, String>{},
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      artifacts: LocalFakeArtifacts(fileSystem),
      processManager: FakeProcessManager.any(),
    );
  });

  testUsingContext('ExtensionAssembleTarget delegates build to ExtensionBuildManager', () async {
    final buildManager = FakeExtensionBuildManager();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    expect(target.name, equals('custom-target'));
    expect(target.dependencies, isEmpty);
    expect(target.inputs, isEmpty);
    expect(target.outputs, isEmpty);

    await target.build(environment);

    expect(buildManager.invokedTargetName, equals('custom-target'));
    expect(buildManager.invokedProjectRoot, equals(environment.projectDir.uri));
    expect(buildManager.invokedMainPath, equals('lib/main.dart'));
    expect(buildManager.invokedBuildMode, equals(BuildMode.debug));
    expect(buildManager.invokedOutputDir, equals(environment.outputDir.uri));
    expect(buildManager.invokedBuildDir, equals(environment.buildDir.uri));
    expect(buildManager.invokedResolvedArtifacts, isEmpty);
  });

  testUsingContext('ExtensionAssembleTarget resolves and passes artifacts', () async {
    final buildManager = FakeExtensionBuildManager();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
      inputs: <Source>[
        Source.artifact(BuiltInArtifacts.icuData),
        Source.hostArtifact(BuiltInHostArtifacts.impellerc),
      ],
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    await target.build(environment);

    expect(buildManager.invokedResolvedArtifacts, hasLength(2));
    expect(buildManager.invokedResolvedArtifacts?['icuData'], endsWith('/artifacts/icuData'));
    expect(
      buildManager.invokedResolvedArtifacts?['impellerc'],
      endsWith('/artifacts/host/impellerc'),
    );
  });

  testUsingContext('ExtensionAssembleTarget resolves outputDir pattern', () async {
    final buildManager = FakeExtensionBuildManager();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
      outputDir: '{PROJECT_DIR}/build/custom-out/{BUILD_MODE}',
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    await target.build(environment);

    expect(
      buildManager.invokedOutputDir,
      equals(
        fileSystem
            .directory(
              fileSystem.path.join(environment.projectDir.path, 'build', 'custom-out', 'debug'),
            )
            .uri,
      ),
    );
  });

  testUsingContext('ExtensionAssembleTarget throws ToolExit if BuildMode is missing', () async {
    environment.defines.remove(kBuildMode);
    final buildManager = FakeExtensionBuildManager();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    await expectLater(
      () => target.build(environment),
      throwsA(
        isA<ToolExit>().having(
          (ToolExit e) => e.message,
          'message',
          contains('BuildMode define is required'),
        ),
      ),
    );
  });

  testUsingContext('ExtensionAssembleTarget throws ToolExit if build fails', () async {
    final buildManager = FakeExtensionBuildManager(
      buildResult: const ExtensionBuildResult.failure(message: 'Build failed error'),
    );
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    await expectLater(
      () => target.build(environment),
      throwsA(
        isA<ToolExit>().having(
          (ToolExit e) => e.message,
          'message',
          contains('Build failed error'),
        ),
      ),
    );
  });

  testUsingContext('ExtensionAssembleTarget maps inputs and outputs', () async {
    final buildManager = FakeExtensionBuildManager();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
      inputs: <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')],
      outputs: <Source>[Source.pattern('{BUILD_DIR}/bar.dart')],
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) => throw UnimplementedError(),
    );

    environment.buildDir.createSync(recursive: true);
    environment.outputDir.createSync(recursive: true);

    final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
    expect(resolvedInputs.sources, hasLength(1));
    expect(resolvedInputs.sources.first.path, endsWith('foo.dart'));

    final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
    expect(resolvedOutputs.sources, hasLength(1));
    expect(resolvedOutputs.sources.first.path, endsWith('bar.dart'));
  });

  testUsingContext('ExtensionAssembleTarget resolves dependencies', () async {
    final buildManager = FakeExtensionBuildManager();
    final depTarget = FakeTarget();
    const buildTarget = ExtensionBuildTarget(
      description: 'description',
      name: 'custom-target',
      targetPlatform: 'linux-x64',
      dependencies: <String>['dep-target'],
    );
    final target = ExtensionAssembleTarget(
      buildManager: buildManager,
      buildTarget: buildTarget,
      dependencyResolver: (String name) {
        if (name == 'dep-target') {
          return depTarget;
        }
        throw fail('Unexpected dependency lookup: $name');
      },
    );

    expect(target.dependencies, hasLength(1));
    expect(target.dependencies.first, same(depTarget));
  });

  testUsingContext(
    'ExtensionAssembleTarget maps artifact and host_artifact inputs/outputs',
    () async {
      final buildManager = FakeExtensionBuildManager();
      const buildTarget = ExtensionBuildTarget(
        description: 'description',
        name: 'custom-target',
        targetPlatform: 'linux-x64',
        inputs: <Source>[
          Source.artifact(BuiltInArtifacts.icuData),
          Source.hostArtifact(BuiltInHostArtifacts.impellerc),
        ],
      );
      final target = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: buildTarget,
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
      expect(resolvedInputs.sources, hasLength(2));
      expect(resolvedInputs.sources[0].path, endsWith('/artifacts/icuData'));
      expect(resolvedInputs.sources[1].path, endsWith('/artifacts/host/impellerc'));
    },
  );

  testUsingContext(
    'ExtensionAssembleTarget resolves {BUILD_DIR} placeholder in outputDir pattern',
    () async {
      final buildManager = FakeExtensionBuildManager();
      const buildTarget = ExtensionBuildTarget(
        description: 'description',
        name: 'custom-target',
        targetPlatform: 'linux-x64',
        outputDir: '{BUILD_DIR}/custom-out',
      );
      final target = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: buildTarget,
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      await target.build(environment);

      expect(
        buildManager.invokedOutputDir,
        equals(
          fileSystem.directory(fileSystem.path.join(environment.buildDir.path, 'custom-out')).uri,
        ),
      );
    },
  );

  testUsingContext(
    'ExtensionAssembleTarget throws ArgumentError for unknown artifact or hostArtifact',
    () async {
      final buildManager = FakeExtensionBuildManager();
      final unknownArtifactTarget = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: const ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          targetPlatform: 'linux-x64',
          inputs: <Source>[Source.artifact(core.Artifact('unknownArtifact'))],
        ),
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      await expectLater(
        () => unknownArtifactTarget.build(environment),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Unknown artifact name.',
          ),
        ),
      );

      final unknownHostArtifactTarget = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: const ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          targetPlatform: 'linux-x64',
          inputs: <Source>[Source.hostArtifact(core.HostArtifact('unknownHostArtifact'))],
        ),
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      await expectLater(
        () => unknownHostArtifactTarget.build(environment),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Unknown host artifact name.',
          ),
        ),
      );
    },
  );

  testUsingContext(
    'ExtensionAssembleTarget throws ToolExit for invalid targetPlatform or artifact platformName',
    () async {
      final buildManager = FakeExtensionBuildManager();
      final invalidTargetPlatformTarget = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: const ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          targetPlatform: 'invalid-platform',
        ),
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      await expectLater(
        () => invalidTargetPlatformTarget.build(environment),
        throwsToolExit(
          message: 'Invalid target platform "invalid-platform" for extension build target "custom-target".',
        ),
      );

      final invalidArtifactPlatformTarget = ExtensionAssembleTarget(
        buildManager: buildManager,
        buildTarget: const ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          targetPlatform: 'linux-x64',
          inputs: <Source>[
            Source.artifact(BuiltInArtifacts.icuData, platform: 'invalid-artifact-platform'),
          ],
        ),
        dependencyResolver: (String name) => throw UnimplementedError(),
      );

      await expectLater(
        () => invalidArtifactPlatformTarget.build(environment),
        throwsToolExit(
          message: 'Invalid platform name "invalid-artifact-platform" for artifact "icuData".',
        ),
      );
    },
  );
}

final class FakeTarget extends Fake implements Target {
  @override
  String get name => 'fake-target';
}

final class LocalFakeArtifacts extends Fake implements Artifacts {
  LocalFakeArtifacts(this._fileSystem);
  final FileSystem _fileSystem;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    return '/artifacts/${artifact.name}';
  }

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    return _fileSystem.file('/artifacts/host/${artifact.name}');
  }
}
