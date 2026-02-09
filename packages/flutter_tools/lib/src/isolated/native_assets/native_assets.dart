// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:hooks_runner/hooks_runner.dart';
import 'package:logging/logging.dart' as logging;
import 'package:package_config/package_config_types.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../build_system/exceptions.dart';
import '../../cache.dart';
import '../../convert.dart';
import '../../features.dart';
import '../../globals.dart' as globals;
import 'android/native_assets.dart';
import 'dart_hook_result.dart';
import 'ios/native_assets.dart';
import 'macos/native_assets.dart';
import 'targets.dart';

/// A [CodeAsset] for a specific [target].
///
/// Flutter builds [CodeAsset]s for multiple architectures (on MacOS and iOS).
/// This class distinguishes the (otherwise identical) [codeAsset]s on different
/// [target]s. These are then later combined into a single [KernelAsset] before
/// being added to the native assets manifest.
class FlutterCodeAsset {
  FlutterCodeAsset({required this.codeAsset, required this.target});

  final CodeAsset codeAsset;
  final Target target;
}

/// Matching [CodeAsset] and [DataAsset] in native assets - but Flutter could
/// support more asset types in the future.
enum SupportedAssetTypes { codeAssets, dataAssets }

/// Invokes the build of all transitive Dart package hooks and prepares assets
/// to be included in the native build.
Future<DartHooksResult> runFlutterSpecificHooks({
  required Map<String, String> environmentDefines,
  required FlutterNativeAssetsBuildRunner buildRunner,
  required TargetPlatform targetPlatform,
  required Uri projectUri,
  required FileSystem fileSystem,
}) async {
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetPlatform.osName);
  final Directory buildDir = fileSystem.directory(buildUri);
  if (!await buildDir.exists()) {
    // Ensure the folder exists so the native build system can copy it even
    // if there's no native assets.
    await buildDir.create(recursive: true);
  }

  if (!await _hookRunRequired(buildRunner)) {
    return DartHooksResult.empty();
  }

  final supportedAssetTypes = <SupportedAssetTypes>[
    if (featureFlags.isNativeAssetsEnabled) SupportedAssetTypes.codeAssets,
    if (featureFlags.isDartDataAssetsEnabled) SupportedAssetTypes.dataAssets,
  ];
  final List<AssetBuildTarget> targets = AssetBuildTarget.targetsFor(
    targetPlatform: targetPlatform,
    environmentDefines: environmentDefines,
    fileSystem: fileSystem,
    supportedAssetTypes: supportedAssetTypes,
  );

  // This is ugly, but sadly necessary as fetching the cCompilerConfig is async,
  // while using it in native_assets_builder is not.
  for (final CodeAssetTarget target in targets.whereType<CodeAssetTarget>()) {
    await buildRunner.setCCompilerConfig(target);
  }

  final BuildMode buildMode = _getBuildMode(
    environmentDefines,
    targetPlatform == TargetPlatform.tester,
  );
  final bool linkingEnabled = _nativeAssetsLinkingEnabled(buildMode);

  return _runDartHooks(
    buildRunner: buildRunner,
    projectUri: projectUri,
    linkingEnabled: linkingEnabled,
    targets: targets,
  );
}

Future<void> installCodeAssets({
  required DartHooksResult dartHookResult,
  required Map<String, String> environmentDefines,
  required TargetPlatform targetPlatform,
  required Uri projectUri,
  required FileSystem fileSystem,
  required Uri nativeAssetsFileUri,
}) async {
  final OS targetOS = getNativeOSFromTargetPlatform(targetPlatform);
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS.name);
  final flutterTester = targetPlatform == TargetPlatform.tester;
  final BuildMode buildMode = _getBuildMode(environmentDefines, flutterTester);

  final String? codesignIdentity = environmentDefines[kCodesignIdentity];
  final Map<FlutterCodeAsset, KernelAsset> assetTargetLocations = assetTargetLocationsForOS(
    targetOS,
    dartHookResult.codeAssets,
    flutterTester,
    buildUri,
  );
  await _copyNativeCodeAssetsForOS(
    targetOS,
    buildUri,
    buildMode,
    fileSystem,
    assetTargetLocations,
    codesignIdentity,
    flutterTester,
  );
  await _writeNativeAssetsJson(
    assetTargetLocations.values.toList(),
    nativeAssetsFileUri,
    fileSystem,
  );
}

