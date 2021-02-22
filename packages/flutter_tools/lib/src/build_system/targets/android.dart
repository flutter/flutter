// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/deferred_component.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../globals.dart' as globals hide fs, artifacts, logger, processManager;
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'common.dart';
import 'icon_tree_shaker.dart';

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
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>[
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
      final String vmSnapshotData = environment.artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = environment.artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(outputDirectory.childFile('kernel_blob.bin').path);
      environment.fileSystem.file(vmSnapshotData)
          .copySync(outputDirectory.childFile('vm_snapshot_data').path);
      environment.fileSystem.file(isolateSnapshotData)
          .copySync(outputDirectory.childFile('isolate_snapshot_data').path);
    }
    final Depfile assetDepfile = await copyAssets(
      environment,
      outputDirectory,
      targetPlatform: TargetPlatform.android,
    );
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      assetDepfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
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
    const Source.pattern('{OUTPUT_DIR}/flutter_assets/vm_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/flutter_assets/isolate_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/flutter_assets/kernel_blob.bin'),
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
    AotElfProfile(TargetPlatform.android_arm),
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
    AotElfRelease(TargetPlatform.android_arm),
    AotAndroidAssetBundle(),
  ];
}

/// Generate an ELF binary from a dart kernel file in release mode.
///
/// This rule implementation outputs the generated so to a unique location
/// based on the Android ABI. This allows concurrent invocations of gen_snapshot
/// to run simultaneously.
///
/// The name of an instance of this rule would be 'android_aot_profile_android-x64'
/// and is relied upon by flutter.gradle to match the correct rule.
///
/// It will produce an 'app.so` in the build directory under a folder named with
/// the matching Android ABI.
class AndroidAot extends AotElfBase {
  /// Create an [AndroidAot] implementation for a given [targetPlatform] and [buildMode].
  const AndroidAot(this.targetPlatform, this.buildMode);

  /// The name of the produced Android ABI.
  String get _androidAbiName {
    return getNameForAndroidArch(
      getAndroidArchForName(getNameForTargetPlatform(targetPlatform)));
  }

  @override
  String get name => 'android_aot_${getNameForBuildMode(buildMode)}_'
    '${getNameForTargetPlatform(targetPlatform)}';

  /// The specific Android ABI we are building for.
  final TargetPlatform targetPlatform;

  /// The selected build mode.
  ///
  /// This is restricted to [BuildMode.profile] or [BuildMode.release].
  final BuildMode buildMode;

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/android.dart'),
    const Source.pattern('{BUILD_DIR}/app.dill'),
    const Source.artifact(Artifact.engineDartBinary),
    const Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      mode: buildMode,
      platform: targetPlatform,
     ),
  ];

  @override
  List<Source> get outputs => <Source>[
    Source.pattern('{BUILD_DIR}/$_androidAbiName/app.so'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  Future<void> build(Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(
      reportTimings: false,
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      xcode: globals.xcode,
      processManager: environment.processManager,
      artifacts: environment.artifacts,
    );
    final Directory output = environment.buildDir.childDirectory(_androidAbiName);
    final String splitDebugInfo = environment.defines[kSplitDebugInfo];
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'aot_elf');
    }
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }
    final List<String> extraGenSnapshotOptions = decodeCommaSeparated(environment.defines, kExtraGenSnapshotOptions);
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final bool dartObfuscation = environment.defines[kDartObfuscation] == 'true';
    final String codeSizeDirectory = environment.defines[kCodeSizeDirectory];

    if (codeSizeDirectory != null) {
      final File codeSizeFile = environment.fileSystem
        .directory(codeSizeDirectory)
        .childFile('snapshot.$_androidAbiName.json');
      final File precompilerTraceFile = environment.fileSystem
        .directory(codeSizeDirectory)
        .childFile('trace.$_androidAbiName.json');
      extraGenSnapshotOptions.add('--write-v8-snapshot-profile-to=${codeSizeFile.path}');
      extraGenSnapshotOptions.add('--trace-precompiler-to=${precompilerTraceFile.path}');
    }

    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      outputPath: output.path,
      bitcode: false,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
      splitDebugInfo: splitDebugInfo,
      dartObfuscation: dartObfuscation,
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  }
}

// AndroidAot instances used by the bundle rules below.
const AndroidAot androidArmProfile = AndroidAot(TargetPlatform.android_arm,  BuildMode.profile);
const AndroidAot androidArm64Profile = AndroidAot(TargetPlatform.android_arm64, BuildMode.profile);
const AndroidAot androidx64Profile = AndroidAot(TargetPlatform.android_x64, BuildMode.profile);
const AndroidAot androidArmRelease = AndroidAot(TargetPlatform.android_arm,  BuildMode.release);
const AndroidAot androidArm64Release = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
const AndroidAot androidx64Release = AndroidAot(TargetPlatform.android_x64, BuildMode.release);

