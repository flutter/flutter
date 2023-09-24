// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart' show BuildResult;
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../native_assets.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file.
Future<Uri?> dryRunNativeAssetsLinux({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
}) async {
  if (await hasNoPackageConfig(buildRunner) || await isDisabledAndNoNativeAssets(buildRunner)) {
    return null;
  }

  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, OS.linux);
  final Iterable<Asset> nativeAssetPaths = await dryRunNativeAssetsLinuxInternal(
    fileSystem,
    projectUri,
    flutterTester,
    buildRunner,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    nativeAssetPaths,
    buildUri_,
    fileSystem,
  );
  return nativeAssetsUri;
}

Future<Iterable<Asset>> dryRunNativeAssetsLinuxInternal(
  FileSystem fileSystem,
  Uri projectUri,
  bool flutterTester,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OS targetOs = OS.linux;
  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, targetOs);

  globals.logger.printTrace('Dry running native assets for $targetOs.');
  final List<Asset> nativeAssets = (await buildRunner.dryRun(
    linkModePreference: LinkModePreference.dynamic,
    targetOs: targetOs,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
  ))
      .assets;
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Dry running native assets for $targetOs done.');
  final Uri? absolutePath = flutterTester ? buildUri_ : null;
  final Map<Asset, Asset> assetTargetLocations = _assetTargetLocations(nativeAssets, absolutePath);
  final Iterable<Asset> nativeAssetPaths = assetTargetLocations.values;
  return nativeAssetPaths;
}

/// Builds native assets.
///
/// If [targetPlatform] is omitted, the current target architecture is used.
///
/// If [flutterTester] is true, absolute paths are emitted in the native
/// assets mapping. This can be used for JIT mode without sandbox on the host.
/// This is used in `flutter test` and `flutter run -d flutter-tester`.
Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)> buildNativeAssetsLinux({
  required NativeAssetsBuildRunner buildRunner,
  TargetPlatform? targetPlatform,
  required Uri projectUri,
  required BuildMode buildMode,
  bool flutterTester = false,
  Uri? yamlParentDirectory,
  required FileSystem fileSystem,
}) async {
  const OS targetOs = OS.linux;
  final Uri buildUri_ = nativeAssetsBuildUri(projectUri, targetOs);
  final Directory buildDir = fileSystem.directory(buildUri_);
  if (!await buildDir.exists()) {
    // CMake requires the folder to exist to do copying.
    await buildDir.create(recursive: true);
  }
  if (await hasNoPackageConfig(buildRunner) || await isDisabledAndNoNativeAssets(buildRunner)) {
    final Uri nativeAssetsYaml = await writeNativeAssetsYaml(<Asset>[], yamlParentDirectory ?? buildUri_, fileSystem);
    return (nativeAssetsYaml, <Uri>[]);
  }

  final Target target = targetPlatform != null ? _getNativeTarget(targetPlatform) : Target.current;
  final native_assets_cli.BuildMode buildModeCli = nativeAssetsBuildMode(buildMode);

  globals.logger.printTrace('Building native assets for $target $buildModeCli.');
  final BuildResult result = await buildRunner.build(
    linkModePreference: LinkModePreference.dynamic,
    target: target,
    buildMode: buildModeCli,
    workingDirectory: projectUri,
    includeParentEnvironment: true,
    cCompilerConfig: await buildRunner.cCompilerConfig,
  );
  final List<Asset> nativeAssets = result.assets;
  final Set<Uri> dependencies = result.dependencies.toSet();
  ensureNoLinkModeStatic(nativeAssets);
  globals.logger.printTrace('Building native assets for $target done.');
  final Uri? absolutePath = flutterTester ? buildUri_ : null;
  final Map<Asset, Asset> assetTargetLocations = _assetTargetLocations(nativeAssets, absolutePath);
  await _copyNativeAssetsLinux(
    buildUri_,
    assetTargetLocations,
    buildMode,
    fileSystem,
  );
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(
    assetTargetLocations.values,
    yamlParentDirectory ?? buildUri_,
    fileSystem,
  );
  return (nativeAssetsUri, dependencies.toList());
}

Map<Asset, Asset> _assetTargetLocations(
  List<Asset> nativeAssets,
  Uri? absolutePath,
) =>
    <Asset, Asset>{
      for (final Asset asset in nativeAssets) asset: _targetLocationLinux(asset, absolutePath),
    };

Asset _targetLocationLinux(Asset asset, Uri? absolutePath) {
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
  throw Exception('Unsupported asset path type ${path.runtimeType} in asset $asset');
}

/// Extract the [Target] from a [TargetPlatform].
Target _getNativeTarget(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.linux_x64:
      return Target.linuxX64;
    case TargetPlatform.linux_arm64:
      return Target.linuxArm64;
    case TargetPlatform.android:
    case TargetPlatform.ios:
    case TargetPlatform.darwin:
    case TargetPlatform.windows_x64:
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

Future<void> _copyNativeAssetsLinux(
  Uri buildUri,
  Map<Asset, Asset> assetTargetLocations,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
    if (!buildDir.existsSync()) {
      buildDir.createSync(recursive: true);
    }
    for (final MapEntry<Asset, Asset> assetMapping in assetTargetLocations.entries) {
      final Uri source = (assetMapping.key.path as AssetAbsolutePath).uri;
      final Uri target = (assetMapping.value.path as AssetAbsolutePath).uri;
      final Uri targetUri = buildUri.resolveUri(target);
      final String targetFullPath = targetUri.toFilePath();
      await fileSystem.file(source).copy(targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

/// Flutter expects `clang++` to be on the path on Linux hosts.
///
/// Search for the accompanying `clang`, `ar`, and `ld`.
Future<CCompilerConfig> cCompilerConfigLinux() async {
  const String kClangPlusPlusBinary = 'clang++';
  const String kClangBinary = 'clang';
  const String kArBinary = 'llvm-ar';
  const String kLdBinary = 'ld.lld';

  final ProcessResult whichResult = await globals.processManager.run(<String>['which', kClangPlusPlusBinary]);
  if (whichResult.exitCode != 0) {
    throwToolExit('Failed to find $kClangPlusPlusBinary on PATH.');
  }
  File clangPpFile = globals.fs.file((whichResult.stdout as String).trim());
  clangPpFile = globals.fs.file(await clangPpFile.resolveSymbolicLinks());

  final Directory clangDir = clangPpFile.parent;
  final Map<String, Uri> binaryPaths = <String, Uri>{};
  for (final String binary in <String>[kClangBinary, kArBinary, kLdBinary]) {
    final File binaryFile = clangDir.childFile(binary);
    if (!await binaryFile.exists()) {
      throwToolExit("Failed to find $binary relative to $clangPpFile: $binaryFile doesn't exist.");
    }
    binaryPaths[binary] = binaryFile.uri;
  }
  return CCompilerConfig(
    ar: binaryPaths[kArBinary],
    cc: binaryPaths[kClangBinary],
    ld: binaryPaths[kLdBinary],
  );
}
