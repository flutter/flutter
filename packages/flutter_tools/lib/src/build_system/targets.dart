// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../asset.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../compile.dart';
import '../devfs.dart';
import '../project.dart';

import 'build_system.dart';

/// Build definitions.

/// List all asset files in a project by parsing the asset manfiest.
List<File> listAssets(Environment environment) {
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  assetBundle.build(
    manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  final List<File> results = <File>[];
  final Iterable<DevFSFileContent> files = assetBundle.entries.values.whereType<DevFSFileContent>();
  for (DevFSFileContent devFsContent in files) {
    results.add(fs.file(devFsContent.file.path));
  }
  return results;
}

/// List all output files in a project by parsing the asset manfiest and
/// replacing the path with the output directory.
List<File> listOutputAssets(Environment environment) {
  final List<File> inputs = listAssets(environment);
  final List<File> results = <File>[];
  for (File input in inputs) {
    final String assetName = fs.path.join(
      environment.buildDir.path,
      'flutter_assets',
      fs.path.basename(input.path),
    );
    results.add(fs.file(assetName));
  }
  return results;
}

/// Assemble the assets used in the application into a build directory.
const Target copyAssets = Target(
  name: 'copy_assets',
  inputs: <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.function(listAssets),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/flutter_assets/AssetManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/FontManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/LICENSE'),
    Source.function(listOutputAssets), // <- everything in this subdirectory.
  ],
  dependencies: <Target>[],
  invocation: copyAssetsInvocation,
);

/// Copies the asset files from the [copyAssets] rule into place.
Future<void> copyAssetsInvocation(List<FileSystemEntity> inputs, Environment environment) async {
  final Directory output = environment.buildDir.childDirectory('flutter_assets');
  if (!output.existsSync()) {
    output.createSync(recursive: true);
  }
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  await Future.wait<void>(
    assetBundle.entries.entries.map((MapEntry<String, DevFSContent> entry) async {
      final File file = fs.file(fs.path.join(output.path, entry.key));
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(await entry.value.contentsAsBytes());
  }));
}

