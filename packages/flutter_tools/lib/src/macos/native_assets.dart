// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:logging/logging.dart' as logging;
import 'package:native_assets_builder/native_assets_builder.dart';
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

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file and
/// the xcode project.
Future<Uri?> dryRunNativeAssetsMacOS({
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
}) async {
  if (fileSystem is MemoryFileSystem) {
    return null; // https://github.com/dart-lang/native/issues/90
  }
  if (await isDisabledAndNoNativeAssets(projectUri)) {
    return null;
  }

  const OS targetOs = OS.macOS;
  final Uri buildUri_ = buildUri(projectUri, targetOs);

  globals.logger.printTrace(
      'Dry running native assets for $targetOs.');
  final List<Asset> nativeAssets = await NativeAssetsBuildRunner(
    logger: loggingLogger,
    dartExecutable: flutterDartUri(fileSystem),
  ).dryRun(
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
  final Uri nativeAssetsUri =
      await writeNativeAssetsYaml(
      assetTargetLocations.values, buildUri_, fileSystem);
  return nativeAssetsUri;
}

/// Builds native assets.
///
/// If [darwinArchs] is omitted, the current target architecture is used.
///
/// If [flutterTester] is true, absolute paths are emitted in the native
/// assets mapping. This can be used for JIT mode without sandbox on the host.
/// This is used in `flutter test` and `flutter run -dflutter-tester`.
Future<Uri?> buildNativeAssetsMacOS({
  List<DarwinArch>? darwinArchs,
  required Uri projectUri,
  required BuildMode buildMode,
  bool flutterTester = false,
  String? codesignIdentity,
  bool writeYamlFile = true,
  required FileSystem fileSystem,
}) async {
  if (fileSystem is MemoryFileSystem) {
    return null; // https://github.com/dart-lang/native/issues/90
  }
  if (await isDisabledAndNoNativeAssets(projectUri)) {
    return null;
  }

  final List<Target> targets = darwinArchs != null
      ? darwinArchs.map(_getNativeTarget).toList()
      : <Target>[Target.current];
  final native_assets_cli.BuildMode buildModeCli = getBuildMode(buildMode);

  const OS targetOs = OS.macOS;
  final Uri buildUri_ = buildUri(projectUri, targetOs);

  globals.logger.printTrace(
      'Building native assets for $targets $buildModeCli.');
  final List<Asset> nativeAssets = <Asset>[
    for (final Target target in targets)
      ...await NativeAssetsBuildRunner(
        logger: loggingLogger,
        dartExecutable: flutterDartUri(fileSystem),
      ).build(
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
  await copyNativeAssets(
      buildUri_, fatAssetTargetLocations, codesignIdentity,
      buildMode, fileSystem);
  if (writeYamlFile) {
    final Uri nativeAssetsUri =
        await writeNativeAssetsYaml(
        assetTargetLocations.values, buildUri_, fileSystem);
    return nativeAssetsUri;
  }
  return null;
}

Future<bool> isDisabledAndNoNativeAssets(Uri workingDirectory) async {
  if (featureFlags.isNativeAssetsEnabled) {
    return false;
  }

  final PackageLayout packageLayout =
      await PackageLayout.fromRootPackageRoot(workingDirectory);
  final List<Package> packagesWithNativeAssets =
      await packageLayout.packagesWithNativeAssets;
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

Future<void> ensureNoNativeAssetsUnimplementedOs(
    Uri workingDirectory, String os, FileSystem fileSystem) async {
  if (fileSystem is MemoryFileSystem) {
    return; // https://github.com/dart-lang/native/issues/90
  }
  final PackageLayout packageLayout =
      await PackageLayout.fromRootPackageRoot(workingDirectory);
  final List<Package> packagesWithNativeAssets =
      await packageLayout.packagesWithNativeAssets;
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
  final Uri buildUri = projectUri.resolve('build/native_assets/$os/');
  return buildUri;
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
      await setInstallnameDylib(targetUri);
      await codesignDylib(codesignIdentity, buildMode, targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

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
  assert(lipoResult.exitCode == 0);
  globals.logger.printTrace(lipoResult.stdout as String);
  globals.logger.printTrace(lipoResult.stderr as String);
}

Future<void> setInstallnameDylib(Uri targetUri) async {
  final String fileName = targetUri.pathSegments.last;
  final ProcessResult installNameResult = await globals.processManager.run(
    <String>[
      'install_name_tool',
      '-id',
      '@executable_path/Frameworks/$fileName',
      targetUri.toFilePath(),
    ],
  );
  assert(installNameResult.exitCode == 0);
  globals.logger.printTrace(installNameResult.stderr as String);
  globals.logger.printTrace(installNameResult.stdout as String);
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
  assert(codesignResult.exitCode == 0);
  globals.logger.printTrace(codesignResult.stdout as String);
  globals.logger.printTrace(codesignResult.stderr as String);
}

Future<Uri> writeNativeAssetsYaml(
    Iterable<Asset> nativeAssetsMappingUsed,
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
        List<Asset> nativeAssets, Uri? absolutePath) =>
    <Asset, Asset>{
      for (final Asset asset in nativeAssets)
        asset: _targetLocationMacOS(asset, absolutePath),
    };

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
  assert(xcrunResult.exitCode == 0);
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
