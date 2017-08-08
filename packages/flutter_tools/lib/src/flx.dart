// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'asset.dart';
import 'base/build.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'globals.dart';
import 'zip.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultFlxOutputPath => fs.path.join(getBuildDirectory(), 'app.flx');
String get defaultSnapshotPath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin');
String get defaultDepfilePath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');
const String defaultPrivateKeyPath = 'privatekey.der';

const String _kKernelKey = 'kernel_blob.bin';
const String _kSnapshotKey = 'snapshot_blob.bin';
const String _kDylibKey = 'libapp.so';

Future<Null> build({
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String outputPath,
  String snapshotPath,
  String depfilePath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath,
  String packagesPath,
  String kernelPath,
  bool precompiledSnapshot: false,
  bool reportLicensedPackages: false
}) async {
  outputPath ??= defaultFlxOutputPath;
  snapshotPath ??= defaultSnapshotPath;
  depfilePath ??= defaultDepfilePath;
  workingDirPath ??= getAssetBuildDirectory();
  packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
  File snapshotFile;

  if (!precompiledSnapshot) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    final Snapshotter snapshotter = new Snapshotter();
    final int result = await snapshotter.buildScriptSnapshot(
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
  if (kernelPath != null)
    kernelContent = new DevFSFileContent(fs.file(kernelPath));

  return assemble(
    manifestPath: manifestPath,
    kernelContent: kernelContent,
    snapshotFile: snapshotFile,
    outputPath: outputPath,
    privateKeyPath: privateKeyPath,
    workingDirPath: workingDirPath,
    packagesPath: packagesPath,
    reportLicensedPackages: reportLicensedPackages
  ).then((_) => null);
}

Future<List<String>> assemble({
  String manifestPath,
  DevFSContent kernelContent,
  File snapshotFile,
  File dylibFile,
  String outputPath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath,
  String packagesPath,
  bool includeDefaultFonts: true,
  bool reportLicensedPackages: false
}) async {
  outputPath ??= defaultFlxOutputPath;
  workingDirPath ??= getAssetBuildDirectory();
  packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
  printTrace('Building $outputPath');

  // Build the asset bundle.
  final AssetBundle assetBundle = new AssetBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    workingDirPath: workingDirPath,
    packagesPath: packagesPath,
    includeDefaultFonts: includeDefaultFonts,
    reportLicensedPackages: reportLicensedPackages
  );
  if (result != 0)
    throwToolExit('Error building $outputPath: $result', exitCode: result);

  final ZipBuilder zipBuilder = new ZipBuilder();

  // Add all entries from the asset bundle.
  zipBuilder.entries.addAll(assetBundle.entries);

  final List<String> fileDependencies = assetBundle.entries.values
      .expand((DevFSContent content) => content.fileDependencies)
      .toList();

  if (kernelContent != null)
    zipBuilder.entries[_kKernelKey] = kernelContent;
  if (snapshotFile != null)
    zipBuilder.entries[_kSnapshotKey] = new DevFSFileContent(snapshotFile);
  if (dylibFile != null)
    zipBuilder.entries[_kDylibKey] = new DevFSFileContent(dylibFile);

  ensureDirectoryExists(outputPath);

  printTrace('Encoding zip file to $outputPath');
  await zipBuilder.createZip(fs.file(outputPath), fs.directory(workingDirPath));

  printTrace('Built $outputPath.');

  return fileDependencies;
}
