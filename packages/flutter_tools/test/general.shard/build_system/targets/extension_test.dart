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
  Uri? invokedFlutterRoot;
  String? invokedMainPath;
  Uri? invokedOutputDir;
  Uri? invokedProjectRoot;
  Map<String, String>? invokedResolvedArtifacts;
  String? invokedTargetName;

  @override
  Future<ExtensionBuildResult> assemble({
    required Uri buildDir,
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) async {
    invokedBuildDir = buildDir;
    invokedBuildMode = buildMode;
    invokedFlutterRoot = flutterRoot;
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

ExtensionTarget _createTarget({
  FakeExtensionBuildManager? buildManager,
  List<String> dependencies = const <String>[],
  DependencyResolverCallback? dependencyResolver,
  List<String> depfiles = const <String>[],
  List<ExtensionSource> inputs = const <ExtensionSource>[],
  String name = 'custom-target',
  List<ExtensionSource> outputs = const <ExtensionSource>[],
  String targetPlatform = 'linux-x64',
}) {
  return ExtensionTarget(
    assembleTarget: ExtensionAssembleTarget(
      description: 'description',
      name: name,
      targetPlatform: targetPlatform,
      dependencies: dependencies,
      depfiles: depfiles,
      inputs: inputs,
      outputs: outputs,
    ),
    buildManager: buildManager ?? FakeExtensionBuildManager(),
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

  testWithoutContext('ExtensionTarget delegates assemble to ExtensionBuildManager', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionTarget target = _createTarget(buildManager: buildManager);

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
    expect(buildManager.invokedFlutterRoot, equals(environment.flutterRootDir.uri));
    expect(buildManager.invokedResolvedArtifacts, isEmpty);
  });

  testWithoutContext('ExtensionTarget resolves and passes artifacts', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionTarget target = _createTarget(
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
    'ExtensionTarget throws MissingDefineException if BuildMode is missing',
    () async {
      environment.defines.remove(kBuildMode);
      final ExtensionTarget target = _createTarget();

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

  testWithoutContext('ExtensionTarget throws ToolExit if assemble fails', () async {
    final buildManager = FakeExtensionBuildManager(
      buildResult: const ExtensionBuildResult(success: false, errorMessage: 'Build failed error'),
    );
    final ExtensionTarget target = _createTarget(buildManager: buildManager);

    await expectLater(
      () => target.build(environment),
      throwsToolExit(
        message: 'Extension assemble target "custom-target" failed: Build failed error',
      ),
    );

    final ExtensionTarget emptyMessageTarget = _createTarget(
      buildManager: FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(success: false, errorMessage: ''),
      ),
    );
    await expectLater(
      () => emptyMessageTarget.build(environment),
      throwsToolExit(message: 'Extension assemble target "custom-target" failed.'),
    );

    final ExtensionTarget nullMessageTarget = _createTarget(
      buildManager: FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(success: false),
      ),
    );
    await expectLater(
      () => nullMessageTarget.build(environment),
      throwsToolExit(message: 'Extension assemble target "custom-target" failed.'),
    );
  });

  testWithoutContext('ExtensionTarget maps pattern, artifact, and hostArtifact sources', () {
    final ExtensionTarget target = _createTarget(
      inputs: const <ExtensionSource>[
        ExtensionSource.pattern('{PROJECT_DIR}/foo.dart'),
        ExtensionSource.artifact(BuiltInArtifacts.icuData, mode: .debug),
        ExtensionSource.artifact(
          BuiltInArtifacts.genSnapshot,
          platform: 'linux-arm64',
          mode: .release,
        ),
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
        'Artifact.genSnapshot.TargetPlatform.linux_arm64.release',
        'HostArtifact.impellerc',
      ]),
    );

    final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
    expect(resolvedOutputs.sources, hasLength(1));
    expect(resolvedOutputs.sources.single.path, endsWith('bar.dart'));
  });

  testWithoutContext('ExtensionTarget resolves dependencies', () {
    final depTarget = FakeTarget();
    final ExtensionTarget target = _createTarget(
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
    'ExtensionTarget merges extraDefines into environment.defines and normalizes declared depfiles',
    () async {
      final buildManager = FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(
          success: true,
          extraDefines: <String, String>{'CustomDefine': 'custom-value'},
        ),
      );
      final ExtensionTarget target = _createTarget(
        buildManager: buildManager,
        depfiles: const <String>['custom_target.d'],
      );
      expect(target.depfiles, equals(const <String>['custom_target.d']));

      environment.buildDir.createSync(recursive: true);
      final File depfile = environment.buildDir.childFile('custom_target.d');
      depfile.writeAsStringSync(
        const ExtensionDepfile(
          inputs: <String>['lib/extra_input.dart'],
          outputs: <String>['build/extra_output.txt'],
        ).format(),
      );

      await target.build(environment);

      expect(environment.defines['CustomDefine'], equals('custom-value'));
      final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
      expect(resolvedInputs.sources.map((File f) => f.path), contains('/lib/extra_input.dart'));
      final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
      expect(resolvedOutputs.sources.map((File f) => f.path), contains('/build/extra_output.txt'));
    },
  );

  testWithoutContext(
    'ExtensionTarget throws ToolExit for unsupported artifact or hostArtifact',
    () async {
      final ExtensionTarget unknownArtifactTarget = _createTarget(
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

      final ExtensionTarget unknownHostArtifactTarget = _createTarget(
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

  testWithoutContext('ExtensionTarget supports custom targetPlatform and throws ToolExit for invalid artifact platformName', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionTarget customTargetPlatformTarget = _createTarget(
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

    final ExtensionTarget invalidArtifactPlatformTarget = _createTarget(
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
        pattern: '{PROJECT_DIR}/custom/{TARGET_PLATFORM}/{BUILD_MODE}',
        expectedPath: '/project/custom/linux-x64/profile',
      ),
      (
        description: 'substitutes {OUTPUT_DIR}',
        pattern: '{OUTPUT_DIR}/custom-out',
        expectedPath: '/project/build/custom-out',
      ),
      (
        description: 'resolves relative outputDir against projectDir',
        pattern: 'custom_out/{BUILD_MODE}',
        expectedPath: '/project/custom_out/profile',
      ),
    ];

    for (final (:String description, :String pattern, :String expectedPath) in cases) {
      testWithoutContext(description, () {
        final Directory projectDir = fileSystem.directory('/project');
        final Directory buildOutputDir = projectDir.childDirectory('build');
        final Directory resolved = resolveExtensionOutputDir(
          buildMode: .profile,
          buildOutputDir: buildOutputDir,
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

    testWithoutContext('allows projectDir and buildOutputDir paths containing braces', () {
      final Directory projectDir = fileSystem.directory('/home/user/{client}/project');
      final Directory buildOutputDir = projectDir.childDirectory('build');
      final Directory resolved = resolveExtensionOutputDir(
        buildMode: .profile,
        buildOutputDir: buildOutputDir,
        fileSystem: fileSystem,
        projectDir: projectDir,
        target: const ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          outputDir: '{OUTPUT_DIR}/custom/{BUILD_MODE}',
          targetPlatform: 'linux-x64',
        ),
      );
      expect(resolved.path, equals('/home/user/{client}/project/build/custom/profile'));
    });

    testWithoutContext(
      'throws ToolExit when outputDir contains unsupported placeholder like {BUILD_DIR}',
      () {
        final Directory projectDir = fileSystem.directory('/project');
        final Directory buildOutputDir = projectDir.childDirectory('build');
        expect(
          () => resolveExtensionOutputDir(
            buildMode: .profile,
            buildOutputDir: buildOutputDir,
            fileSystem: fileSystem,
            projectDir: projectDir,
            target: const ExtensionBuildTarget(
              description: 'description',
              name: 'custom-target',
              outputDir: '{BUILD_DIR}/custom-out',
              targetPlatform: 'linux-x64',
            ),
          ),
          throwsToolExit(
            message: 'Unsupported placeholder "{BUILD_DIR}" in outputDir "{BUILD_DIR}/custom-out" for build target "custom-target".',
          ),
        );
      },
    );

    testWithoutContext('resolves outputDir without {TARGET_PLATFORM} when targetPlatform is null and throws ToolExit if {TARGET_PLATFORM} is used', () {
      final Directory projectDir = fileSystem.directory('/project');
      final Directory buildOutputDir = projectDir.childDirectory('build');
      final Directory resolved = resolveExtensionOutputDir(
        buildMode: .release,
        buildOutputDir: buildOutputDir,
        fileSystem: fileSystem,
        projectDir: projectDir,
        target: const ExtensionBuildTarget(
          description: 'Platform-agnostic target',
          name: 'agnostic-target',
          outputDir: '{OUTPUT_DIR}/agnostic/{BUILD_MODE}',
        ),
      );
      expect(resolved.path, equals('/project/build/agnostic/release'));

      expect(
        () => resolveExtensionOutputDir(
          buildMode: .release,
          buildOutputDir: buildOutputDir,
          fileSystem: fileSystem,
          projectDir: projectDir,
          target: const ExtensionBuildTarget(
            description: 'Platform-agnostic target with invalid placeholder',
            name: 'agnostic-target',
            outputDir: '{OUTPUT_DIR}/{TARGET_PLATFORM}/{BUILD_MODE}',
          ),
        ),
        throwsToolExit(
          message:
              'Placeholder "{TARGET_PLATFORM}" in outputDir "{OUTPUT_DIR}/{TARGET_PLATFORM}/{BUILD_MODE}" '
              'requires targetPlatform to be set on build target "agnostic-target".',
        ),
      );
    });
  });

  testWithoutContext('BuiltInArtifacts, BuiltInHostArtifacts, Linux artifacts, and BuiltInTargets match host definitions', () {
    const buildTarget = ExtensionBuildTarget(
      description: 'Contract check build target',
      name: 'contract-build-target',
      outputDir: '{OUTPUT_DIR}/contract-build',
      targetPlatform: 'linux-x64',
      artifacts: <ExtensionArtifact>{
        BuiltInArtifacts.flutterPatchedSdkPath,
        BuiltInArtifacts.genSnapshot,
        BuiltInArtifacts.icuData,
        ExtensionArtifact('linuxDesktopPath'),
        ExtensionArtifact('linuxHeaders'),
      },
      hostArtifacts: <ExtensionHostArtifact>{
        BuiltInHostArtifacts.impellerc,
        BuiltInHostArtifacts.libtessellator,
      },
    );

    final Map<String, String> resolvedBuild = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: .debug,
      target: buildTarget,
    );
    expect(
      resolvedBuild.keys,
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

    const assembleTarget = ExtensionAssembleTarget(
      description: 'Contract check assemble target',
      name: 'contract-assemble-target',
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

    final Map<String, String> resolvedAssemble = resolveExtensionAssembleTargetArtifacts(
      artifacts: artifacts,
      buildMode: .debug,
      target: assembleTarget,
    );
    expect(resolvedAssemble, equals(resolvedBuild));

    expect(BuiltInTargets.copyAssets, equals(const CopyAssets().name));
    expect(BuiltInTargets.kernelSnapshot, equals(const KernelSnapshot().name));
  });
}