/// A rule paired with [AndroidAot] that copies the produced so files into the output directory.
class AndroidAotBundle extends Target {
  /// Create an [AndroidAotBundle] implementation for a given [targetPlatform] and [buildMode].
  const AndroidAotBundle(this.dependency);

  /// The [AndroidAot] instance this bundle rule depends on.
  final AndroidAot dependency;

  /// The name of the produced Android ABI.
  String get _androidAbiName {
    return getNameForAndroidArch(
      getAndroidArchForName(getNameForTargetPlatform(dependency.targetPlatform)));
  }

  @override
  String get name => 'android_aot_bundle_${getNameForBuildMode(dependency.buildMode)}_'
    '${getNameForTargetPlatform(dependency.targetPlatform)}';

  @override
  List<Source> get inputs => <Source>[
   Source.pattern('{BUILD_DIR}/$_androidAbiName/app.so'),
  ];

  // flutter.gradle has been updated to correctly consume it.
  @override
  List<Source> get outputs => <Source>[
    Source.pattern('{OUTPUT_DIR}/$_androidAbiName/app.so'),
  ];

  @override
  List<Target> get dependencies => <Target>[
    dependency,
    const AotAndroidAssetBundle(),
  ];

  @override
  Future<void> build(Environment environment) async {
    final File outputFile = environment.buildDir
      .childDirectory(_androidAbiName)
      .childFile('app.so');
    final Directory outputDirectory = environment.outputDir
      .childDirectory(_androidAbiName);
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }
    outputFile.copySync(outputDirectory.childFile('app.so').path);
  }
}

// AndroidBundleAot instances.
const Target androidArmProfileBundle = AndroidAotBundle(androidArmProfile);
const Target androidArm64ProfileBundle = AndroidAotBundle(androidArm64Profile);
const Target androidx64ProfileBundle = AndroidAotBundle(androidx64Profile);
const Target androidArmReleaseBundle = AndroidAotBundle(androidArmRelease);
const Target androidArm64ReleaseBundle = AndroidAotBundle(androidArm64Release);
const Target androidx64ReleaseBundle = AndroidAotBundle(androidx64Release);

/// Utility method to copy and rename the required .so shared libs from the build output
/// to the correct component intermediate directory.
///
/// The [DeferredComponent]s passed to this method must have had loading units assigned.
/// Assigned components are components that have determined which loading units contains
/// the dart libraries it has via the DeferredComponent.assignLoadingUnits method.
Depfile copyDeferredComponentSoFiles(
    Environment env,
    List<DeferredComponent> components,
    List<LoadingUnit> loadingUnits,
    Directory buildDir, // generally `<projectDir>/build`
    List<String> abis,
    BuildMode buildMode,) {
  final List<File> inputs = <File>[];
  final List<File> outputs = <File>[];
  final Set<int> usedLoadingUnits = <int>{};
  // Copy all .so files for loading units that are paired with a deferred component.
  for (final String abi in abis) {
    for (final DeferredComponent component in components) {
      if (!component.assigned) {
        globals.printError('Deferred component require loading units to be assigned.');
        return Depfile(inputs, outputs);
      }
      for (final LoadingUnit unit in component.loadingUnits) {
        // ensure the abi for the unit is one of the abis we build for.
        final List<String> splitPath = unit.path.split(env.fileSystem.path.separator);
        if (splitPath[splitPath.length - 2] != abi) {
          continue;
        }
        usedLoadingUnits.add(unit.id);
        // the deferred_libs directory is added as a source set for the component.
        final File destination = buildDir
            .childDirectory(component.name)
            .childDirectory('intermediates')
            .childDirectory('flutter')
            .childDirectory(buildMode.name)
            .childDirectory('deferred_libs')
            .childDirectory(abi)
            .childFile('libapp.so-${unit.id}.part.so');
        if (!destination.existsSync()) {
          destination.createSync(recursive: true);
        }
        final File source = env.fileSystem.file(unit.path);
        source.copySync(destination.path);
        inputs.add(source);
        outputs.add(destination);
      }
    }
  }
  // Copy unused loading units, which are included in the base module.
  for (final String abi in abis) {
    for (final LoadingUnit unit in loadingUnits) {
      if (usedLoadingUnits.contains(unit.id)) {
        continue;
      }
        // ensure the abi for the unit is one of the abis we build for.
      final List<String> splitPath = unit.path.split(env.fileSystem.path.separator);
      if (splitPath[splitPath.length - 2] != abi) {
        continue;
      }
      final File destination = env.outputDir
          .childDirectory(abi)
          // Omit 'lib' prefix here as it is added by the gradle task that adds 'lib' to 'app.so'.
          .childFile('app.so-${unit.id}.part.so');
      if (!destination.existsSync()) {
          destination.createSync(recursive: true);
        }
      final File source = env.fileSystem.file(unit.path);
      source.copySync(destination.path);
      inputs.add(source);
      outputs.add(destination);
    }
  }
  return Depfile(inputs, outputs);
}
