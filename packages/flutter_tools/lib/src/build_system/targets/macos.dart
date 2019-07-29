// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
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
    Source.pattern('$_kOutputPrefix/Headers/FLEOpenGLContextHandling.h'),
    Source.pattern('$_kOutputPrefix/Headers/FLEReshapeListener.h'),
    Source.pattern('$_kOutputPrefix/Headers/FLEView.h'),
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

// TODO(jonahwilliams): real AOT implementation.
class ReleaseMacOSApplication extends DebugMacOSApplication {
  const ReleaseMacOSApplication();

  @override
  String get name => 'release_macos_application';
}
class ProfileMacOSApplication extends DebugMacOSApplication {
  const ProfileMacOSApplication();

  @override
  String get name => 'profile_macos_application';
}
