// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'compile.dart';
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

const String _kKernelKey = 'kernel_blob.bin';
const String _kVMSnapshotData = 'vm_snapshot_data';
const String _kIsolateSnapshotData = 'isolate_snapshot_data';

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
    applicationKernelFilePath ??= getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation);
    final FlutterProject flutterProject = FlutterProject.current();

    DevFSContent kernelContent;
    if (!precompiledSnapshot) {
      if ((extraFrontEndOptions != null) && extraFrontEndOptions.isNotEmpty)
        printTrace('Extra front-end options: $extraFrontEndOptions');
      ensureDirectoryExists(applicationKernelFilePath);
      final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(flutterProject);
      final CompilerOutput compilerOutput = await kernelCompiler.compile(
        sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
        mainPath: fs.file(mainPath).absolute.path,
        outputFilePath: applicationKernelFilePath,
        depFilePath: depfilePath,
        trackWidgetCreation: trackWidgetCreation,
        extraFrontEndOptions: extraFrontEndOptions,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        packagesPath: packagesPath,
      );
      if (compilerOutput?.outputFilename == null) {
        throwToolExit('Compiler failed on $mainPath');
      }
      kernelContent = DevFSFileContent(fs.file(compilerOutput.outputFilename));

      fs.directory(getBuildDirectory()).childFile('frontend_server.d')
          .writeAsStringSync('frontend_server.d: ${artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk)}\n');
    }

    final AssetBundle assets = await buildAssets(
      manifestPath: manifestPath,
      assetDirPath: assetDirPath,
      packagesPath: packagesPath,
      reportLicensedPackages: reportLicensedPackages,
    );
    if (assets == null)
      throwToolExit('Error building assets', exitCode: 1);

    await assemble(
      buildMode: buildMode,
      assetBundle: assets,
      kernelContent: kernelContent,
      privateKeyPath: privateKeyPath,
      assetDirPath: assetDirPath,
    );
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
  if (result != 0)
    return null;

  return assetBundle;
}

Future<void> assemble({
  BuildMode buildMode,
  AssetBundle assetBundle,
  DevFSContent kernelContent,
  String privateKeyPath = defaultPrivateKeyPath,
  String assetDirPath,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  printTrace('Building bundle');

  final Map<String, DevFSContent> assetEntries = Map<String, DevFSContent>.from(assetBundle.entries);
  if (kernelContent != null) {
    final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: buildMode);
    final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: buildMode);
    assetEntries[_kKernelKey] = kernelContent;
    assetEntries[_kVMSnapshotData] = DevFSFileContent(fs.file(vmSnapshotData));
    assetEntries[_kIsolateSnapshotData] = DevFSFileContent(fs.file(isolateSnapshotData));
  }

  printTrace('Writing asset files to $assetDirPath');
  ensureDirectoryExists(assetDirPath);

  await writeBundle(fs.directory(assetDirPath), assetEntries);
  printTrace('Wrote $assetDirPath');
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, DevFSContent> assetEntries,
) async {
  if (bundleDir.existsSync())
    bundleDir.deleteSync(recursive: true);
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
