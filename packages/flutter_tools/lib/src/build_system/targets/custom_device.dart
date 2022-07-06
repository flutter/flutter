// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../devfs.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'common.dart';
import 'icon_tree_shaker.dart';

/// Creates a bundle for the custom device target.
abstract class BundleCustomDeviceAssets extends Target {
  const BundleCustomDeviceAssets(this.targetPlatform);

  factory BundleCustomDeviceAssets.forBuildMode(BuildMode mode, TargetPlatform targetPlatform) {
    switch (mode) {
      case BuildMode.debug:
        return DebugCustomDeviceAssets(targetPlatform);
      case BuildMode.profile:
       return ProfileCustomDeviceAssets(targetPlatform);
      default:
      throw FallThroughError();
    }
  }

  final TargetPlatform targetPlatform;

  @override
  List<Target> get dependencies => <Target>[
    const KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/custom_device.dart'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'bundle_custom_device_assets');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]!);
    final Directory outputDirectory = environment.outputDir;
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    // Only copy the kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      environment.buildDir.childFile('app.dill')
        .copySync(outputDirectory.childFile('kernel_blob.bin').path);
    }

    final String flutterEngineLibraryPath = environment.artifacts.getArtifactPath(Artifact.flutterEngineLibrary);

    environment.fileSystem.file(flutterEngineLibraryPath)
      .copySync(outputDirectory.childFile(environment.fileSystem.path.basename(flutterEngineLibraryPath)).path);

    final String versionInfo = FlutterProject.current().getVersionInfo();
    final Depfile depfile = await copyAssets(
      environment,
      outputDirectory,
      targetPlatform: targetPlatform,
      additionalContent: <String, DevFSContent>{
        'version.json': DevFSStringContent(versionInfo),
      }
    );
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

/// A wrapper for AOT compilation that copies app.so into the output directory.
class CustomDeviceAotBundle extends Target {
  /// Create a [CustomDeviceAotBundle] wrapper for [aotTarget].
  const CustomDeviceAotBundle(this.aotTarget);

  /// The [AotElfBase] subclass that produces the app.so.
  final AotElfBase aotTarget;

  @override
  String get name => 'custom_device_aot_bundle';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.so'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/app.so'),
  ];

  @override
  List<Target> get dependencies => <Target>[

    aotTarget,
  ];

  @override
  Future<void> build(Environment environment) async {
    final File outputFile = environment.buildDir.childFile('app.so');
    outputFile.copySync(environment.outputDir.childFile('app.so').path);
  }
}

class DebugCustomDeviceAssets extends BundleCustomDeviceAssets {
  const DebugCustomDeviceAssets(TargetPlatform targetPlatform) : super(targetPlatform);

  @override
  String get name => 'debug_bundle_${getNameForTargetPlatform(targetPlatform)}_assets';

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{BUILD_DIR}/app.dill'),
  ];

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{OUTPUT_DIR}/flutter_assets/kernel_blob.bin'),
  ];
}

class ProfileCustomDeviceAssets extends BundleCustomDeviceAssets {
  const ProfileCustomDeviceAssets(TargetPlatform targetPlatform) : super(targetPlatform);

  @override
  String get name => 'profile_bundle_${getNameForTargetPlatform(targetPlatform)}_assets';

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<Target> get dependencies => <Target>[
    ...super.dependencies,
    CustomDeviceAotBundle(AotElfProfile(targetPlatform)),
  ];
}

class ReleaseCustomDevicesAssets extends BundleCustomDeviceAssets {
  const ReleaseCustomDevicesAssets(TargetPlatform targetPlatform) : super(targetPlatform);

  @override
  String get name => 'release_bundle_${getNameForTargetPlatform(targetPlatform)}_assets';

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<Target> get dependencies => <Target>[
    ...super.dependencies,
    CustomDeviceAotBundle(AotElfRelease(targetPlatform)),
  ];
}
