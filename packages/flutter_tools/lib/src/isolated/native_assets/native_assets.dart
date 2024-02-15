// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import 'package:logging/logging.dart' as logging;
import 'package:native_assets_builder/native_assets_builder.dart'
    as native_assets_builder show NativeAssetsBuildRunner;
import 'package:native_assets_builder/native_assets_builder.dart'
    hide NativeAssetsBuildRunner;
import 'package:native_assets_cli/native_assets_cli_internal.dart';
import 'package:package_config/package_config_types.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/platform.dart';
import '../../build_info.dart' as build_info;
import '../../cache.dart';
import '../../features.dart';
import '../../globals.dart' as globals;
import '../../resident_runner.dart';
import '../../run_hot.dart';
import 'android/native_assets.dart';
import 'ios/native_assets.dart';
import 'linux/native_assets.dart';
import 'macos/native_assets.dart';
import 'macos/native_assets_host.dart';
import 'windows/native_assets.dart';

/// Programmatic API to be used by Dart launchers to invoke native builds.
///
/// It enables mocking `package:native_assets_builder` package.
/// It also enables mocking native toolchain discovery via [cCompilerConfig].
abstract class NativeAssetsBuildRunner {
  /// Whether the project has a `.dart_tools/package_config.json`.
  ///
  /// If there is no package config, [packagesWithNativeAssets], [build], and
  /// [dryRun] must not be invoked.
  Future<bool> hasPackageConfig();

  /// All packages in the transitive dependencies that have a `build.dart`.
  Future<List<Package>> packagesWithNativeAssets();

  /// Runs all [packagesWithNativeAssets] `build.dart` in dry run.
  Future<DryRunResult> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOS,
    required Uri workingDirectory,
  });

  /// Runs all [packagesWithNativeAssets] `build.dart`.
  Future<BuildResult> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  });

  /// The C compiler config to use for compilation.
  Future<CCompilerConfig> get cCompilerConfig;

  /// The NDK compiler to use to use for compilation for Android.
  Future<CCompilerConfig> get ndkCCompilerConfig;
}

/// Uses `package:native_assets_builder` for its implementation.
class NativeAssetsBuildRunnerImpl implements NativeAssetsBuildRunner {
  NativeAssetsBuildRunnerImpl(
    this.projectUri,
    this.packageConfig,
    this.fileSystem,
    this.logger,
  );

  final Uri projectUri;
  final PackageConfig packageConfig;
  final FileSystem fileSystem;
  final Logger logger;

  late final logging.Logger _logger = logging.Logger('')
    ..onRecord.listen((logging.LogRecord record) {
      final int levelValue = record.level.value;
      final String message = record.message;
      if (levelValue >= logging.Level.SEVERE.value) {
        logger.printError(message);
      } else if (levelValue >= logging.Level.WARNING.value) {
        logger.printWarning(message);
      } else if (levelValue >= logging.Level.INFO.value) {
        logger.printTrace(message);
      } else {
        logger.printTrace(message);
      }
    });

  late final Uri _dartExecutable = fileSystem.directory(Cache.flutterRoot).uri.resolve('bin/dart');

  late final native_assets_builder.NativeAssetsBuildRunner _buildRunner = native_assets_builder.NativeAssetsBuildRunner(
    logger: _logger,
    dartExecutable: _dartExecutable,
  );

  @override
  Future<bool> hasPackageConfig() {
    final File packageConfigJson =
        fileSystem.directory(projectUri.toFilePath()).childDirectory('.dart_tool').childFile('package_config.json');
    return packageConfigJson.exists();
  }

  @override
  Future<List<Package>> packagesWithNativeAssets() async {
    final PackageLayout packageLayout = PackageLayout.fromPackageConfig(
      packageConfig,
      projectUri.resolve('.dart_tool/package_config.json'),
    );
    return packageLayout.packagesWithNativeAssets;
  }