/// Supports compiling dart source to kernel with a subset of flags.
Future<void> compileKernel(List<FileSystemEntity> inputs, Environment environment) async {
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

/// Supports compiling dart source to kernel with track widget creation.
Future<void> compileKernelTrack(List<FileSystemEntity> inputs, Environment environment) async {
  final KernelCompiler compiler = await kernelCompilerFactory.create(
    FlutterProject.fromDirectory(environment.projectDir),
  );
  await compiler.compile(
    aot: false,
    trackWidgetCreation: true,
    targetModel: environment.targetPlatform == TargetPlatform.fuchsia
        ? TargetModel.flutterRunner
        : TargetModel.flutterRunner,
    targetProductVm: environment.buildMode == BuildMode.release,
    outputFilePath: environment
      .buildDir
      .childDirectory(getNameForBuildMode(environment.buildMode))
      .childFile('main.app.track.dill')
      .path,
    depFilePath: null, // Use timestamp based analysis instead.
  );
}


/// Generate a snapshot of the dart code used in the program.
const Target kernelSnapshot = Target(
  name: 'kernel_snapshot',
  inputs: <Source>[
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/{mode}/main.app.dill'),
  ],
  dependencies: <Target>[],
  invocation: compileKernel,
);

/// Generate a snapshot of the dart code used in this program with the
/// track widget creation flag applied.
const Target kernelSnapshotTrack = Target(
  name: 'kernel_snapshot_track',
  inputs: <Source>[
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/{mode}/main.app.track.dill'),
  ],
  dependencies: <Target>[],
  invocation: compileKernelTrack,
  modes: <BuildMode>[
    BuildMode.debug,
  ]
);

/// Desktop embedder specific rules

/// List all input files under `cpp_client_wrapper`.
List<File> listClientWrapperInput(Environment environment) {
  return environment
    .cacheDir
    .childDirectory(getNameForTargetPlatform(environment.targetPlatform))
    .childDirectory('cpp_client_wrapper')
    .listSync(recursive: true)
    .whereType<File>()
    .toList();
}

/// List all expected output files under `cpp_client_wrapper`.
List<File> listClientWrapperOutput(Environment environment) {
  return environment
    .copyDir
    .childDirectory('cpp_client_wrapper')
    .listSync(recursive: true)
    .whereType<File>()
    .toList();
}

/// Copies all of the input files to the correct copy dir.
Future<void> copyDesktopAssets(List<FileSystemEntity> inputs, Environment environment) async {
  for (File input in inputs) {
    // Sort of a hack until I figure out the best way to structure this.
    String outputPath;
    if (input.path.contains('cpp_client_wrapper')) {
      final Iterable<String> parts = fs.path
        .split(input.path)
        .skipWhile((String segment) => segment != 'cpp_client_wrapper');
      outputPath = fs.path.joinAll(<String>[
        environment.copyDir.path,
        ...parts,
      ]);
    } else {
      outputPath = fs.path.join(environment.copyDir.path, input.basename);
    }
    final File destinationFile = fs.file(outputPath);
    if (!destinationFile.parent.existsSync()) {
      destinationFile.parent.createSync(recursive: true);
    }
    input.copySync(destinationFile.path);
  }
}

/// Copy the macOS framework to the correct copy dir by invoking 'cp -R'.
///
/// The shelling out is done to avoid complications with preserving special
/// files (e.g., symbolic links) in the framework structure.
///
/// Removes any previous version of the framework that already exists in the
/// target directory.
Future<void> copyFramework(List<FileSystemEntity> input, Environment environment) async {
    // Ensure that the path is a framework, to minimize the potential for
    // catastrophic deletion bugs with bad arguments.
    if (fs.path.extension(input.single.path) != '.framework') {
      throw Exception('Attempted to delete a non-framework directory: $input.single.path');
    }
    final Directory targetDirectory = environment
      .copyDir
      .childDirectory('FlutterMacOS.framework');
    if (targetDirectory.existsSync()) {
      targetDirectory.deleteSync(recursive: true);
    }

    final ProcessResult result = processManager
        .runSync(<String>['cp', '-R', input.single.path, targetDirectory.path]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
}

/// Copies the Linux desktop embedder files to the copy directory.
const Target unpackLinux = Target(
  name: 'unpack_linux',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/libflutter_linux.so'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.function(listClientWrapperInput),
  ],
  outputs: <Source>[
    Source.pattern('{COPY_DIR}/libflutter_linux.so'),
    Source.pattern('{COPY_DIR}/flutter_export.h'),
    Source.pattern('{COPY_DIR}/flutter_messenger.h'),
    Source.pattern('{COPY_DIR}/flutter_plugin_registrar.h'),
    Source.pattern('{COPY_DIR}/flutter_glfw.h'),
    Source.pattern('{COPY_DIR}/icudtl.dat'),
    Source.function(listClientWrapperOutput),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.linux_x64,
  ],
  invocation: copyDesktopAssets,
);

/// Copies the macOS desktop framework to the copy directory.
const Target unpackMacos = Target(
  name: 'unpack_macos',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/FlutterMacOS.framework/'),
  ],
  outputs: <Source>[
    Source.pattern('{COPY_DIR}/FlutterMacOS.framework/'),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.darwin_x64,
  ],
  invocation: copyFramework,
);

/// Copies the Windows desktop embedder files to the copy directory.
const Target unpackWindows = Target(
  name: 'unpack_windows',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.exp'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.lib'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.pdb'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.function(listClientWrapperInput),
  ],
  outputs: <Source>[
    Source.pattern('{COPY_DIR}/flutter_windows.dll'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.exp'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.lib'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.pdb'),
    Source.pattern('{COPY_DIR}/flutter_export.h'),
    Source.pattern('{COPY_DIR}/flutter_messenger.h'),
    Source.pattern('{COPY_DIR}/flutter_plugin_registrar.h'),
    Source.pattern('{COPY_DIR}/flutter_glfw.h'),
    Source.pattern('{COPY_DIR}/icudtl.dat'),
    Source.function(listClientWrapperOutput),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.windows_x64,
  ],
  invocation: copyDesktopAssets,
);

/// All currently implemented build targets.
///
/// Includes:
///   * [copyAssets]
///   * [kernelSnapshot]
///   * [kernelSnapshotTrack]
///   * [unpackWindows]
///   * [unpackLinux]
///   * [unpackMacos]
const List<Target> allTargets = <Target>[
  copyAssets,
  kernelSnapshot,
  kernelSnapshotTrack,
  unpackWindows,
  unpackLinux,
  unpackMacos,
];