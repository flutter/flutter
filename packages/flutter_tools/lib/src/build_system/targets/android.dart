// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../globals.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';

/// Prepares the asset bundle in the format expected by flutter.gradle.
///
/// The vm_snapshot_data, isolate_snapshot_data, and kernel_blob.bin are
/// expected to be in the root output directory.
///
/// All assets and manifests are included from flutter_assets/**.
abstract class AndroidAssetBundle extends Target {
  const AndroidAssetBundle();

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets')
      ..createSync(recursive: true);

    // Only copy the prebuilt runtimes and kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(outputDirectory.childFile('kernel_blob.bin').path);
      fs.file(vmSnapshotData)
          .copySync(outputDirectory.childFile('vm_snapshot_data').path);
      fs.file(isolateSnapshotData)
          .copySync(outputDirectory.childFile('isolate_snapshot_data').path);
    }
    final Depfile assetDepfile = await copyAssets(environment, outputDirectory);
    assetDepfile.writeToFile(environment.buildDir.childFile('flutter_assets.d'));
  }

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}

/// An implementation of [AndroidAssetBundle] that includes dependencies on vm
/// and isolate data.
class DebugAndroidApplication extends AndroidAssetBundle {
  const DebugAndroidApplication();

  @override
  String get name => 'debug_android_application';

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
}

/// An implementation of [AndroidAssetBundle] that only includes assets.
class AotAndroidAssetBundle extends AndroidAssetBundle {
  const AotAndroidAssetBundle();

  @override
  String get name => 'aot_android_asset_bundle';
}

/// Build a profile android application's Dart artifacts.
class ProfileAndroidApplication extends CopyFlutterAotBundle {
  const ProfileAndroidApplication();

  @override
  String get name => 'profile_android_application';

  @override
  List<Target> get dependencies => const <Target>[
    AotElfProfile(),
    AotAndroidAssetBundle(),
  ];
}

/// Build a release android application's Dart artifacts.
class ReleaseAndroidApplication extends CopyFlutterAotBundle {
  const ReleaseAndroidApplication();

  @override
  String get name => 'release_android_application';

  @override
  List<Target> get dependencies => const <Target>[
    AotElfRelease(),
    AotAndroidAssetBundle(),
  ];
}
