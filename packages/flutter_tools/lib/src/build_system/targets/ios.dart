// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process.dart';
import '../../build_info.dart';
import '../../globals.dart' as globals hide fs, logger, processManager, artifacts;
import '../../macos/xcode.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'common.dart';
import 'icon_tree_shaker.dart';

/// Supports compiling a dart kernel file to an assembly file.
///
/// If more than one iOS arch is provided, then this rule will
/// produce a universal binary.
abstract class AotAssemblyBase extends Target {
  const AotAssemblyBase();

  @override
  String get analyticsName => 'ios_aot';

  @override
  Future<void> build(Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(
      reportTimings: false,
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      xcode: globals.xcode,
      artifacts: environment.artifacts,
      processManager: environment.processManager,
    );
    final String buildOutputPath = environment.buildDir.path;
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'aot_assembly');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'aot_assembly');
    }
    final List<String> extraGenSnapshotOptions = decodeDartDefines(environment.defines, kExtraGenSnapshotOptions);
    final bool bitcode = environment.defines[kBitcodeFlag] == 'true';
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    final String splitDebugInfo = environment.defines[kSplitDebugInfo];
    final bool dartObfuscation = environment.defines[kDartObfuscation] == 'true';
    final List<DarwinArch> darwinArchs = environment.defines[kIosArchs]
      ?.split(' ')
      ?.map(getIOSArchForName)
      ?.toList()
      ?? <DarwinArch>[DarwinArch.arm64];
    if (targetPlatform != TargetPlatform.ios) {
      throw Exception('aot_assembly is only supported for iOS applications.');
    }
    if (darwinArchs.contains(DarwinArch.x86_64)) {
      throw Exception(
        'release/profile builds are only supported for physical devices. '
        'attempted to build for $darwinArchs.'
      );
    }
    final String codeSizeDirectory = environment.defines[kCodeSizeDirectory];

    // If we're building multiple iOS archs the binaries need to be lipo'd
    // together.
    final List<Future<int>> pending = <Future<int>>[];
    for (final DarwinArch darwinArch in darwinArchs) {
      final List<String> archExtraGenSnapshotOptions = List<String>.of(extraGenSnapshotOptions);
      if (codeSizeDirectory != null) {
        final File codeSizeFile = environment.fileSystem
          .directory(codeSizeDirectory)
          .childFile('snapshot.${getNameForDarwinArch(darwinArch)}.json');
        final File precompilerTraceFile = environment.fileSystem
          .directory(codeSizeDirectory)
          .childFile('trace.${getNameForDarwinArch(darwinArch)}.json');
        archExtraGenSnapshotOptions.add('--write-v8-snapshot-profile-to=${codeSizeFile.path}');
        archExtraGenSnapshotOptions.add('--trace-precompiler-to=${precompilerTraceFile.path}');
      }
      pending.add(snapshotter.build(
        platform: targetPlatform,
        buildMode: buildMode,
        mainPath: environment.buildDir.childFile('app.dill').path,
        packagesPath: environment.projectDir.childFile('.packages').path,
        outputPath: environment.fileSystem.path.join(buildOutputPath, getNameForDarwinArch(darwinArch)),
        darwinArch: darwinArch,
        bitcode: bitcode,
        quiet: true,
        splitDebugInfo: splitDebugInfo,
        dartObfuscation: dartObfuscation,
        extraGenSnapshotOptions: archExtraGenSnapshotOptions,
      ));
    }
    final List<int> results = await Future.wait(pending);
    if (results.any((int result) => result != 0)) {
      throw Exception('AOT snapshotter exited with code ${results.join()}');
    }
    final String resultPath = environment.fileSystem.path.join(environment.buildDir.path, 'App.framework', 'App');
    environment.fileSystem.directory(resultPath).parent.createSync(recursive: true);
    final ProcessResult result = await environment.processManager.run(<String>[
      'lipo',
      ...darwinArchs.map((DarwinArch iosArch) =>
          environment.fileSystem.path.join(buildOutputPath, getNameForDarwinArch(iosArch), 'App.framework', 'App')),
      '-create',
      '-output',
      resultPath,
    ]);
    if (result.exitCode != 0) {
      throw Exception('lipo exited with code ${result.exitCode}.\n${result.stderr}');
    }
  }
}

