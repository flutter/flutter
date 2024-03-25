// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    hide NativeAssetsBuildRunner;
import 'package:native_assets_cli/native_assets_cli_internal.dart';

import '../../../base/file_system.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;

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

  final Uri buildUri = nativeAssetsBuildUri(projectUri, OSImpl.iOS);
  final Iterable<KernelAsset> assetTargetLocations = await dryRunNativeAssetsIOSInternal(
    fileSystem,
    projectUri,
    buildRunner,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    KernelAssets(assetTargetLocations),
    buildUri,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<KernelAsset>> dryRunNativeAssetsIOSInternal(
  FileSystem fileSystem,
  Uri projectUri,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OSImpl targetOS = OSImpl.iOS;
  globals.logger.printTrace('Dry running native assets for $targetOS.');
  final DryRunResult dryRunResult = await buildRunner.dryRun(
    linkModePreference: LinkModePreferenceImpl.dynamic,
    targetOS: targetOS,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
  );
  ensureNativeAssetsBuildSucceed(dryRunResult);
  final List<AssetImpl> nativeAssets = dryRunResult.assets;
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Dry running native assets for $targetOS done.');
  return _assetTargetLocations(nativeAssets).values;
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
    await writeNativeAssetsYaml(KernelAssets(), yamlParentDirectory, fileSystem);
    return <Uri>[];
  }

  final List<Target> targets = darwinArchs.map(_getNativeTarget).toList();
  final BuildModeImpl buildModeCli = nativeAssetsBuildMode(buildMode);

  const OSImpl targetOS = OSImpl.iOS;
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);
  final IOSSdkImpl iosSdk = _getIOSSdkImpl(environmentType);

  globals.logger.printTrace('Building native assets for $targets $buildModeCli.');
  final List<AssetImpl> nativeAssets = <AssetImpl>[];
  final Set<Uri> dependencies = <Uri>{};
  for (final Target target in targets) {
    final BuildResult result = await buildRunner.build(
      linkModePreference: LinkModePreferenceImpl.dynamic,
      target: target,
      targetIOSSdkImpl: iosSdk,
      buildMode: buildModeCli,
      workingDirectory: projectUri,
      includeParentEnvironment: true,
      cCompilerConfig: await buildRunner.cCompilerConfig,
    );
    ensureNativeAssetsBuildSucceed(result);
    nativeAssets.addAll(result.assets);
    dependencies.addAll(result.dependencies);
  }
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $targets done.');
  final Map<KernelAssetPath, List<AssetImpl>> fatAssetTargetLocations =
      _fatAssetTargetLocations(nativeAssets);
  await _copyNativeAssetsIOS(
    buildUri,
    fatAssetTargetLocations,
    codesignIdentity,
    buildMode,
    fileSystem,
  );

  final Map<AssetImpl, KernelAsset> assetTargetLocations =
      _assetTargetLocations(nativeAssets);
  await writeNativeAssetsYaml(
    KernelAssets(assetTargetLocations.values),
    yamlParentDirectory,
    fileSystem,
  );
  return dependencies.toList();
}

IOSSdkImpl _getIOSSdkImpl(EnvironmentType environmentType) {
  switch (environmentType) {
    case EnvironmentType.physical:
      return IOSSdkImpl.iPhoneOS;
    case EnvironmentType.simulator:
      return IOSSdkImpl.iPhoneSimulator;
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

Map<KernelAssetPath, List<AssetImpl>> _fatAssetTargetLocations(
    List<AssetImpl> nativeAssets) {
  final Set<String> alreadyTakenNames = <String>{};
  final Map<KernelAssetPath, List<AssetImpl>> result =
      <KernelAssetPath, List<AssetImpl>>{};
  final Map<String, KernelAssetPath> idToPath = <String, KernelAssetPath>{};
  for (final AssetImpl asset in nativeAssets) {
    // Use same target path for all assets with the same id.
    final KernelAssetPath path = idToPath[asset.id] ??
        _targetLocationIOS(
          asset,
          alreadyTakenNames,
        ).path;
    idToPath[asset.id] = path;
    result[path] ??= <AssetImpl>[];
    result[path]!.add(asset);
  }
  return result;
}

Map<AssetImpl, KernelAsset> _assetTargetLocations(
    List<AssetImpl> nativeAssets) {
  final Set<String> alreadyTakenNames = <String>{};
  return <AssetImpl, KernelAsset>{
    for (final AssetImpl asset in nativeAssets)
      asset: _targetLocationIOS(asset, alreadyTakenNames),
  };
}

KernelAsset _targetLocationIOS(AssetImpl asset, Set<String> alreadyTakenNames) {
  final LinkModeImpl linkMode = (asset as NativeCodeAssetImpl).linkMode;
final KernelAssetPath kernelAssetPath;
  switch (linkMode) {
    case DynamicLoadingSystemImpl _:
      kernelAssetPath = KernelAssetSystemPath(linkMode.uri);
    case LookupInExecutableImpl _:
      kernelAssetPath = KernelAssetInExecutable();
    case LookupInProcessImpl _:
      kernelAssetPath = KernelAssetInProcess();
    case DynamicLoadingBundledImpl _:
      final String fileName = asset.file!.pathSegments.last;
      kernelAssetPath = KernelAssetAbsolutePath(frameworkUri(
        fileName,
        alreadyTakenNames,
      ));
    default:
      throw Exception(
        'Unsupported asset link mode $linkMode in asset $asset',
      );
  }
  return KernelAsset(
    id: asset.id,
    target: Target.fromArchitectureAndOS(asset.architecture!, asset.os),
    path: kernelAssetPath,
  );
}

/// Copies native assets into a framework per dynamic library.
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// The install name is set so that it matches what the place it will
/// be bundled in the final app.
///
/// Code signing is also done here, so that it doesn't have to be done in
/// in xcode_backend.dart.
Future<void> _copyNativeAssetsIOS(
  Uri buildUri,
  Map<KernelAssetPath, List<AssetImpl>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger
        .printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    for (final MapEntry<KernelAssetPath, List<AssetImpl>> assetMapping
        in assetTargetLocations.entries) {
      final Uri target = (assetMapping.key as KernelAssetAbsolutePath).uri;
      final List<Uri> sources = <Uri>[
        for (final AssetImpl source in assetMapping.value) source.file!
      ];
      final Uri targetUri = buildUri.resolveUri(target);
      final File dylibFile = fileSystem.file(targetUri);
      final Directory frameworkDir = dylibFile.parent;
      if (!await frameworkDir.exists()) {
        await frameworkDir.create(recursive: true);
      }
      await lipoDylibs(dylibFile, sources);
      await setInstallNameDylib(dylibFile);
      await createInfoPlist(targetUri.pathSegments.last, frameworkDir);
      await codesignDylib(codesignIdentity, buildMode, frameworkDir);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}
