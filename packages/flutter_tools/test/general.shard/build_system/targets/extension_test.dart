// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/extension.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
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
    return buildResult ?? const ExtensionBuildResult(success: true);
  }
}

final class FakeTarget extends Fake implements Target {
  @override
  String get name => 'fake-target';
}

ExtensionAssembleTarget _createTarget({
  FakeExtensionBuildManager? buildManager,
  List<String> dependencies = const <String>[],
  DependencyResolverCallback? dependencyResolver,
  List<ExtensionSource> inputs = const <ExtensionSource>[],
  String name = 'custom-target',
  String outputDir = kBuildDirPlaceholder,
  List<ExtensionSource> outputs = const <ExtensionSource>[],
  String targetPlatform = 'linux-x64',
}) {
  return ExtensionAssembleTarget(
    buildManager: buildManager ?? FakeExtensionBuildManager(),
    buildTarget: ExtensionBuildTarget(
      description: 'description',
      name: name,
      targetPlatform: targetPlatform,
      dependencies: dependencies,
      inputs: inputs,
      outputDir: outputDir,
      outputs: outputs,
    ),
    dependencyResolver:
        dependencyResolver ?? (String dep) => fail('Unexpected dependency lookup: $dep'),
  );
}

void main() {
  late FileSystem fileSystem;
  late Artifacts artifacts;
  late Environment environment;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    artifacts = Artifacts.test(fileSystem: fileSystem);
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      inputs: <String, String>{},
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
    );
  });

  testWithoutContext('ExtensionAssembleTarget delegates build to ExtensionBuildManager', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionAssembleTarget target = _createTarget(buildManager: buildManager);

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

  testWithoutContext('ExtensionAssembleTarget resolves and passes artifacts', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionAssembleTarget target = _createTarget(
      buildManager: buildManager,
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.icuData),
        ExtensionSource.artifact(
          BuiltInArtifacts.genSnapshot,
          platform: 'linux-arm64',
          mode: .release,
        ),
        ExtensionSource.hostArtifact(BuiltInHostArtifacts.impellerc),
      ],
    );

    await target.build(environment);

    expect(
      buildManager.invokedResolvedArtifacts,
      equals(<String, String>{
        'icuData': 'Artifact.icuData.TargetPlatform.linux_x64.debug',
        'genSnapshot': 'Artifact.genSnapshot.TargetPlatform.linux_arm64.release',
        'impellerc': 'HostArtifact.impellerc',
      }),
    );
  });

  testWithoutContext(
    'ExtensionAssembleTarget throws MissingDefineException if BuildMode is missing',
    () async {
      environment.defines.remove(kBuildMode);
      final ExtensionAssembleTarget target = _createTarget();

      await expectLater(
        () => target.build(environment),
        throwsA(
          isA<MissingDefineException>()
              .having((MissingDefineException e) => e.define, 'define', kBuildMode)
              .having((MissingDefineException e) => e.target, 'target', 'custom-target'),
        ),
      );
    },
  );

  testWithoutContext('ExtensionAssembleTarget throws ToolExit if build fails', () async {
    final buildManager = FakeExtensionBuildManager(
      buildResult: const ExtensionBuildResult(success: false, errorMessage: 'Build failed error'),
    );
    final ExtensionAssembleTarget target = _createTarget(buildManager: buildManager);

    await expectLater(
      () => target.build(environment),
      throwsToolExit(message: 'Extension build target "custom-target" failed: Build failed error'),
    );

    final ExtensionAssembleTarget emptyMessageTarget = _createTarget(
      buildManager: FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(success: false, errorMessage: ''),
      ),
    );
    await expectLater(
      () => emptyMessageTarget.build(environment),
      throwsToolExit(message: 'Extension build target "custom-target" failed.'),
    );

    final ExtensionAssembleTarget nullMessageTarget = _createTarget(
      buildManager: FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(success: false),
      ),
    );
    await expectLater(
      () => nullMessageTarget.build(environment),
      throwsToolExit(message: 'Extension build target "custom-target" failed.'),
    );
  });

  testWithoutContext(
    'ExtensionAssembleTarget maps pattern, artifact, and hostArtifact sources',
    () {
      final ExtensionAssembleTarget target = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.pattern('{PROJECT_DIR}/foo.dart'),
          ExtensionSource.artifact(BuiltInArtifacts.icuData, platform: 'linux-x64', mode: .debug),
          ExtensionSource.hostArtifact(BuiltInHostArtifacts.impellerc),
        ],
        outputs: const <ExtensionSource>[ExtensionSource.pattern('{BUILD_DIR}/bar.dart')],
      );

      environment.buildDir.createSync(recursive: true);
      environment.outputDir.createSync(recursive: true);

      final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
      expect(
        resolvedInputs.sources.map((File f) => f.path),
        equals(<String>[
          '/foo.dart',
          'Artifact.icuData.TargetPlatform.linux_x64.debug',
          'HostArtifact.impellerc',
        ]),
      );

      final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
      expect(resolvedOutputs.sources, hasLength(1));
      expect(resolvedOutputs.sources.single.path, endsWith('bar.dart'));
    },
  );

  testWithoutContext('ExtensionAssembleTarget resolves dependencies', () {
    final depTarget = FakeTarget();
    final ExtensionAssembleTarget target = _createTarget(
      dependencies: const <String>['dep-target'],
      dependencyResolver: (String name) {
        if (name == 'dep-target') {
          return depTarget;
        }
        fail('Unexpected dependency lookup: $name');
      },
    );

    expect(target.dependencies, equals(<Target>[depTarget]));
  });

  testWithoutContext(
    'ExtensionAssembleTarget throws ToolExit for unsupported artifact or hostArtifact',
    () async {
      final ExtensionAssembleTarget unknownArtifactTarget = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(ExtensionArtifact('unknownArtifact')),
        ],
      );

      await expectLater(
        () => unknownArtifactTarget.build(environment),
        throwsToolExit(
          message: 'Unsupported artifact "unknownArtifact" requested by a tool extension.',
        ),
      );

      final ExtensionAssembleTarget unknownHostArtifactTarget = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.hostArtifact(ExtensionHostArtifact('unknownHostArtifact')),
        ],
      );

      await expectLater(
        () => unknownHostArtifactTarget.build(environment),
        throwsToolExit(
          message: 'Unsupported host artifact "unknownHostArtifact" requested by a tool extension.',
        ),
      );
    },
  );

  testWithoutContext('ExtensionAssembleTarget supports custom targetPlatform and throws ToolExit for invalid artifact platformName', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionAssembleTarget customTargetPlatformTarget = _createTarget(
      buildManager: buildManager,
      targetPlatform: 'custom-embedder-arm64',
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.icuData),
        ExtensionSource.artifact(
          BuiltInArtifacts.genSnapshot,
          platform: 'linux-arm64',
          mode: .release,
        ),
      ],
    );

    await customTargetPlatformTarget.build(environment);

    expect(
      buildManager.invokedResolvedArtifacts,
      equals(<String, String>{
        'icuData': 'Artifact.icuData.debug',
        'genSnapshot': 'Artifact.genSnapshot.TargetPlatform.linux_arm64.release',
      }),
    );

    final ExtensionAssembleTarget invalidArtifactPlatformTarget = _createTarget(
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.icuData, platform: 'invalid-artifact-platform'),
      ],
    );

    await expectLater(
      () => invalidArtifactPlatformTarget.build(environment),
      throwsToolExit(
        message: 'Invalid platform name "invalid-artifact-platform" for artifact "icuData".',
      ),
    );
  });

  group('resolveExtensionOutputDir', () {
    final cases = <({String description, String pattern, String expectedPath})>[
      (
        description: 'substitutes {PROJECT_DIR}, {BUILD_MODE}, and {TARGET_PLATFORM}',
        pattern: '{PROJECT_DIR}/build/custom/{TARGET_PLATFORM}/{BUILD_MODE}',
        expectedPath: '/project/build/custom/linux-x64/profile',
      ),
      (
        description: 'substitutes {BUILD_DIR}',
        pattern: '{BUILD_DIR}/custom-out',
        expectedPath: '/project/.dart_tool/flutter_build/custom-out',
      ),
      (
        description: 'resolves relative outputDir against projectDir',
        pattern: 'build/custom_out/{BUILD_MODE}',
        expectedPath: '/project/build/custom_out/profile',
      ),
    ];

    for (final (:String description, :String pattern, :String expectedPath) in cases) {
      testWithoutContext(description, () {
        final Directory projectDir = fileSystem.directory('/project');
        final Directory buildDir = projectDir
            .childDirectory('.dart_tool')
            .childDirectory('flutter_build');
        final Directory resolved = resolveExtensionOutputDir(
          buildDir: buildDir,
          buildMode: .profile,
          fileSystem: fileSystem,
          projectDir: projectDir,
          target: ExtensionBuildTarget(
            description: 'description',
            name: 'custom-target',
            outputDir: pattern,
            targetPlatform: 'linux-x64',
          ),
        );
        expect(resolved.path, equals(expectedPath));
      });
    }
  });

  testWithoutContext('BuiltInArtifacts, BuiltInHostArtifacts, Linux artifacts, and BuiltInTargets match host definitions', () {
    const target = ExtensionBuildTarget(
      description: 'Contract check target',
      name: 'contract-target',
      targetPlatform: 'linux-x64',
      inputs: <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.flutterPatchedSdkPath),
        ExtensionSource.artifact(BuiltInArtifacts.genSnapshot),
        ExtensionSource.artifact(BuiltInArtifacts.icuData),
        ExtensionSource.artifact(ExtensionArtifact('linuxDesktopPath')),
        ExtensionSource.artifact(ExtensionArtifact('linuxHeaders')),
        ExtensionSource.hostArtifact(BuiltInHostArtifacts.impellerc),
        ExtensionSource.hostArtifact(BuiltInHostArtifacts.libtessellator),
      ],
    );

    final Map<String, String> resolved = resolveExtensionTargetArtifacts(
      artifacts: artifacts,
      buildMode: .debug,
      target: target,
    );
    expect(
      resolved.keys,
      unorderedEquals(<String>[
        BuiltInArtifacts.flutterPatchedSdkPath.name,
        BuiltInArtifacts.genSnapshot.name,
        BuiltInArtifacts.icuData.name,
        'linuxDesktopPath',
        'linuxHeaders',
        BuiltInHostArtifacts.impellerc.name,
        BuiltInHostArtifacts.libtessellator.name,
      ]),
    );

    expect(BuiltInTargets.copyAssets, equals(const CopyAssets().name));
    expect(BuiltInTargets.kernelSnapshot, equals(const KernelSnapshot().name));
  });
}
