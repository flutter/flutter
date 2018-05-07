// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'artifacts.dart';
import 'asset.dart';
import 'base/build.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/fingerprint.dart';
import 'build_info.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'globals.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultSnapshotPath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin');
String get defaultDepfilePath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');
String get defaultApplicationKernelPath => fs.path.join(getBuildDirectory(), 'app.dill');
const String defaultPrivateKeyPath = 'privatekey.der';

const String _kKernelKey = 'kernel_blob.bin';
const String _kSnapshotKey = 'snapshot_blob.bin';
const String _kDylibKey = 'libapp.so';
const String _kPlatformKernelKey = 'platform.dill';

Future<void> build({
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String snapshotPath,
  String applicationKernelFilePath,
  String depfilePath,
  String privateKeyPath: defaultPrivateKeyPath,
  String assetDirPath,
  String packagesPath,
  bool previewDart2 : false,
  bool precompiledSnapshot: false,
  bool reportLicensedPackages: false,
  bool trackWidgetCreation: false,
  List<String> fileSystemRoots,
  String fileSystemScheme,
}) async {
  snapshotPath ??= defaultSnapshotPath;
  depfilePath ??= defaultDepfilePath;
  assetDirPath ??= getAssetBuildDirectory();
  packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
  applicationKernelFilePath ??= defaultApplicationKernelPath;
  File snapshotFile;

  if (!precompiledSnapshot && !previewDart2) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    final int result = await new ScriptSnapshotter().build(
      mainPath: mainPath,
      snapshotPath: snapshotPath,
      depfilePath: depfilePath,
      packagesPath: packagesPath,
    );
    if (result != 0)
      throwToolExit('Failed to run the Flutter compiler. Exit code: $result', exitCode: result);

    snapshotFile = fs.file(snapshotPath);
  }

  DevFSContent kernelContent;
  if (!precompiledSnapshot && previewDart2) {
    bool needBuild = true;
    final Fingerprinter fingerprinter = new Fingerprinter(
      fingerprintPath: '$depfilePath.fingerprint',
      paths: <String>[mainPath],
      properties: <String, String>{
        'entryPoint': mainPath,
        'trackWidgetCreation': trackWidgetCreation.toString(),
      },
      depfilePaths: <String>[depfilePath],
    );

    if (await fingerprinter.doesFingerprintMatch()) {
      needBuild = false;
      printStatus('Skipping compilation. Fingerprint match.');
    }

    String kernelBinaryFilename;
    if (needBuild) {
      ensureDirectoryExists(applicationKernelFilePath);
      final CompilerOutput compilerOutput = await kernelCompiler.compile(
        sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
        incrementalCompilerByteStorePath: fs.path.absolute(getIncrementalCompilerByteStoreDirectory()),
        mainPath: fs.file(mainPath).absolute.path,
        outputFilePath: applicationKernelFilePath,
        depFilePath: depfilePath,
        trackWidgetCreation: trackWidgetCreation,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        packagesPath: packagesPath,
      );
      kernelBinaryFilename = compilerOutput?.outputFilename;
      if (kernelBinaryFilename == null) {
        throwToolExit('Compiler failed on $mainPath');
      }
      // Compute and record build fingerprint.
      await fingerprinter.writeFingerprint();
    } else {
      kernelBinaryFilename = applicationKernelFilePath;
    }
    kernelContent = new DevFSFileContent(fs.file(kernelBinaryFilename));

    await fs.directory(getBuildDirectory()).childFile('frontend_server.d')
        .writeAsString('frontend_server.d: ${artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk)}\n');
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
    assetBundle: assets,
    kernelContent: kernelContent,
    snapshotFile: snapshotFile,
    privateKeyPath: privateKeyPath,
    assetDirPath: assetDirPath,
  );
}

Future<AssetBundle> buildAssets({
  String manifestPath,
  String assetDirPath,
  String packagesPath,
  bool includeDefaultFonts: true,
  bool reportLicensedPackages: false
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
    reportLicensedPackages: reportLicensedPackages
  );
  if (result != 0)
    return null;

  return assetBundle;
}

Future<void> assemble({
  AssetBundle assetBundle,
  DevFSContent kernelContent,
  File snapshotFile,
  File dylibFile,
  String privateKeyPath: defaultPrivateKeyPath,
  String assetDirPath,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  printTrace('Building bundle');

  final Map<String, DevFSContent> assetEntries = new Map<String, DevFSContent>.from(assetBundle.entries);

  if (kernelContent != null) {
    final String platformKernelDill = artifacts.getArtifactPath(Artifact.platformKernelDill);
    assetEntries[_kKernelKey] = kernelContent;
    assetEntries[_kPlatformKernelKey] = new DevFSFileContent(fs.file(platformKernelDill));
  }
  if (snapshotFile != null)
    assetEntries[_kSnapshotKey] = new DevFSFileContent(snapshotFile);
  if (dylibFile != null)
    assetEntries[_kDylibKey] = new DevFSFileContent(dylibFile);

  printTrace('Writing asset files to $assetDirPath');
  ensureDirectoryExists(assetDirPath);

  await writeBundle(fs.directory(assetDirPath), assetEntries);
  printTrace('Wrote $assetDirPath');
}

Future<void> writeBundle(
    Directory bundleDir, Map<String, DevFSContent> assetEntries) async {
  if (bundleDir.existsSync())
    bundleDir.deleteSync(recursive: true);
  bundleDir.createSync(recursive: true);

  await Future.wait(
      assetEntries.entries.map((MapEntry<String, DevFSContent> entry) async {
    final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(await entry.value.contentsAsBytes());
  }));
}


