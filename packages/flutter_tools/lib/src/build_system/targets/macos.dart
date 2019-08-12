// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/asset.dart';
import 'package:pool/pool.dart';

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process_manager.dart';
import '../../build_info.dart';
import '../../devfs.dart';
import '../../globals.dart';
import '../../macos/cocoapods.dart';
import '../../project.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';

const String _kOutputPrefix = '{PROJECT_DIR}/macos/Flutter/ephemeral/FlutterMacOS.framework';

/// Copy the macOS framework to the correct copy dir by invoking 'cp -R'.
///
/// The shelling out is done to avoid complications with preserving special
/// files (e.g., symbolic links) in the framework structure.
///
/// Removes any previous version of the framework that already exists in the
/// target directory.
// TODO(jonahwilliams): remove shell out.
class UnpackMacOS extends Target {
  const UnpackMacOS();

  @override
  String get name => 'unpack_macos';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
    Source.artifact(Artifact.flutterMacOSFramework),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('$_kOutputPrefix/FlutterMacOS'),
    // Headers
    Source.pattern('$_kOutputPrefix/Headers/FLEViewController.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterChannels.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterCodecs.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginRegistrarMacOS.h'),
    // Modules
    Source.pattern('$_kOutputPrefix/Modules/module.modulemap'),
    // Resources
    Source.pattern('$_kOutputPrefix/Resources/icudtl.dat'),
    Source.pattern('$_kOutputPrefix/Resources/info.plist'),
    // Ignore Versions folder for now
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final String basePath = artifacts.getArtifactPath(Artifact.flutterMacOSFramework);
    final Directory targetDirectory = environment
      .projectDir
      .childDirectory('macos')
      .childDirectory('Flutter')
      .childDirectory('ephemeral')
      .childDirectory('FlutterMacOS.framework');
    if (targetDirectory.existsSync()) {
      targetDirectory.deleteSync(recursive: true);
    }

    final ProcessResult result = await processManager
        .run(<String>['cp', '-R', basePath, targetDirectory.path]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
  }
}

/// Compile an App.framework for a macOS target device.
class MacOSAotAssembly extends Target {
  const MacOSAotAssembly();

  @override
  String get name => 'macos_aot_assembly';

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
    final String outputPath = fs.path.join(environment.projectDir.path, 'macos', 'Flutter', 'ephemeral');
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'macos_aot_assembly');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'macos_aot_assembly');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    if (targetPlatform != TargetPlatform.darwin_x64) {
      throw Exception('macos_aot_assembly is only supported for iOS application.s');
    }
    if (buildMode == BuildMode.debug) {
      throw Exception('macos_aot_assembly is only supported in profile or release mode.');
    }
    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      iosArch: IOSArch.x86_64,
      bitcode: false,
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  }

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill')
  ];

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/App')
  ];
}

/// Create an App.framework for debug macOS targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// string.
class DebugMacOSFramework extends Target {
  const DebugMacOSFramework();

  @override
  String get name => 'debug_macos_framework';

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final File outputFile = fs.file(fs.path.join(environment.projectDir.path, 'macos', 'Flutter', 'ephemeral', 'App.framework', 'App'));
    outputFile.createSync(recursive: true);
    // TODO(jonahwilliams): rewrite this in dart.
    final ProcessResult processResult = await processManager.run(<String>[
      environment.flutterRootDir
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('bin')
        .childFile('hack_script.sh').path,
    ], runInShell: true);
    if (processResult.exitCode != 0) {
      throw Exception('Failed to compile debug App.framework');
    }
    // Copy assets into asset directory.
    final Directory assetDirectory = outputFile.parent.childDirectory('flutter_assets')
      ..createSync();
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    final int result = await assetBundle.build(
      manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
    );
    if (result != 0) {
      throw Exception('Failed to create asset bundle: $result');
    }
    // Limit number of open files to avoid running out of file descriptors.
    try {
      final Pool pool = Pool(64);
      await Future.wait<void>(
        assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
          final PoolResource resource = await pool.request();
          try {
            final File file = fs.file(fs.path.join(assetDirectory.path, entry.key));
            file.parent.createSync(recursive: true);
            print('writing to ${file.path}');
            await file.writeAsBytes(await entry.value.contentsAsBytes());
          } finally {
            resource.release();
          }
        }));
    } catch (err, st){
      throw Exception('Failed to copy assets: $st');
    }
    // Copy dill file.
    try {
      final File sourceFile = environment.buildDir.childFile('app.dill');
      sourceFile.copySync(assetDirectory.childFile('kernel_blob.bin').path);
    } catch (err, st) {
      throw Exception('Failed to copy app.dill: $st');
    }

    // Copy precompiled runtimes.
    try {
      final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData,
          platform: TargetPlatform.darwin_x64, mode: BuildMode.debug);
      final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData,
          platform: TargetPlatform.darwin_x64, mode: BuildMode.debug);
      fs.file(vmSnapshotData).copySync(
          assetDirectory.childFile('vm_snapshot_data').path);
      fs.file(isolateSnapshotData).copySync(
          assetDirectory.childFile('isolate_snapshot_data').path);
    } catch (err, st) {
      throw Exception('Failed to copy precompiled runtimes: $st');
    }
  }

  @override
  List<Target> get dependencies => const <Target>[
    UnpackMacOS(),
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/App'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/flutter_assets/AssetManifest.json'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/flutter_assets/FontManifest.json'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/flutter_assets/LICENSE'),
  ];
}

/// Build all of the artifacts for a debug macOS application.
class DebugMacOSApplication extends Target {
  const DebugMacOSApplication();

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final File sourceFile = environment.buildDir.childFile('app.dill');
    final File destinationFile = environment.buildDir
        .childDirectory('flutter_assets')
        .childFile('kernel_blob.bin');
    if (!destinationFile.parent.existsSync()) {
      destinationFile.parent.createSync(recursive: true);
    }
    sourceFile.copySync(destinationFile.path);
  }

  @override
  List<Target> get dependencies => const <Target>[
    FlutterPlugins(),
    UnpackMacOS(),
    KernelSnapshot(),
    CopyAssets(),
    // DebugMacOSPodInstall(),
    // DummyMacOSAotAssembly(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill')
  ];

  @override
  String get name => 'debug_macos_application';

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/flutter_assets/kernel_blob.bin'),
  ];
}

class ReleaseMacOSApplication extends Target {
  const ReleaseMacOSApplication();

  @override
  String get name => 'release_macos_application';

  @override
  List<Target> get dependencies => const <Target>[
    FlutterPlugins(),
    UnpackMacOS(),
    MacOSAotAssembly(),
    CopyAssets(),
    // DebugMacOSPodInstall(),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
class ProfileMacOSApplication extends Target {
  const ProfileMacOSApplication();

  @override
  String get name => 'profile_macos_application';

  @override
  List<Target> get dependencies => const <Target>[
    FlutterPlugins(),
    UnpackMacOS(),
    MacOSAotAssembly(),
    CopyAssets(),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
