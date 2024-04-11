// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    hide NativeAssetsBuildRunner;
import 'package:native_assets_cli/native_assets_cli_internal.dart';

import '../../../android/android_sdk.dart';
import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;
import '../native_assets.dart';

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

  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, OSImpl.android);
  final Iterable<KernelAsset> nativeAssetPaths =
      await dryRunNativeAssetsAndroidInternal(
    fileSystem,
    projectUri,
    buildRunner,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    KernelAssets(nativeAssetPaths),
    buildUri_,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<KernelAsset>> dryRunNativeAssetsAndroidInternal(
  FileSystem fileSystem,
  Uri projectUri,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OSImpl targetOS = OSImpl.android;

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
  final Map<AssetImpl, KernelAsset> assetTargetLocations =
      _assetTargetLocations(nativeAssets);
  return assetTargetLocations.values;
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
}) async {
  const OSImpl targetOS = OSImpl.android;
  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, targetOS);
  if (!await nativeBuildRequired(buildRunner)) {
    final Uri nativeAssetsYaml = await writeNativeAssetsYaml(
      KernelAssets(),
      yamlParentDirectory ?? buildUri_,
      fileSystem,
    );
    return (nativeAssetsYaml, <Uri>[]);
  }

  final List<Target> targets = androidArchs.map(_getNativeTarget).toList();
  final BuildModeImpl buildModeCli =
      nativeAssetsBuildMode(buildMode);

  globals.logger
      .printTrace('Building native assets for $targets $buildModeCli.');
  final List<AssetImpl> nativeAssets = <AssetImpl>[];
  final Set<Uri> dependencies = <Uri>{};
  for (final Target target in targets) {
    final BuildResult result = await buildRunner.build(
      linkModePreference: LinkModePreferenceImpl.dynamic,
      target: target,
      buildMode: buildModeCli,
      workingDirectory: projectUri,
      includeParentEnvironment: true,
      cCompilerConfig: await buildRunner.ndkCCompilerConfigImpl,
      targetAndroidNdkApi: targetAndroidNdkApi,
    );
    ensureNativeAssetsBuildSucceed(result);
    nativeAssets.addAll(result.assets);
    dependencies.addAll(result.dependencies);
  }
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $targets done.');
  final Map<AssetImpl, KernelAsset> assetTargetLocations =
      _assetTargetLocations(nativeAssets);
  await _copyNativeAssetsAndroid(buildUri_, assetTargetLocations, fileSystem);
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
      KernelAssets(assetTargetLocations.values),
      yamlParentDirectory ?? buildUri_,
      fileSystem);
  return (nativeAssetsUri, dependencies.toList());
}

Future<void> _copyNativeAssetsAndroid(
  Uri buildUri,
  Map<AssetImpl, KernelAsset> assetTargetLocations,
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
    for (final MapEntry<AssetImpl, KernelAsset> assetMapping
        in assetTargetLocations.entries) {
      final Uri source = assetMapping.key.file!;
      final Uri target = (assetMapping.value.path as KernelAssetAbsolutePath).uri;
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
  return switch (androidArch) {
    AndroidArch.armeabi_v7a => Target.androidArm,
    AndroidArch.arm64_v8a   => Target.androidArm64,
    AndroidArch.x86         => Target.androidIA32,
    AndroidArch.x86_64      => Target.androidX64,
  };
}

/// Get the [AndroidArch] for [target].
AndroidArch _getAndroidArch(Target target) {
  return switch (target) {
    Target.androidArm   => AndroidArch.armeabi_v7a,
    Target.androidArm64 => AndroidArch.arm64_v8a,
    Target.androidIA32  => AndroidArch.x86,
    Target.androidX64   => AndroidArch.x86_64,
    Target.androidRiscv64 => throwToolExit('Android RISC-V not yet supported.'),
    _ => throwToolExit('Invalid target: $target.'),
  };
}

Map<AssetImpl, KernelAsset> _assetTargetLocations(
    List<AssetImpl> nativeAssets) {
  return <AssetImpl, KernelAsset>{
    for (final AssetImpl asset in nativeAssets)
      asset: _targetLocationAndroid(asset),
  };
}

/// Converts the `path` of [asset] as output from a `build.dart` invocation to
/// the path used inside the Flutter app bundle.
KernelAsset _targetLocationAndroid(AssetImpl asset) {
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
      kernelAssetPath = KernelAssetAbsolutePath(Uri(path: fileName));
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

/// Looks the NDK clang compiler tools.
///
/// Tool-exits if the NDK cannot be found.
///
/// Should only be invoked if a native assets build is performed. If the native
/// assets feature is disabled, or none of the packages have native assets, a
/// missing NDK is okay.
@override
Future<CCompilerConfigImpl> cCompilerConfigAndroid() async {
  final AndroidSdk? androidSdk = AndroidSdk.locateAndroidSdk();
  if (androidSdk == null) {
    throwToolExit('Android SDK could not be found.');
  }
  final CCompilerConfigImpl result = CCompilerConfigImpl(
    compiler: _toOptionalFileUri(androidSdk.getNdkClangPath()),
    archiver: _toOptionalFileUri(androidSdk.getNdkArPath()),
    linker: _toOptionalFileUri(androidSdk.getNdkLdPath()),
  );
  if (result.compiler == null ||
      result.archiver == null ||
      result.linker == null) {
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
