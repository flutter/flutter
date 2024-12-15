// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart';

import '../../../android/android_sdk.dart';
import '../../../android/gradle_utils.dart';
import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../build_info.dart' hide BuildMode;
import '../../../globals.dart' as globals;

int targetAndroidNdkApi(Map<String, String> environmentDefines) {
  return int.parse(environmentDefines[kMinSdkVersion] ?? minSdkVersion);
}

Future<void> copyNativeCodeAssetsAndroid(
  Uri buildUri,
  Map<NativeCodeAssetImpl, KernelAsset> assetTargetLocations,
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
    for (final MapEntry<NativeCodeAssetImpl, KernelAsset> assetMapping
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
Target getNativeAndroidTarget(AndroidArch androidArch) {
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

Map<NativeCodeAssetImpl, KernelAsset> assetTargetLocationsAndroid(
    List<NativeCodeAssetImpl> nativeAssets) {
  return <NativeCodeAssetImpl, KernelAsset>{
    for (final NativeCodeAssetImpl asset in nativeAssets)
      asset: _targetLocationAndroid(asset),
  };
}

/// Converts the `path` of [asset] as output from a `build.dart` invocation to
/// the path used inside the Flutter app bundle.
KernelAsset _targetLocationAndroid(NativeCodeAssetImpl asset) {
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
