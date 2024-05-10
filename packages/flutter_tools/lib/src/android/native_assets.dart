// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    show BuildResult, DryRunResult;
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../native_assets.dart';
import 'android_sdk.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file.
Future<Uri?> dryRunNativeAssetsAndroid({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
}) async {
  if (!await nativeBuildRequired(buildRunner)) {
    return null;
  }

  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, OS.android);
  final Iterable<Asset> nativeAssetPaths =
      await dryRunNativeAssetsAndroidInternal(
    fileSystem,
    projectUri,
    buildRunner,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    nativeAssetPaths,
    buildUri_,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<Asset>> dryRunNativeAssetsAndroidInternal(
  FileSystem fileSystem,
  Uri projectUri,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OS targetOS = OS.android;

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
  final Map<Asset, Asset> assetTargetLocations =
      _assetTargetLocations(nativeAssets);
  final Iterable<Asset> nativeAssetPaths = assetTargetLocations.values;
  return nativeAssetPaths;
}

/// Builds native assets.
Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)>
    buildNativeAssetsAndroid({
  required NativeAssetsBuildRunner buildRunner,
  required Iterable<AndroidArch> androidArchs,
  required Uri projectUri,
  required BuildMode buildMode,
  String? codesignIdentity,
  Uri? yamlParentDirectory,
  required FileSystem fileSystem,
  required int targetAndroidNdkApi,
  bool isAndroidLibrary = false,
}) async {
  const OS targetOS = OS.android;
  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, targetOS);
  if (!await nativeBuildRequired(buildRunner)) {
    final Uri nativeAssetsYaml = await writeNativeAssetsYaml(
      <Asset>[],
      yamlParentDirectory ?? buildUri_,
      fileSystem,
    );
    return (nativeAssetsYaml, <Uri>[]);
  }

  final List<Target> targets = androidArchs.map(_getNativeTarget).toList();
  final native_assets_cli.BuildMode buildModeCli =
      nativeAssetsBuildMode(buildMode);

  globals.logger
      .printTrace('Building native assets for $targets $buildModeCli.');
  final List<Asset> nativeAssets = <Asset>[];
  final Set<Uri> dependencies = <Uri>{};
  for (final Target target in targets) {
    final BuildResult result = await buildRunner.build(
      linkModePreference: LinkModePreference.dynamic,
      target: target,
      buildMode: buildModeCli,
      workingDirectory: projectUri,
      includeParentEnvironment: true,
      cCompilerConfig: await buildRunner.ndkCCompilerConfig,
      targetAndroidNdkApi: targetAndroidNdkApi,
    );
    ensureNativeAssetsBuildSucceed(result);
    nativeAssets.addAll(result.assets);
    dependencies.addAll(result.dependencies);
  }
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $targets done.');
  if (isAndroidLibrary && nativeAssets.isNotEmpty) {
    throwToolExit('Native assets are not yet supported in Android add2app.');
  }
  final Map<Asset, Asset> assetTargetLocations =
      _assetTargetLocations(nativeAssets);
  await _copyNativeAssetsAndroid(buildUri_, assetTargetLocations, fileSystem);
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
      assetTargetLocations.values,
      yamlParentDirectory ?? buildUri_,
      fileSystem);
  return (nativeAssetsUri, dependencies.toList());
}

Future<void> _copyNativeAssetsAndroid(
  Uri buildUri,
  Map<Asset, Asset> assetTargetLocations,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger
        .printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    final List<String> jniArchDirs = <String>[
      for (final AndroidArch androidArch in AndroidArch.values)
        androidArch.archName,
    ];
    for (final String jniArchDir in jniArchDirs) {
      final Uri archUri = buildUri.resolve('jniLibs/lib/$jniArchDir/');
      await fileSystem.directory(archUri).create(recursive: true);
    }
    for (final MapEntry<Asset, Asset> assetMapping
        in assetTargetLocations.entries) {
      final Uri source = (assetMapping.key.path as AssetAbsolutePath).uri;
      final Uri target = (assetMapping.value.path as AssetAbsolutePath).uri;
      final AndroidArch androidArch =
          _getAndroidArch(assetMapping.value.target);
      final String jniArchDir = androidArch.archName;
      final Uri archUri = buildUri.resolve('jniLibs/lib/$jniArchDir/');
      final Uri targetUri = archUri.resolveUri(target);
      final String targetFullPath = targetUri.toFilePath();
      await fileSystem.file(source).copy(targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

/// Get the [Target] for [androidArch].
Target _getNativeTarget(AndroidArch androidArch) {
  switch (androidArch) {
    case AndroidArch.armeabi_v7a:
      return Target.androidArm;
    case AndroidArch.arm64_v8a:
      return Target.androidArm64;
    case AndroidArch.x86:
      return Target.androidIA32;
    case AndroidArch.x86_64:
      return Target.androidX64;
  }
}

/// Get the [AndroidArch] for [target].
AndroidArch _getAndroidArch(Target target) {
  switch (target) {
    case Target.androidArm:
      return AndroidArch.armeabi_v7a;
    case Target.androidArm64:
      return AndroidArch.arm64_v8a;
    case Target.androidIA32:
      return AndroidArch.x86;
    case Target.androidX64:
      return AndroidArch.x86_64;
    case Target.androidRiscv64:
      throwToolExit('Android RISC-V not yet supported.');
    default:
      throwToolExit('Invalid target: $target.');
  }
}

Map<Asset, Asset> _assetTargetLocations(List<Asset> nativeAssets) {
  return <Asset, Asset>{
    for (final Asset asset in nativeAssets)
      asset: _targetLocationAndroid(asset),
  };
}

/// Converts the `path` of [asset] as output from a `build.dart` invocation to
/// the path used inside the Flutter app bundle.
Asset _targetLocationAndroid(Asset asset) {
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
  throw Exception(
    'Unsupported asset path type ${path.runtimeType} in asset $asset',
  );
}

/// Looks the NDK clang compiler tools.
///
/// Tool-exits if the NDK cannot be found.
///
/// Should only be invoked if a native assets build is performed. If the native
/// assets feature is disabled, or none of the packages have native assets, a
/// missing NDK is okay.
@override
Future<CCompilerConfig> cCompilerConfigAndroid() async {
  final AndroidSdk? androidSdk = AndroidSdk.locateAndroidSdk();
  if (androidSdk == null) {
    throwToolExit('Android SDK could not be found.');
  }
  final CCompilerConfig result = CCompilerConfig(
    cc: _toOptionalFileUri(androidSdk.getNdkClangPath()),
    ar: _toOptionalFileUri(androidSdk.getNdkArPath()),
    ld: _toOptionalFileUri(androidSdk.getNdkLdPath()),
  );
  if (result.cc == null || result.ar == null || result.ld == null) {
    throwToolExit('Android NDK Clang could not be found.');
  }
  return result;
}

Uri? _toOptionalFileUri(String? string) {
  if (string == null) {
    return null;
  }
  return Uri.file(string);
}
