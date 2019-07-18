// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/platform.dart';
import '../../base/process_manager.dart';
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
const String kBitcodeFlag = 'bitcode';

/// The define to control what iOS architectures are built for.
///
/// This is expected to be a comma-separated list of architectures. If not
/// provided, defaults to arm64.
///
/// The other supported value is armv7, the 32-bit iOS architecture.
const String kIosArchs = 'IosArchs';

/// Supports compiling dart source to kernel with a subset of flags.
///
/// This is a non-incremental compile so the specific [updates] are ignored.
Future<void> compileKernel(Map<String, ChangeType> updates, Environment environment) async {
  final KernelCompiler compiler = await kernelCompilerFactory.create(
    FlutterProject.fromDirectory(environment.projectDir),
  );
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'kernel_snapshot');
  }
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
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
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'aot_elf');
  }
  if (environment.defines[kTargetPlatform] == null) {
    throw MissingDefineException(kTargetPlatform, 'aot_elf');
  }
  final bool bitcode = environment.defines[kBitcodeFlag] == 'true';

  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
  final int snapshotExitCode = await snapshotter.build(
    platform: targetPlatform,
    buildMode: buildMode,
    mainPath: environment.buildDir.childFile('main.app.dill').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
    outputPath: outputPath,
    bitcode: bitcode,
  );
  if (snapshotExitCode != 0) {
    throw Exception('AOT snapshotter exited with code $snapshotExitCode');
  }
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

/// Supports compiling a dart kernel file to an assembly file.
///
/// If more than one iOS arch is provided, then this rule will
/// produce a univeral binary.
Future<void> compileAotAssembly(Map<String, ChangeType> updates, Environment environment) async {
  final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
  final String outputPath = environment.buildDir.path;
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'aot_assembly');
  }
  if (environment.defines[kTargetPlatform] == null) {
    throw MissingDefineException(kTargetPlatform, 'aot_assembly');
  }
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
  final List<IOSArch> iosArchs = environment.defines[kIosArchs]?.split(',')?.map(getIOSArchForName)?.toList()
      ?? <IOSArch>[IOSArch.arm64];
  if (targetPlatform != TargetPlatform.ios) {
    throw Exception('aot_assembly is only supported for iOS applications');
  }
  final bool bitcode = environment.defines[kBitcodeFlag] == 'true';

  // If we're building for a single architecture (common), then skip the lipo.
  if (iosArchs.length == 1) {
    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('main.app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      iosArch: iosArchs.single,
      bitcode: bitcode,
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  } else {
    // If we're building multiple iOS archs the binaries need to be lipo'd
    // together.
    final List<Future<int>> pending = <Future<int>>[];
    for (IOSArch iosArch in iosArchs) {
      pending.add(snapshotter.build(
        platform: targetPlatform,
        buildMode: buildMode,
        mainPath: environment.buildDir.childFile('main.app.dill').path,
        packagesPath: environment.projectDir.childFile('.packages').path,
        outputPath: fs.path.join(outputPath, getNameForIOSArch(iosArch)),
        iosArch: iosArch,
        bitcode: bitcode,
      ));
    }
    final List<int> results = await Future.wait(pending);
    if (results.any((int result) => result != 0)) {
      throw Exception('AOT snapshotter exited with code ${results.join()}');
    }
    final ProcessResult result = await processManager.run(<String>[
      'lipo',
      ...iosArchs.map((IOSArch iosArch) =>
          fs.path.join(outputPath, getNameForIOSArch(iosArch), 'App.framework', 'App')),
      '-create',
      '-output',
      fs.path.join(outputPath, 'App.framework', 'App'),
    ]);
    if (result.exitCode != 0) {
      throw Exception('lipo exited with code ${result.exitCode}');
    }
  }
}

/// Generate a snapshot of the dart code used in the program.
const Target kernelSnapshot = Target(
  name: 'kernel_snapshot',
  inputs: <Source>[
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib and in .packages
    Source.artifact(Artifact.platformKernelDill),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.frontendServerSnapshotForEngineDartSdk),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
  ],
  dependencies: <Target>[],
  buildAction: compileKernel,
);

/// Generate an ELF binary from a dart kernel file in profile mode.
const Target aotElfProfile = Target(
  name: 'aot_elf_profile',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    ),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotElf,
);

/// Generate an ELF binary from a dart kernel file in release mode.
const Target aotElfRelease= Target(
  name: 'aot_elf_release',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.release,
    ),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotElf,
);

/// Generate an assembly target from a dart kernel file in profile mode.
const Target aotAssemblyProfile = Target(
  name: 'aot_assembly_profile',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.profile,
    ),
  ],
  outputs: <Source>[
    // TODO(jonahwilliams): are these used or just a side effect?
    // Source.pattern('{BUILD_DIR}/snapshot_assembly.S'),
    // Source.pattern('{BUILD_DIR}/snapshot_assembly.o'),
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotAssembly,
);

/// Generate an assembly target from a dart kernel file in release mode.
const Target aotAssemblyRelease = Target(
  name: 'aot_assembly_release',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/main.app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.release,
    ),
  ],
  outputs: <Source>[
    // TODO(jonahwilliams): are these used or just a side effect?
    // Source.pattern('{BUILD_DIR}/snapshot_assembly.S'),
    // Source.pattern('{BUILD_DIR}/snapshot_assembly.o'),
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotAssembly,
);
