// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart' as logging;
// import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;
import 'package:package_config/package_config.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../ios/native_assets.dart';
import '../native_assets.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file and
/// the Xcode project.
Future<Uri?> dryRunNativeAssetsMacOS({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
}) async {
  if (await hasNoPackageConfig(buildRunner)) {
    return null;
  }
  if (await isDisabledAndNoNativeAssets(buildRunner)) {
    return null;
  }

  final Uri buildUri_ = buildUri(projectUri, OS.macOS);
  final Iterable<Asset> nativeAssetPaths =
      await dryRunNativeAssetsMacosInternal(
          fileSystem, projectUri, flutterTester, buildRunner);
  final Uri nativeAssetsUri =
      await writeNativeAssetsYaml(nativeAssetPaths, buildUri_, fileSystem);
  return nativeAssetsUri;
}

/// Dry run the native builds for multiple OSes.
///
/// Needed for `flutter run -d all`.
Future<Uri?> dryRunNativeAssetsMultipeOSes({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  required FileSystem fileSystem,
  required Iterable<TargetPlatform> targetPlatforms,
}) async {
  if (await hasNoPackageConfig(buildRunner)) {
    return null;
  }
  if (await isDisabledAndNoNativeAssets(buildRunner)) {
    return null;
  }

  final Uri buildUri_ = buildUriMultiple(projectUri);
  final Iterable<Asset> nativeAssetPaths = <Asset>[
    if (targetPlatforms.contains(TargetPlatform.darwin) ||
        (targetPlatforms.contains(TargetPlatform.tester) &&
            OS.current == OS.macOS))
      ...await dryRunNativeAssetsMacosInternal(
          fileSystem, projectUri, false, buildRunner),
    if (targetPlatforms.contains(TargetPlatform.ios))
      ...await dryRunNativeAssetsIosInternal(
          fileSystem, projectUri, buildRunner)
  ];
  final Uri nativeAssetsUri =
      await writeNativeAssetsYaml(nativeAssetPaths, buildUri_, fileSystem);
  return nativeAssetsUri;
}

Future<Iterable<Asset>> dryRunNativeAssetsMacosInternal(
  FileSystem fileSystem,
  Uri projectUri,
  bool flutterTester,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OS targetOs = OS.macOS;
  final Uri buildUri_ = buildUri(projectUri, targetOs);

  globals.logger.printTrace('Dry running native assets for $targetOs.');
  final List<Asset> nativeAssets = await buildRunner.dryRun(
    linkModePreference: LinkModePreference.dynamic,
    targetOs: targetOs,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
  );
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Dry running native assets for $targetOs done.');
  final Uri? absolutePath = flutterTester ? buildUri_ : null;
  final Map<Asset, Asset> assetTargetLocations =
      _assetTargetLocations(nativeAssets, absolutePath);
  final Iterable<Asset> nativeAssetPaths = assetTargetLocations.values;
  return nativeAssetPaths;
}