/// Programmatic API to be used by Dart launchers to invoke native builds.
///
/// It enables mocking `package:hooks_runner` package.
/// It also enables mocking native toolchain discovery via [setCCompilerConfig].
abstract interface class FlutterNativeAssetsBuildRunner {
  /// All packages in the transitive dependencies that have a `build.dart`.
  Future<List<String>> packagesWithNativeAssets();

  /// Runs all [packagesWithNativeAssets] `build.dart`.
  Future<BuildResult?> build({
    required List<ProtocolExtension> extensions,
    required bool linkingEnabled,
  });

  /// Runs all [packagesWithNativeAssets] `link.dart`.
  Future<LinkResult?> link({
    required List<ProtocolExtension> extensions,
    required BuildResult buildResult,
  });

  Future<void> setCCompilerConfig(CodeAssetTarget target);
}

/// Uses `package:hooks_runner` for its implementation.
class FlutterNativeAssetsBuildRunnerImpl implements FlutterNativeAssetsBuildRunner {
  FlutterNativeAssetsBuildRunnerImpl(
    this.packageConfigPath,
    this.packageConfig,
    this.fileSystem,
    this.logger,
    this.runPackageName,
    this.pubspecPath, {
    required this.includeDevDependencies,
  });

  final String pubspecPath;
  final String packageConfigPath;
  final PackageConfig packageConfig;
  final FileSystem fileSystem;
  final Logger logger;
  final String runPackageName;

  /// Include the dev dependencies of [runPackageName].
  final bool includeDevDependencies;

  late final _logger = logging.Logger('')
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

  // Flutter wraps the Dart executable to update it in place
  // ($FLUTTER_ROOT/bin/dart). However, since this is a Dart process invocation
  // in a Flutter process invocation, it should not try to update in place, so
  // use the Dart standalone executable
  // ($FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart).
  late final Uri _dartExecutable = fileSystem
      .directory(Cache.flutterRoot)
      .uri
      .resolve('bin/cache/dart-sdk/bin/dart');

  late final packageLayout = PackageLayout.fromPackageConfig(
    fileSystem,
    packageConfig,
    Uri.file(packageConfigPath),
    runPackageName,
    includeDevDependencies: includeDevDependencies,
  );

  late final _buildRunner = NativeAssetsBuildRunner(
    logger: _logger,
    dartExecutable: _dartExecutable,
    fileSystem: fileSystem,
    packageLayout: packageLayout,
    userDefines: UserDefines(workspacePubspec: Uri.file(pubspecPath)),
  );

  @override
  Future<List<String>> packagesWithNativeAssets() async {
    // It suffices to only check for build hooks. If no packages have a build
    // hook. Then no build hook will output any assets for any link hook, and
    // thus the link hooks will never be run.
    return _buildRunner.packagesWithBuildHooks();
  }

  @override
  Future<BuildResult?> build({
    required List<ProtocolExtension> extensions,
    required bool linkingEnabled,
  }) async {
    final Result<BuildResult, HooksRunnerFailure> result = await _buildRunner.build(
      linkingEnabled: linkingEnabled,
      extensions: extensions,
    );
    if (result.isSuccess) {
      return result.success;
    } else {
      return null;
    }
  }

  @override
  Future<LinkResult?> link({
    required List<ProtocolExtension> extensions,
    required BuildResult buildResult,
  }) async {
    final Result<LinkResult, HooksRunnerFailure> result = await _buildRunner.link(
      extensions: extensions,
      buildResult: buildResult,
    );
    if (result.isSuccess) {
      return result.success;
    } else {
      return null;
    }
  }

