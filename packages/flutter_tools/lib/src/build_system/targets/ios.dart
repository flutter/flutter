// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart' show Logger;
import '../../base/process.dart';
import '../../base/version.dart';
import '../../build_info.dart';
import '../../darwin/darwin.dart';
import '../../devfs.dart';
import '../../globals.dart' as globals;
import '../../ios/mac.dart';
import '../../isolated/native_assets/dart_hook_result.dart';
import '../../macos/xcode.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import '../tools/shader_compiler.dart';
import 'assets.dart';
import 'common.dart';
import 'darwin.dart';
import 'icon_tree_shaker.dart';
import 'native_assets.dart';

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
    final snapshotter = AOTSnapshotter(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
      xcode: globals.xcode!,
      artifacts: environment.artifacts,
      processManager: environment.processManager,
    );
    final String buildOutputPath = environment.buildDir.path;
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, 'aot_assembly');
    }
    final String? environmentTargetPlatform = environment.defines[kTargetPlatform];
    if (environmentTargetPlatform == null) {
      throw MissingDefineException(kTargetPlatform, 'aot_assembly');
    }
    final String? sdkRoot = environment.defines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, 'aot_assembly');
    }

    final List<String> extraGenSnapshotOptions = decodeCommaSeparated(
      environment.defines,
      kExtraGenSnapshotOptions,
    );
    final buildMode = BuildMode.fromCliName(environmentBuildMode);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environmentTargetPlatform);
    final String? splitDebugInfo = environment.defines[kSplitDebugInfo];
    final dartObfuscation = environment.defines[kDartObfuscation] == 'true';
    final List<DarwinArch> darwinArchs =
        environment.defines[kIosArchs]?.split(' ').map(getIOSArchForName).toList() ??
        <DarwinArch>[DarwinArch.arm64];
    if (targetPlatform != TargetPlatform.ios) {
      throw Exception('aot_assembly is only supported for iOS applications.');
    }

    final EnvironmentType? environmentType = environmentTypeFromSdkroot(
      sdkRoot,
      environment.fileSystem,
    );
    if (environmentType == EnvironmentType.simulator) {
      throw Exception(
        'release/profile builds are only supported for physical devices. '
        'attempted to build for simulator.',
      );
    }
    final String? codeSizeDirectory = environment.defines[kCodeSizeDirectory];

    // If we're building multiple iOS archs the binaries need to be lipo'd
    // together.
    final pending = <Future<int>>[];
    for (final darwinArch in darwinArchs) {
      final archExtraGenSnapshotOptions = List<String>.of(extraGenSnapshotOptions);
      if (codeSizeDirectory != null) {
        final File codeSizeFile = environment.fileSystem
            .directory(codeSizeDirectory)
            .childFile('snapshot.${darwinArch.name}.json');
        final File precompilerTraceFile = environment.fileSystem
            .directory(codeSizeDirectory)
            .childFile('trace.${darwinArch.name}.json');
        archExtraGenSnapshotOptions.add('--write-v8-snapshot-profile-to=${codeSizeFile.path}');
        archExtraGenSnapshotOptions.add('--trace-precompiler-to=${precompilerTraceFile.path}');
      }
      pending.add(
        snapshotter.build(
          platform: targetPlatform,
          buildMode: buildMode,
          mainPath: environment.buildDir.childFile('app.dill').path,
          outputPath: environment.fileSystem.path.join(buildOutputPath, darwinArch.name),
          darwinArch: darwinArch,
          sdkRoot: sdkRoot,
          quiet: true,
          splitDebugInfo: splitDebugInfo,
          dartObfuscation: dartObfuscation,
          extraGenSnapshotOptions: archExtraGenSnapshotOptions,
        ),
      );
    }
    final List<int> results = await Future.wait(pending);
    if (results.any((int result) => result != 0)) {
      throw Exception('AOT snapshotter exited with code ${results.join()}');
    }

    // Combine the app lib into a fat framework.
    await Lipo.create(
      environment,
      darwinArchs,
      relativePath: 'App.framework/App',
      inputDir: buildOutputPath,
    );

    // And combine the dSYM for each architecture too, if it was created.
    await Lipo.create(
      environment,
      darwinArchs,
      relativePath: 'App.framework.dSYM/Contents/Resources/DWARF/App',
      inputDir: buildOutputPath,
      // Don't fail if the dSYM wasn't created (i.e. during a debug build).
      skipMissingInputs: true,
    );
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
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    // TODO(zanderso): cannot reference gen_snapshot with artifacts since
    // it resolves to a file (ios/gen_snapshot) that never exists. This was
    // split into gen_snapshot_arm64 and gen_snapshot_armv7.
    // Source.artifact(Artifact.genSnapshot,
    //   platform: TargetPlatform.ios,
    //   mode: BuildMode.release,
    // ),
  ];

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{OUTPUT_DIR}/App.framework/App')];

  @override
  List<Target> get dependencies => const <Target>[ReleaseUnpackIOS(), KernelSnapshot()];
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
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    // TODO(zanderso): cannot reference gen_snapshot with artifacts since
    // it resolves to a file (ios/gen_snapshot) that never exists. This was
    // split into gen_snapshot_arm64 and gen_snapshot_armv7.
    // Source.artifact(Artifact.genSnapshot,
    //   platform: TargetPlatform.ios,
    //   mode: BuildMode.profile,
    // ),
  ];

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{OUTPUT_DIR}/App.framework/App')];

  @override
  List<Target> get dependencies => const <Target>[ProfileUnpackIOS(), KernelSnapshot()];
}