/// Builds native assets.
///
/// If [darwinArchs] is omitted, the current target architecture is used.
///
/// If [flutterTester] is true, absolute paths are emitted in the native
/// assets mapping. This can be used for JIT mode without sandbox on the host.
/// This is used in `flutter test` and `flutter run -d flutter-tester`.
Future<Uri?> buildNativeAssetsMacOS({
  required NativeAssetsBuildRunner buildRunner,
  List<DarwinArch>? darwinArchs,
  required Uri projectUri,
  required BuildMode buildMode,
  bool flutterTester = false,
  String? codesignIdentity,
  bool writeYamlFile = true,
  required FileSystem fileSystem,
}) async {
  if (await hasNoPackageConfig(buildRunner)) {
    return null;
  }
  if (await isDisabledAndNoNativeAssets(buildRunner)) {
    return null;
  }

  final List<Target> targets = darwinArchs != null
      ? darwinArchs.map(_getNativeTarget).toList()
      : <Target>[Target.current];
  final native_assets_cli.BuildMode buildModeCli = getBuildMode(buildMode);

  const OS targetOs = OS.macOS;
  final Uri buildUri_ = buildUri(projectUri, targetOs);

  globals.logger
      .printTrace('Building native assets for $targets $buildModeCli.');
  final List<Asset> nativeAssets = <Asset>[
    for (final Target target in targets)
      ...await buildRunner.build(
        linkModePreference: LinkModePreference.dynamic,
        target: target,
        buildMode: buildModeCli,
        workingDirectory: projectUri,
        includeParentEnvironment: true,
        cCompilerConfig: await cCompilerConfig,
      ),
  ];
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $targets done.');
  final Uri? absolutePath = flutterTester ? buildUri_ : null;
  final Map<Asset, Asset> assetTargetLocations =
      _assetTargetLocations(nativeAssets, absolutePath);
  final Map<AssetPath, List<Asset>> fatAssetTargetLocations =
      _fatAssetTargetLocations(nativeAssets, absolutePath);
  await copyNativeAssets(buildUri_, fatAssetTargetLocations, codesignIdentity,
      buildMode, fileSystem);
  if (writeYamlFile) {
    final Uri nativeAssetsUri = await writeNativeAssetsYaml(
        assetTargetLocations.values, buildUri_, fileSystem);
    return nativeAssetsUri;
  }
  return null;
}

/// Checks whether this project does not yet have a package config file.
///
/// A project has no package config when `pub get` has not yet been run.
///
/// Native asset builds cannot be run without a package config. If there is
/// no package config, leave a logging trace about that.
Future<bool> hasNoPackageConfig(
    NativeAssetsBuildRunner buildRunner) async {
  final bool packageConfigExists = await buildRunner.hasPackageConfig();
  if (!packageConfigExists) {
    globals.logger.printTrace(
        'No package config found. Skipping native assets compilation.');
  }
  return !packageConfigExists;
}

/// Checks that if native assets is disabled, none of the dependencies declare
/// native assets.
///
/// If any of the dependencies have native assets, but native assets are
/// disabled, exits the tool.
Future<bool> isDisabledAndNoNativeAssets(
    NativeAssetsBuildRunner buildRunner) async {
  if (featureFlags.isNativeAssetsEnabled) {
    return false;
  }
  final List<Package> packagesWithNativeAssets =
      await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    return true;
  }
  final String packageNames =
      packagesWithNativeAssets.map((Package p) => p.name).join(' ');
  throwToolExit(
    'Package(s) $packageNames require the native assets feature to be enabled. '
    'Enable using `flutter config --enable-native-assets`.',
  );
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
  if (await hasNoPackageConfig(buildRunner)) {
    return;
  }
  final List<Package> packagesWithNativeAssets =
      await buildRunner.packagesWithNativeAssets();
  if (packagesWithNativeAssets.isEmpty) {
    return;
  }
  final String packageNames =
      packagesWithNativeAssets.map((Package p) => p.name).join(' ');
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
  final Iterable<Asset> staticAssets =
      nativeAssets.whereLinkMode(LinkMode.static);
  if (staticAssets.isNotEmpty) {
    final String assetNames =
        staticAssets.map((Asset a) => a.name).toSet().join(', ');
    throwToolExit(
      'Native asset(s) $assetNames have their link mode set to static, '
      'but this is not yet supported. '
      'For more info see https://github.com/dart-lang/sdk/issues/49418.',
    );
  }
}

Uri flutterDartUri(FileSystem fileSystem) =>
    fileSystem.directory(Cache.flutterRoot).uri.resolve('bin/dart');

/// This should be the same for different archs, debug/release, etc.
/// It should work for all MacOS.
Uri buildUri(Uri projectUri, OS os) {
  final String buildDir = getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/$os/');
}

/// With `flutter run -d all` we need a place to store the native assets
/// mapping for multiple OSes combined.
Uri buildUriMultiple(Uri projectUri) {
  final String buildDir = getBuildDirectory();
  return projectUri.resolve('$buildDir/native_assets/multiple/');
}

