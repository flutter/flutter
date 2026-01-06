// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:hooks_runner/hooks_runner.dart';

import '../../../android/android_sdk.dart';
import '../../../android/gradle_utils.dart';
import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../build_info.dart';
import '../native_assets.dart';

int targetAndroidNdkApi(Map<String, String> environmentDefines) {
  return int.parse(environmentDefines[kMinSdkVersion] ?? minSdkVersion);
}

Future<void> copyNativeCodeAssetsAndroid(
  Uri buildUri,
  Map<FlutterCodeAsset, KernelAsset> assetTargetLocations,
  FileSystem fileSystem,
) async {
  assert(assetTargetLocations.isNotEmpty);
  final jniArchDirs = <String>[
    for (final AndroidArch androidArch in AndroidArch.values) androidArch.archName,
  ];
  for (final jniArchDir in jniArchDirs) {
    final Uri archUri = buildUri.resolve('jniLibs/lib/$jniArchDir/');
    await fileSystem.directory(archUri).create(recursive: true);
  }
  for (final MapEntry<FlutterCodeAsset, KernelAsset> assetMapping in assetTargetLocations.entries) {
    final Uri source = assetMapping.key.codeAsset.file!;
    final Uri target = (assetMapping.value.path as KernelAssetAbsolutePath).uri;
    final AndroidArch androidArch = _getAndroidArch(assetMapping.value.target.architecture);
    final String jniArchDir = androidArch.archName;
    final Uri archUri = buildUri.resolve('jniLibs/lib/$jniArchDir/');
    final Uri targetUri = archUri.resolveUri(target);
    final String targetFullPath = targetUri.toFilePath();
    await fileSystem.file(source).copy(targetFullPath);
  }
}

/// Get the [Architecture] for [androidArch].
Architecture getNativeAndroidArchitecture(AndroidArch androidArch) {
  return switch (androidArch) {
    AndroidArch.armeabi_v7a => Architecture.arm,
    AndroidArch.arm64_v8a => Architecture.arm64,
    AndroidArch.x86_64 => Architecture.x64,
  };
}

/// Get the [AndroidArch] for [architecture].
AndroidArch _getAndroidArch(Architecture architecture) {
  return switch (architecture) {
    Architecture.arm => AndroidArch.armeabi_v7a,
    Architecture.arm64 => AndroidArch.arm64_v8a,
    Architecture.x64 => AndroidArch.x86_64,
    Architecture.riscv64 => throwToolExit('Android RISC-V not yet supported.'),
    _ => throwToolExit('Invalid architecture: $architecture.'),
  };
}

Map<FlutterCodeAsset, KernelAsset> assetTargetLocationsAndroid(
  List<FlutterCodeAsset> nativeAssets,
) {
  return <FlutterCodeAsset, KernelAsset>{
    for (final FlutterCodeAsset asset in nativeAssets) asset: _targetLocationAndroid(asset),
  };
}

/// Converts the `path` of [asset] as output from a `build.dart` invocation to
/// the path used inside the Flutter app bundle.
KernelAsset _targetLocationAndroid(FlutterCodeAsset asset) {
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
      kernelAssetPath = KernelAssetAbsolutePath(Uri(path: fileName));
    default:
      throw Exception('Unsupported asset link mode $linkMode in asset $asset');
  }
  return KernelAsset(id: asset.codeAsset.id, target: asset.target, path: kernelAssetPath);
}

/// Looks the NDK clang compiler tools.
///
/// Returns `null` if the NDK cannot be found.
///
/// Typically the Flutter Gradle Plugin will install an NDK. This method will
/// return the newest NDK if multiple NDKs are found on the system.
Future<CCompilerConfig?> cCompilerConfigAndroid() async {
  final AndroidSdk? androidSdk = AndroidSdk.locateAndroidSdk();
  if (androidSdk == null) {
    throwToolExit('Android SDK could not be found.');
  }
  final Uri? compiler = _toOptionalFileUri(androidSdk.getNdkClangPath());
  final Uri? archiver = _toOptionalFileUri(androidSdk.getNdkArPath());
  final Uri? linker = _toOptionalFileUri(androidSdk.getNdkLdPath());
  if (compiler == null || archiver == null || linker == null) {
    return null;
  }
  final result = CCompilerConfig(compiler: compiler, archiver: archiver, linker: linker);
  return result;
}

Uri? _toOptionalFileUri(String? string) {
  if (string == null) {
    return null;
  }
  return Uri.file(string);
}
