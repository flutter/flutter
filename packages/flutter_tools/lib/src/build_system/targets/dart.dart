// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../convert.dart';
import '../../globals.dart' as globals;
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'icon_tree_shaker.dart';

/// The define to pass a [BuildMode].
const String kBuildMode= 'BuildMode';

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

/// Defines specified via the `--dart-define` command-line option.
const String kDartDefines = 'DartDefines';

/// The define to control what iOS architectures are built for.
///
/// This is expected to be a comma-separated list of architectures. If not
/// provided, defaults to arm64.
///
/// The other supported value is armv7, the 32-bit iOS architecture.
const String kIosArchs = 'IosArchs';

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
      final String vmSnapshotData = globals.artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = globals.artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(environment.outputDir.childFile('kernel_blob.bin').path);
      globals.fs.file(vmSnapshotData)
          .copySync(environment.outputDir.childFile('vm_snapshot_data').path);
      globals.fs.file(isolateSnapshotData)
          .copySync(environment.outputDir.childFile('isolate_snapshot_data').path);
    }
    final Depfile assetDepfile = await copyAssets(environment, environment.outputDir);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
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
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/dart.dart'),
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
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    final KernelCompiler compiler = await kernelCompilerFactory.create(
      FlutterProject.fromDirectory(environment.projectDir),
    );
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'kernel_snapshot');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'kernel_snapshot');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String targetFile = environment.defines[kTargetFile] ?? globals.fs.path.join('lib', 'main.dart');
    final String packagesPath = environment.projectDir.childFile('.packages').path;
    final String targetFileAbsolute = globals.fs.file(targetFile).absolute.path;
    // everything besides 'false' is considered to be enabled.
    final bool trackWidgetCreation = environment.defines[kTrackWidgetCreation] != 'false';
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);

    // This configuration is all optional.
    final List<String> extraFrontEndOptions = <String>[
      ...?environment.defines[kExtraFrontEndOptions]?.split(',')
    ];
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

    final CompilerOutput output = await compiler.compile(
      sdkRoot: globals.artifacts.getArtifactPath(
        Artifact.flutterPatchedSdkPath,
        platform: targetPlatform,
        mode: buildMode,
      ),
      aot: buildMode.isPrecompiled,
      buildMode: buildMode,
      trackWidgetCreation: trackWidgetCreation && buildMode == BuildMode.debug,
      targetModel: targetModel,
      outputFilePath: environment.buildDir.childFile('app.dill').path,
      packagesPath: packagesPath,
      linkPlatformKernelIn: forceLinkPlatform || buildMode.isPrecompiled,
      mainPath: targetFileAbsolute,
      depFilePath: environment.buildDir.childFile('kernel_snapshot.d').path,
      extraFrontEndOptions: extraFrontEndOptions,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      dartDefines: parseDartDefines(environment),
    );
    if (output == null || output.errorCount != 0) {
      throw Exception('Errors during snapshot creation: $output');
    }
  }
}

/// Supports compiling a dart kernel file to an ELF binary.
abstract class AotElfBase extends Target {
  const AotElfBase();

  @override
  Future<void> build(Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
    final String outputPath = environment.buildDir.path;
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'aot_elf');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'aot_elf');
    }
    final List<String> extraGenSnapshotOptions = environment.defines[kExtraGenSnapshotOptions]?.split(',')
      ?? const <String>[];
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    final String saveDebuggingInformation = environment.defines[kSplitDebugInfo];
    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      bitcode: false,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
      splitDebugInfo: saveDebuggingInformation
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  }
}

/// Generate an ELF binary from a dart kernel file in profile mode.
class AotElfProfile extends AotElfBase {
  const AotElfProfile();

  @override
  String get name => 'aot_elf_profile';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/dart.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.android_arm,
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
}

/// Generate an ELF binary from a dart kernel file in release mode.
class AotElfRelease extends AotElfBase {
  const AotElfRelease();

  @override
  String get name => 'aot_elf_release';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/dart.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.android_arm,
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

/// Dart defines are encoded inside [Environment] as a JSON array.
List<String> parseDartDefines(Environment environment) {
  if (!environment.defines.containsKey(kDartDefines)) {
    return const <String>[];
  }

  final String dartDefinesJson = environment.defines[kDartDefines];
  try {
    final List<Object> parsedDefines = jsonDecode(dartDefinesJson) as List<Object>;
    return parsedDefines.cast<String>();
  } on FormatException catch (_) {
    throw Exception(
      'The value of -D$kDartDefines is not formatted correctly.\n'
      'The value must be a JSON-encoded list of strings but was:\n'
      '$dartDefinesJson'
    );
  }
}
