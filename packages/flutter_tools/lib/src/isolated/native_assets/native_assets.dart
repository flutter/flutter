// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import 'package:logging/logging.dart' as logging;
import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/code_assets_builder.dart';
import 'package:native_assets_cli/data_assets_builder.dart';
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
import '../../macos/xcode.dart' as xcode;
import 'android/native_assets.dart';
import 'ios/native_assets.dart';
import 'linux/native_assets.dart';
import 'macos/native_assets.dart';
import 'macos/native_assets_host.dart';
import 'windows/native_assets.dart';

export 'package:native_assets_cli/code_assets_builder.dart' show CodeAsset, DynamicLoadingBundled;
export 'package:native_assets_cli/data_assets_builder.dart' show DataAsset;

/// The assets produced by a Dart build and the dependencies of those assets.
///
/// If any of the dependencies change, then the Dart build should be performed
/// again.
final class DartBuildResult {
  const DartBuildResult(
    this.buildStart,
    this.buildEnd,
    this.codeAssets,
    this.dataAssets,
    this.dependencies,
  );

  DartBuildResult.empty()
    : buildStart = DateTime.now(),
      buildEnd = DateTime.now(),
      codeAssets = const <CodeAsset>[],
      dataAssets = const <DataAsset>[],
      dependencies = const <Uri>[];

  factory DartBuildResult.fromJson(Map<String, Object?> json) {
    final DateTime buildStart = DateTime.parse((json['build_start'] as String?)!);
    final DateTime buildEnd = DateTime.parse((json['build_end'] as String?)!);
    final List<Uri> dependencies = <Uri>[
      for (final Object? encodedUri in json['dependencies']! as List<Object?>)
        Uri.parse(encodedUri! as String),
    ];
    final List<CodeAsset> codeAssets = <CodeAsset>[
      for (final Object? json in json['code_assets'] as List<Object?>? ?? const <Object?>[])
        CodeAsset.fromEncoded(EncodedAsset.fromJson(json! as Map<String, Object?>)),
    ];
    final List<DataAsset> dataAssets = <DataAsset>[
      for (final Object? json in json['data_assets'] as List<Object?>? ?? const <Object?>[])
        DataAsset.fromEncoded(EncodedAsset.fromJson(json! as Map<String, Object?>)),
    ];
    return DartBuildResult(buildStart, buildEnd, codeAssets, dataAssets, dependencies);
  }

  final DateTime buildStart;
  final DateTime buildEnd;
  final List<CodeAsset> codeAssets;
  final List<DataAsset> dataAssets;
  final List<Uri> dependencies;

  Map<String, Object?> toJson() => <String, Object?>{
    'build_start': buildStart.toIso8601String(),
    'build_end': buildEnd.toIso8601String(),
    'dependencies': <Object?>[for (final Uri dep in dependencies) dep.toString()],
    'code_assets': <Object?>[for (final CodeAsset code in codeAssets) code.encode().toJson()],
    'data_assets': <Object?>[for (final DataAsset asset in dataAssets) asset.encode().toJson()],
  };

  /// The files that eventually should be bundled with the app.
  List<Uri> get filesToBeBundled => <Uri>[
    for (final CodeAsset code in codeAssets)
      if (code.linkMode is DynamicLoadingBundled) code.file!,
    for (final DataAsset asset in dataAssets) asset.file,
  ];

  /// Whether caller may need to re-run the dart build.
  bool isBuildUpToDate(FileSystem fileSystem) {
    return !_wasAnyFileModifiedSince(fileSystem, buildStart, dependencies);
  }

  /// Whether the files produced by the build are up-to-date.
  ///
  /// NOTICE: The build itself may be up-to-date but the output may not be (as
  /// the output may be existing on disc and not be produced by the build
  /// itself - in which case we may not need to re-build if the file changes,
  /// but we may need to make a new asset bundle with the modified file).
  bool isBuildOutputDirty(FileSystem fileSystem) {
    return _wasAnyFileModifiedSince(fileSystem, buildEnd, filesToBeBundled);
  }