/// Generate an assembly target from a dart kernel file in release mode.
class AotAssemblyRelease extends AotAssemblyBase {
  const AotAssemblyRelease();

  @override
  String get name => 'aot_assembly_release';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    // TODO(jonahwilliams): cannot reference gen_snapshot with artifacts since
    // it resolves to a file (ios/gen_snapshot) that never exists. This was
    // split into gen_snapshot_arm64 and gen_snapshot_armv7.
    // Source.artifact(Artifact.genSnapshot,
    //   platform: TargetPlatform.ios,
    //   mode: BuildMode.release,
    // ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}


/// Generate an assembly target from a dart kernel file in profile mode.
class AotAssemblyProfile extends AotAssemblyBase {
  const AotAssemblyProfile();

  @override
  String get name => 'aot_assembly_profile';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    // TODO(jonahwilliams): cannot reference gen_snapshot with artifacts since
    // it resolves to a file (ios/gen_snapshot) that never exists. This was
    // split into gen_snapshot_arm64 and gen_snapshot_armv7.
    // Source.artifact(Artifact.genSnapshot,
    //   platform: TargetPlatform.ios,
    //   mode: BuildMode.profile,
    // ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}

/// Create a trivial App.framework file for debug iOS builds.
class DebugUniveralFramework extends Target {
  const DebugUniveralFramework();

  @override
  String get name => 'debug_universal_framework';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
     Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ];

  @override
  Future<void> build(Environment environment) async {
    // Generate a trivial App.framework.
    final Set<DarwinArch> iosArchs = environment.defines[kIosArchs]
      ?.split(' ')
      ?.map(getIOSArchForName)
      ?.toSet()
      ?? <DarwinArch>{DarwinArch.arm64};
    final File iphoneFile = environment.buildDir.childFile('iphone_framework');
    final File simulatorFile = environment.buildDir.childFile('simulator_framework');
    final File lipoOutputFile = environment.buildDir
      .childDirectory('App.framework')
      .childFile('App');
    lipoOutputFile.parent.createSync(recursive: true);
    final RunResult iphoneResult = await createStubAppFramework(
      iphoneFile,
      SdkType.iPhone,
      // Only include 32bit if it is contained in the active architectures.
      include32Bit: iosArchs.contains(DarwinArch.armv7)
    );
    final RunResult simulatorResult = await createStubAppFramework(
      simulatorFile,
      SdkType.iPhoneSimulator,
    );
    if (iphoneResult.exitCode != 0 || simulatorResult.exitCode != 0) {
      throw Exception('Failed to create App.framework.');
    }
    final List<String> lipoCommand = <String>[
      ...globals.xcode.xcrunCommand(),
      'lipo',
      '-create',
      iphoneFile.path,
      simulatorFile.path,
      '-output',
      lipoOutputFile.path,
    ];

    final RunResult lipoResult = await processUtils.run(
      lipoCommand,
    );

    if (lipoResult.exitCode != 0) {
      throw Exception('Failed to create App.framework.');
    }
  }
}

/// The base class for all iOS bundle targets.
///
/// This is responsible for setting up the basic App.framework structure, including:
/// * Copying the app.dill/kernel_blob.bin from the build directory to assets (debug)
/// * Copying the precompiled isolate/vm data from the engine (debug)
/// * Copying the flutter assets to App.framework/flutter_assets
/// * Copying either the stub or real App assembly file to App.framework/App
abstract class IosAssetBundle extends Target {
  const IosAssetBundle();

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
    Source.pattern('{OUTPUT_DIR}/App.framework/Info.plist')
  ];

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
    final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
    final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
    frameworkDirectory.createSync(recursive: true);
    assetDirectory.createSync();

    // Only copy the prebuilt runtimes and kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      // Copy the App.framework to the output directory.
      environment.buildDir
        .childDirectory('App.framework')
        .childFile('App')
        .copySync(frameworkDirectory.childFile('App').path);

