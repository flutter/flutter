// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    show BuildResult, DryRunResult;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide BuildMode;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    as native_assets_cli;

import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../native_assets.dart';
import 'native_assets_host.dart';

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
  if (!await nativeBuildRequired(buildRunner)) {
    return null;
  }

  final Uri buildUri = nativeAssetsBuildUri(projectUri, OS.macOS);
  final Iterable<Asset> nativeAssetPaths = await dryRunNativeAssetsMacOSInternal(fileSystem, projectUri, flutterTester, buildRunner);
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(nativeAssetPaths, buildUri, fileSystem);
  return nativeAssetsUri;
}

Future<Iterable<Asset>> dryRunNativeAssetsMacOSInternal(
  FileSystem fileSystem,
  Uri projectUri,
  bool flutterTester,
  NativeAssetsBuildRunner buildRunner,
) async {
  const OS targetOS = OS.macOS;
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);

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
  final Uri? absolutePath = flutterTester ? buildUri : null;
  final Map<Asset, Asset> assetTargetLocations = _assetTargetLocations(nativeAssets, absolutePath);
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
Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)> buildNativeAssetsMacOS({
  required NativeAssetsBuildRunner buildRunner,
  List<DarwinArch>? darwinArchs,
  required Uri projectUri,
  required BuildMode buildMode,
  bool flutterTester = false,
  String? codesignIdentity,
  Uri? yamlParentDirectory,
  required FileSystem fileSystem,
}) async {
  const OS targetOS = OS.macOS;
  final Uri buildUri = nativeAssetsBuildUri(projectUri, targetOS);
  if (!await nativeBuildRequired(buildRunner)) {
    final Uri nativeAssetsYaml = await writeNativeAssetsYaml(<Asset>[], yamlParentDirectory ?? buildUri, fileSystem);
    return (nativeAssetsYaml, <Uri>[]);
  }

  final List<Target> targets = darwinArchs != null ? darwinArchs.map(_getNativeTarget).toList() : <Target>[Target.current];
  final native_assets_cli.BuildMode buildModeCli = nativeAssetsBuildMode(buildMode);

  globals.logger.printTrace('Building native assets for $targets $buildModeCli.');
  final List<Asset> nativeAssets = <Asset>[];
  final Set<Uri> dependencies = <Uri>{};
  for (final Target target in targets) {
    final BuildResult result = await buildRunner.build(
      linkModePreference: LinkModePreference.dynamic,
      target: target,
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
  final Uri? absolutePath = flutterTester ? buildUri : null;
  final Map<Asset, Asset> assetTargetLocations = _assetTargetLocations(nativeAssets, absolutePath);
  final Map<AssetPath, List<Asset>> fatAssetTargetLocations = _fatAssetTargetLocations(nativeAssets, absolutePath);
  if (flutterTester) {
    await _copyNativeAssetsMacOSFlutterTester(
      buildUri,
      fatAssetTargetLocations,
      codesignIdentity,
      buildMode,
      fileSystem,
    );
  } else {
    await _copyNativeAssetsMacOS(
      buildUri,
      fatAssetTargetLocations,
      codesignIdentity,
      buildMode,
      fileSystem,
    );
  }
  final Uri nativeAssetsUri = await writeNativeAssetsYaml(assetTargetLocations.values, yamlParentDirectory ?? buildUri, fileSystem);
  return (nativeAssetsUri, dependencies.toList());
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

Map<AssetPath, List<Asset>> _fatAssetTargetLocations(
  List<Asset> nativeAssets,
  Uri? absolutePath,
) {
  final Set<String> alreadyTakenNames = <String>{};
  final Map<AssetPath, List<Asset>> result = <AssetPath, List<Asset>>{};
  for (final Asset asset in nativeAssets) {
    final AssetPath path = _targetLocationMacOS(
      asset,
      absolutePath,
      alreadyTakenNames,
    ).path;
    result[path] ??= <Asset>[];
    result[path]!.add(asset);
  }
  return result;
}

Map<Asset, Asset> _assetTargetLocations(
  List<Asset> nativeAssets,
  Uri? absolutePath,
) {
  final Set<String> alreadyTakenNames = <String>{};
  return <Asset, Asset>{
    for (final Asset asset in nativeAssets)
      asset: _targetLocationMacOS(asset, absolutePath, alreadyTakenNames),
  };
}

Asset _targetLocationMacOS(
  Asset asset,
  Uri? absolutePath,
  Set<String> alreadyTakenNames,
) {
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
        uri = frameworkUri(fileName, alreadyTakenNames);

      }
      return asset.copyWith(path: AssetAbsolutePath(uri));
  }
  throw Exception('Unsupported asset path type ${path.runtimeType} in asset $asset');
}

/// Copies native assets into a framework per dynamic library.
///
/// The framework contains symlinks according to
/// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// The install name is set so that it matches what the place it will
/// be bundled in the final app.
///
/// Code signing is also done here, so that it doesn't have to be done in
/// in macos_assemble.sh.
Future<void> _copyNativeAssetsMacOS(
  Uri buildUri,
  Map<AssetPath, List<Asset>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    for (final MapEntry<AssetPath, List<Asset>> assetMapping in assetTargetLocations.entries) {
      final Uri target = (assetMapping.key as AssetAbsolutePath).uri;
      final List<Uri> sources = <Uri>[
        for (final Asset source in assetMapping.value)
          (source.path as AssetAbsolutePath).uri,
      ];
      final Uri targetUri = buildUri.resolveUri(target);
      final String name = targetUri.pathSegments.last;
      final Directory frameworkDir = fileSystem.file(targetUri).parent;
      if (await frameworkDir.exists()) {
        await frameworkDir.delete(recursive: true);
      }
      // MyFramework.framework/                           frameworkDir
      //   MyFramework  -> Versions/Current/MyFramework   dylibLink
      //   Resources    -> Versions/Current/Resources     resourcesLink
      //   Versions/                                      versionsDir
      //     A/                                           versionADir
      //       MyFramework                                dylibFile
      //       Resources/                                 resourcesDir
      //         Info.plist
      //     Current  -> A                                currentLink
      final Directory versionsDir = frameworkDir.childDirectory('Versions');
      final Directory versionADir = versionsDir.childDirectory('A');
      final Directory resourcesDir = versionADir.childDirectory('Resources');
      await resourcesDir.create(recursive: true);
      final File dylibFile = versionADir.childFile(name);
      final Link currentLink = versionsDir.childLink('Current');
      await currentLink.create(fileSystem.path.relative(
        versionADir.path,
        from: currentLink.parent.path,
      ));
      final Link resourcesLink = frameworkDir.childLink('Resources');
      await resourcesLink.create(fileSystem.path.relative(
        resourcesDir.path,
        from: resourcesLink.parent.path,
      ));
      await lipoDylibs(dylibFile, sources);
      final Link dylibLink = frameworkDir.childLink(name);
      await dylibLink.create(fileSystem.path.relative(
        versionsDir.childDirectory('Current').childFile(name).path,
        from: dylibLink.parent.path,
      ));
      await setInstallNameDylib(dylibFile);
      await createInfoPlist(name, resourcesDir);
      await codesignDylib(codesignIdentity, buildMode, frameworkDir);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}


/// Copies native assets for flutter tester.
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// In contrast to [_copyNativeAssetsMacOS], it does not set the install name.
///
/// Code signing is also done here.
Future<void> _copyNativeAssetsMacOSFlutterTester(
  Uri buildUri,
  Map<AssetPath, List<Asset>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    for (final MapEntry<AssetPath, List<Asset>> assetMapping in assetTargetLocations.entries) {
      final Uri target = (assetMapping.key as AssetAbsolutePath).uri;
      final List<Uri> sources = <Uri>[
        for (final Asset source in assetMapping.value)
          (source.path as AssetAbsolutePath).uri,
      ];
      final Uri targetUri = buildUri.resolveUri(target);
      final File dylibFile = fileSystem.file(targetUri);
      final Directory targetParent = dylibFile.parent;
      if (!await targetParent.exists()) {
        await targetParent.create(recursive: true);
      }
      await lipoDylibs(dylibFile, sources);
      await codesignDylib(codesignIdentity, buildMode, dylibFile);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}