/// The target location for native assets on MacOS.
///
/// Because we need to have a multi-architecture solution for
/// `flutter run --release`, we use `lipo` to combine all target architectures
/// into a single file.
///
/// We need to set the install name so that it matches what the place it will
/// be bundled in the final app.
///
/// Code signing is also done here, so that we don't have to worry about it
/// in xcode_backend.dart and macos_assemble.sh.
Future<void> copyNativeAssets(
  Uri buildUri,
  Map<AssetPath, List<Asset>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger
        .printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
    if (!buildDir.existsSync()) {
      buildDir.createSync(recursive: true);
    }
    for (final MapEntry<AssetPath, List<Asset>> assetMapping
        in assetTargetLocations.entries) {
      final Uri target = (assetMapping.key as AssetAbsolutePath).uri;
      final List<Uri> sources = <Uri>[
        for (final Asset source in assetMapping.value)
          (source.path as AssetAbsolutePath).uri
      ];
      final Uri targetUri = buildUri.resolveUri(target);
      final String targetFullPath = targetUri.toFilePath();
      await lipoDylibs(targetFullPath, sources);
      await setInstallNameDylib(targetUri);
      await codesignDylib(codesignIdentity, buildMode, targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

/// Combines dylibs from [sources] into a fat binary at [targetFullPath].
///
/// The dylibs must have different architectures. E.g. a dylib targeting
/// arm64 ios simulator cannot be combined with a dylib targeting arm64
/// ios device or macos arm64.
Future<void> lipoDylibs(String targetFullPath, List<Uri> sources) async {
  final ProcessResult lipoResult = await globals.processManager.run(
    <String>[
      'lipo',
      '-create',
      '-output',
      targetFullPath,
      for (final Uri source in sources) source.toFilePath(),
    ],
  );
  if (lipoResult.exitCode != 0) {
    throwToolExit('Failed to create universal binary:\n${lipoResult.stderr}');
  }
  globals.logger.printTrace(lipoResult.stdout as String);
  globals.logger.printTrace(lipoResult.stderr as String);
}

/// Sets the install name in a dylib with a Mach-O format.
///
/// On MacOS and iOS, opening a dylib at runtime fails if the path inside the
/// dylib itself does not correspond to the path that the file is at. Therefore,
/// native assets copied into their final location also need their install name
/// updated with the `install_name_tool`.
Future<void> setInstallNameDylib(Uri targetUri) async {
  final String fileName = targetUri.pathSegments.last;
  final ProcessResult installNameResult = await globals.processManager.run(
    <String>[
      'install_name_tool',
      '-id',
      '@executable_path/Frameworks/$fileName',
      targetUri.toFilePath(),
    ],
  );
  if (installNameResult.exitCode != 0) {
    throwToolExit(
        'Failed to change the install name of $targetUri:\n${installNameResult.stderr}');
  }
}

Future<void> codesignDylib(
  String? codesignIdentity,
  BuildMode buildMode,
  String targetFullPath,
) async {
  if (codesignIdentity == null || codesignIdentity.isEmpty) {
    codesignIdentity = '-';
  }
  final List<String> codesignCommand = <String>[
    'codesign',
    '--force',
    '--sign',
    codesignIdentity,
    if (buildMode != BuildMode.release) ...<String>[
      // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
      '--timestamp=none',
    ],
    targetFullPath,
  ];
  globals.logger.printTrace(codesignCommand.join(' '));
  final ProcessResult codesignResult =
      await globals.processManager.run(codesignCommand);
  if (codesignResult.exitCode != 0) {
    throwToolExit('Failed to code sign binary:\n${codesignResult.stderr}');
  }
  globals.logger.printTrace(codesignResult.stdout as String);
  globals.logger.printTrace(codesignResult.stderr as String);
}

Future<Uri> writeNativeAssetsYaml(Iterable<Asset> nativeAssetsMappingUsed,
    Uri buildUri, FileSystem fileSystem) async {
  globals.logger.printTrace('Writing native_assets.yaml.');
  final String nativeAssetsDartContents =
      nativeAssetsMappingUsed.toNativeAssetsFile();
  final Directory nativeAssetsDirectory = fileSystem.directory(buildUri);
  await nativeAssetsDirectory.create(recursive: true);
  final Uri nativeAssetsUri = buildUri.resolve('native_assets.yaml');
  final File nativeAssetsFile =
      fileSystem.file(buildUri.resolve('native_assets.yaml'));
  await nativeAssetsFile.writeAsString(nativeAssetsDartContents);
  globals.logger.printTrace('Writing ${nativeAssetsFile.path} done.');
  return nativeAssetsUri;
}

/// Extract the [Target] from a [DarwinArch].
Target _getNativeTarget(DarwinArch darwinArch) {
  switch (darwinArch) {
    case DarwinArch.arm64:
      return Target.macOSArm64;
    case DarwinArch.x86_64:
      return Target.macOSX64;
    case DarwinArch.armv7:
      throw Exception('Unknown DarwinArch: $darwinArch.');
  }
}

native_assets_cli.BuildMode getBuildMode(BuildMode buildMode) {
  switch (buildMode) {
    case BuildMode.debug:
      return native_assets_cli.BuildMode.debug;
    case BuildMode.jitRelease:
    case BuildMode.profile:
    case BuildMode.release:
      return native_assets_cli.BuildMode.release;
  }
}

Map<AssetPath, List<Asset>> _fatAssetTargetLocations(
    List<Asset> nativeAssets, Uri? absolutePath) {
  final Map<AssetPath, List<Asset>> result = <AssetPath, List<Asset>>{};
  for (final Asset asset in nativeAssets) {
    final AssetPath path = _targetLocationMacOS(asset, absolutePath).path;
    result[path] ??= <Asset>[];
    result[path]!.add(asset);
  }
  return result;
}

Map<Asset, Asset> _assetTargetLocations(
  List<Asset> nativeAssets,
  Uri? absolutePath,
) {
  return <Asset, Asset>{
    for (final Asset asset in nativeAssets)
      asset: _targetLocationMacOS(asset, absolutePath),
  };
}

Asset _targetLocationMacOS(Asset asset, Uri? absolutePath) {
  final AssetPath path = asset.path;
  switch (path) {
    case AssetSystemPath _:
    case AssetInExecutable _:
    case AssetInProcess _:
      return asset;
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
      return asset.copyWith(path: AssetAbsolutePath(uri));
  }
  throw Exception(
      'Unsupported asset path type ${path.runtimeType} in asset $asset');
}

final logging.Logger loggingLogger = logging.Logger('')
  ..onRecord.listen((logging.LogRecord record) {
    final int levelValue = record.level.value;
    final String message = record.message;
    if (levelValue >= logging.Level.SEVERE.value) {
      globals.logger.printError(message);
    } else if (levelValue >= logging.Level.WARNING.value) {
      globals.logger.printWarning(message);
    } else if (levelValue >= logging.Level.INFO.value) {
      globals.logger.printTrace(message);
    } else {
      globals.logger.printTrace(message);
    }
  });

/// Flutter expects `xcrun` to be on the path.
///
/// Use the `clang`, `ar`, and `ld` that would be used if run with `xcrun`.
final Future<CCompilerConfig> cCompilerConfig = () async {
  final ProcessResult xcrunResult =
      await globals.processManager.run(<String>['xcrun', 'clang', '--version']);
  if (xcrunResult.exitCode != 0) {
    throwToolExit('Failed to find clang with xcrun:\n${xcrunResult.stderr}');
  }
  final String installPath = (xcrunResult.stdout as String)
      .split('\n')
      .firstWhere((String s) => s.startsWith('InstalledDir: '))
      .split(' ')
      .last;
  return CCompilerConfig(
    cc: Uri.file('$installPath/clang'),
    ar: Uri.file('$installPath/ar'),
    ld: Uri.file('$installPath/ld'),
  );
}();
