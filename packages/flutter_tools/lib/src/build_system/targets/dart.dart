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
const String kAndroid64Bit = 'Android64bit';

/// The define to control what target file is used.
const String kTargetFile = 'TargetFile';

/// Supports compiling dart source to kernel with a subset of flags.
///
/// This is a non-incremental compile so the specific [updates] are ignored.
Future<void> compileKernel(Map<String, ChangeType> updates, Environment environment) async {
  final KernelCompiler compiler = await kernelCompilerFactory.create(
    FlutterProject.fromDirectory(environment.projectDir),
  );
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  if (buildMode == null) {
    throw MissingDefineException(kBuildMode, 'kernel_snapshot');
  }
  final String targetFile = environment.defines[kTargetFile] ?? fs.path.join('lib', 'main.dart');

  final CompilerOutput output = await compiler.compile(
    sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
    aot: buildMode != BuildMode.debug,
    trackWidgetCreation: false,
    targetModel: TargetModel.flutter,
    targetProductVm: buildMode == BuildMode.release,
    outputFilePath: environment
      .buildDir
      .childFile('main.app.dill')
      .path,
    depFilePath: null,
    mainPath: targetFile,
  );
  if (output.errorCount != 0) {
    throw Exception('Errors during snapshot creation: $output');
  }
}

/// Supports compiling a dart kernel file to an ELF binary.
Future<void> compileAotElf(Map<String, ChangeType> updates, Environment environment) async {
  final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
  final String outputPath = environment.buildDir.path;
  final bool use64Bit = environment.defines[kAndroid64Bit] == 'true';
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  if (buildMode == null) {
    throw MissingDefineException(kBuildMode, 'kernel_snapshot');
  }

  final int snapshotExitCode = await snapshotter.build(
    platform: use64Bit ? TargetPlatform.android_arm64 : TargetPlatform.android_arm,
    buildMode: buildMode,
    mainPath: environment.buildDir.childFile('main.app.dill').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
    outputPath: outputPath,
  );
  if (snapshotExitCode != 0) {
    throw Exception('AOT snapshotter exited with code $snapshotExitCode');
  }
}

/// Find the correct gen_snapshot implemenation for the aot elf build.
List<File> findGenSnapshotAndroidElf(Environment environment) {
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  final bool use64Bit = environment.defines[kAndroid64Bit] == 'true';
  if (buildMode == null) {
    throw MissingDefineException(kBuildMode, 'aot_elf');
  }
  String platformName;
  if (platform.isMacOS) {
    platformName = 'darwin-x64';
  } else if (platform.isLinux) {
    platformName = 'linux-x64';
  } else if (platform.isWindows) {
    platformName = 'windows-x64';
  } else {
    throw Exception('Unsupported host platform ${platform.localeName}');
  }
  final String path = fs.path.join(environment.cacheDir.path,
    'artifacts', 'engine',
    'android-arm${use64Bit ? '64' : ''}-${buildMode == BuildMode.release ? 'release' : 'profile'}',
    platformName, 'gen_snapshot'
  );
  return <File>[fs.file(path)];
}

/// Finds the locations of all dart files within the project.
///
/// This does not attempt to determine if a file is used or imported, so it
/// may otherwise report more files than strictly necessary.
List<File> listDartSources(Environment environment) {
  final Map<String, Uri> packageMap = PackageMap(environment.projectDir.childFile('.packages').path).map;
  final List<File> dartFiles = <File>[];
  for (Uri uri in packageMap.values) {
    final Directory libDirectory = fs.directory(uri.toFilePath(windows: platform.isWindows));
    for (FileSystemEntity entity in libDirectory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
  }
  return dartFiles;
}

/// Generate a snapshot of the dart code used in the program.
const Target kernelSnapshot = Target(
  name: 'kernel_snapshot',
  inputs: <Source>[
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib and .packages
    Source.pattern('{CACHE_DIR}/artifacts/engine/common/flutter_patched_sdk/platform_strong.dill'),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
  ],
  dependencies: <Target>[],
  buildAction: compileKernel,
);

/// Generate an ELF binary from a dart snapshot.
const Target aotElf = Target(
  name: 'aot_elf',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.pattern('{CACHE_DIR}/pkg/sky_engine/lib/ui/ui.dart'),
    Source.pattern('{CACHE_DIR}/pkg/sky_engine/sdk_ext/vmservice_io.dart'),
    Source.function(findGenSnapshotAndroidElf),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
    Source.pattern('{BUILD_DIR}/gen_snapshot.d'),
    Source.pattern('{BUILD_DIR}/snapshot.d.fingerprint'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotElf,
);