/// Create a trivial App.framework file for debug iOS builds.
class DebugUniversalFramework extends Target {
  const DebugUniversalFramework();

  @override
  String get name => 'debug_universal_framework';

  @override
  List<Target> get dependencies => const <Target>[DebugUnpackIOS(), KernelSnapshot()];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{BUILD_DIR}/App.framework/App')];

  @override
  Future<void> build(Environment environment) async {
    final String? sdkRoot = environment.defines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, name);
    }

    // Generate a trivial App.framework.
    final Set<String>? iosArchNames = environment.defines[kIosArchs]?.split(' ').toSet();
    final File output = environment.buildDir.childDirectory('App.framework').childFile('App');
    environment.buildDir.createSync(recursive: true);
    await _createStubAppFramework(output, environment, iosArchNames, sdkRoot);
  }
}

/// Copy the iOS framework to the correct copy dir by invoking 'rsync'.
///
/// This class is abstract to share logic between the three concrete
/// implementations. The shelling out is done to avoid complications with
/// preserving special files (e.g., symbolic links) in the framework structure.
abstract class UnpackIOS extends UnpackDarwin {
  const UnpackIOS();

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart',
    ),
    Source.artifact(Artifact.flutterXcframework, platform: TargetPlatform.ios, mode: buildMode),
  ];

  @override
  List<Source> get outputs => const <Source>[kFlutterIOSFrameworkBinarySource];

  @override
  List<Target> get dependencies => <Target>[];

  @visibleForOverriding
  BuildMode get buildMode;

  @override
  Future<void> build(Environment environment) async {
    final String? sdkRoot = environment.defines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, name);
    }
    final String? archs = environment.defines[kIosArchs];
    if (archs == null) {
      throw MissingDefineException(kIosArchs, name);
    }

    // Copy Flutter framework.
    final EnvironmentType? environmentType = environmentTypeFromSdkroot(
      sdkRoot,
      environment.fileSystem,
    );
    await copyFramework(
      environment,
      environmentType: environmentType,
      framework: Artifact.flutterFramework,
      targetPlatform: TargetPlatform.ios,
      buildMode: buildMode,
    );
    await _copyFrameworkDysm(environment, sdkRoot: sdkRoot, environmentType: environmentType);

    final File frameworkBinary = environment.outputDir
        .childDirectory(FlutterDarwinPlatform.ios.frameworkName)
        .childFile(FlutterDarwinPlatform.ios.binaryName);
    final String frameworkBinaryPath = frameworkBinary.path;
    if (!await frameworkBinary.exists()) {
      throw Exception('Binary $frameworkBinaryPath does not exist, cannot thin');
    }
    await thinFramework(environment, frameworkBinaryPath, archs);
    await _signFramework(environment, frameworkBinary, buildMode);
  }

  Future<void> _copyFrameworkDysm(
    Environment environment, {
    required String sdkRoot,
    EnvironmentType? environmentType,
  }) async {
    // Copy Flutter framework dSYM (debug symbol) bundle, if present.
    final Directory frameworkDsym = environment.fileSystem.directory(
      environment.artifacts.getArtifactPath(
        Artifact.flutterFrameworkDsym,
        platform: TargetPlatform.ios,
        mode: buildMode,
        environmentType: environmentType,
      ),
    );
    if (frameworkDsym.existsSync()) {
      final ProcessResult result = await environment.processManager.run(<String>[
        'rsync',
        '-av',
        '--delete',
        '--filter',
        '- .DS_Store/',
        '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
        frameworkDsym.path,
        environment.outputDir.path,
      ]);
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to copy framework dSYM (exit ${result.exitCode}:\n'
          '${result.stdout}\n---\n${result.stderr}',
        );
      }
    }
  }
}

