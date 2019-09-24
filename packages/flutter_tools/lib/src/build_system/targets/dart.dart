// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../dart/package_map.dart';
import '../../globals.dart';
import '../../project.dart';
import '../build_system.dart';
import '../exceptions.dart';

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

/// Generate a snapshot of the dart code used in the program.
class KernelSnapshot extends Target {
  const KernelSnapshot();

  @override
  String get name => 'kernel_snapshot';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/dart.dart'),
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib and in .packages
    Source.artifact(Artifact.platformKernelDill),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.frontendServerSnapshotForEngineDartSdk),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
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
    final PackageUriMapper packageUriMapper = PackageUriMapper(targetFile,
        packagesPath, null, null);

    final CompilerOutput output = await compiler.compile(
      sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
      aot: buildMode != BuildMode.debug,
      trackWidgetCreation: buildMode == BuildMode.debug,
      targetModel: TargetModel.flutter,
      targetProductVm: buildMode == BuildMode.release,
      outputFilePath: environment.buildDir.childFile('app.dill').path,
      depFilePath: null,
      packagesPath: packagesPath,
      linkPlatformKernelIn: buildMode == BuildMode.release,
      mainPath: packageUriMapper.map(targetFile)?.toString() ?? targetFile,
    );
    if (output.errorCount != 0) {
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
