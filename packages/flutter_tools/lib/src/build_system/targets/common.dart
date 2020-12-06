// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../dart/package_map.dart';
import '../../globals.dart' as globals hide fs, processManager, artifacts, logger;
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'icon_tree_shaker.dart';
import 'localizations.dart';

/// The define to pass a [BuildMode].
const String kBuildMode = 'BuildMode';

/// The define to pass whether we compile 64-bit android-arm code.
const String kTargetPlatform = 'TargetPlatform';

/// The define to control what target file is used.
const String kTargetFile = 'TargetFile';

/// The define to control whether the AOT snapshot is built with bitcode.
const String kBitcodeFlag = 'EnableBitcode';

/// Whether to enable or disable track widget creation.
const String kTrackWidgetCreation = 'TrackWidgetCreation';

/// Additional configuration passed to the dart front end.
///
/// This is expected to be a comma separated list of strings.
const String kExtraFrontEndOptions = 'ExtraFrontEndOptions';

/// Additional configuration passed to gen_snapshot.
///
/// This is expected to be a comma separated list of strings.
const String kExtraGenSnapshotOptions = 'ExtraGenSnapshotOptions';

/// Whether to strip source code information out of release builds and where to save it.
const String kSplitDebugInfo = 'SplitDebugInfo';

/// Alternative scheme for file URIs.
///
/// May be used along with [kFileSystemRoots] to support a multi-root
/// filesystem.
const String kFileSystemScheme = 'FileSystemScheme';

/// Additional filesystem roots.
///
/// If provided, must be used along with [kFileSystemScheme].
const String kFileSystemRoots = 'FileSystemRoots';

/// The define to control what iOS architectures are built for.
///
/// This is expected to be a comma-separated list of architectures. If not
/// provided, defaults to arm64.
///
/// The other supported value is armv7, the 32-bit iOS architecture.
const String kIosArchs = 'IosArchs';

/// Whether to enable Dart obfuscation and where to save the symbol map.
const String kDartObfuscation = 'DartObfuscation';

/// An output directory where one or more code-size measurements may be written.
const String kCodeSizeDirectory = 'CodeSizeDirectory';

/// Copies the pre-built flutter bundle.
// This is a one-off rule for implementing build bundle in terms of assemble.
class CopyFlutterBundle extends Target {
  const CopyFlutterBundle();

  @override
  String get name => 'copy_flutter_bundle';

  @override
  List<Source> get inputs => const <Source>[
    Source.artifact(Artifact.vmSnapshotData, mode: BuildMode.debug),
    Source.artifact(Artifact.isolateSnapshotData, mode: BuildMode.debug),
    Source.pattern('{BUILD_DIR}/app.dill'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/vm_snapshot_data'),
    Source.pattern('{OUTPUT_DIR}/isolate_snapshot_data'),
    Source.pattern('{OUTPUT_DIR}/kernel_blob.bin'),
  ];

  @override
  List<String> get depfiles => <String>[
    'flutter_assets.d'
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'copy_flutter_bundle');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    environment.outputDir.createSync(recursive: true);

    // Only copy the prebuilt runtimes and kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      final String vmSnapshotData = environment.artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = environment.artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(environment.outputDir.childFile('kernel_blob.bin').path);
      environment.fileSystem.file(vmSnapshotData)
          .copySync(environment.outputDir.childFile('vm_snapshot_data').path);
      environment.fileSystem.file(isolateSnapshotData)
          .copySync(environment.outputDir.childFile('isolate_snapshot_data').path);
    }
    final Depfile assetDepfile = await copyAssets(
      environment,
      environment.outputDir,
      targetPlatform: TargetPlatform.android,
    );
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      assetDepfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}

/// Copies the pre-built flutter bundle for release mode.
class ReleaseCopyFlutterBundle extends CopyFlutterBundle {
  const ReleaseCopyFlutterBundle();

  @override
  String get name => 'release_flutter_bundle';

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  List<Target> get dependencies => const <Target>[];
}


/// Generate a snapshot of the dart code used in the program.
class KernelSnapshot extends Target {
  const KernelSnapshot();