/// Unpack the release prebuilt engine framework.
class ReleaseUnpackIOS extends UnpackIOS {
  const ReleaseUnpackIOS();

  @override
  String get name => 'release_unpack_ios';

  @override
  BuildMode get buildMode => BuildMode.release;
}

/// Unpack the profile prebuilt engine framework.
class ProfileUnpackIOS extends UnpackIOS {
  const ProfileUnpackIOS();

  @override
  String get name => 'profile_unpack_ios';

  @override
  BuildMode get buildMode => BuildMode.profile;
}

/// Unpack the debug prebuilt engine framework.
class DebugUnpackIOS extends UnpackIOS {
  const DebugUnpackIOS();

  @override
  String get name => 'debug_unpack_ios';

  @override
  BuildMode get buildMode => BuildMode.debug;
}

// TODO(gaaclarke): Remove this after a reasonable amount of time where the
// UISceneDelegate migration being on stable. This incurs a minor build time
// cost.
Future<void> _checkForLaunchRootViewControllerAccessDeprecation(
  Logger logger,
  File file,
  Pattern usage,
  Pattern terminator,
) async {
  final List<String> lines = file.readAsLinesSync();

  var inDidFinishLaunchingWithOptions = false;
  var lineNumber = 0;
  for (final line in lines) {
    lineNumber += 1;
    if (!inDidFinishLaunchingWithOptions) {
      if (line.contains('didFinishLaunchingWithOptions')) {
        inDidFinishLaunchingWithOptions = true;
      }
    } else {
      if (line.startsWith(terminator)) {
        inDidFinishLaunchingWithOptions = false;
      } else if (line.contains(usage)) {
        _printWarning(
          logger,
          file.path,
          lineNumber,
          // TODO(gaaclarke): Add a link to the migration guide when it's written.
          'Flutter deprecation: Accessing rootViewController in `application:didFinishLaunchingWithOptions:` [flutter-launch-rootvc].\n'
          '\tnote: \n' // The space after `note:` is meaningful, it is required associate the note with the warning in Xcode.
          '\tAfter the UISceneDelegate migration the `UIApplicationDelegate.window` and '
          '`UIWindow.rootViewController` properties will not be set in '
          '`application:didFinishLaunchingWithOptions:`. If you are relying on that '
          'in order to register platform channels at application launch use the '
          '`FlutterPluginRegistry` API instead. Other setup can be moved to a '
          'FlutterViewController subclass (ex: `awakeFromNib`).',
        );
      }
    }
  }
}

