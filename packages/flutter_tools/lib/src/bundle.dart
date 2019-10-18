// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/depfile.dart';
import 'build_system/targets/dart.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'globals.dart';
import 'project.dart';

String get defaultMainPath => fs.path.join('lib', 'main.dart');
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultDepfilePath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');

String getDefaultApplicationKernelPath({ @required bool trackWidgetCreation }) {
  return getKernelPathForTransformerOptions(
    fs.path.join(getBuildDirectory(), 'app.dill'),
    trackWidgetCreation: trackWidgetCreation,
  );
}

String getKernelPathForTransformerOptions(
  String path, {
  @required bool trackWidgetCreation,
}) {
  if (trackWidgetCreation) {
    path += '.track.dill';
  }
  return path;
}

const String defaultPrivateKeyPath = 'privatekey.der';

/// Provides a `build` method that builds the bundle.
class BundleBuilder {
  /// Builds the bundle for the given target platform.
  ///
  /// The default `mainPath` is `lib/main.dart`.
  /// The default  `manifestPath` is `pubspec.yaml`
  Future<void> build({
    TargetPlatform platform,
    BuildMode buildMode,
    String mainPath,
    String manifestPath = defaultManifestPath,
    String applicationKernelFilePath,
    String depfilePath,
    String privateKeyPath = defaultPrivateKeyPath,
    String assetDirPath,
    String packagesPath,
    bool precompiledSnapshot = false,
    bool reportLicensedPackages = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    List<String> fileSystemRoots,
    String fileSystemScheme,
  }) async {
    mainPath ??= defaultMainPath;
    depfilePath ??= defaultDepfilePath;
    assetDirPath ??= getAssetBuildDirectory();
    packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
    final FlutterProject flutterProject = FlutterProject.current();
    await buildWithAssemble(
      buildMode: buildMode ?? BuildMode.debug,
      targetPlatform: platform,
      mainPath: mainPath,
      flutterProject: flutterProject,
      outputDir: assetDirPath,
      depfilePath: depfilePath,
      precompiled: precompiledSnapshot,
      trackWidgetCreation: trackWidgetCreation,
    );
    // Work around for flutter_tester placing kernel artifacts in odd places.
    if (applicationKernelFilePath != null) {
      final File outputDill = fs.directory(assetDirPath).childFile('kernel_blob.bin');
      if (outputDill.existsSync()) {
        outputDill.copySync(applicationKernelFilePath);
      }
    }
    return;
  }
}

/// Build an application bundle using flutter assemble.
///
/// This is a temporary shim to migrate the build implementations.
Future<void> buildWithAssemble({
  @required FlutterProject flutterProject,
  @required BuildMode buildMode,
  @required TargetPlatform targetPlatform,
  @required String mainPath,
  @required String outputDir,
  @required String depfilePath,
  @required bool precompiled,
  bool trackWidgetCreation,
}) async {
  // If the precompiled flag was not passed, force us into debug mode.
  buildMode = precompiled ? buildMode : BuildMode.debug;
  final Environment environment = Environment(
    projectDir: flutterProject.directory,
    outputDir: fs.directory(outputDir),
    buildDir: flutterProject.dartTool.childDirectory('flutter_build'),
    defines: <String, String>{
      kTargetFile: mainPath,
      kBuildMode: getNameForBuildMode(buildMode),
      kTargetPlatform: getNameForTargetPlatform(targetPlatform),
      kTrackWidgetCreation: trackWidgetCreation?.toString(),
    },
  );
  final Target target = buildMode == BuildMode.debug
    ? const CopyFlutterBundle()
    : const ReleaseCopyFlutterBundle();
  final BuildResult result = await buildSystem.build(target, environment);

  if (!result.success) {
    for (ExceptionMeasurement measurement in result.exceptions.values) {
      printError(measurement.exception.toString());
      printError(measurement.stackTrace.toString());
    }
    throwToolExit('Failed to build bundle.');
  }
  if (depfilePath != null) {
    final Depfile depfile = Depfile(result.inputFiles, result.outputFiles);
    final File outputDepfile = fs.file(depfilePath);
    if (!outputDepfile.parent.existsSync()) {
      outputDepfile.parent.createSync(recursive: true);
    }
    depfile.writeToFile(outputDepfile);
  }
}

Future<AssetBundle> buildAssets({
  String manifestPath,
  String assetDirPath,
  String packagesPath,
  bool includeDefaultFonts = true,
  bool reportLicensedPackages = false,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);

  // Build the asset bundle.
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    assetDirPath: assetDirPath,
    packagesPath: packagesPath,
    includeDefaultFonts: includeDefaultFonts,
    reportLicensedPackages: reportLicensedPackages,
  );
  if (result != 0) {
    return null;
  }

  return assetBundle;
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, DevFSContent> assetEntries,
) async {
  if (bundleDir.existsSync()) {
    bundleDir.deleteSync(recursive: true);
  }
  bundleDir.createSync(recursive: true);

  // Limit number of open files to avoid running out of file descriptors.
  final Pool pool = Pool(64);
  await Future.wait<void>(
    assetEntries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      } finally {
        resource.release();
      }
    }));
}
