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
import '../../plugins.dart';
import '../../project.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';

/// Copies the app.dill file into a kernel_blob.bin file for iOS projects.
Future<void> copyBlob(Map<String, ChangeType> updates, Environment environment) async {
  final File blob = environment.buildDir.childFile('app.dill');
  final String destination = fs.path.join(environment.projectDir.path,
    'ios',
    'Flutter',
    'App.framework',
    'flutter_assets', 'kernel_blob.bin');
  blob.copySync(destination);
}

/// Copies the prebuilt iOS framework out of the cache.
Future<void> copyFramework(Map<String, ChangeType> updates, Environment environment) async {
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'unpack_ios');
  }
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  // Copy framework.
  final String basePath = artifacts.getArtifactPath(Artifact.flutterFramework,
      platform: TargetPlatform.ios, mode: buildMode);
  final Directory targetDirectory = environment
    .projectDir
    .childDirectory('ios')
    .childDirectory('Flutter')
    .childDirectory('Flutter.framework');
  if (targetDirectory.existsSync()) {
    targetDirectory.deleteSync(recursive: true);
  }
  final ProcessResult copyResult = await processManager
      .run(<String>['cp', '-R', basePath, targetDirectory.path]);
  if (copyResult.exitCode != 0) {
    throw Exception(
      'Failed to copy framework (exit ${copyResult.exitCode}:\n'
      '${copyResult.stdout}\n---\n${copyResult.stderr}',
    );
  }
  // Copy plist file
  final File inputPlist = fs.file(fs.path.join(environment.projectDir.path,
    'ios', 'Flutter', 'AppFrameworkInfo.plist'));
  // Create derived App.framework directory.
  final Directory frameworkDir = fs.directory(
    fs.path.join(environment.projectDir.path, 'ios', 'Flutter', 'App.framework')
  );
  frameworkDir.createSync(recursive: true);
  inputPlist.copySync(fs.path.join(frameworkDir.path, 'Info.plist'));
}

/// Re-generates the flutter plugins file.
Future<void> flutterPluginsAction(Map<String, ChangeType> updates, Environment environment) async {
  final FlutterProject project = FlutterProject.fromDirectory(environment.projectDir);
  refreshPluginsList(project);
}

/// Tell cocoapods to re-fetch dependencies.
Future<void> podInstallAction(Map<String, ChangeType> updates, Environment environment) async {
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'unpack_ios');
  }
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  final FlutterProject project = FlutterProject.fromDirectory(environment.projectDir);
  final String enginePath = artifacts.getArtifactPath(Artifact.flutterIosPodspec,
      mode: buildMode, platform: TargetPlatform.ios);

  await cocoaPods.processPods(
    xcodeProject: project.ios,
    engineDir: enginePath,
    isSwift: project.ios.isSwift,
    dependenciesChanged: true,
  );
}

/// Generate the flutter plugins registrant.
const Target flutterPlugins = Target(
  name: 'flutter_plugins',
  buildAction: flutterPluginsAction,
  inputs: <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml')
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/.flutter-plugins'),
  ]
);

/// Invoke cocoapods to install dependencies
const Target podInstall = Target(
  name: 'pod_install',
  buildAction: podInstallAction,
  inputs: <Source>[
    Source.artifact(Artifact.flutterIosPodspec,
        platform: TargetPlatform.ios, mode: BuildMode.debug),
    Source.pattern('{PROJECT_DIR}/.flutter-plugins'),
    Source.pattern('{PROJECT_DIR}/ios/Podfile'),
    Source.pattern('{PROJECT_DIR}/ios/Runner.xcodeproj/project.pbxproj'),
    Source.pattern('{PROJECT_DIR}/ios/Flutter/Generated.xcconfig'),
  ],
  outputs: <Source>[
    // No outputs because we assume that cocoapods tracks these.
  ],
  dependencies: <Target>[
    unpackIos,
    flutterPlugins,
  ],
);

/// Unpack the iOS debug artifacts.
const Target unpackIos = Target(
  name: 'unpack_ios',
  buildAction: copyFramework,
  inputs: <Source>[
    Source.artifact(Artifact.flutterFramework,
        platform: TargetPlatform.ios, mode: BuildMode.debug)
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/ios/Flutter/Flutter.framework/Flutter'),
    // TODO(jonahwilliams): list more.
  ],
  dependencies: <Target>[]
);

/// Create an iOS debug application.
const Target debugIosApplication = Target(
  name: 'debug_ios_application',
  buildAction: copyBlob,
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/ios/Flutter/App.framework/flutter_assets/kernel_blob.bin'),
  ],
  dependencies: <Target>[
    podInstall,
    copyAssetsFramework,
    kernelSnapshot,
  ]
);

/// Create an iOS profile application.
const Target profileIosApplication = Target(
  name: 'profile_ios_application',
  buildAction: null,
  inputs: <Source>[],
  outputs: <Source>[],
  dependencies: <Target>[
    copyAssetsFramework,
    aotAssemblyProfile,
  ]
);

/// Create an iOS debug application.
const Target releaseIosApplication = Target(
  name: 'release_ios_application',
  buildAction: null,
  inputs: <Source>[],
  outputs: <Source>[],
  dependencies: <Target>[
    copyAssetsFramework,
    aotAssemblyRelease,
  ]
);