  @override
  Future<DryRunResult> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOS,
    required Uri workingDirectory,
  }) {
    final PackageLayout packageLayout = PackageLayout.fromPackageConfig(
      packageConfig,
      projectUri.resolve('.dart_tool/package_config.json'),
    );
    return _buildRunner.dryRun(
      includeParentEnvironment: includeParentEnvironment,
      linkModePreference: linkModePreference,
      targetOs: targetOS,
      workingDirectory: workingDirectory,
      packageLayout: packageLayout,
    );
  }

  @override
  Future<BuildResult> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  }) {
    final PackageLayout packageLayout = PackageLayout.fromPackageConfig(
      packageConfig,
      projectUri.resolve('.dart_tool/package_config.json'),
    );
    return _buildRunner.build(
      buildMode: buildMode,
      cCompilerConfig: cCompilerConfig,
      includeParentEnvironment: includeParentEnvironment,
      linkModePreference: linkModePreference,
      target: target,
      targetAndroidNdkApi: targetAndroidNdkApi,
      targetIOSSdk: targetIOSSdk,
      workingDirectory: workingDirectory,
      packageLayout: packageLayout,
    );
  }

  @override
  late final Future<CCompilerConfig> cCompilerConfig = () {
    if (globals.platform.isMacOS || globals.platform.isIOS) {
      return cCompilerConfigMacOS();
    }
    if (globals.platform.isLinux) {
      return cCompilerConfigLinux();
    }
    if (globals.platform.isWindows) {
      return cCompilerConfigWindows();
    }
    if (globals.platform.isAndroid) {
      throwToolExit('Should use ndkCCompilerConfig for Android.');
    }
    throwToolExit('Unknown target OS.');
  }();

  @override
  late final Future<CCompilerConfig> ndkCCompilerConfig = () {
    return cCompilerConfigAndroid();
  }();
}

/// Write [assets] to `native_assets.yaml` in [yamlParentDirectory].
Future<Uri> writeNativeAssetsYaml(
  KernelAssets assets,
  Uri yamlParentDirectory,
  FileSystem fileSystem,
) async {
  globals.logger.printTrace('Writing native_assets.yaml.');
  final String nativeAssetsDartContents = assets.toNativeAssetsFile();
  final Directory parentDirectory = fileSystem.directory(yamlParentDirectory);
  if (!await parentDirectory.exists()) {
    await parentDirectory.create(recursive: true);
  }
  final File nativeAssetsFile = parentDirectory.childFile('native_assets.yaml');
  await nativeAssetsFile.writeAsString(nativeAssetsDartContents);
  globals.logger.printTrace('Writing ${nativeAssetsFile.path} done.');
  return nativeAssetsFile.uri;
}

/// Select the native asset build mode for a given Flutter build mode.
BuildMode nativeAssetsBuildMode(build_info.BuildMode buildMode) {
  switch (buildMode) {
    case build_info.BuildMode.debug:
      return BuildMode.debug;
    case build_info.BuildMode.jitRelease:
    case build_info.BuildMode.profile:
    case build_info.BuildMode.release:
      return BuildMode.release;
  }
}

/// Checks whether this project does not yet have a package config file.
///
/// A project has no package config when `pub get` has not yet been run.
///
/// Native asset builds cannot be run without a package config. If there is
/// no package config, leave a logging trace about that.
Future<bool> _hasNoPackageConfig(NativeAssetsBuildRunner buildRunner) async {
  final bool packageConfigExists = await buildRunner.hasPackageConfig();
  if (!packageConfigExists) {
    globals.logger.printTrace('No package config found. Skipping native assets compilation.');
  }
  return !packageConfigExists;
}

Future<bool> nativeBuildRequired(NativeAssetsBuildRunner buildRunner) async {
  if (await _hasNoPackageConfig(buildRunner)) {
    return false;
  }
  final List<Package> packagesWithNativeAssets = await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    globals.logger.printTrace(
      'No packages with native assets. Skipping native assets compilation.',
    );
    return false;
  }

  if (!featureFlags.isNativeAssetsEnabled) {
    final String packageNames = packagesWithNativeAssets.map((Package p) => p.name).join(' ');
    throwToolExit(
      'Package(s) $packageNames require the native assets feature to be enabled. '
      'Enable using `flutter config --enable-native-assets`.',
    );
  }
  return true;
}

