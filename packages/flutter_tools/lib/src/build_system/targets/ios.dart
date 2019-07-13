// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pool/pool.dart';

import '../../artifacts.dart';
import '../../asset.dart';
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

/// Supports compiling a dart kernel file to an assembly file.
///
/// If more than one iOS arch is provided, then this rule will
/// produce a univeral binary.
Future<void> compileAotAssembly(Map<String, ChangeType> updates, Environment environment) async {
  final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
  final String outputPath = environment.buildDir.path;
  if (environment.defines[kBuildMode] == null) {
    throw MissingDefineException(kBuildMode, 'aot_assembly');
  }
  if (environment.defines[kTargetPlatform] == null) {
    throw MissingDefineException(kTargetPlatform, 'aot_assembly');
  }
  final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
  final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
  final List<IOSArch> iosArchs = environment.defines[kIosArchs]?.split(',')?.map(getIOSArchForName)?.toList()
      ?? <IOSArch>[IOSArch.arm64];
  if (targetPlatform != TargetPlatform.ios) {
    throw Exception('aot_assembly is only supported for iOS applications');
  }

  // If we're building for a single architecture (common), then skip the lipo.
  if (iosArchs.length == 1) {
    final int snapshotExitCode = await snapshotter.build(
      platform: targetPlatform,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
      outputPath: outputPath,
      iosArch: iosArchs.single,
    );
    if (snapshotExitCode != 0) {
      throw Exception('AOT snapshotter exited with code $snapshotExitCode');
    }
  } else {
    // If we're building multiple iOS archs the binaries need to be lipo'd
    // together.
    final List<Future<int>> pending = <Future<int>>[];
    for (IOSArch iosArch in iosArchs) {
      pending.add(snapshotter.build(
        platform: targetPlatform,
        buildMode: buildMode,
        mainPath: environment.buildDir.childFile('app.dill').path,
        packagesPath: environment.projectDir.childFile('.packages').path,
        outputPath: fs.path.join(outputPath, getNameForIOSArch(iosArch)),
        iosArch: iosArch,
      ));
    }
    final List<int> results = await Future.wait(pending);
    if (results.any((int result) => result != 0)) {
      throw Exception('AOT snapshotter exited with code ${results.join()}');
    }
    final ProcessResult result = await processManager.run(<String>[
      'lipo',
      ...iosArchs.map((IOSArch iosArch) =>
          fs.path.join(outputPath, getNameForIOSArch(iosArch), 'App.framework', 'App')),
      '-create',
      '-output',
      fs.path.join(outputPath, 'App.framework', 'App'),
    ]);
    if (result.exitCode != 0) {
      throw Exception('lipo exited with code ${result.exitCode}');
    }
  }
}

// Copies the prebuilt iOS framework out of the cache.
Future<void> copyFrameworkIos(Map<String, ChangeType> updates, Environment environment) async {
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

/// Copies the asset files into the iOS framework.
Future<void> copyAssetsFrameworkInvocation(Map<String, ChangeType> updates, Environment environment) async {
  final Directory output = environment
    .projectDir
    .childDirectory('ios')
    .childDirectory('Flutter')
    .childDirectory('App.framework')
    .childDirectory('flutter_assets');
  if (output.existsSync()) {
    output.deleteSync(recursive: true);
  }
  output.createSync(recursive: true);
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  // Limit number of open files to avoid running out of file descriptors.
  final Pool pool = Pool(64);
  await Future.wait<void>(
    assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        final File file = fs.file(fs.path.join(output.path, entry.key));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      } finally {
        resource.release();
      }
    }));
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

/// Invoke cocoapods to install dependencies
const Target podInstallDebug = Target(
  name: 'pod_install_debug',
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
    unpackIosDebug,
    flutterPlugins,
  ],
);

/// Invoke cocoapods to install dependencies
const Target podInstallProfile = Target(
  name: 'pod_install_profile',
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
    unpackIosDebug,
    flutterPlugins,
  ],
);

/// Invoke cocoapods to install dependencies
const Target podInstallRelease = Target(
  name: 'pod_install_release',
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
    unpackIosDebug,
    flutterPlugins,
  ],
);

/// Unpack the iOS debug artifacts.
const Target unpackIosDebug = Target(
  name: 'unpack_ios_debug',
  buildAction: copyFrameworkIos,
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

/// Unpack the iOS profile artifacts.
const Target unpackIosProfile = Target(
  name: 'unpack_ios_profile',
  buildAction: copyFrameworkIos,
  inputs: <Source>[
    Source.artifact(Artifact.flutterFramework,
        platform: TargetPlatform.ios, mode: BuildMode.profile)
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/ios/Flutter/Flutter.framework/Flutter'),
    // TODO(jonahwilliams): list more.
  ],
  dependencies: <Target>[]
);

/// Unpack the iOS release artifacts.
const Target unpackIosRelease = Target(
  name: 'unpack_ios_release',
  buildAction: copyFrameworkIos,
  inputs: <Source>[
    Source.artifact(Artifact.flutterFramework,
        platform: TargetPlatform.ios, mode: BuildMode.release)
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/ios/Flutter/Flutter.framework/Flutter'),
    // TODO(jonahwilliams): list more.
  ],
  dependencies: <Target>[]
);

 // Copy the assets used in the application into a Framework
const Target copyAssetsFramework = Target(
  name: 'copy_assets_framework',
  inputs: <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.behavior(AssetBehavior()),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/ios/Flutter/App.framework/flutter_assets/AssetManifest.json'),
    Source.pattern('{PROJECT_DIR}/ios/Flutter/App.framework/flutter_assets/FontManifest.json'),
    Source.pattern('{PROJECT_DIR}/ios/Flutter/App.framework/flutter_assets/LICENSE'),
    //Source.behavior(AssetBehavior()), // <- everything in this subdirectory.
  ],
  dependencies: <Target>[],
  buildAction: copyAssetsFrameworkInvocation,
);

/// Generate an assembly target from a dart kernel file in profile mode.
const Target aotAssemblyProfile = Target(
  name: 'aot_assembly_profile',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.profile,
    ),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotAssembly,
);

/// Generate an assembly target from a dart kernel file in release mode.
const Target aotAssemblyRelease = Target(
  name: 'aot_assembly_release',
  inputs: <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.release,
    ),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ],
  dependencies: <Target>[
    kernelSnapshot,
  ],
  buildAction: compileAotAssembly,
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
    podInstallDebug,
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
    podInstallProfile,
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
    podInstallRelease,
    copyAssetsFramework,
    aotAssemblyRelease,
  ]
);