  @override
  Future<void> setCCompilerConfig(CodeAssetTarget target) async => target.setCCompilerConfig();
}

Future<Uri> _writeNativeAssetsJson(
  List<KernelAsset> assets,
  Uri nativeAssetsJsonUri,
  FileSystem fileSystem,
) async {
  globals.logger.printTrace('Writing native assets json to $nativeAssetsJsonUri.');
  final String nativeAssetsDartContents = _toNativeAssetsJsonFile(assets);
  final File nativeAssetsFile = fileSystem.file(nativeAssetsJsonUri);
  final Directory parentDirectory = nativeAssetsFile.parent;
  if (!await parentDirectory.exists()) {
    await parentDirectory.create(recursive: true);
  }
  await nativeAssetsFile.writeAsString(nativeAssetsDartContents);
  globals.logger.printTrace('Writing ${nativeAssetsFile.path} done.');
  return nativeAssetsFile.uri;
}

String _toNativeAssetsJsonFile(List<KernelAsset> kernelAssets) {
  final assetsPerTarget = <Target, List<KernelAsset>>{};
  for (final asset in kernelAssets) {
    assetsPerTarget.putIfAbsent(asset.target, () => <KernelAsset>[]).add(asset);
  }

  const formatVersionKey = 'format-version';
  const nativeAssetsKey = 'native-assets';

  // See assets/native_assets.cc in the engine for the expected format.
  final jsonContents = <String, Object>{
    formatVersionKey: const <int>[1, 0, 0],
    nativeAssetsKey: <String, Map<String, List<String>>>{
      for (final MapEntry<Target, List<KernelAsset>> entry in assetsPerTarget.entries)
        entry.key.toString(): <String, List<String>>{
          for (final KernelAsset e in entry.value) e.id: e.path.toJson(),
        },
    },
  };

  return jsonEncode(jsonContents);
}

/// Whether link hooks should be run.
///
/// Link hooks should only be run for AOT Dart builds, which is the non-debug
/// modes in Flutter.
bool _nativeAssetsLinkingEnabled(BuildMode buildMode) {
  switch (buildMode) {
    case BuildMode.debug:
      return false;
    case BuildMode.jitRelease:
    case BuildMode.profile:
    case BuildMode.release:
      return true;
  }
}

Future<bool> _hookRunRequired(FlutterNativeAssetsBuildRunner buildRunner) async {
  final List<String> packagesWithNativeAssets = await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    globals.logger.printTrace(
      'No packages with native assets. Skipping native assets compilation.',
    );
    return false;
  }

  if (!featureFlags.isNativeAssetsEnabled && !featureFlags.isDartDataAssetsEnabled) {
    final String packageNames = packagesWithNativeAssets.join(' ');
    throwToolExit(
      'Package(s) $packageNames require the dart assets feature to be enabled.\n'
      '  Enable code assets using `flutter config --enable-native-assets`.'
      '  Enable data assets using `flutter config --enable-dart-data-assets`.',
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
  FlutterNativeAssetsBuildRunner buildRunner,
) async {
  final List<String> packagesWithNativeAssets = await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    globals.logger.printTrace(
      'No packages with native assets. Skipping native assets compilation.',
    );
    return;
  }
  final String packageNames = packagesWithNativeAssets.join(' ');
  throwToolExit(
    'Package(s) $packageNames require the native assets feature. '
    'This feature has not yet been implemented for `$os`. '
    'For more info see https://github.com/flutter/flutter/issues/129757.',
  );
}

/// This should be the same for different archs, debug/release, etc.
/// It should work for all macOS.
Uri nativeAssetsBuildUri(Uri projectUri, String osName) {
  final String buildDir = getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/$osName/');
}

Map<FlutterCodeAsset, KernelAsset> _assetTargetLocationsWindowsLinux(
  List<FlutterCodeAsset> assets,
  Uri? absolutePath,
) {
  return <FlutterCodeAsset, KernelAsset>{
    for (final FlutterCodeAsset asset in assets)
      asset: _targetLocationSingleArchitecture(asset, absolutePath),
  };
}