/// Ensures that either this project has no native assets, or that native assets
/// are supported on that operating system.
///
/// Exits the tool if the above condition is not satisfied.
Future<void> ensureNoNativeAssetsOrOsIsSupported(
  Uri workingDirectory,
  String os,
  FileSystem fileSystem,
  NativeAssetsBuildRunner buildRunner,
) async {
  if (await _hasNoPackageConfig(buildRunner)) {
    return;
  }
  final List<Package> packagesWithNativeAssets = await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    globals.logger.printTrace(
      'No packages with native assets. Skipping native assets compilation.',
    );
    return;
  }
  final String packageNames = packagesWithNativeAssets.map((Package p) => p.name).join(' ');
  throwToolExit(
    'Package(s) $packageNames require the native assets feature. '
    'This feature has not yet been implemented for `$os`. '
    'For more info see https://github.com/flutter/flutter/issues/129757.',
  );
}

/// Ensure all native assets have a linkmode declared to be dynamic loading.
///
/// In JIT, the link mode must always be dynamic linking.
/// In AOT, the static linking has not yet been implemented in Dart:
/// https://github.com/dart-lang/sdk/issues/49418.
///
/// Therefore, ensure all `build.dart` scripts return only dynamic libraries.
void ensureNoLinkModeStatic(List<Asset> nativeAssets) {
  final Iterable<Asset> staticAssets = nativeAssets.where((Asset e) => e.linkMode == LinkMode.static);
  if (staticAssets.isNotEmpty) {
    final String assetIds = staticAssets.map((Asset a) => a.id).toSet().join(', ');
    throwToolExit(
      'Native asset(s) $assetIds have their link mode set to static, '
      'but this is not yet supported. '
      'For more info see https://github.com/dart-lang/sdk/issues/49418.',
    );
  }
}

/// This should be the same for different archs, debug/release, etc.
/// It should work for all macOS.
Uri nativeAssetsBuildUri(Uri projectUri, OS os) {
  final String buildDir = build_info.getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/$os/');
}

class HotRunnerNativeAssetsBuilderImpl implements HotRunnerNativeAssetsBuilder {
  const HotRunnerNativeAssetsBuilderImpl();

  @override
  Future<Uri?> dryRun({
    required Uri projectUri,
    required FileSystem fileSystem,
    required List<FlutterDevice> flutterDevices,
    required PackageConfig packageConfig,
    required Logger logger,
  }) async {
    final NativeAssetsBuildRunner buildRunner = NativeAssetsBuildRunnerImpl(
      projectUri,
      packageConfig,
      fileSystem,
      globals.logger,
    );
    return dryRunNativeAssets(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
      flutterDevices: flutterDevices,
    );
  }
}

