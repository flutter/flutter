// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';
import 'desktop.dart';
import 'icon_tree_shaker.dart';

/// The only files/subdirectories we care out.
const List<String> _kLinuxArtifacts = <String>[
  'libflutter_linux_glfw.so',
  'flutter_export.h',
  'flutter_messenger.h',
  'flutter_plugin_registrar.h',
  'flutter_glfw.h',
  'icudtl.dat',
];

const String _kLinuxDepfile = 'linux_engine_sources.d';

/// Copies the Linux desktop embedding files to the copy directory.
class UnpackLinux extends Target {
  const UnpackLinux();

  @override
  String get name => 'unpack_linux';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[_kLinuxDepfile];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String engineSourcePath = environment.artifacts
      .getArtifactPath(
        Artifact.linuxDesktopPath,
        mode: buildMode,
        platform: TargetPlatform.linux_x64,
      );
    final String clientSourcePath = environment.artifacts
      .getArtifactPath(
        Artifact.linuxCppClientWrapper,
        mode: buildMode,
        platform: TargetPlatform.linux_x64,
      );
    final Directory outputDirectory = environment.fileSystem.directory(
      environment.fileSystem.path.join(
      environment.projectDir.path,
      'linux',
      'flutter',
      'ephemeral',
    ));
    final Depfile depfile = unpackDesktopArtifacts(
      fileSystem: environment.fileSystem,
      engineSourcePath: engineSourcePath,
      outputDirectory: outputDirectory,
      artifacts: _kLinuxArtifacts,
      clientSourcePath: clientSourcePath,
    );
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile(_kLinuxDepfile),
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
    UnpackLinux(),
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
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets');
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    environment.buildDir.childFile('app.dill')
      .copySync(outputDirectory.childFile('kernel_blob.bin').path);

    final Depfile depfile = await copyAssets(environment, outputDirectory);
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}

/// Generate an ELF binary from a dart kernel file in profile mode.
class LinuxAotElfProfile extends AotElfBase {
  const LinuxAotElfProfile();

  @override
  String get name => 'linux_aot_elf_profile';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.linux_x64,
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
class LinuxAotElfRelease extends AotElfBase {
  const LinuxAotElfRelease();

  @override
  String get name => 'linux_aot_elf_release';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.linux_x64,
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

/// Creates a profile bundle for the Linux desktop target.
class ProfileBundleLinuxAssets extends Target {
  const ProfileBundleLinuxAssets();

  @override
  String get name => 'profile_bundle_linux_assets';

  @override
  List<Target> get dependencies => const <Target>[
    LinuxAotElfProfile(),
    UnpackLinux(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/flutter_assets/libapp.so'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'profile_bundle_linux_assets');
    }
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets');
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    environment.buildDir.childFile('app.so')
      .copySync(outputDirectory.childFile('libapp.so').path);

    final Depfile depfile = await copyAssets(environment, outputDirectory);
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}

/// Creates a release bundle for the Linux desktop target.
class ReleaseBundleLinuxAssets extends Target {
  const ReleaseBundleLinuxAssets();

  @override
  String get name => 'release_bundle_linux_assets';

  @override
  List<Target> get dependencies => const <Target>[
    LinuxAotElfRelease(),
    UnpackLinux(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/flutter_assets/libapp.so'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'release_bundle_linux_assets');
    }
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets');
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    environment.buildDir.childFile('app.so')
      .copySync(outputDirectory.childFile('libapp.so').path);

    final Depfile depfile = await copyAssets(environment, outputDirectory);
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}
