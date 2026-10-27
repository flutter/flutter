// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
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

final class ModeAssertingArtifacts extends Fake implements Artifacts {
  ModeAssertingArtifacts(this.fileSystem);

  final FileSystem fileSystem;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (artifact == Artifact.genSnapshot && mode == null) {
      throw ArgumentError('mode is required for genSnapshot');
    }
    return fileSystem.path.join(
      fileSystem.currentDirectory.path,
      'artifacts',
      '${artifact.name}_${platform?.toString() ?? 'no_platform'}_${mode?.cliName ?? 'no_mode'}',
    );
  }

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) => fileSystem.file(
    fileSystem.path.join(fileSystem.currentDirectory.path, 'artifacts', artifact.name),
  );
}

ExtensionTarget _createTarget({
  FakeExtensionBuildManager? buildManager,
  List<String> dependencies = const <String>[],
  DependencyResolverCallback? dependencyResolver,
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

  testWithoutContext(
    'ExtensionTarget throws ExtensionAssembleException if assemble fails',
    () async {
      final buildManager = FakeExtensionBuildManager(
        buildResult: const ExtensionBuildResult(success: false, errorMessage: 'Build failed error'),
      );
      final ExtensionTarget target = _createTarget(buildManager: buildManager);

      await expectLater(
        () => target.build(environment),
        throwsA(
          isA<ExtensionAssembleException>()
              .having((ExtensionAssembleException e) => e.target, 'target', 'custom-target')
              .having(
                (ExtensionAssembleException e) => e.errorMessage,
                'errorMessage',
                'Build failed error',
              )
              .having(
                (ExtensionAssembleException e) => e.toString(),
                'toString',
                equals('Extension assemble target "custom-target" failed: Build failed error'),
              ),
        ),
      );

      final ExtensionTarget emptyMessageTarget = _createTarget(
        buildManager: FakeExtensionBuildManager(
          buildResult: const ExtensionBuildResult(success: false, errorMessage: ''),
        ),
      );
      await expectLater(
        () => emptyMessageTarget.build(environment),
        throwsA(
          isA<ExtensionAssembleException>()
              .having((ExtensionAssembleException e) => e.target, 'target', 'custom-target')
              .having(
                (ExtensionAssembleException e) => e.toString(),
                'toString',
                equals('Extension assemble target "custom-target" failed.'),
              ),
        ),
      );

      final ExtensionTarget nullMessageTarget = _createTarget(
        buildManager: FakeExtensionBuildManager(
          buildResult: const ExtensionBuildResult(success: false),
        ),
      );
      await expectLater(
        () => nullMessageTarget.build(environment),
        throwsA(
          isA<ExtensionAssembleException>()
              .having((ExtensionAssembleException e) => e.target, 'target', 'custom-target')
              .having(
                (ExtensionAssembleException e) => e.toString(),
                'toString',
                equals('Extension assemble target "custom-target" failed.'),
              ),
        ),
      );
    },
  );

  testWithoutContext('ExtensionTarget maps pattern, artifact, and hostArtifact sources', () {
    final ExtensionTarget target = _createTarget(
      inputs: <ExtensionSource>[
        ExtensionSource.pattern('{PROJECT_DIR}/foo.dart'),
        const ExtensionSource.artifact(BuiltInArtifacts.icuData, mode: .debug),
        const ExtensionSource.artifact(
          BuiltInArtifacts.genSnapshot,
          platform: 'linux-arm64',
          mode: .release,
        ),
        const ExtensionSource.hostArtifact(BuiltInHostArtifacts.impellerc),
      ],
      outputs: <ExtensionSource>[ExtensionSource.pattern('{BUILD_DIR}/bar.dart')],
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

  testWithoutContext('ExtensionTarget.resolveInputs and resolveOutputs inherit BuildMode from environment when artifact mode is omitted', () {
    environment.defines[kBuildMode] = BuildMode.release.cliName;
    final ExtensionTarget target = _createTarget(
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.genSnapshot),
        ExtensionSource.artifact(BuiltInArtifacts.icuData, mode: .debug),
      ],
      outputs: const <ExtensionSource>[ExtensionSource.artifact(BuiltInArtifacts.genSnapshot)],
    );

    final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
    expect(
      resolvedInputs.sources.map((File f) => f.path),
      equals(<String>[
        'Artifact.genSnapshot.TargetPlatform.linux_x64.release',
        'Artifact.icuData.TargetPlatform.linux_x64.debug',
      ]),
    );

    final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
    expect(
      resolvedOutputs.sources.map((File f) => f.path),
      equals(<String>['Artifact.genSnapshot.TargetPlatform.linux_x64.release']),
    );
  });

  testWithoutContext(
    'ExtensionTarget with mode-less genSnapshot artifact builds cleanly through FlutterBuildSystem',
    () async {
      final logger = BufferLogger.test();
      final platform = FakePlatform();
      final modeAssertingArtifacts = ModeAssertingArtifacts(fileSystem);
      final modeAssertingEnvironment = Environment.test(
        fileSystem.currentDirectory,
        artifacts: modeAssertingArtifacts,
        defines: <String, String>{kBuildMode: BuildMode.release.cliName},
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      );

      final String expectedGenSnapshotPath = modeAssertingArtifacts.getArtifactPath(
        Artifact.genSnapshot,
        mode: .release,
        platform: .android_arm64,
      );
      fileSystem.file(expectedGenSnapshotPath).createSync(recursive: true);

      final buildManager = FakeExtensionBuildManager();
      final ExtensionTarget target = _createTarget(
        buildManager: buildManager,
        inputs: const <ExtensionSource>[ExtensionSource.artifact(BuiltInArtifacts.genSnapshot)],
        targetPlatform: 'android-arm64',
      );

      final buildSystem = FlutterBuildSystem(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
      );
      final BuildResult result = await buildSystem.build(target, modeAssertingEnvironment);

      expect(result.success, isTrue);
      expect(
        buildManager.invokedResolvedArtifacts,
        equals(<String, String>{'genSnapshot': expectedGenSnapshotPath}),
      );
      expect(result.inputFiles.map((File f) => f.path), contains(expectedGenSnapshotPath));
    },
  );

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

  testWithoutContext(
    'ExtensionTarget supports custom targetPlatform on target and artifact sources',
    () async {
      final buildManager = FakeExtensionBuildManager();
      final ExtensionTarget customTargetPlatformTarget = _createTarget(
        buildManager: buildManager,
        targetPlatform: 'custom-embedder-arm64',
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(BuiltInArtifacts.icuData),
          ExtensionSource.artifact(
            BuiltInArtifacts.flutterPatchedSdkPath,
            platform: 'custom-artifact-platform',
          ),
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
          'flutterPatchedSdkPath': 'Artifact.flutterPatchedSdkPath.debug',
          'genSnapshot': 'Artifact.genSnapshot.TargetPlatform.linux_arm64.release',
        }),
      );

      final builtInTargetBuildManager = FakeExtensionBuildManager();
      final ExtensionTarget builtInTargetWithCustomArtifactPlatform = _createTarget(
        buildManager: builtInTargetBuildManager,
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(BuiltInArtifacts.icuData),
          ExtensionSource.artifact(
            BuiltInArtifacts.flutterPatchedSdkPath,
            platform: 'custom-artifact-platform',
          ),
        ],
      );

      final ResolvedFiles resolvedInputs = builtInTargetWithCustomArtifactPlatform.resolveInputs(
        environment,
      );
      expect(
        resolvedInputs.sources.map((File file) => file.path),
        containsAll(<String>[
          'Artifact.icuData.TargetPlatform.linux_x64.debug',
          'Artifact.flutterPatchedSdkPath.debug',
        ]),
      );

      await builtInTargetWithCustomArtifactPlatform.build(environment);

      expect(
        builtInTargetBuildManager.invokedResolvedArtifacts,
        equals(<String, String>{
          'icuData': 'Artifact.icuData.TargetPlatform.linux_x64.debug',
          'flutterPatchedSdkPath': 'Artifact.flutterPatchedSdkPath.debug',
        }),
      );
    },
  );

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