      final String vmSnapshotData = environment.artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug);
      final String isolateSnapshotData = environment.artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug);
      environment.buildDir.childFile('app.dill')
          .copySync(assetDirectory.childFile('kernel_blob.bin').path);
      environment.fileSystem.file(vmSnapshotData)
          .copySync(assetDirectory.childFile('vm_snapshot_data').path);
      environment.fileSystem.file(isolateSnapshotData)
          .copySync(assetDirectory.childFile('isolate_snapshot_data').path);
    } else {
      environment.buildDir.childDirectory('App.framework').childFile('App')
        .copySync(frameworkDirectory.childFile('App').path);
    }

    // Copy the assets.
    final Depfile assetDepfile = await copyAssets(
      environment,
      assetDirectory,
      targetPlatform: TargetPlatform.ios,
    );
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      assetDepfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );


    // Copy the plist from either the project or module.
    // TODO(jonahwilliams): add plist to inputs
    final FlutterProject flutterProject = FlutterProject.fromDirectory(environment.projectDir);
    final Directory plistRoot = flutterProject.isModule
      ? flutterProject.ios.ephemeralDirectory
      : environment.projectDir.childDirectory('ios');
    plistRoot
      .childDirectory('Flutter')
      .childFile('AppFrameworkInfo.plist')
      .copySync(environment.outputDir
      .childDirectory('App.framework')
      .childFile('Info.plist').path);
  }
}

/// Build a debug iOS application bundle.
class DebugIosApplicationBundle extends IosAssetBundle {
  const DebugIosApplicationBundle();

  @override
  String get name => 'debug_ios_bundle_flutter_assets';

  @override
  List<Source> get inputs => <Source>[
    const Source.artifact(Artifact.vmSnapshotData, mode: BuildMode.debug),
    const Source.artifact(Artifact.isolateSnapshotData, mode: BuildMode.debug),
    const Source.pattern('{BUILD_DIR}/app.dill'),
    ...super.inputs,
  ];

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{OUTPUT_DIR}/App.framework/flutter_assets/vm_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/App.framework/flutter_assets/isolate_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/App.framework/flutter_assets/kernel_blob.bin'),
    ...super.outputs,
  ];

  @override
  List<Target> get dependencies => <Target>[
    const DebugUniveralFramework(),
    ...super.dependencies,
  ];
}

/// Build a profile iOS application bundle.
class ProfileIosApplicationBundle extends IosAssetBundle {
  const ProfileIosApplicationBundle();

  @override
  String get name => 'profile_ios_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[
    AotAssemblyProfile(),
  ];
}

/// Build a release iOS application bundle.
class ReleaseIosApplicationBundle extends IosAssetBundle {
  const ReleaseIosApplicationBundle();

  @override
  String get name => 'release_ios_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[
    AotAssemblyRelease(),
  ];
}

/// Create an App.framework for debug iOS targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// constant.
Future<RunResult> createStubAppFramework(File outputFile, SdkType sdk, { bool include32Bit = true }) async {
  try {
    outputFile.createSync(recursive: true);
  } on Exception catch (e) {
    throwToolExit('Failed to create App.framework stub at ${outputFile.path}: $e');
  }

  final Directory tempDir = outputFile.fileSystem.systemTempDirectory
    .createTempSync('flutter_tools_stub_source.');
  try {
    final File stubSource = tempDir.childFile('debug_app.cc')
      ..writeAsStringSync(r'''
  static const int Moo = 88;
  ''');

    List<String> archFlags;
    if (sdk == SdkType.iPhone) {
      archFlags = <String>[
        if (include32Bit)
          ...<String>['-arch', getNameForDarwinArch(DarwinArch.armv7)],
        '-arch',
        getNameForDarwinArch(DarwinArch.arm64),
      ];
    } else {
      archFlags = <String>[
        '-arch',
        getNameForDarwinArch(DarwinArch.x86_64),
      ];
    }

    return await globals.xcode.clang(<String>[
      '-x',
      'c',
      ...archFlags,
      stubSource.path,
      '-dynamiclib',
      '-fembed-bitcode-marker',
      '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
      '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
      '-install_name', '@rpath/App.framework/App',
      '-isysroot', await globals.xcode.sdkLocation(sdk),
      '-o', outputFile.path,
    ]);
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort. Sometimes we can't delete things from system temp.
    } on Exception catch (e) {
      throwToolExit('Failed to create App.framework stub at ${outputFile.path}: $e');
    }
  }
}