  @override
  String get name => 'kernel_snapshot';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/common.dart'),
    Source.artifact(Artifact.platformKernelDill),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.frontendServerSnapshotForEngineDartSdk),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>[
    'kernel_snapshot.d',
  ];

  @override
  List<Target> get dependencies => const <Target>[
    GenerateLocalizationsTarget(),
  ];

  @override
  Future<void> build(Environment environment) async {
    final KernelCompiler compiler = KernelCompiler(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      processManager: environment.processManager,
      artifacts: environment.artifacts,
    );
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'kernel_snapshot');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'kernel_snapshot');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String targetFile = environment.defines[kTargetFile] ?? environment.fileSystem.path.join('lib', 'main.dart');
    final File packagesFile = environment.projectDir.childFile('.packages');
    final String targetFileAbsolute = environment.fileSystem.file(targetFile).absolute.path;
    // everything besides 'false' is considered to be enabled.
    final bool trackWidgetCreation = environment.defines[kTrackWidgetCreation] != 'false';
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);

    // This configuration is all optional.
    final List<String> extraFrontEndOptions = decodeDartDefines(environment.defines, kExtraFrontEndOptions);
    final List<String> fileSystemRoots = environment.defines[kFileSystemRoots]?.split(',');
    final String fileSystemScheme = environment.defines[kFileSystemScheme];

    TargetModel targetModel = TargetModel.flutter;
    if (targetPlatform == TargetPlatform.fuchsia_x64 ||
        targetPlatform == TargetPlatform.fuchsia_arm64) {
      targetModel = TargetModel.flutterRunner;
    }
    // Force linking of the platform for desktop embedder targets since these
    // do not correctly load the core snapshots in debug mode.
    // See https://github.com/flutter/flutter/issues/44724
    bool forceLinkPlatform;
    switch (targetPlatform) {
      case TargetPlatform.darwin_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.linux_x64:
        forceLinkPlatform = true;
        break;
      default:
        forceLinkPlatform = false;
    }

    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      environment.projectDir.childFile('.packages'),
      logger: environment.logger,
    );

    final CompilerOutput output = await compiler.compile(
      sdkRoot: environment.artifacts.getArtifactPath(
        Artifact.flutterPatchedSdkPath,
        platform: targetPlatform,
        mode: buildMode,
      ),
      aot: buildMode.isPrecompiled,
      buildMode: buildMode,
      trackWidgetCreation: trackWidgetCreation && buildMode == BuildMode.debug,
      targetModel: targetModel,
      outputFilePath: environment.buildDir.childFile('app.dill').path,
      packagesPath: packagesFile.path,
      linkPlatformKernelIn: forceLinkPlatform || buildMode.isPrecompiled,
      mainPath: targetFileAbsolute,
      depFilePath: environment.buildDir.childFile('kernel_snapshot.d').path,
      extraFrontEndOptions: extraFrontEndOptions,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      dartDefines: decodeDartDefines(environment.defines, kDartDefines),
      packageConfig: packageConfig,
    );
    if (output == null || output.errorCount != 0) {
      throw Exception();
    }
  }
}

/// Supports compiling a dart kernel file to an ELF binary.
abstract class AotElfBase extends Target {
  const AotElfBase();

  @override
  String get analyticsName => 'android_aot';

  @override
  Future<void> build(Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(
      reportTimings: false,
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      xcode: globals.xcode,
      processManager: environment.processManager,
      artifacts: environment.artifacts,
    );
    final String outputPath = environment.buildDir.path;
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'aot_elf');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'aot_elf');
    }
    final List<String> extraGenSnapshotOptions = decodeDartDefines(environment.defines, kExtraGenSnapshotOptions);
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    final String splitDebugInfo = environment.defines[kSplitDebugInfo];
    final bool dartObfuscation = environment.defines[kDartObfuscation] == 'true';
    final String codeSizeDirectory = environment.defines[kCodeSizeDirectory];

    if (codeSizeDirectory != null) {
      final File codeSizeFile = environment.fileSystem
        .directory(codeSizeDirectory)
        .childFile('snapshot.${environment.defines[kTargetPlatform]}.json');
      final File precompilerTraceFile = environment.fileSystem
        .directory(codeSizeDirectory)
        .childFile('trace.${environment.defines[kTargetPlatform]}.json');
      extraGenSnapshotOptions.add('--write-v8-snapshot-profile-to=${codeSizeFile.path}');
      extraGenSnapshotOptions.add('--trace-precompiler-to=${precompilerTraceFile.path}');
    }

    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      bitcode: false,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
      splitDebugInfo: splitDebugInfo,
      dartObfuscation: dartObfuscation,
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  }
}

/// Generate an ELF binary from a dart kernel file in profile mode.
class AotElfProfile extends AotElfBase {
  const AotElfProfile(this.targetPlatform);

  @override
  String get name => 'aot_elf_profile';

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/common.dart'),
    const Source.pattern('{BUILD_DIR}/app.dill'),
    const Source.pattern('{PROJECT_DIR}/.packages'),
    const Source.artifact(Artifact.engineDartBinary),
    const Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: targetPlatform,
      mode: BuildMode.profile,
    ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  final TargetPlatform targetPlatform;
}

/// Generate an ELF binary from a dart kernel file in release mode.
class AotElfRelease extends AotElfBase {
  const AotElfRelease(this.targetPlatform);

  @override
  String get name => 'aot_elf_release';

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/common.dart'),
    const Source.pattern('{BUILD_DIR}/app.dill'),
    const Source.pattern('{PROJECT_DIR}/.packages'),
    const Source.artifact(Artifact.engineDartBinary),
    const Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: targetPlatform,
      mode: BuildMode.release,
    ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  final TargetPlatform targetPlatform;
}

/// Copies the pre-built flutter aot bundle.
// This is a one-off rule for implementing build aot in terms of assemble.
abstract class CopyFlutterAotBundle extends Target {
  const CopyFlutterAotBundle();

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/app.so'),
  ];

  @override
  Future<void> build(Environment environment) async {
    final File outputFile = environment.outputDir.childFile('app.so');
    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }
    environment.buildDir.childFile('app.so').copySync(outputFile.path);
  }
}
