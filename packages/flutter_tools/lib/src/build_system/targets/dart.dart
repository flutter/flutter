// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../dart/package_map.dart';
import '../../project.dart';
import '../build_system.dart';

/// Supports compiling dart source to kernel with a subset of flags.
///
/// This is a non-incremental compile so the specific [updates] are ignored.
Future<void> compileKernel(Map<String, ChangeType> updates, Environment environment) async {
  final KernelCompiler compiler = await kernelCompilerFactory.create(
    FlutterProject.fromDirectory(environment.projectDir),
  );
  await compiler.compile(
    aot: environment.buildMode != BuildMode.debug,
    trackWidgetCreation: false,
    targetModel: environment.targetPlatform == TargetPlatform.fuchsia
        ? TargetModel.flutterRunner
        : TargetModel.flutterRunner,
    targetProductVm: environment.buildMode == BuildMode.release,
    outputFilePath: environment
      .buildDir
      .childDirectory(getNameForBuildMode(environment.buildMode))
      .childFile('main.app.dill')
      .path,
    depFilePath: null, // Use timestamp based analysis instead.
  );
}

/// Finds the locations of all dart files within the project.
///
/// This does not attempt to determine if a file is used or imported, so it
/// may otherwise report more files than strictly necessary.
List<FileSystemEntity> listDartSources(Environment environment) {
  final Map<String, Uri> packageMap = PackageMap(PackageMap.globalPackagesPath).map;
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
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/{mode}/main.app.dill'),
  ],
  dependencies: <Target>[],
  invocation: compileKernel,
);