/// Checks [file] representing objc code for deprecated usage of the
/// rootViewController and writes it to [logger].
@visibleForTesting
Future<void> checkForLaunchRootViewControllerAccessDeprecationObjc(Logger logger, File file) async {
  try {
    await _checkForLaunchRootViewControllerAccessDeprecation(
      logger,
      file,
      RegExp('self.*?window.*?rootViewController'),
      RegExp('^}'),
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {}
}

/// Checks [file] representing swift code for deprecated usage of the
/// rootViewController and writes it to [logger].
@visibleForTesting
Future<void> checkForLaunchRootViewControllerAccessDeprecationSwift(
  Logger logger,
  File file,
) async {
  try {
    await _checkForLaunchRootViewControllerAccessDeprecation(
      logger,
      file,
      'window?.rootViewController',
      RegExp(r'^.*?func\s*?\S*?\('),
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {}
}

void _printWarning(Logger logger, String path, int line, String warning) {
  logger.printWarning('$path:$line: warning: $warning');
}

class _IssueLaunchRootViewControllerAccess extends Target {
  const _IssueLaunchRootViewControllerAccess();

  @override
  Future<void> build(Environment environment) async {
    final FlutterProject flutterProject = FlutterProject.fromDirectory(environment.projectDir);
    if (flutterProject.ios.appDelegateSwift.existsSync()) {
      await checkForLaunchRootViewControllerAccessDeprecationSwift(
        environment.logger,
        flutterProject.ios.appDelegateSwift,
      );
    }
    if (flutterProject.ios.appDelegateObjcImplementation.existsSync()) {
      await checkForLaunchRootViewControllerAccessDeprecationObjc(
        environment.logger,
        flutterProject.ios.appDelegateObjcImplementation,
      );
    }
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs {
    return <Source>[
      const Source.pattern(
        '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart',
      ),
      Source.fromProject(
        (FlutterProject project) => project.ios.appDelegateObjcImplementation,
        optional: true,
      ),
      Source.fromProject((FlutterProject project) => project.ios.appDelegateSwift, optional: true),
    ];
  }

  @override
  String get name => 'IssueLaunchRootViewControllerAccess';

  @override
  List<Source> get outputs => <Source>[];
}

/// This target verifies that the Xcode project has an LLDB Init File set within
/// at least one scheme.
///
/// LLDB Init File is needed for debugging on physical iOS 26+ devices.
class DebugIosLLDBInit extends Target {
  const DebugIosLLDBInit();

  @override
  String get name => 'debug_ios_lldb_init';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/darwin.dart',
    ),
  ];

  @override
  List<Source> get outputs => <Source>[
    Source.fromProject((FlutterProject project) => project.ios.lldbInitFile),
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    final String? sdkRoot = environment.defines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, name);
    }
    final EnvironmentType? environmentType = environmentTypeFromSdkroot(
      sdkRoot,
      environment.fileSystem,
    );

    // LLDB Init File is only required for physical devices in debug mode.
    if (environmentType != EnvironmentType.physical) {
      return;
    }

    final String? targetDeviceVersionString = environment.defines[kTargetDeviceOSVersion];
    if (targetDeviceVersionString == null) {
      // Skip if TARGET_DEVICE_OS_VERSION is not found. TARGET_DEVICE_OS_VERSION
      // is not set if "build ios-framework" is called, which builds the
      // DebugIosApplicationBundle directly rather than through flutter assemble.
      // If may also be null if the build is targeting multiple architectures.
      return;
    }

    final Version? targetDeviceVersion = Version.parse(targetDeviceVersionString);
    if (targetDeviceVersion == null) {
      environment.logger.printError(
        'Failed to parse TARGET_DEVICE_OS_VERSION: $targetDeviceVersionString',
      );
      return;
    }

    // LLDB Init File is only needed for iOS 26+.
    if (targetDeviceVersion < Version(26, 0, null)) {
      return;
    }

    final String? srcRoot = environment.defines[kSrcRoot];
    if (srcRoot == null) {
      environment.logger.printError('Failed to find $srcRoot');
      return;
    }

    final Directory xcodeProjectDir = environment.fileSystem.directory(srcRoot);
    if (!xcodeProjectDir.existsSync()) {
      environment.logger.printError('Failed to find ${xcodeProjectDir.path}');
      return;
    }

    // The scheme name is not available in Xcode Build Phases Run Scripts.
    // Instead, find all xcscheme files in the Xcode project (this may be the
    // Flutter Xcode project or an Add to App native Xcode project) and check
    // if any of them contain "customLLDBInitFile". If none have it set, print
    // a warning.
    // Also, this cannot check for a specific path/name for the LLDB Init File
    // since Flutter's LLDB Init file may be imported from within a user's
    // custom LLDB Init File.
    final FlutterProject flutterProject = FlutterProject.fromDirectory(environment.projectDir);
    if (flutterProject.isModule) {
      var anyLLDBInitFound = false;
      await for (final FileSystemEntity entity in xcodeProjectDir.list(recursive: true)) {
        if (environment.fileSystem.path.extension(entity.path) == '.xcscheme' && entity is File) {
          if (entity.readAsStringSync().contains('customLLDBInitFile')) {
            anyLLDBInitFound = true;
            break;
          }
        }
      }
      if (!anyLLDBInitFound) {
        printXcodeWarning(
          'Debugging Flutter on new iOS versions requires an LLDB Init File. To '
          'ensure debug mode works, please complete instructions found in '
          '"Embed a Flutter module in your iOS app > Use CocoaPods > Set LLDB Init File" '
          'section of https://docs.flutter.dev/to/ios-add-to-app-embed-setup.',
        );
      }
    }
    return;
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
    InstallCodeAssets(),
    _IssueLaunchRootViewControllerAccess(),
    DartBuildForNative(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...IconTreeShaker.inputs,
    ...ShaderCompiler.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
    Source.pattern('{OUTPUT_DIR}/App.framework/Info.plist'),
  ];

  @override
  List<String> get depfiles => <String>['flutter_assets.d'];

  @override
  Future<void> build(Environment environment) async {
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final buildMode = BuildMode.fromCliName(environmentBuildMode);
    final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
    final File frameworkBinary = frameworkDirectory.childFile('App');
    final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
    frameworkDirectory.createSync(recursive: true);
    assetDirectory.createSync();

    // Only copy the prebuilt runtimes and kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      // Copy the App.framework to the output directory.
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .copySync(frameworkBinary.path);

      final String vmSnapshotData = environment.artifacts.getArtifactPath(
        Artifact.vmSnapshotData,
        mode: BuildMode.debug,
      );
      final String isolateSnapshotData = environment.artifacts.getArtifactPath(
        Artifact.isolateSnapshotData,
        mode: BuildMode.debug,
      );
      environment.buildDir
          .childFile('app.dill')
          .copySync(assetDirectory.childFile('kernel_blob.bin').path);
      environment.fileSystem
          .file(vmSnapshotData)
          .copySync(assetDirectory.childFile('vm_snapshot_data').path);
      environment.fileSystem
          .file(isolateSnapshotData)
          .copySync(assetDirectory.childFile('isolate_snapshot_data').path);
    } else {
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .copySync(frameworkBinary.path);
    }

    // Copy the dSYM
    if (environment.buildDir.childDirectory('App.framework.dSYM').existsSync()) {
      final File dsymOutputBinary = environment.outputDir
          .childDirectory('App.framework.dSYM')
          .childDirectory('Contents')
          .childDirectory('Resources')
          .childDirectory('DWARF')
          .childFile('App');
      dsymOutputBinary.parent.createSync(recursive: true);
      environment.buildDir
          .childDirectory('App.framework.dSYM')
          .childDirectory('Contents')
          .childDirectory('Resources')
          .childDirectory('DWARF')
          .childFile('App')
          .copySync(dsymOutputBinary.path);
    }

    final FlutterProject flutterProject = FlutterProject.fromDirectory(environment.projectDir);
    final String? flavor = await flutterProject.ios.parseFlavorFromConfiguration(environment);

    // Copy the assets.
    final DartHooksResult dartHookResult = await DartBuild.loadHookResult(environment);
    final Depfile assetDepfile = await copyAssets(
      environment,
      assetDirectory,
      dartHookResult: dartHookResult,
      targetPlatform: TargetPlatform.ios,
      buildMode: buildMode,
      additionalInputs: <File>[
        flutterProject.ios.infoPlist,
        flutterProject.ios.appFrameworkInfoPlist,
      ],
      additionalContent: <String, DevFSContent>{
        'NativeAssetsManifest.json': DevFSFileContent(
          environment.buildDir.childFile('native_assets.json'),
        ),
      },
      flavor: flavor,
    );
    environment.depFileService.writeToFile(
      assetDepfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );

    // Copy the plist from either the project or module.
    final File appFrameworkInfoPlist = environment.outputDir
        .childDirectory('App.framework')
        .childFile('Info.plist');
    flutterProject.ios.appFrameworkInfoPlist.copySync(appFrameworkInfoPlist.path);

    await _updateMinimumOSVersion(appFrameworkInfoPlist, environment);

    await _signFramework(environment, frameworkBinary, buildMode);
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
    const DebugUniversalFramework(),
    const DebugIosLLDBInit(),
    ...super.dependencies,
  ];
}

/// IosAssetBundle with debug symbols, used for Profile and Release builds.
abstract class _IosAssetBundleWithDSYM extends IosAssetBundle {
  const _IosAssetBundleWithDSYM();

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.pattern('{BUILD_DIR}/App.framework.dSYM/Contents/Resources/DWARF/App'),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...super.outputs,
    const Source.pattern('{OUTPUT_DIR}/App.framework.dSYM/Contents/Resources/DWARF/App'),
  ];
}

