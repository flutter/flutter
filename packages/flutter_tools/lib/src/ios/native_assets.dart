// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart' show BuildResult;
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;

import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart' as globals;

import '../macos/native_assets_host.dart';
import '../native_assets.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file and
/// the Xcode project.
Future<Uri?> dryRunNativeAssetsIOS({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  required FileSystem fileSystem,
}) async {
  if (!await nativeBuildRequired(buildRunner)) {
    return null;
  }

  final Uri buildUri = nativeAssetsBuildUri(projectUri, OS.iOS);
  final Iterable<Asset> assetTargetLocations = await dryRunNativeAssetsIOSInternal(
    fileSystem,
    projectUri,
    buildRunner,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    assetTargetLocations,
    buildUri,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<Asset>> dryRunNativeAssetsIOSInternal(
  FileSystem fileSystem,
  Uri projectUri,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OS targetOS = OS.iOS;
  globals.logger.printTrace('Dry running native assets for $targetOS.');
  final List<Asset> nativeAssets = (await buildRunner.dryRun(
    linkModePreference: LinkModePreference.dynamic,
    targetOS: targetOS,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
  ))
      .assets;
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Dry running native assets for $targetOS done.');
  final Iterable<Asset> assetTargetLocations = _assetTargetLocations(nativeAssets).values;
  return assetTargetLocations;
}

/// Builds native assets.
Future<List<Uri>> buildNativeAssetsIOS({
  required NativeAssetsBuildRunner buildRunner,
  required List<DarwinArch> darwinArchs,
  required EnvironmentType environmentType,
  required Uri projectUri,
  required BuildMode buildMode,
  String? codesignIdentity,
  required Uri yamlParentDirectory,
  required FileSystem fileSystem,
}) async {
  if (!await nativeBuildRequired(buildRunner)) {
    await writeNativeAssetsYaml(<Asset>[], yamlParentDirectory, fileSystem);
    return <Uri>[];
  }

  final List<Target> targets = darwinArchs.map(_getNativeTarget).toList();
  final native_assets_cli.BuildMode buildModeCli = nativeAssetsBuildMode(buildMode);

  const OS targetOS = OS.iOS;
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);
  final IOSSdk iosSdk = _getIOSSdk(environmentType);

  globals.logger.printTrace('Building native assets for $targets $buildModeCli.');
  final List<Asset> nativeAssets = <Asset>[];
  final Set<Uri> dependencies = <Uri>{};
  for (final Target target in targets) {
    final BuildResult result = await buildRunner.build(
      linkModePreference: LinkModePreference.dynamic,
      target: target,
      targetIOSSdk: iosSdk,
      buildMode: buildModeCli,
      workingDirectory: projectUri,
      includeParentEnvironment: true,
      cCompilerConfig: await buildRunner.cCompilerConfig,
    );
    nativeAssets.addAll(result.assets);
    dependencies.addAll(result.dependencies);
  }
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $targets done.');
  final Map<AssetPath, List<Asset>> fatAssetTargetLocations = _fatAssetTargetLocations(nativeAssets);
  await copyNativeAssetsMacOSHost(
    buildUri,
    fatAssetTargetLocations,
    codesignIdentity,
    buildMode,
    fileSystem,
  );

  final Map<Asset, Asset> assetTargetLocations = _assetTargetLocations(nativeAssets);
  await writeNativeAssetsYaml(
    assetTargetLocations.values,
    yamlParentDirectory,
    fileSystem,
  );
  return dependencies.toList();
}

IOSSdk _getIOSSdk(EnvironmentType environmentType) {
  switch (environmentType) {
    case EnvironmentType.physical:
      return IOSSdk.iPhoneOs;
    case EnvironmentType.simulator:
      return IOSSdk.iPhoneSimulator;
  }
}

/// Extract the [Target] from a [DarwinArch].
Target _getNativeTarget(DarwinArch darwinArch) {
  switch (darwinArch) {
    case DarwinArch.armv7:
      return Target.iOSArm;
    case DarwinArch.arm64:
      return Target.iOSArm64;
    case DarwinArch.x86_64:
      return Target.iOSX64;
  }
}

Map<AssetPath, List<Asset>> _fatAssetTargetLocations(List<Asset> nativeAssets) {
  final Map<AssetPath, List<Asset>> result = <AssetPath, List<Asset>>{};
  for (final Asset asset in nativeAssets) {
    final AssetPath path = _targetLocationIOS(asset).path;
    result[path] ??= <Asset>[];
    result[path]!.add(asset);
  }
  return result;
}

Map<Asset, Asset> _assetTargetLocations(List<Asset> nativeAssets) => <Asset, Asset>{
  for (final Asset asset in nativeAssets)
    asset: _targetLocationIOS(asset),
};

Asset _targetLocationIOS(Asset asset) {
  final AssetPath path = asset.path;
  switch (path) {
    case AssetSystemPath _:
    case AssetInExecutable _:
    case AssetInProcess _:
      return asset;
    case AssetAbsolutePath _:
      final String fileName = path.uri.pathSegments.last;
      return asset.copyWith(path: AssetAbsolutePath(Uri(path: fileName)));
  }
  throw Exception('Unsupported asset path type ${path.runtimeType} in asset $asset');
}