  static bool _wasAnyFileModifiedSince(FileSystem fileSystem, DateTime since, List<Uri> uris) {
    for (final Uri uri in uris) {
      final DateTime modified = fileSystem.statSync(uri.toFilePath()).modified;
      if (modified.isAfter(since)) {
        return true;
      }
    }
    return false;
  }
}

/// Invokes the build of all transitive Dart packages and prepares code assets
/// to be included in the native build.
Future<DartBuildResult> runFlutterSpecificDartBuild({
  required Map<String, String> environmentDefines,
  required FlutterNativeAssetsBuildRunner buildRunner,
  required TargetPlatform targetPlatform,
  required Uri projectUri,
  required FileSystem fileSystem,
  required Uri? recordedUsagesFile,
}) async {
  final bool isWeb = targetPlatform == TargetPlatform.web_javascript;
  final OS? targetOS = getNativeOSFromTargetPlatform(targetPlatform);
  assert(isWeb || targetOS != null);
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);

  // Sanity check.
  final String? codesignIdentity = environmentDefines[kCodesignIdentity];
  assert(codesignIdentity == null || targetOS == OS.iOS || targetOS == OS.macOS);

  final Directory buildDir = fileSystem.directory(buildUri);

  final bool flutterTester = targetPlatform == TargetPlatform.tester;

  if (!await buildDir.exists()) {
    // Ensure the folder exists so the native build system can copy it even
    // if there's no native assets.
    await buildDir.create(recursive: true);
  }

  if (!await _nativeBuildRequired(buildRunner)) {
    return DartBuildResult.empty();
  }

  final BuildMode buildMode = _getBuildMode(environmentDefines, flutterTester);
  final List<Architecture>? architectures =
      isWeb
          ? null
          : (flutterTester
              ? <Architecture>[Architecture.current]
              : _architecturesForOS(targetPlatform, targetOS!, environmentDefines));
  final DartBuildResult result =
      architectures?.isEmpty ?? false
          ? DartBuildResult.empty()
          : await _runDartBuild(
            environmentDefines: environmentDefines,
            buildRunner: buildRunner,
            codeAssetSupport: !isWeb && featureFlags.isNativeAssetsEnabled,
            dataAssetSupport: featureFlags.isDartDataAssetsEnabled,
            architectures: architectures,
            projectUri: projectUri,
            linkingEnabled: _nativeAssetsLinkingEnabled(buildMode),
            fileSystem: fileSystem,
            targetOS: targetOS,
            recordedUsagesFile: recordedUsagesFile,
          );
  return result;
}