/// Build a profile iOS application bundle.
class ProfileIosApplicationBundle extends _IosAssetBundleWithDSYM {
  const ProfileIosApplicationBundle();

  @override
  String get name => 'profile_ios_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[AotAssemblyProfile(), InstallCodeAssets()];
}

/// Build a release iOS application bundle.
class ReleaseIosApplicationBundle extends _IosAssetBundleWithDSYM {
  const ReleaseIosApplicationBundle();

  @override
  String get name => 'release_ios_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[AotAssemblyRelease(), InstallCodeAssets()];

  @override
  Future<void> build(Environment environment) async {
    var buildSuccess = true;
    try {
      await super.build(environment);
    } catch (_) {
      buildSuccess = false;
      rethrow;
    } finally {
      // Send a usage event when the app is being archived.
      // Since assemble is run during a `flutter build`/`run` as well as an out-of-band
      // archive command from Xcode, this is a more accurate count than `flutter build ipa` alone.
      if (environment.defines[kXcodeAction]?.toLowerCase() == 'install') {
        environment.logger.printTrace('Sending archive event if usage enabled.');
        environment.analytics.send(
          Event.appleUsageEvent(
            workflow: 'assemble',
            parameter: 'ios-archive',
            result: buildSuccess ? 'success' : 'fail',
          ),
        );
      }
    }
  }
}

