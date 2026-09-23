// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../android/android_sdk.dart';
import '../../../android/gradle_utils.dart';
import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../build_info.dart';
import '../native_assets.dart';
import '../native_assets_manifest.dart';

int targetAndroidNdkApi(Map<String, String> environmentDefines) {
  return int.parse(environmentDefines[kMinSdkVersion] ?? minSdkVersion);
}

Future<List<File>> copyNativeCodeAssetsAndroid(
  Uri targetUri,
  Map<FlutterCodeAsset, FlutterCodeAssetTargetLocation> assetTargetLocations,
  FileSystem fileSystem,
) async {
  assert(assetTargetLocations.isNotEmpty);
  final installedFiles = <File>[];
  final jniArchDirs = <String>[
    for (final CpuArch cpuArch in <CpuArch>[CpuArch.armv7, CpuArch.arm64, CpuArch.x64])
      cpuArch.androidArchName,
  ];
  for (final jniArchDir in jniArchDirs) {
    final Uri archUri = targetUri.resolve('jniLibs/lib/$jniArchDir/');
    await fileSystem.directory(archUri).create(recursive: true);
  }
  for (final MapEntry<FlutterCodeAsset, FlutterCodeAssetTargetLocation> assetMapping
      in assetTargetLocations.entries) {
    final Uri source = assetMapping.key.codeAsset.file!;
    final Uri target = assetMapping.value.bundlePath!;
    final CpuArch cpuArch = _getAndroidArch(assetMapping.key.architecture);
    final String jniArchDir = cpuArch.androidArchName;
    final Uri archUri = targetUri.resolve('jniLibs/lib/$jniArchDir/');
    final Uri assetTargetUri = archUri.resolveUri(target);
    final String targetFullPath = assetTargetUri.toFilePath();
    final File installedFile = await fileSystem.file(source).copy(targetFullPath);
    installedFiles.add(installedFile);
  }
  return installedFiles;
}

/// Get the [Architecture] for [cpuArch].
Architecture getNativeAndroidArchitecture(CpuArch cpuArch) {
  return switch (cpuArch) {
    CpuArch.armv7 => Architecture.arm,
    CpuArch.arm64 => Architecture.arm64,
    CpuArch.x64 => Architecture.x64,
    CpuArch.x86 ||
    CpuArch.riscv64 ||
    CpuArch.unknown => throwToolExit('Invalid Android arch: $cpuArch.'),
  };
}

/// Get the [CpuArch] for [architecture].
CpuArch _getAndroidArch(Architecture architecture) {
  return switch (architecture) {
    Architecture.arm => CpuArch.armv7,
    Architecture.arm64 => CpuArch.arm64,
    Architecture.x64 => CpuArch.x64,
    Architecture.riscv64 => throwToolExit('Android RISC-V not yet supported.'),
    _ => throwToolExit('Invalid architecture: $architecture.'),
  };
}

Map<FlutterCodeAsset, FlutterCodeAssetTargetLocation> assetTargetLocationsAndroid(
  List<FlutterCodeAsset> nativeAssets,
) {
  return <FlutterCodeAsset, FlutterCodeAssetTargetLocation>{
    for (final FlutterCodeAsset asset in nativeAssets)
      asset: targetLocationForCodeAsset(asset, (FlutterCodeAsset asset) {
        final String fileName = asset.codeAsset.file!.pathSegments.last;
        final uri = Uri(path: fileName);
        return FlutterCodeAssetTargetLocation(
          runtimePath: NativeAssetAbsolutePath(fileName),
          bundlePath: uri,
        );
      }),
  };
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