Future<void> installCodeAssets({
  required DartBuildResult dartBuildResult,
  required Map<String, String> environmentDefines,
  required TargetPlatform targetPlatform,
  required Uri projectUri,
  required FileSystem fileSystem,
  required Uri nativeAssetsFileUri,
}) async {
  final OS? targetOS = getNativeOSFromTargetPlatform(targetPlatform);
  assert(targetOS != null);

  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);
  final bool flutterTester = targetPlatform == TargetPlatform.tester;
  final BuildMode buildMode = _getBuildMode(environmentDefines, flutterTester);

  final String? codesignIdentity = environmentDefines[kCodesignIdentity];
  final Map<CodeAsset, KernelAsset> assetTargetLocations = assetTargetLocationsForOS(
    targetOS!,
    dartBuildResult.codeAssets,
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
/// It enables mocking `package:native_assets_builder` package.
/// It also enables mocking native toolchain discovery via [cCompilerConfig].
abstract interface class FlutterNativeAssetsBuildRunner {
  /// All packages in the transitive dependencies that have a `build.dart`.
  Future<List<String>> packagesWithNativeAssets();

  /// Runs all [packagesWithNativeAssets] `build.dart`.
  Future<BuildResult?> build({
    required List<String> buildAssetTypes,
    required BuildInputValidator inputValidator,
    required BuildInputCreator inputCreator,
    required BuildValidator buildValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required Uri workingDirectory,
    required bool linkingEnabled,
  });

  /// Runs all [packagesWithNativeAssets] `link.dart`.
  Future<LinkResult?> link({
    required List<String> buildAssetTypes,
    required LinkInputValidator inputValidator,
    required LinkInputCreator inputCreator,
    required LinkValidator linkValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required Uri workingDirectory,
    required BuildResult buildResult,
    required Uri? recordedUsagesFile,
  });

  /// The C compiler config to use for compilation.
  Future<CCompilerConfig?> get cCompilerConfig;

  /// The NDK compiler to use to use for compilation for Android.
  Future<CCompilerConfig?> get ndkCCompilerConfig;
}

/// Uses `package:native_assets_builder` for its implementation.
class FlutterNativeAssetsBuildRunnerImpl implements FlutterNativeAssetsBuildRunner {
  FlutterNativeAssetsBuildRunnerImpl(
    this.packageConfigPath,
    this.packageConfig,
    this.fileSystem,
    this.logger,
    this.runPackageName,
  );

  final String packageConfigPath;
  final PackageConfig packageConfig;
  final FileSystem fileSystem;
  final Logger logger;
  final String runPackageName;

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

  // Flutter wraps the Dart executable to update it in place
  // ($FLUTTER_ROOT/bin/dart). However, since this is a Dart process invocation
  // in a Flutter process invocation, it should not try to update in place, so
  // use the Dart standalone executable
  // ($FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart).
  late final Uri _dartExecutable = fileSystem
      .directory(Cache.flutterRoot)
      .uri
      .resolve('bin/cache/dart-sdk/bin/dart');

  late final PackageLayout packageLayout = PackageLayout.fromPackageConfig(
    fileSystem,
    packageConfig,
    Uri.file(packageConfigPath),
    runPackageName,
  );

  late final NativeAssetsBuildRunner _buildRunner = NativeAssetsBuildRunner(
    logger: _logger,
    dartExecutable: _dartExecutable,
    fileSystem: fileSystem,
    packageLayout: packageLayout,
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
    required List<String> buildAssetTypes,
    required BuildInputValidator inputValidator,
    required BuildInputCreator inputCreator,
    required BuildValidator buildValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required Uri workingDirectory,
    required bool linkingEnabled,
  }) {
    return _buildRunner.build(
      buildAssetTypes: buildAssetTypes,
      inputCreator: inputCreator,
      inputValidator: inputValidator,
      buildValidator: buildValidator,
      applicationAssetValidator: applicationAssetValidator,
      linkingEnabled: linkingEnabled,
    );
  }

  @override
  Future<LinkResult?> link({
    required List<String> buildAssetTypes,
    required LinkInputValidator inputValidator,
    required LinkInputCreator inputCreator,
    required LinkValidator linkValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required Uri workingDirectory,
    required BuildResult buildResult,
    required Uri? recordedUsagesFile,
  }) {
    return _buildRunner.link(
      buildAssetTypes: buildAssetTypes,
      inputCreator: inputCreator,
      inputValidator: inputValidator,
      linkValidator: linkValidator,
      applicationAssetValidator: applicationAssetValidator,
      buildResult: buildResult,
      resourceIdentifiers: recordedUsagesFile,
    );
  }

  @override
  late final Future<CCompilerConfig?> cCompilerConfig = () {
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
  final Map<Target, List<KernelAsset>> assetsPerTarget = <Target, List<KernelAsset>>{};
  for (final KernelAsset asset in kernelAssets) {
    assetsPerTarget.putIfAbsent(asset.target, () => <KernelAsset>[]).add(asset);
  }

  const String formatVersionKey = 'format-version';
  const String nativeAssetsKey = 'native-assets';

  // See assets/native_assets.cc in the engine for the expected format.
  final Map<String, Object> jsonContents = <String, Object>{
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

Future<bool> _nativeBuildRequired(FlutterNativeAssetsBuildRunner buildRunner) async {
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
Uri nativeAssetsBuildUri(Uri projectUri, OS? os) {
  final String buildDir = getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/${os == null ? 'web' : os.name}/');
}

Map<CodeAsset, KernelAsset> _assetTargetLocationsWindowsLinux(
  List<CodeAsset> assets,
  Uri? absolutePath,
) {
  return <CodeAsset, KernelAsset>{
    for (final CodeAsset asset in assets)
      asset: _targetLocationSingleArchitecture(asset, absolutePath),
  };
}

KernelAsset _targetLocationSingleArchitecture(CodeAsset asset, Uri? absolutePath) {
  final LinkMode linkMode = asset.linkMode;
  final KernelAssetPath kernelAssetPath;
  switch (linkMode) {
    case DynamicLoadingSystem _:
      kernelAssetPath = KernelAssetSystemPath(linkMode.uri);
    case LookupInExecutable _:
      kernelAssetPath = KernelAssetInExecutable();
    case LookupInProcess _:
      kernelAssetPath = KernelAssetInProcess();
    case DynamicLoadingBundled _:
      final String fileName = asset.file!.pathSegments.last;
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
  return KernelAsset(
    id: asset.id,
    target: Target.fromArchitectureAndOS(asset.architecture!, asset.os),
    path: kernelAssetPath,
  );
}

Map<CodeAsset, KernelAsset> assetTargetLocationsForOS(
  OS targetOS,
  List<CodeAsset> codeAssets,
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
  Map<CodeAsset, KernelAsset> assetTargetLocations,
  String? codesignIdentity,
  bool flutterTester,
) async {
  // We only have to copy code assets that are bundled within the app.
  // If a code asset that use a linking mode of [LookupInProcess],
  // [LookupInExecutable] or [DynamicLoadingSystem] do not have anything to
  // bundle as part of the app.
  assetTargetLocations = <CodeAsset, KernelAsset>{
    for (final CodeAsset codeAsset in assetTargetLocations.keys)
      if (codeAsset.linkMode is DynamicLoadingBundled) codeAsset: assetTargetLocations[codeAsset]!,
  };

  if (assetTargetLocations.isEmpty) {
    return;
  }

  globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
  final List<CodeAsset> codeAssets = assetTargetLocations.keys.toList();
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
Future<DartBuildResult> _runDartBuild({
  required Map<String, String> environmentDefines,
  required FlutterNativeAssetsBuildRunner buildRunner,
  required List<Architecture>? architectures,
  required Uri projectUri,
  required FileSystem fileSystem,
  required OS? targetOS,
  required bool linkingEnabled,
  required bool codeAssetSupport,
  required bool dataAssetSupport,
  required Uri? recordedUsagesFile,
}) async {
  final DateTime buildStart = DateTime.now();

  // For native builds we have valid architectures.
  // For web builds we use `null` as the single architecture.
  final bool isWeb = architectures == null;

  final String targetString = isWeb ? 'web' : '$targetOS ${architectures.join(',')}';

  globals.logger.printTrace('Building native assets for $targetString.');
  final List<EncodedAsset> assets = <EncodedAsset>[];
  final Set<Uri> dependencies = <Uri>{};

  final EnvironmentType? environmentType;
  if (targetOS == OS.iOS) {
    final String? sdkRoot = environmentDefines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, 'native_assets');
    }
    environmentType = xcode.environmentTypeFromSdkroot(sdkRoot, fileSystem);
  } else {
    environmentType = null;
  }

  final CCompilerConfig? cCompilerConfig =
      targetOS == OS.android
          ? await buildRunner.ndkCCompilerConfig
          : await buildRunner.cCompilerConfig;

  final String? codesignIdentity = environmentDefines[kCodesignIdentity];
  assert(codesignIdentity == null || targetOS == OS.iOS || targetOS == OS.macOS);

  final AndroidCodeConfig? androidConfig =
      targetOS == OS.android
          ? AndroidCodeConfig(targetNdkApi: targetAndroidNdkApi(environmentDefines))
          : null;
  final IOSCodeConfig? iosConfig =
      targetOS == OS.iOS
          ? IOSCodeConfig(targetVersion: targetIOSVersion, targetSdk: getIOSSdk(environmentType!))
          : null;
  final MacOSCodeConfig? macOSConfig =
      targetOS == OS.macOS ? MacOSCodeConfig(targetVersion: targetMacOSVersion) : null;
  for (final Architecture? architecture in architectures ?? <Architecture?>[null]) {
    assert(!codeAssetSupport || architecture != null);
    final BuildResult? buildResult = await buildRunner.build(
      buildAssetTypes: <String>[
        if (codeAssetSupport) CodeAsset.type,
        if (dataAssetSupport) DataAsset.type,
      ],
      inputCreator: () {
        final BuildInputBuilder buildInputBuilder = BuildInputBuilder();
        if (targetOS != null && codeAssetSupport) {
          buildInputBuilder.config.setupCode(
            targetArchitecture: architecture,
            linkModePreference: LinkModePreference.dynamic,
            cCompiler: cCompilerConfig,
            targetOS: targetOS,
            android: androidConfig,
            iOS: iosConfig,
            macOS: macOSConfig,
          );
        }
        return buildInputBuilder;
      },
      inputValidator:
          (BuildInput config) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetBuildInput(config),
            if (dataAssetSupport) ...await validateDataAssetBuildInput(config),
          ],
      buildValidator:
          (BuildInput config, BuildOutput output) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetBuildOutput(config, output),
            if (dataAssetSupport) ...await validateDataAssetBuildOutput(config, output),
          ],
      applicationAssetValidator:
          (List<EncodedAsset> assets) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetInApplication(assets),
          ],
      workingDirectory: projectUri,
      linkingEnabled: linkingEnabled,
    );
    if (buildResult == null) {
      _throwNativeAssetsBuildFailed();
    }
    dependencies.addAll(buildResult.dependencies);
    if (!linkingEnabled) {
      assets.addAll(buildResult.encodedAssets);
      continue;
    }
    final LinkResult? linkResult = await buildRunner.link(
      buildAssetTypes: <String>[
        if (codeAssetSupport) CodeAsset.type,
        if (dataAssetSupport) DataAsset.type,
      ],
      inputCreator: () {
        final LinkInputBuilder linkInputBuilder = LinkInputBuilder();
        if (targetOS != null && codeAssetSupport) {
          linkInputBuilder.config.setupCode(
            targetArchitecture: architecture,
            linkModePreference: LinkModePreference.dynamic,
            cCompiler: cCompilerConfig,
            targetOS: targetOS,
            android: androidConfig,
            iOS: iosConfig,
            macOS: macOSConfig,
          );
        }
        return linkInputBuilder;
      },
      inputValidator:
          (LinkInput config) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetLinkInput(config),
            if (dataAssetSupport) ...await validateDataAssetLinkInput(config),
          ],
      linkValidator:
          (LinkInput config, LinkOutput output) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetLinkOutput(config, output),
            if (dataAssetSupport) ...await validateDataAssetLinkOutput(config, output),
          ],
      applicationAssetValidator:
          (List<EncodedAsset> assets) async => <String>[
            if (codeAssetSupport) ...await validateCodeAssetInApplication(assets),
          ],
      workingDirectory: projectUri,
      buildResult: buildResult,
      recordedUsagesFile: recordedUsagesFile,
    );
    if (linkResult == null) {
      _throwNativeAssetsLinkFailed();
    }
    assets.addAll(linkResult.encodedAssets);
    dependencies.addAll(<Uri>[
      ...linkResult.dependencies,
      if (recordedUsagesFile != null) recordedUsagesFile,
    ]);
  }

  final List<CodeAsset> codeAssets =
      assets
          .where((EncodedAsset asset) => asset.type == CodeAsset.type)
          .map<CodeAsset>(CodeAsset.fromEncoded)
          .toList();
  final List<DataAsset> dataAssets =
      assets
          .where((EncodedAsset asset) => asset.type == DataAsset.type)
          .map<DataAsset>(DataAsset.fromEncoded)
          .toList();
  globals.logger.printTrace('Building native assets for $targetString done.');

  final DateTime buildEnd = DateTime.now();
  return DartBuildResult(buildStart, buildEnd, codeAssets, dataAssets, dependencies.toList());
}

