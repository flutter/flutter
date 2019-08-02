// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process_manager.dart';
import '../../build_info.dart';
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

/// Create an App.framework for debug targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// string.
class DummyMacOSAotAssembly extends Target {
  const DummyMacOSAotAssembly();

  @override
  String get name => 'dummy_macos_aot_assembly';

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final String outputPath = fs.path.join(environment.projectDir.path, 'macos', 'Flutter', 'ephemeral');
    final String outputFile = fs.path.join(outputPath, 'App.framework', 'App');
    fs.file(outputFile).createSync(recursive: true);
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
  }

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/App')
  ];
}

/// Tell cocoapods to re-fetch dependencies.
class DebugMacOSPodInstall extends Target {
  const DebugMacOSPodInstall();

  @override
  String get name => 'debug_macos_pod_install';

  @override
  List<Source> get inputs => const <Source>[
    Source.artifact(Artifact.flutterMacOSPodspec,
      platform: TargetPlatform.darwin_x64,
      mode: BuildMode.debug
    ),
    Source.pattern('{PROJECT_DIR}/macos/Podfile', optional: true),
    Source.pattern('{PROJECT_DIR}/macos/Runner.xcodeproj/project.pbxproj'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/ephemeral/Flutter-Generated.xcconfig'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    // TODO(jonahwilliams): introduce configuration/planning phase to build.
    // No outputs because Cocoapods is fully responsible for tracking. plus there
    // is no concept of an optional output. Instead we will need a build config
    // phase to conditionally add this rule so that it can be written properly.
  ];

  @override
  List<Target> get dependencies => const <Target>[
    UnpackMacOS(),
    FlutterPlugins(),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'debug_macos_pod_install');
    }
    // If there is no podfile do not perform any pods actions.
    if (!environment.projectDir.childDirectory('macos')
        .childFile('Podfile').existsSync()) {
      return;
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final FlutterProject project = FlutterProject.fromDirectory(environment.projectDir);
    final String enginePath = artifacts.getArtifactPath(Artifact.flutterMacOSPodspec,
        mode: buildMode, platform: TargetPlatform.darwin_x64);

    await cocoaPods.processPods(
      xcodeProject: project.macos,
      engineDir: enginePath,
      isSwift: true,
      dependenciesChanged: true,
    );
  }
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
    DebugMacOSPodInstall(),
    DummyMacOSAotAssembly(),
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
    DebugMacOSPodInstall(),
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
    DebugMacOSPodInstall(),
  ];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