KernelAsset _targetLocationSingleArchitecture(FlutterCodeAsset asset, Uri? absolutePath) {
  final LinkMode linkMode = asset.codeAsset.linkMode;
  final KernelAssetPath kernelAssetPath;
  switch (linkMode) {
    case DynamicLoadingSystem _:
      kernelAssetPath = KernelAssetSystemPath(linkMode.uri);
    case LookupInExecutable _:
      kernelAssetPath = KernelAssetInExecutable();
    case LookupInProcess _:
      kernelAssetPath = KernelAssetInProcess();
    case DynamicLoadingBundled _:
      final String fileName = asset.codeAsset.file!.pathSegments.last;
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
      throw Exception('Unsupported asset link mode ${linkMode.runtimeType} in asset $asset');
  }
  return KernelAsset(id: asset.codeAsset.id, target: asset.target, path: kernelAssetPath);
}

Map<FlutterCodeAsset, KernelAsset> assetTargetLocationsForOS(
  OS targetOS,
  List<FlutterCodeAsset> codeAssets,
  bool flutterTester,
  Uri buildUri,
) {
  switch (targetOS) {
    case OS.windows:
    case OS.linux:
      final Uri? absolutePath = flutterTester ? buildUri : null;
      return _assetTargetLocationsWindowsLinux(codeAssets, absolutePath);
    case OS.macOS:
      final Uri? absolutePath = flutterTester ? buildUri : null;
      return assetTargetLocationsMacOS(codeAssets, absolutePath);
    case OS.iOS:
      return assetTargetLocationsIOS(codeAssets);
    case OS.android:
      return assetTargetLocationsAndroid(codeAssets);
    default:
      throw UnimplementedError('This should be unreachable.');
  }
}

Future<void> _copyNativeCodeAssetsForOS(
  OS targetOS,
  Uri buildUri,
  BuildMode buildMode,
  FileSystem fileSystem,
  Map<FlutterCodeAsset, KernelAsset> assetTargetLocations,
  String? codesignIdentity,
  bool flutterTester,
) async {
  // We only have to copy code assets that are bundled within the app.
  // If a code asset that use a linking mode of [LookupInProcess],
  // [LookupInExecutable] or [DynamicLoadingSystem] do not have anything to
  // bundle as part of the app.
  assetTargetLocations = <FlutterCodeAsset, KernelAsset>{
    for (final FlutterCodeAsset codeAsset in assetTargetLocations.keys)
      if (codeAsset.codeAsset.linkMode is DynamicLoadingBundled)
        codeAsset: assetTargetLocations[codeAsset]!,
  };

  if (assetTargetLocations.isEmpty) {
    return;
  }

  globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
  final List<FlutterCodeAsset> codeAssets = assetTargetLocations.keys.toList();
  switch (targetOS) {
    case OS.windows:
    case OS.linux:
      assert(codesignIdentity == null);
      await _copyNativeCodeAssetsToBundleOnWindowsLinux(
        buildUri,
        assetTargetLocations,
        buildMode,
        fileSystem,
      );
    case OS.macOS:
      if (flutterTester) {
        await copyNativeCodeAssetsMacOSFlutterTester(
          buildUri,
          fatAssetTargetLocationsMacOS(codeAssets, buildUri),
          codesignIdentity,
          buildMode,
          fileSystem,
        );
      } else {
        await copyNativeCodeAssetsMacOS(
          buildUri,
          fatAssetTargetLocationsMacOS(codeAssets, null),
          codesignIdentity,
          buildMode,
          fileSystem,
        );
      }
    case OS.iOS:
      await copyNativeCodeAssetsIOS(
        buildUri,
        fatAssetTargetLocationsIOS(codeAssets),
        codesignIdentity,
        buildMode,
        fileSystem,
      );
    case OS.android:
      assert(codesignIdentity == null);
      await copyNativeCodeAssetsAndroid(buildUri, assetTargetLocations, fileSystem);
    default:
      throw StateError('This should be unreachable.');
  }
  globals.logger.printTrace('Copying native assets done.');
}