List<Architecture> _architecturesForOS(
  TargetPlatform targetPlatform,
  OS targetOS,
  Map<String, String> environmentDefines,
) {
  switch (targetOS) {
    case OS.linux:
      return <Architecture>[_getNativeArchitecture(targetPlatform)];
    case OS.windows:
      return <Architecture>[_getNativeArchitecture(targetPlatform)];
    case OS.macOS:
      final List<DarwinArch> darwinArchs =
          _emptyToNull(
            environmentDefines[kDarwinArchs],
          )?.split(' ').map(getDarwinArchForName).toList() ??
          <DarwinArch>[DarwinArch.x86_64, DarwinArch.arm64];
      return darwinArchs.map(getNativeMacOSArchitecture).toList();
    case OS.android:
      final String? androidArchsEnvironment = environmentDefines[kAndroidArchs];
      final List<AndroidArch> androidArchs = _androidArchs(targetPlatform, androidArchsEnvironment);
      return androidArchs.map(getNativeAndroidArchitecture).toList();
    case OS.iOS:
      final List<DarwinArch> iosArchs =
          _emptyToNull(environmentDefines[kIosArchs])?.split(' ').map(getIOSArchForName).toList() ??
          <DarwinArch>[DarwinArch.arm64];
      return iosArchs.map(getNativeIOSArchitecture).toList();
    default:
      // TODO(dacoharkes): Implement other OSes. https://github.com/flutter/flutter/issues/129757
      // Write the file we claim to have in the [outputs].
      return <Architecture>[];
  }
}