/// Gets the native asset id to dylib mapping to embed in the kernel file.
///
/// Run hot compiles a kernel file that is pushed to the device after hot
/// restart. We need to embed the native assets mapping in order to access
/// native assets after hot restart.
Future<Uri?> dryRunNativeAssets({
  required Uri projectUri,
  required FileSystem fileSystem,
  required NativeAssetsBuildRunner buildRunner,
  required List<FlutterDevice> flutterDevices,
}) async {
  if (flutterDevices.length != 1) {
    return dryRunNativeAssetsMultipleOSes(
      projectUri: projectUri,
      fileSystem: fileSystem,
      targetPlatforms: flutterDevices.map((FlutterDevice d) => d.targetPlatform).nonNulls,
      buildRunner: buildRunner,
    );
  }
  final FlutterDevice flutterDevice = flutterDevices.single;
  final build_info.TargetPlatform targetPlatform = flutterDevice.targetPlatform!;

  final Uri? nativeAssetsYaml;
  switch (targetPlatform) {
    case build_info.TargetPlatform.darwin:
      nativeAssetsYaml = await dryRunNativeAssetsMacOS(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
    case build_info.TargetPlatform.ios:
      nativeAssetsYaml = await dryRunNativeAssetsIOS(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
    case build_info.TargetPlatform.tester:
      if (const LocalPlatform().isMacOS) {
        nativeAssetsYaml = await dryRunNativeAssetsMacOS(
          projectUri: projectUri,
          flutterTester: true,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      } else if (const LocalPlatform().isLinux) {
        nativeAssetsYaml = await dryRunNativeAssetsLinux(
          projectUri: projectUri,
          flutterTester: true,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      } else if (const LocalPlatform().isWindows) {
        nativeAssetsYaml = await dryRunNativeAssetsWindows(
          projectUri: projectUri,
          flutterTester: true,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      } else {
        await nativeBuildRequired(buildRunner);
        nativeAssetsYaml = null;
      }
    case build_info.TargetPlatform.linux_arm64:
    case build_info.TargetPlatform.linux_x64:
      nativeAssetsYaml = await dryRunNativeAssetsLinux(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
    case build_info.TargetPlatform.windows_arm64:
    case build_info.TargetPlatform.windows_x64:
      nativeAssetsYaml = await dryRunNativeAssetsWindows(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
    case build_info.TargetPlatform.android_arm:
    case build_info.TargetPlatform.android_arm64:
    case build_info.TargetPlatform.android_x64:
    case build_info.TargetPlatform.android_x86:
    case build_info.TargetPlatform.android:
      nativeAssetsYaml = await dryRunNativeAssetsAndroid(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
    case build_info.TargetPlatform.fuchsia_arm64:
    case build_info.TargetPlatform.fuchsia_x64:
    case build_info.TargetPlatform.web_javascript:
      await ensureNoNativeAssetsOrOsIsSupported(
        projectUri,
        targetPlatform.toString(),
        fileSystem,
        buildRunner,
      );
      nativeAssetsYaml = null;
  }
  return nativeAssetsYaml;
}

/// Dry run the native builds for multiple OSes.
///
/// Needed for `flutter run -d all`.
Future<Uri?> dryRunNativeAssetsMultipleOSes({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  required FileSystem fileSystem,
  required Iterable<build_info.TargetPlatform> targetPlatforms,
}) async {
  if (await nativeBuildRequired(buildRunner)) {
    return null;
  }

  final Uri buildUri = buildUriMultiple(projectUri);
  final Iterable<KernelAsset> nativeAssetPaths = <KernelAsset>[
    if (targetPlatforms.contains(build_info.TargetPlatform.darwin) ||
        (targetPlatforms.contains(build_info.TargetPlatform.tester) && OS.current == OS.macOS))
      ...await dryRunNativeAssetsMacOSInternal(
        fileSystem,
        projectUri,
        false,
        buildRunner,
      ),
    if (targetPlatforms.contains(build_info.TargetPlatform.linux_arm64) ||
        targetPlatforms.contains(build_info.TargetPlatform.linux_x64) ||
        (targetPlatforms.contains(build_info.TargetPlatform.tester) && OS.current == OS.linux))
      ...await dryRunNativeAssetsLinuxInternal(
        fileSystem,
        projectUri,
        false,
        buildRunner,
      ),
    if (targetPlatforms.contains(build_info.TargetPlatform.windows_arm64) ||
        targetPlatforms.contains(build_info.TargetPlatform.windows_x64) ||
        (targetPlatforms.contains(build_info.TargetPlatform.tester) && OS.current == OS.windows))
      ...await dryRunNativeAssetsWindowsInternal(
        fileSystem,
        projectUri,
        false,
        buildRunner,
      ),
    if (targetPlatforms.contains(build_info.TargetPlatform.ios))
      ...await dryRunNativeAssetsIOSInternal(
        fileSystem,
        projectUri,
        buildRunner,
      ),
    if (targetPlatforms.contains(build_info.TargetPlatform.android) ||
        targetPlatforms.contains(build_info.TargetPlatform.android_arm) ||
        targetPlatforms.contains(build_info.TargetPlatform.android_arm64) ||
        targetPlatforms.contains(build_info.TargetPlatform.android_x64) ||
        targetPlatforms.contains(build_info.TargetPlatform.android_x86))
      ...await dryRunNativeAssetsAndroidInternal(
        fileSystem,
        projectUri,
        buildRunner,
      ),
  ];
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    KernelAssets(nativeAssetPaths),
    buildUri,
    fileSystem,
  );
  return nativeAssetsUri;
}

/// With `flutter run -d all` we need a place to store the native assets
/// mapping for multiple OSes combined.
Uri buildUriMultiple(Uri projectUri) {
  final String buildDir = build_info.getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/multiple/');
}

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file.
Future<Uri?> dryRunNativeAssetsSingleArchitecture({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
  required OS os,
}) async {
  if (!await nativeBuildRequired(buildRunner)) {
    return null;
  }

  final Uri buildUri = nativeAssetsBuildUri(projectUri, os);
  final Iterable<KernelAsset> nativeAssetPaths = await dryRunNativeAssetsSingleArchitectureInternal(
    fileSystem,
    projectUri,
    flutterTester,
    buildRunner,
    os,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    KernelAssets(nativeAssetPaths.toList()),
    buildUri,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<KernelAsset>> dryRunNativeAssetsSingleArchitectureInternal(
  FileSystem fileSystem,
  Uri projectUri,
  bool flutterTester,
  NativeAssetsBuildRunner buildRunner,
  OS targetOS,
) async {
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);

  globals.logger.printTrace('Dry running native assets for $targetOS.');

  final DryRunResult dryRunResult = await buildRunner.dryRun(
    linkModePreference: LinkModePreference.dynamic,
    targetOS: targetOS,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
  );
  ensureNativeAssetsBuildSucceed(dryRunResult);
  final List<Asset> nativeAssets = dryRunResult.assets;
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Dry running native assets for $targetOS done.');
  final Uri? absolutePath = flutterTester ? buildUri : null;
  final Map<Asset, KernelAsset> assetTargetLocations = _assetTargetLocationsSingleArchitecture(
    nativeAssets,
    absolutePath,
  );
  return assetTargetLocations.values;
}

/// Builds native assets.
///
/// If [targetPlatform] is omitted, the current target architecture is used.
///
/// If [flutterTester] is true, absolute paths are emitted in the native
/// assets mapping. This can be used for JIT mode without sandbox on the host.
/// This is used in `flutter test` and `flutter run -d flutter-tester`.
Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)> buildNativeAssetsSingleArchitecture({
  required NativeAssetsBuildRunner buildRunner,
  build_info.TargetPlatform? targetPlatform,
  required Uri projectUri,
  required build_info.BuildMode buildMode,
  bool flutterTester = false,
  Uri? yamlParentDirectory,
  required FileSystem fileSystem,
}) async {
  final Target target = targetPlatform != null ? _getNativeTarget(targetPlatform) : Target.current;
  final OS targetOS = target.os;
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);
  final Directory buildDir = fileSystem.directory(buildUri);
  if (!await buildDir.exists()) {
    // CMake requires the folder to exist to do copying.
    await buildDir.create(recursive: true);
  }
  if (!await nativeBuildRequired(buildRunner)) {
    final Uri nativeAssetsYaml = await writeNativeAssetsYaml(
      KernelAssets(),
      yamlParentDirectory ?? buildUri,
      fileSystem,
    );
    return (nativeAssetsYaml, <Uri>[]);
  }

  final BuildMode buildModeCli = nativeAssetsBuildMode(buildMode);

  globals.logger.printTrace('Building native assets for $target $buildModeCli.');
  final BuildResult result = await buildRunner.build(
    linkModePreference: LinkModePreference.dynamic,
    target: target,
    buildMode: buildModeCli,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
    cCompilerConfig: await buildRunner.cCompilerConfig,
  );
  ensureNativeAssetsBuildSucceed(result);
  final List<Asset> nativeAssets = result.assets;
  final Set<Uri> dependencies = result.dependencies.toSet();
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $target done.');
  final Uri? absolutePath = flutterTester ? buildUri : null;
  final Map<Asset, KernelAsset> assetTargetLocations = _assetTargetLocationsSingleArchitecture(nativeAssets, absolutePath);
  await _copyNativeAssetsSingleArchitecture(
    buildUri,
    assetTargetLocations,
    buildMode,
    fileSystem,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    KernelAssets(assetTargetLocations.values.toList()),
    yamlParentDirectory ?? buildUri,
    fileSystem,
  );
  return (nativeAssetsUri, dependencies.toList());
}

Map<Asset, KernelAsset> _assetTargetLocationsSingleArchitecture(
  List<Asset> nativeAssets,
  Uri? absolutePath,
) {
  return <Asset, KernelAsset>{
    for (final Asset asset in nativeAssets)
      asset: _targetLocationSingleArchitecture(
        asset,
        absolutePath,
      ),
  };
}

KernelAsset _targetLocationSingleArchitecture(Asset asset, Uri? absolutePath) {
  final AssetPath path = asset.path;
  final KernelAssetPath kernelAssetPath;
  switch (path) {
    case AssetSystemPath _:
      kernelAssetPath = KernelAssetSystemPath(path.uri);
    case AssetInExecutable _:
      kernelAssetPath = KernelAssetInExecutable();
    case AssetInProcess _:
      kernelAssetPath = KernelAssetInProcess();
    case AssetAbsolutePath _:
      final String fileName = path.uri.pathSegments.last;
      Uri uri;
      if (absolutePath != null) {
        // Flutter tester needs full host paths.
        uri = absolutePath.resolve(fileName);
      } else {
        // Flutter Desktop needs "absolute" paths inside the app.
        // "relative" in the context of native assets would be relative to the
        // kernel or aot snapshot.
        uri = Uri(path: fileName);
      }
      kernelAssetPath = KernelAssetAbsolutePath(uri);
    default:
      throw Exception(
        'Unsupported asset path type ${path.runtimeType} in asset $asset',
      );
  }
  return KernelAsset(
    id: asset.id,
    target: asset.target,
    path: kernelAssetPath,
  );
}

/// Extract the [Target] from a [TargetPlatform].
///
/// Does not cover MacOS, iOS, and Android as these pass the architecture
/// in other enums.
Target _getNativeTarget(build_info.TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case build_info.TargetPlatform.linux_x64:
      return Target.linuxX64;
    case build_info.TargetPlatform.linux_arm64:
      return Target.linuxArm64;
    case build_info.TargetPlatform.windows_x64:
      return Target.windowsX64;
    case build_info.TargetPlatform.windows_arm64:
      return Target.windowsArm64;
    case build_info.TargetPlatform.android:
    case build_info.TargetPlatform.ios:
    case build_info.TargetPlatform.darwin:
    case build_info.TargetPlatform.fuchsia_arm64:
    case build_info.TargetPlatform.fuchsia_x64:
    case build_info.TargetPlatform.tester:
    case build_info.TargetPlatform.web_javascript:
    case build_info.TargetPlatform.android_arm:
    case build_info.TargetPlatform.android_arm64:
    case build_info.TargetPlatform.android_x64:
    case build_info.TargetPlatform.android_x86:
      throw Exception('Unknown targetPlatform: $targetPlatform.');
  }
}

Future<void> _copyNativeAssetsSingleArchitecture(
  Uri buildUri,
  Map<Asset, KernelAsset> assetTargetLocations,
  build_info.BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
    if (!buildDir.existsSync()) {
      buildDir.createSync(recursive: true);
    }
    for (final MapEntry<Asset, KernelAsset> assetMapping in assetTargetLocations.entries) {
      final Uri source = (assetMapping.key.path as AssetAbsolutePath).uri;
      final Uri target = (assetMapping.value.path as KernelAssetAbsolutePath).uri;
      final Uri targetUri = buildUri.resolveUri(target);
      final String targetFullPath = targetUri.toFilePath();
      await fileSystem.file(source).copy(targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

void ensureNativeAssetsBuildSucceed(DryRunResult result) {
  if (!result.success) {
    throwToolExit(
      'Building native assets failed. See the logs for more details.',
    );
  }
}
