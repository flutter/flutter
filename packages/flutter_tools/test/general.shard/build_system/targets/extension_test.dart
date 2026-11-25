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
  FakeExtensionBuildManager({this.assembleError, this.onAssemble})
    : super(
        extensionManager: FakeExtensionManager(),
        featureFlags: TestFeatureFlags(),
        logger: BufferLogger.test(),
      );

  final ToolExtensionException? assembleError;
  final void Function(Uri buildDir)? onAssemble;

  int assembleCount = 0;
  Uri? invokedBuildDir;
  BuildMode? invokedBuildMode;
  String? invokedBuildName;
  String? invokedBuildNumber;
  Uri? invokedCodeSizeDirectory;
  Map<String, Object?>? invokedConfiguration;
  Map<String, String>? invokedDartDefines;
  bool? invokedDartObfuscation;
  Map<String, String>? invokedExtraDefines;
  List<String>? invokedExtraFrontEndOptions;
  List<String>? invokedExtraGenSnapshotOptions;
  String? invokedFlavor;
  Uri? invokedFlutterRoot;
  String? invokedMainPath;
  Uri? invokedOutputDir;
  Uri? invokedProjectRoot;
  Map<String, String>? invokedResolvedArtifacts;
  Uri? invokedSplitDebugInfo;
  String? invokedTargetName;
  String? invokedTargetPlatform;
  bool? invokedTrackWidgetCreation;
  bool? invokedTreeShakeIcons;

  @override
  Future<void> assemble({
    required Uri buildDir,
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
    String? buildName,
    String? buildNumber,
    Uri? codeSizeDirectory,
    Map<String, Object?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    Map<String, String> extraDefines = const <String, String>{},
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetPlatform,
    bool? trackWidgetCreation,
    bool? treeShakeIcons,
  }) async {
    assembleCount += 1;
    invokedBuildDir = buildDir;
    invokedBuildMode = buildMode;
    invokedBuildName = buildName;
    invokedBuildNumber = buildNumber;
    invokedCodeSizeDirectory = codeSizeDirectory;
    invokedConfiguration = configuration;
    invokedDartDefines = dartDefines;
    invokedDartObfuscation = dartObfuscation;
    invokedExtraDefines = extraDefines;
    invokedExtraFrontEndOptions = extraFrontEndOptions;
    invokedExtraGenSnapshotOptions = extraGenSnapshotOptions;
    invokedFlavor = flavor;
    invokedFlutterRoot = flutterRoot;
    invokedMainPath = mainPath;
    invokedOutputDir = outputDir;
    invokedProjectRoot = projectRoot;
    invokedResolvedArtifacts = resolvedArtifacts;
    invokedSplitDebugInfo = splitDebugInfo;
    invokedTargetName = targetName;
    invokedTargetPlatform = targetPlatform;
    invokedTrackWidgetCreation = trackWidgetCreation;
    invokedTreeShakeIcons = treeShakeIcons;
    onAssemble?.call(buildDir);
    if (assembleError case final ToolExtensionException error) {
      throw error;
    }
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
      featureFlags: TestFeatureFlags(),
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
        assembleError: const ToolExtensionException('Build failed error'),
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
        buildManager: FakeExtensionBuildManager(assembleError: const ToolExtensionException('')),
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
        featureFlags: TestFeatureFlags(),
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

  testWithoutContext('ExtensionTarget normalizes declared depfiles', () async {
    final buildManager = FakeExtensionBuildManager(
      onAssemble: (Uri buildDir) {
        fileSystem
            .directory(buildDir)
            .childFile('custom_target.d')
            .writeAsStringSync(
              const Depfile(
                inputs: <String>['lib/extra_input.dart'],
                outputs: <String>['build/extra_output.txt'],
              ).format(),
            );
      },
    );
    final ExtensionTarget target = _createTarget(
      buildManager: buildManager,
      depfiles: const <String>['custom_target.d'],
    );
    expect(target.depfiles, equals(const <String>['custom_target.d']));

    environment.buildDir.createSync(recursive: true);

    await target.build(environment);

    final ResolvedFiles resolvedInputs = target.resolveInputs(environment);
    expect(resolvedInputs.sources.map((File f) => f.path), contains('/lib/extra_input.dart'));
    final ResolvedFiles resolvedOutputs = target.resolveOutputs(environment);
    expect(resolvedOutputs.sources.map((File f) => f.path), contains('/build/extra_output.txt'));
  });

  testWithoutContext('ExtensionTarget logs error and disables incremental caching when declared depfile is missing or omitted on rebuild', () async {
    final logger = BufferLogger.test();
    final buildSystem = FlutterBuildSystem(
      fileSystem: fileSystem,
      platform: FakePlatform(),
      logger: logger,
    );
    final File trackedInput = fileSystem.file('/lib/tracked.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('v1');
    final testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      inputs: <String, String>{},
      fileSystem: fileSystem,
      logger: logger,
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(),
      processManager: FakeProcessManager.any(),
    );
    var writeDepfile = true;
    final buildManager = FakeExtensionBuildManager(
      onAssemble: (Uri buildDir) {
        if (writeDepfile) {
          fileSystem
              .directory(buildDir)
              .childFile('missing.d')
              .writeAsStringSync(const Depfile(inputs: <String>['lib/tracked.dart']).format());
        }
      },
    );
    final ExtensionTarget missingDepfileTarget = _createTarget(
      buildManager: buildManager,
      depfiles: const <String>['missing.d'],
    );

    // Run 1 writes missing.d; an unchanged incremental build skips cleanly.
    final BuildResult firstResult = await buildSystem.build(missingDepfileTarget, testEnvironment);
    expect(firstResult.success, isTrue);
    expect(buildManager.assembleCount, 1);
    expect(logger.errorText, isEmpty);

    final BuildResult cachedResult = await buildSystem.build(missingDepfileTarget, testEnvironment);
    expect(cachedResult.success, isTrue);
    expect(buildManager.assembleCount, 1);

    // Run 2 omits missing.d after trackedInput changes: stale missing.d is cleared,
    // an error is logged, and the subsequent build does not skip.
    writeDepfile = false;
    trackedInput.writeAsStringSync('v2');
    final BuildResult rebuildWithoutDepfile = await buildSystem.build(
      missingDepfileTarget,
      testEnvironment,
    );
    expect(rebuildWithoutDepfile.success, isTrue);
    expect(buildManager.assembleCount, 2);
    expect(
      logger.errorText,
      contains(
        'Extension assemble target "custom-target" declared depfile "missing.d", '
        'but it was not written to the build directory.',
      ),
    );
    expect(logger.errorText, contains('Try upgrading the extension or running "flutter clean".'));

    final BuildResult thirdResult = await buildSystem.build(missingDepfileTarget, testEnvironment);
    expect(thirdResult.success, isTrue);
    expect(buildManager.assembleCount, 3);
  });

  testWithoutContext(
    'ExtensionTarget logs error, deletes malformed depfile, and disables incremental caching',
    () async {
      final logger = BufferLogger.test();
      final buildSystem = FlutterBuildSystem(
        fileSystem: fileSystem,
        platform: FakePlatform(),
        logger: logger,
      );
      final testEnvironment = Environment.test(
        fileSystem.currentDirectory,
        defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
        inputs: <String, String>{},
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        featureFlags: TestFeatureFlags(),
        processManager: FakeProcessManager.any(),
      );
      final buildManager = FakeExtensionBuildManager(
        onAssemble: (Uri buildDir) {
          fileSystem
              .directory(buildDir)
              .childFile('malformed.d')
              .writeAsStringSync('not a valid depfile');
        },
      );
      final ExtensionTarget malformedDepfileTarget = _createTarget(
        buildManager: buildManager,
        depfiles: const <String>['malformed.d'],
      );

      final BuildResult firstResult = await buildSystem.build(
        malformedDepfileTarget,
        testEnvironment,
      );
      expect(firstResult.success, isTrue);
      expect(buildManager.assembleCount, 1);
      expect(
        logger.errorText,
        contains(
          'Invalid depfile "malformed.d" produced by extension assemble target "custom-target":',
        ),
      );
      expect(logger.errorText, isNot(contains('Invalid depfile: ')));
      expect(testEnvironment.buildDir.childFile('malformed.d').existsSync(), isFalse);

      final BuildResult secondResult = await buildSystem.build(
        malformedDepfileTarget,
        testEnvironment,
      );
      expect(secondResult.success, isTrue);
      expect(buildManager.assembleCount, 2);
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

  testWithoutContext(
    'ExtensionTarget throws ToolExit when same artifact is requested for multiple platforms',
    () async {
      final ExtensionTarget conflictingPlatformTarget = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(BuiltInArtifacts.genSnapshot),
          ExtensionSource.artifact(BuiltInArtifacts.genSnapshot, platform: 'linux-arm64'),
        ],
      );

      await expectLater(
        () => conflictingPlatformTarget.build(environment),
        throwsToolExit(
          message:
              'Assemble target "custom-target" requested artifact "genSnapshot" '
              'for multiple target platforms or build modes.',
        ),
      );
    },
  );

  testWithoutContext(
    'ExtensionTarget throws ToolExit when same artifact is requested for multiple modes',
    () async {
      final ExtensionTarget conflictingModeTarget = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(BuiltInArtifacts.genSnapshot),
          ExtensionSource.artifact(BuiltInArtifacts.genSnapshot, mode: .release),
        ],
      );

      await expectLater(
        () => conflictingModeTarget.build(environment),
        throwsToolExit(
          message:
              'Assemble target "custom-target" requested artifact "genSnapshot" '
              'for multiple target platforms or build modes.',
        ),
      );
    },
  );

  testWithoutContext(
    'ExtensionTarget allows duplicate artifact sources that resolve to the same path',
    () async {
      final buildManager = FakeExtensionBuildManager();
      final ExtensionTarget matchingDuplicateArtifactTarget = _createTarget(
        buildManager: buildManager,
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(BuiltInArtifacts.genSnapshot),
          ExtensionSource.artifact(
            BuiltInArtifacts.genSnapshot,
            platform: 'linux-x64',
            mode: .debug,
          ),
        ],
      );

      await matchingDuplicateArtifactTarget.build(environment);
      expect(
        buildManager.invokedResolvedArtifacts,
        equals(<String, String>{
          'genSnapshot': 'Artifact.genSnapshot.TargetPlatform.linux_x64.debug',
        }),
      );
    },
  );

  testWithoutContext('ExtensionTarget supports custom targetPlatform on target with built-in platform override on genSnapshot', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionTarget customTargetPlatformTarget = _createTarget(
      buildManager: buildManager,
      targetPlatform: 'custom-embedder-arm64',
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(BuiltInArtifacts.icuData),
        ExtensionSource.artifact(BuiltInArtifacts.flutterPatchedSdkPath),
        ExtensionSource.artifact(
          BuiltInArtifacts.genSnapshot,
          platform: 'linux-arm64',
          mode: .release,
        ),
      ],
    );

    final ResolvedFiles resolvedInputs = customTargetPlatformTarget.resolveInputs(environment);
    expect(
      resolvedInputs.sources.map((File file) => file.path),
      containsAll(<String>[
        'Artifact.icuData.debug',
        'Artifact.flutterPatchedSdkPath.debug',
        'Artifact.genSnapshot.TargetPlatform.linux_arm64.release',
      ]),
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
  });

  testWithoutContext(
    'ExtensionTarget throws ToolExit when artifact source specifies unsupported target platform',
    () async {
      const expectedMessage =
          'Unsupported target platform "custom-artifact-platform" '
          'for artifact "flutterPatchedSdkPath".';
      final ExtensionTarget targetWithUnsupportedSourcePlatform = _createTarget(
        inputs: const <ExtensionSource>[
          ExtensionSource.artifact(
            BuiltInArtifacts.flutterPatchedSdkPath,
            platform: 'custom-artifact-platform',
          ),
        ],
      );

      expect(
        () => targetWithUnsupportedSourcePlatform.resolveInputs(environment),
        throwsToolExit(message: expectedMessage),
      );

      await expectLater(
        () => targetWithUnsupportedSourcePlatform.build(environment),
        throwsToolExit(message: expectedMessage),
      );
    },
  );

  testWithoutContext('ExtensionTarget throws ToolExit when target-specific artifact resolves to null target platform', () async {
    const expectedGenSnapshotMessage =
        'Artifact "genSnapshot" requires a built-in target platform; specify a built-in '
        '"platform" on the artifact source when targeting out-of-tree platform '
        '"custom-embedder-arm64".';
    final ExtensionTarget outOfTreeGenSnapshotTarget = _createTarget(
      targetPlatform: 'custom-embedder-arm64',
      inputs: const <ExtensionSource>[ExtensionSource.artifact(BuiltInArtifacts.genSnapshot)],
    );

    expect(
      () => outOfTreeGenSnapshotTarget.resolveInputs(environment),
      throwsToolExit(message: expectedGenSnapshotMessage),
    );

    await expectLater(
      () => outOfTreeGenSnapshotTarget.build(environment),
      throwsToolExit(message: expectedGenSnapshotMessage),
    );

    const expectedLinuxDesktopMessage =
        'Artifact "linuxDesktopPath" requires a built-in target platform; specify a built-in '
        '"platform" on the artifact source when targeting out-of-tree platform '
        '"custom-embedder-arm64".';
    final ExtensionTarget outOfTreeLinuxDesktopTarget = _createTarget(
      targetPlatform: 'custom-embedder-arm64',
      inputs: const <ExtensionSource>[
        ExtensionSource.artifact(ExtensionArtifact('linuxDesktopPath')),
      ],
    );

    expect(
      () => outOfTreeLinuxDesktopTarget.resolveInputs(environment),
      throwsToolExit(message: expectedLinuxDesktopMessage),
    );

    await expectLater(
      () => outOfTreeLinuxDesktopTarget.build(environment),
      throwsToolExit(message: expectedLinuxDesktopMessage),
    );
  });

  testWithoutContext('resolveExtensionBuildTargetArtifacts resolves target-independent artifacts and throws ToolExit when target-specific artifact is requested for out-of-tree platform', () {
    final Map<String, String> resolvedIndependent = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: .release,
      target: ExtensionBuildTarget(
        description: 'Out-of-tree build target with target-independent artifacts',
        name: 'custom-target',
        outputDir: '{OUTPUT_DIR}/custom',
        targetPlatforms: const <String>{'custom-embedder-arm64'},
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.flutterPatchedSdkPath,
          BuiltInArtifacts.icuData,
        },
      ),
    );
    expect(
      resolvedIndependent,
      equals(<String, String>{
        'flutterPatchedSdkPath': 'Artifact.flutterPatchedSdkPath.release',
        'icuData': 'Artifact.icuData.release',
      }),
    );

    expect(
      () => resolveExtensionBuildTargetArtifacts(
        artifacts: artifacts,
        buildMode: .release,
        target: ExtensionBuildTarget(
          description: 'Out-of-tree build target with genSnapshot',
          name: 'custom-target',
          outputDir: '{OUTPUT_DIR}/custom',
          targetPlatforms: const <String>{'custom-embedder-arm64'},
          artifacts: const <ExtensionArtifact>{BuiltInArtifacts.genSnapshot},
        ),
      ),
      throwsToolExit(
        message:
            'Artifact "genSnapshot" requires a built-in target platform, '
            'but build target "custom-target" targets out-of-tree platform "custom-embedder-arm64".',
      ),
    );

    expect(
      () => resolveExtensionBuildTargetArtifacts(
        artifacts: artifacts,
        buildMode: .release,
        target: ExtensionBuildTarget(
          description: 'Platform-agnostic build target with genSnapshot',
          name: 'agnostic-target',
          outputDir: '{OUTPUT_DIR}/agnostic',
          artifacts: const <ExtensionArtifact>{BuiltInArtifacts.genSnapshot},
        ),
      ),
      throwsToolExit(
        message:
            'Artifact "genSnapshot" requires a built-in target platform, '
            'but build target "agnostic-target" does not specify a targetPlatform.',
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
            targetPlatforms: const <String>{'linux-x64'},
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
        target: ExtensionBuildTarget(
          description: 'description',
          name: 'custom-target',
          outputDir: '{OUTPUT_DIR}/custom/{BUILD_MODE}',
          targetPlatforms: const <String>{'linux-x64'},
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
            target: ExtensionBuildTarget(
              description: 'description',
              name: 'custom-target',
              outputDir: '{BUILD_DIR}/custom-out',
              targetPlatforms: const <String>{'linux-x64'},
            ),
          ),
          throwsToolExit(
            message: 'Unsupported placeholder "{BUILD_DIR}" in outputDir "{BUILD_DIR}/custom-out" for build target "custom-target".',
          ),
        );
      },
    );

    testWithoutContext('resolves outputDir without {TARGET_PLATFORM} when targetPlatforms is empty and throws ToolExit if {TARGET_PLATFORM} is used', () {
      final Directory projectDir = fileSystem.directory('/project');
      final Directory buildOutputDir = projectDir.childDirectory('build');
      final Directory resolved = resolveExtensionOutputDir(
        buildMode: .release,
        buildOutputDir: buildOutputDir,
        fileSystem: fileSystem,
        projectDir: projectDir,
        target: ExtensionBuildTarget(
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
          target: ExtensionBuildTarget(
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
    final buildTarget = ExtensionBuildTarget(
      description: 'Contract check build target',
      name: 'contract-build-target',
      outputDir: '{OUTPUT_DIR}/contract-build',
      targetPlatforms: const <String>{'linux-x64'},
      artifacts: const <ExtensionArtifact>{
        BuiltInArtifacts.flutterPatchedSdkPath,
        BuiltInArtifacts.genSnapshot,
        BuiltInArtifacts.icuData,
        ExtensionArtifact('linuxDesktopPath'),
        ExtensionArtifact('linuxHeaders'),
      },
      hostArtifacts: const <ExtensionHostArtifact>{
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

    final assembleTarget = ExtensionAssembleTarget(
      description: 'Contract check assemble target',
      name: 'contract-assemble-target',
      targetPlatform: 'linux-x64',
      inputs: const <ExtensionSource>[
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

  testWithoutContext('ExtensionTarget extracts and forwards build context defines and filters built-in keys from extraDefines', () async {
    final buildManager = FakeExtensionBuildManager();
    final ExtensionTarget target = _createTarget(buildManager: buildManager);
    final customEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.release.cliName,
        kTargetFile: 'lib/custom_main.dart',
        kTargetPlatform: 'linux-arm64',
        kFlavor: 'staging',
        kBuildName: '2.0.0',
        kBuildNumber: '99',
        kDartDefines: encodeDartDefines(<String>['API_HOST=api.example.com', 'FLAG=1']),
        kDartObfuscation: 'true',
        kSplitDebugInfo: '/project/symbols',
        kCodeSizeDirectory: '/project/code_size',
        kExtraFrontEndOptions: '--fe-opt1,--fe-opt2',
        kExtraGenSnapshotOptions: '--gs-opt1',
        kTrackWidgetCreation: 'false',
        kIconTreeShakerFlag: 'true',
        kExtensionConfigDefines: encodeExtensionConfigDefines(const <String, Object?>{
          'sdk-dir': '/opt/custom',
          'enable-feature': true,
        }),
        'CustomUserDefine': 'user-val',
      },
      inputs: <String, String>{},
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(),
      processManager: FakeProcessManager.any(),
    );

    await target.build(customEnvironment);

    expect(buildManager.invokedBuildMode, BuildMode.release);
    expect(buildManager.invokedMainPath, 'lib/custom_main.dart');
    expect(buildManager.invokedTargetPlatform, 'linux-arm64');
    expect(buildManager.invokedFlavor, 'staging');
    expect(buildManager.invokedBuildName, '2.0.0');
    expect(buildManager.invokedBuildNumber, '99');
    expect(
      buildManager.invokedDartDefines,
      equals(const <String, String>{'API_HOST': 'api.example.com', 'FLAG': '1'}),
    );
    expect(buildManager.invokedDartObfuscation, isTrue);
    expect(buildManager.invokedSplitDebugInfo, Uri.parse('file:///project/symbols/'));
    expect(buildManager.invokedCodeSizeDirectory, Uri.parse('file:///project/code_size/'));
    expect(
      buildManager.invokedExtraFrontEndOptions,
      equals(const <String>['--fe-opt1', '--fe-opt2']),
    );
    expect(buildManager.invokedExtraGenSnapshotOptions, equals(const <String>['--gs-opt1']));
    expect(buildManager.invokedTrackWidgetCreation, isFalse);
    expect(buildManager.invokedTreeShakeIcons, isTrue);
    expect(
      buildManager.invokedConfiguration,
      equals(const <String, Object?>{'enable-feature': true, 'sdk-dir': '/opt/custom'}),
    );
    expect(
      buildManager.invokedExtraDefines,
      equals(const <String, String>{'CustomUserDefine': 'user-val'}),
    );

    final Directory relativeProjectDir = fileSystem.directory('/workspace/app')
      ..createSync(recursive: true);
    final relativeEnvironment = Environment.test(
      relativeProjectDir,
      defines: <String, String>{
        kBuildMode: BuildMode.release.cliName,
        kSplitDebugInfo: 'rel_symbols',
        kCodeSizeDirectory: 'rel_code_size',
        kExtensionConfigDefines: encodeTargetExtensionConfigDefines(
          const <String, Map<String, Object?>>{
            'custom-target': <String, Object?>{'enable-target': false, 'target-key': 'target-val'},
            'other-target': <String, Object?>{'other-key': 'other-val'},
          },
        ),
      },
      inputs: <String, String>{},
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(),
      processManager: FakeProcessManager.any(),
    );

    await target.build(relativeEnvironment);

    expect(buildManager.invokedSplitDebugInfo, Uri.parse('file:///workspace/app/rel_symbols/'));
    expect(
      buildManager.invokedCodeSizeDirectory,
      Uri.parse('file:///workspace/app/rel_code_size/'),
    );
    expect(
      buildManager.invokedConfiguration,
      equals(const <String, Object?>{'enable-target': false, 'target-key': 'target-val'}),
    );
  });

  testWithoutContext('resolveExtensionOutputDir and resolveExtensionBuildTargetArtifacts honor targetPlatform override', () {
    final Directory projectDir = fileSystem.directory('/project');
    final Directory buildOutputDir = projectDir.childDirectory('build');
    final target = ExtensionBuildTarget(
      description: 'Multi-arch target',
      name: 'multi-arch',
      outputDir: '{OUTPUT_DIR}/{TARGET_PLATFORM}/{BUILD_MODE}',
      targetPlatforms: const <String>{'linux-x64', 'linux-arm64'},
      artifacts: const <ExtensionArtifact>{BuiltInArtifacts.genSnapshot},
    );

    final Directory resolvedDir = resolveExtensionOutputDir(
      buildMode: .release,
      buildOutputDir: buildOutputDir,
      fileSystem: fileSystem,
      projectDir: projectDir,
      target: target,
      targetPlatform: 'linux-arm64',
    );
    expect(resolvedDir.path, equals('/project/build/linux-arm64/release'));

    final Map<String, String> resolvedArtifacts = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: .release,
      target: target,
      targetPlatform: 'linux-arm64',
    );
    expect(
      resolvedArtifacts[BuiltInArtifacts.genSnapshot.name],
      equals('Artifact.genSnapshot.TargetPlatform.linux_arm64.release'),
    );
  });
}