/// Update the MinimumOSVersion key in the given Info.plist file.
Future<void> _updateMinimumOSVersion(File infoPlist, Environment environment) async {
  final minimumOSVersion = FlutterDarwinPlatform.ios.deploymentTarget().toString();
  final plutilArgs = <String>[
    'plutil',
    '-replace',
    'MinimumOSVersion',
    '-string',
    minimumOSVersion,
    infoPlist.path,
  ];
  final ProcessResult result = await environment.processManager.run(plutilArgs);
  if (result.exitCode != 0) {
    printXcodeWarning(
      'Failed to update MinimumOSVersion in ${infoPlist.path}. This may cause AppStore validation failures. Please file an issue at https://github.com/flutter/flutter/issues/new/choose',
    );
  }
}

/// Create an App.framework for debug iOS targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// constant.
Future<void> _createStubAppFramework(
  File outputFile,
  Environment environment,
  Set<String>? iosArchNames,
  String sdkRoot,
) async {
  try {
    outputFile.createSync(recursive: true);
  } on Exception catch (e) {
    throwToolExit('Failed to create App.framework stub at ${outputFile.path}: $e');
  }

  final FileSystem fileSystem = environment.fileSystem;
  final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
    'flutter_tools_stub_source.',
  );
  try {
    final File stubSource = tempDir.childFile('debug_app.cc')
      ..writeAsStringSync(r'''
  static const int Moo = 88;
  ''');

    final EnvironmentType? environmentType = environmentTypeFromSdkroot(sdkRoot, fileSystem);

    await globals.xcode!.clang(<String>[
      '-x',
      'c',
      for (final String arch in iosArchNames ?? <String>{}) ...<String>['-arch', arch],
      stubSource.path,
      '-dynamiclib',
      // Keep version in sync with AOTSnapshotter flag
      if (environmentType == EnvironmentType.physical)
        '-miphoneos-version-min=${FlutterDarwinPlatform.ios.deploymentTarget()}'
      else
        '-miphonesimulator-version-min=${FlutterDarwinPlatform.ios.deploymentTarget()}',
      '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
      '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
      '-fapplication-extension',
      '-install_name', '@rpath/App.framework/App',
      '-isysroot', sdkRoot,
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

  await _signFramework(environment, outputFile, BuildMode.debug);
}

Future<void> _signFramework(Environment environment, File binary, BuildMode buildMode) async {
  await removeFinderExtendedAttributes(
    binary,
    ProcessUtils(processManager: environment.processManager, logger: environment.logger),
    environment.logger,
  );

  String? codesignIdentity = environment.defines[kCodesignIdentity];
  if (codesignIdentity == null || codesignIdentity.isEmpty) {
    codesignIdentity = '-';
  }
  final ProcessResult result = environment.processManager.runSync(<String>[
    'codesign',
    '--force',
    '--sign',
    codesignIdentity,
    if (buildMode != BuildMode.release) ...<String>[
      // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
      '--timestamp=none',
    ],
    binary.path,
  ]);
  if (result.exitCode != 0) {
    final String stdout = (result.stdout as String).trim();
    final String stderr = (result.stderr as String).trim();
    final output = StringBuffer();
    output.writeln('Failed to codesign ${binary.path} with identity $codesignIdentity.');
    if (stdout.isNotEmpty) {
      output.writeln(stdout);
    }
    if (stderr.isNotEmpty) {
      output.writeln(stderr);
    }
    throw Exception(output.toString());
  }
}