Architecture _getNativeArchitecture(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.linux_x64:
    case TargetPlatform.windows_x64:
      return Architecture.x64;
    case TargetPlatform.linux_arm64:
    case TargetPlatform.windows_arm64:
      return Architecture.arm64;
    case TargetPlatform.android:
    case TargetPlatform.ios:
    case TargetPlatform.darwin:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      throw Exception('Unknown targetPlatform: $targetPlatform.');
  }
}

Future<void> _copyNativeCodeAssetsToBundleOnWindowsLinux(
  Uri buildUri,
  Map<CodeAsset, KernelAsset> assetTargetLocations,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  assert(assetTargetLocations.isNotEmpty);

  final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
  if (!buildDir.existsSync()) {
    buildDir.createSync(recursive: true);
  }
  for (final MapEntry<CodeAsset, KernelAsset> assetMapping in assetTargetLocations.entries) {
    final Uri source = assetMapping.key.file!;
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

/// Returns null for the web, and non-null otherwise.
OS? getNativeOSFromTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.ios:
      return OS.iOS;
    case TargetPlatform.darwin:
      return OS.macOS;
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm64:
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
    case TargetPlatform.android_x86:
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
      return null;
  }
}

List<AndroidArch> _androidArchs(TargetPlatform targetPlatform, String? androidArchsEnvironment) {
  switch (targetPlatform) {
    case TargetPlatform.android_arm:
      return <AndroidArch>[AndroidArch.armeabi_v7a];
    case TargetPlatform.android_arm64:
      return <AndroidArch>[AndroidArch.arm64_v8a];
    case TargetPlatform.android_x64:
      return <AndroidArch>[AndroidArch.x86_64];
    case TargetPlatform.android_x86:
      return <AndroidArch>[AndroidArch.x86];
    case TargetPlatform.android:
      if (androidArchsEnvironment == null) {
        throw MissingDefineException(kAndroidArchs, 'native_assets');
      }
      return androidArchsEnvironment.split(' ').map(getAndroidArchForName).toList();
    case TargetPlatform.darwin:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.ios:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
      throwToolExit('Unsupported Android target platform: $targetPlatform.');
  }
}

String? _emptyToNull(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  return input;
}

extension OSArchitectures on OS {
  Set<Architecture> get architectures => _osTargets[this]!;
}

const Map<OS, Set<Architecture>> _osTargets = <OS, Set<Architecture>>{
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
