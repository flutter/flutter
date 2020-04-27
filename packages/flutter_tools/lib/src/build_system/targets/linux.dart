// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../build_system.dart';
import '../depfile.dart';
import 'common.dart';
import 'desktop.dart';

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

class DebugBundleLinuxAssets extends ApplicationAssetBundle {
  const DebugBundleLinuxAssets();

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.artifact(Artifact.vmSnapshotData, mode: BuildMode.debug),
    const Source.artifact(Artifact.isolateSnapshotData, mode: BuildMode.debug),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...super.outputs,
    const Source.pattern('{OUTPUT_DIR}/vm_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/isolate_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/kernel_blob.bin'),
  ];

  @override
  String get name => 'debug_bundle_linux_assets';

  @override
  List<Target> get dependencies => <Target>[
    ...super.dependencies,
    const UnpackLinux(),
  ];
}

class ProfileBundleLinuxAssets extends ApplicationAssetBundle
  with ReleaseAssetBundle {

  const ProfileBundleLinuxAssets();

  @override
  String get name => 'profile_bundle_linux_assets';

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...super.outputs,
    const Source.pattern('{OUTPUT_DIR}/app.so')
  ];

  @override
  List<Target> get dependencies => <Target>[
    ...super.dependencies,
    const AotElfProfile(),
    const UnpackLinux(),
  ];
}

class ReleaseBundleLinuxAssets extends ApplicationAssetBundle
  with ReleaseAssetBundle {

  const ReleaseBundleLinuxAssets();

  @override
  String get name => 'release_bundle_linux_assets';

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...super.outputs,
    const Source.pattern('{OUTPUT_DIR}/app.so')
  ];

  @override
  List<Target> get dependencies => <Target>[
    ...super.dependencies,
    const AotElfRelease(),
    const UnpackLinux(),
  ];
}
