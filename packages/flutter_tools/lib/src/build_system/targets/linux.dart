// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../globals.dart' as globals;
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';
import 'icon_tree_shaker.dart';

/// The only files/subdirectories we care out.
const List<String> _kLinuxArtifacts = <String>[
  'libflutter_linux_glfw.so',
  'flutter_export.h',
  'flutter_messenger.h',
  'flutter_plugin_registrar.h',
  'flutter_glfw.h',
  'icudtl.dat',
  'cpp_client_wrapper_glfw/',
];

/// Copies the Linux desktop embedding files to the copy directory.
class UnpackLinuxDebug extends Target {
  const UnpackLinuxDebug();

  @override
  String get name => 'unpack_linux_debug';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>[
    'linux_engine_sources.d'
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    final String basePath = globals.artifacts.getArtifactPath(Artifact.linuxDesktopPath);
    final List<File> inputs = <File>[];
    final List<File> outputs = <File>[];
    final String outputPrefix = globals.fs.path.join(
      environment.projectDir.path,
      'linux',
      'flutter',
      'ephemeral',
    );
    // The native linux artifacts are composed of 6 files and a directory (listed above)
    // which need to be copied to the target directory.
    for (final String artifact in _kLinuxArtifacts) {
      final String entityPath = globals.fs.path.join(basePath, artifact);
      // If this artifact is a file, just copy the source over.
      if (globals.fs.isFileSync(entityPath)) {
        final String outputPath = globals.fs.path.join(
          outputPrefix,
          globals.fs.path.relative(entityPath, from: basePath),
        );
        final File destinationFile = globals.fs.file(outputPath);
        if (!destinationFile.parent.existsSync()) {
          destinationFile.parent.createSync(recursive: true);
        }
        final File inputFile = globals.fs.file(entityPath);
        inputFile.copySync(destinationFile.path);
        inputs.add(inputFile);
        outputs.add(destinationFile);
        continue;
      }
      // If the artifact is the directory cpp_client_wrapper, recursively
      // copy every file from it.
      for (final File input in globals.fs.directory(entityPath)
          .listSync(recursive: true)
          .whereType<File>()) {
        final String outputPath = globals.fs.path.join(
          outputPrefix,
          globals.fs.path.relative(input.path, from: basePath),
        );
        final File destinationFile = globals.fs.file(outputPath);
        if (!destinationFile.parent.existsSync()) {
          destinationFile.parent.createSync(recursive: true);
        }
        final File inputFile = globals.fs.file(input);
        inputFile.copySync(destinationFile.path);
        inputs.add(inputFile);
        outputs.add(destinationFile);
      }
    }
    final Depfile depfile = Depfile(inputs, outputs);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('linux_engine_sources.d'),
    );
  }
}

/// Creates a debug bundle for the Linux desktop target.
class DebugBundleLinuxAssets extends Target {
  const DebugBundleLinuxAssets();

  @override
  String get name => 'debug_bundle_linux_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
    UnpackLinuxDebug(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/flutter_assets/kernel_blob.bin'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'debug_bundle_linux_assets');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets');
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    // Only copy the kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      environment.buildDir.childFile('app.dill')
        .copySync(outputDirectory.childFile('kernel_blob.bin').path);
    }
    final Depfile depfile = await copyAssets(environment, outputDirectory);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}
