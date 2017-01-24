// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/process.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'build_info.dart';
import 'globals.dart';
import 'toolchain.dart';
import 'zip.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultFlxOutputPath => path.join(getBuildDirectory(), 'app.flx');
String get defaultSnapshotPath => path.join(getBuildDirectory(), 'snapshot_blob.bin');
String get defaultDepfilePath => path.join(getBuildDirectory(), 'snapshot_blob.bin.d');
const String defaultPrivateKeyPath = 'privatekey.der';

const String _kSnapshotKey = 'snapshot_blob.bin';

Future<int> createSnapshot({
  String snapshotterPath,
  String mainPath,
  String snapshotPath,
  String depfilePath,
  String packages
}) {
  assert(snapshotterPath != null);
  assert(mainPath != null);
  assert(snapshotPath != null);
  assert(packages != null);

  final List<String> args = <String>[
    snapshotterPath,
    '--packages=$packages',
    '--snapshot=$snapshotPath'
  ];
  if (depfilePath != null) {
    args.add('--depfile=$depfilePath');
    args.add('--build-output=$snapshotPath');
  }
  args.add(mainPath);
  return runCommandAndStreamOutput(args);
}

/// Build the flx in the build directory and return `localBundlePath` on success.
///
/// Return `null` on failure.
Future<String> buildFlx({
  String mainPath: defaultMainPath,
  bool precompiledSnapshot: false,
  bool includeRobotoFonts: true
}) async {
  await build(
    snapshotPath: defaultSnapshotPath,
    outputPath: defaultFlxOutputPath,
    mainPath: mainPath,
    precompiledSnapshot: precompiledSnapshot,
    includeRobotoFonts: includeRobotoFonts
  );
  return defaultFlxOutputPath;
}

Future<Null> build({
  String snapshotterPath,
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String outputPath,
  String snapshotPath,
  String depfilePath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath,
  String packagesPath,
  bool precompiledSnapshot: false,
  bool includeRobotoFonts: true,
  bool reportLicensedPackages: false
}) async {
  snapshotterPath ??= tools.getHostToolPath(HostTool.SkySnapshot);
  outputPath ??= defaultFlxOutputPath;
  snapshotPath ??= defaultSnapshotPath;
  depfilePath ??= defaultDepfilePath;
  workingDirPath ??= getAssetBuildDirectory();
  packagesPath ??= path.absolute(PackageMap.globalPackagesPath);
  File snapshotFile;

  if (!precompiledSnapshot) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    int result = await createSnapshot(
      snapshotterPath: snapshotterPath,
      mainPath: mainPath,
      snapshotPath: snapshotPath,
      depfilePath: depfilePath,
      packages: packagesPath
    );
    if (result != 0)
      throwToolExit('Failed to run the Flutter compiler. Exit code: $result', exitCode: result);

    snapshotFile = fs.file(snapshotPath);
  }

  return assemble(
    manifestPath: manifestPath,
    snapshotFile: snapshotFile,
    outputPath: outputPath,
    privateKeyPath: privateKeyPath,
    workingDirPath: workingDirPath,
    packagesPath: packagesPath,
    includeRobotoFonts: includeRobotoFonts,
    reportLicensedPackages: reportLicensedPackages
  );
}

Future<Null> assemble({
  String manifestPath,
  File snapshotFile,
  String outputPath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath,
  String packagesPath,
  bool includeDefaultFonts: true,
  bool includeRobotoFonts: true,
  bool reportLicensedPackages: false
}) async {
  outputPath ??= defaultFlxOutputPath;
  workingDirPath ??= getAssetBuildDirectory();
  packagesPath ??= path.absolute(PackageMap.globalPackagesPath);
  printTrace('Building $outputPath');

  // Build the asset bundle.
  AssetBundle assetBundle = new AssetBundle();
  int result = await assetBundle.build(
    manifestPath: manifestPath,
    workingDirPath: workingDirPath,
    packagesPath: packagesPath,
    includeDefaultFonts: includeDefaultFonts,
    includeRobotoFonts: includeRobotoFonts,
    reportLicensedPackages: reportLicensedPackages
  );
  if (result != 0)
    throwToolExit('Error building $outputPath: $result', exitCode: result);

  ZipBuilder zipBuilder = new ZipBuilder();

  // Add all entries from the asset bundle.
  zipBuilder.entries.addAll(assetBundle.entries);

  if (snapshotFile != null)
    zipBuilder.entries[_kSnapshotKey] = new DevFSFileContent(snapshotFile);

  ensureDirectoryExists(outputPath);

  printTrace('Encoding zip file to $outputPath');
  await zipBuilder.createZip(fs.file(outputPath), fs.directory(workingDirPath));

  printTrace('Built $outputPath.');
}