/// Invokes the build of all transitive Dart packages.
///
/// This will invoke `hook/build.dart` and `hook/link.dart` (if applicable) for
/// all transitive dart packages that define such hooks.
Future<DartHooksResult> _runDartHooks({
  required FlutterNativeAssetsBuildRunner buildRunner,
  required List<AssetBuildTarget> targets,
  required Uri projectUri,
  required bool linkingEnabled,
}) async {
  final buildStart = DateTime.now();

  final String targetString = targets
      .map((AssetBuildTarget target) => target.targetString)
      .join(', ');

  globals.logger.printTrace('Building native assets for $targetString.');

  final codeAssets = <FlutterCodeAsset>[];
  final dataAssets = <DataAsset>[];
  final dependencies = <Uri>{};
  for (var i = 0; i < targets.length; i++) {
    final AssetBuildTarget target = targets[i];
    final List<ProtocolExtension> extensions;
    if (i > 0) {
      // We do not have to rebuild assets for the same target.
      extensions = target.extensions.whereType<CodeAssetExtension>().toList();
    } else {
      extensions = target.extensions;
    }
    final BuildResult buildResult = await _build(buildRunner, extensions, linkingEnabled);

    LinkResult? linkResult;
    if (linkingEnabled) {
      linkResult = await _link(buildRunner, extensions, buildResult);
      if (target is CodeAssetTarget) {
        codeAssets.addAll(
          _filterCodeAssets(
            linkResult.encodedAssets,
            Target.fromArchitectureAndOS(target.architecture, target.os),
          ),
        );
      }
      dataAssets.addAll(_filterDataAssets(linkResult.encodedAssets));
      dependencies.addAll(linkResult.dependencies);
    }
    if (target is CodeAssetTarget) {
      codeAssets.addAll(
        _filterCodeAssets(
          buildResult.encodedAssets,
          Target.fromArchitectureAndOS(target.architecture, target.os),
        ),
      );
    }
    dataAssets.addAll(_filterDataAssets(buildResult.encodedAssets));
    dependencies.addAll(buildResult.dependencies);
  }
  if (codeAssets.isNotEmpty) {
    globals.logger.printTrace(
      'Note: You are using the dart build hooks feature which is currently '
      'in preview. Please see '
      'https://dart.dev/interop/c-interop#native-assets for more details.',
    );
  }

  if (dataAssets.map((DataAsset asset) => asset.id).toSet().length != dataAssets.length) {
    throwToolExit(
      'Found duplicates in the data assets: ${dataAssets.map((DataAsset e) => e.id).toList()} while compiling for ${targets.map((AssetBuildTarget e) => e.targetString).toList()}.',
    );
  }

  if (codeAssets.toSet().length != codeAssets.length) {
    throwToolExit(
      'Found duplicates in the code assets: ${codeAssets.map((FlutterCodeAsset e) => e.codeAsset.id).toList()} while compiling for ${targets.map((AssetBuildTarget e) => e.targetString).toList()}.',
    );
  }

  globals.logger.printTrace('Building native assets for $targetString done.');

  return DartHooksResult(
    buildStart: buildStart,
    buildEnd: DateTime.now(),
    codeAssets: codeAssets,
    dataAssets: dataAssets,
    dependencies: dependencies.toList(),
  );
}

Iterable<FlutterCodeAsset> _filterCodeAssets(Iterable<EncodedAsset> assets, Target target) => assets
    .where((EncodedAsset asset) => asset.isCodeAsset)
    .map<FlutterCodeAsset>(
      (EncodedAsset encodedAsset) =>
          FlutterCodeAsset(codeAsset: encodedAsset.asCodeAsset, target: target),
    );

Iterable<DataAsset> _filterDataAssets(Iterable<EncodedAsset> assets) =>
    assets.where((EncodedAsset asset) => asset.isDataAsset).map<DataAsset>(DataAsset.fromEncoded);

