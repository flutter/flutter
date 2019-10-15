// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pool/pool.dart';

import '../../artifacts.dart';
import '../../asset.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../dart/package_map.dart';
import '../../devfs.dart';
import '../../globals.dart';
import '../../project.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'assets.dart';

/// The define to pass a [BuildMode].
const String kBuildMode= 'BuildMode';

/// The define to pass whether we compile 64-bit android-arm code.
const String kTargetPlatform = 'TargetPlatform';

/// The define to control what target file is used.
const String kTargetFile = 'TargetFile';

/// The define to control whether the AOT snapshot is built with bitcode.
const String kBitcodeFlag = 'EnableBitcode';

/// The define to control what iOS architectures are built for.
///
/// This is expected to be a comma-separated list of architectures. If not
/// provided, defaults to arm64.
///
/// The other supported value is armv7, the 32-bit iOS architecture.
const String kIosArchs = 'IosArchs';

/// Finds the locations of all dart files within the project.
///
/// This does not attempt to determine if a file is used or imported, so it
/// may otherwise report more files than strictly necessary.
List<File> listDartSources(Environment environment) {
  final Map<String, Uri> packageMap = PackageMap(environment.projectDir.childFile('.packages').path).map;
  final List<File> dartFiles = <File>[];
  for (Uri uri in packageMap.values) {
    final Directory libDirectory = fs.directory(uri.toFilePath(windows: platform.isWindows));
    if (!libDirectory.existsSync()) {
      continue;
    }
    for (FileSystemEntity entity in libDirectory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
  }
  return dartFiles;
}

/// Copies the prebuilt flutter bundle.
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
    Source.behavior(AssetOutputBehavior()),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/vm_snapshot_data'),
    Source.pattern('{OUTPUT_DIR}/isolate_snapshot_data'),
    Source.pattern('{OUTPUT_DIR}/kernel_blob.bin'),
    Source.pattern('{OUTPUT_DIR}/AssetManifest.json'),
    Source.pattern('{OUTPUT_DIR}/FontManifest.json'),
    Source.pattern('{OUTPUT_DIR}/LICENSE'),
    Source.behavior(AssetOutputBehavior()),
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'copy_flutter_bundle');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);

    // We're not smart enough to only remove assets that are removed. If
    // anything changes blow away the whole directory.
    if (environment.outputDir.existsSync()) {
      environment.outputDir.deleteSync(recursive: true);
    }
    environment.outputDir.createSync(recursive: true);

    // Only copy the prebuilt runtimes and kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(environment.outputDir.childFile('kernel_blob.bin').path);
      fs.file(vmSnapshotData)
          .copySync(environment.outputDir.childFile('vm_snapshot_data').path);
      fs.file(isolateSnapshotData)
          .copySync(environment.outputDir.childFile('isolate_snapshot_data').path);
    }

    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    await assetBundle.build();
    await copyAssets(assetBundle, environment);
  }

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}

/// A helper function to copy an [assetBundle] into an [environment]'s output directory,
/// plus an optional [pathSuffix]
Future<void> copyAssets(AssetBundle assetBundle, Environment environment, [String pathSuffix = '']) async {
  final Pool pool = Pool(kMaxOpenFiles);
  await Future.wait<void>(
    assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        final File file = fs.file(fs.path.join(environment.outputDir.path, pathSuffix, entry.key));
        file.parent.createSync(recursive: true);
        final DevFSContent content = entry.value;
        if (content is DevFSFileContent && content.file is File) {
          await (content.file as File).copy(file.path);
        } else {
          await file.writeAsBytes(await entry.value.contentsAsBytes());
        }
      } finally {
        resource.release();
      }
  }));
}

/// Copies the prebuilt flutter bundle for release mode.
class ReleaseCopyFlutterBundle extends CopyFlutterBundle {
  const ReleaseCopyFlutterBundle();

  @override
  String get name => 'release_flutter_bundle';

  @override
  List<Source> get inputs => const <Source>[
    Source.behavior(AssetOutputBehavior()),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/AssetManifest.json'),
    Source.pattern('{OUTPUT_DIR}/FontManifest.json'),
    Source.pattern('{OUTPUT_DIR}/LICENSE'),
    Source.behavior(AssetOutputBehavior()),
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
    Source.depfile('kernel_snapshot.d'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.depfile('kernel_snapshot.d'),
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
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String targetFile = environment.defines[kTargetFile] ?? fs.path.join('lib', 'main.dart');
    final String packagesPath = environment.projectDir.childFile('.packages').path;
    final String targetFileAbsolute = fs.file(targetFile).absolute.path;

    final CompilerOutput output = await compiler.compile(
      sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
      aot: buildMode != BuildMode.debug,
      buildMode: buildMode,
      trackWidgetCreation: buildMode == BuildMode.debug,
      targetModel: TargetModel.flutter,
      outputFilePath: environment.buildDir.childFile('app.dill').path,
      packagesPath: packagesPath,
      linkPlatformKernelIn: buildMode == BuildMode.release,
      mainPath: targetFileAbsolute,
      depFilePath: environment.buildDir.childFile('kernel_snapshot.d').path,
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
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      bitcode: false,
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