Future<BuildResult> _build(
  FlutterNativeAssetsBuildRunner buildRunner,
  List<ProtocolExtension> extensions,
  bool linkingEnabled,
) async {
  final BuildResult? buildResult = await buildRunner.build(
    extensions: extensions,
    linkingEnabled: linkingEnabled,
  );
  if (buildResult == null) {
    _throwNativeAssetsBuildFailed();
  }
  return buildResult;
}

Future<LinkResult> _link(
  FlutterNativeAssetsBuildRunner buildRunner,
  List<ProtocolExtension> extensions,
  BuildResult buildResult,
) async {
  final LinkResult? linkResult = await buildRunner.link(
    extensions: extensions,
    buildResult: buildResult,
  );
  if (linkResult == null) {
    _throwNativeAssetsLinkFailed();
  }
  return linkResult;
}

Future<void> _copyNativeCodeAssetsToBundleOnWindowsLinux(
  Uri buildUri,
  Map<FlutterCodeAsset, KernelAsset> assetTargetLocations,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  assert(assetTargetLocations.isNotEmpty);

  final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
  if (!buildDir.existsSync()) {
    buildDir.createSync(recursive: true);
  }
  for (final MapEntry<FlutterCodeAsset, KernelAsset> assetMapping in assetTargetLocations.entries) {
    final Uri source = assetMapping.key.codeAsset.file!;
    final Uri target = (assetMapping.value.path as KernelAssetAbsolutePath).uri;
    final Uri targetUri = buildUri.resolveUri(target);
    final String targetFullPath = targetUri.toFilePath();
    await fileSystem.file(source).copy(targetFullPath);
  }
}

Never _throwNativeAssetsBuildFailed() {
  throwToolExit('Building native assets failed. See the logs for more details.');
}

Never _throwNativeAssetsLinkFailed() {
  throwToolExit('Linking native assets failed. See the logs for more details.');
}

OS getNativeOSFromTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.ios:
      return OS.iOS;
    case TargetPlatform.darwin:
      return OS.macOS;
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_riscv64:
      return OS.linux;
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
      return OS.windows;
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
      return OS.fuchsia;
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
      return OS.android;
    case TargetPlatform.tester:
      if (const LocalPlatform().isMacOS) {
        return OS.macOS;
      } else if (const LocalPlatform().isLinux) {
        return OS.linux;
      } else if (const LocalPlatform().isWindows) {
        return OS.windows;
      } else {
        throw StateError('Unknown operating system');
      }
    case TargetPlatform.web_javascript:
      throw StateError('No dart builds for web yet.');
    case TargetPlatform.unsupported:
      TargetPlatform.throwUnsupportedTarget();
  }
}

extension OSArchitectures on OS {
  Set<Architecture> get architectures => _osTargets[this]!;
}

const _osTargets = <OS, Set<Architecture>>{
  OS.android: <Architecture>{
    Architecture.arm,
    Architecture.arm64,
    Architecture.ia32,
    Architecture.x64,
    Architecture.riscv64,
  },
  OS.fuchsia: <Architecture>{Architecture.arm64, Architecture.x64},
  OS.iOS: <Architecture>{Architecture.arm, Architecture.arm64, Architecture.x64},
  OS.linux: <Architecture>{
    Architecture.arm,
    Architecture.arm64,
    Architecture.ia32,
    Architecture.riscv32,
    Architecture.riscv64,
    Architecture.x64,
  },
  OS.macOS: <Architecture>{Architecture.arm64, Architecture.x64},
  OS.windows: <Architecture>{Architecture.arm64, Architecture.ia32, Architecture.x64},
};

BuildMode _getBuildMode(Map<String, String> environmentDefines, bool isFlutterTester) {
  if (isFlutterTester) {
    return BuildMode.debug;
  }
  final String? environmentBuildMode = environmentDefines[kBuildMode];
  if (environmentBuildMode == null) {
    throw MissingDefineException(kBuildMode, 'native_assets');
  }
  return BuildMode.fromCliName(environmentBuildMode);
}
