// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required;

import 'artifacts.dart';
import 'asset.dart';
import 'base/build.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/process.dart';
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

Future<int> _createSnapshot({
  @required String mainPath,
  @required String snapshotPath,
  @required String depfilePath,
  @required String packages
}) async {
  assert(mainPath != null);
  assert(snapshotPath != null);
  assert(depfilePath != null);
  assert(packages != null);
  final BuildMode buildMode = BuildMode.debug;
  final String snapshotterPath = artifacts.getArtifactPath(Artifact.genSnapshot, null, buildMode);
  final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData);
  final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData);

  final List<String> args = <String>[
    snapshotterPath,
    '--snapshot_kind=script',
    '--vm_snapshot_data=$vmSnapshotData',
    '--isolate_snapshot_data=$isolateSnapshotData',
    '--packages=$packages',
    '--script_snapshot=$snapshotPath',
    '--dependencies=$depfilePath',
    mainPath,
  ];

  // Write the depfile path to disk.
  fs.file(depfilePath).parent.childFile('gen_snapshot.d').writeAsString('$depfilePath: $snapshotterPath\n');

  final File checksumFile = fs.file('$depfilePath.checksums');
  final File snapshotFile = fs.file(snapshotPath);
  final File depfile = fs.file(depfilePath);
  if (snapshotFile.existsSync() && depfile.existsSync() && checksumFile.existsSync()) {
    try {
        final String json = await checksumFile.readAsString();
        final Checksum oldChecksum = new Checksum.fromJson(json);
        final Set<String> inputPaths = await _readDepfile(depfilePath);
        inputPaths.add(snapshotPath);
        inputPaths.add(mainPath);
        final Checksum newChecksum = new Checksum.fromFiles(buildMode, inputPaths);
        if (oldChecksum == newChecksum) {
          printTrace('Skipping snapshot build. Checksums match.');
          return 0;
        }
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      printTrace('Error during snapshot checksum check: $e\n$s');
    }
  }

  // Build the snapshot.
  final int exitCode = await runCommandAndStreamOutput(args);
  if (exitCode != 0)
    return exitCode;

  // Compute and record input file checksums.
  try {
    final Set<String> inputPaths = await _readDepfile(depfilePath);
    inputPaths.add(snapshotPath);
    inputPaths.add(mainPath);
    final Checksum checksum = new Checksum.fromFiles(buildMode, inputPaths);
    await checksumFile.writeAsString(checksum.toJson());
  } catch (e, s) {
    // Log exception and continue, this step is a performance improvement only.
    printTrace('Error during snapshot checksum output: $e\n$s');
  }
  return 0;
}

/// Parses a VM snapshot dependency file.
///
/// Snapshot dependency files are a single line mapping the output snapshot to a
/// space-separated list of input files used to generate that output. e.g,
///
/// outfile : file1.dart file2.dart file3.dart
Future<Set<String>> _readDepfile(String depfilePath) async {
  // Depfile format:
  // outfile : file1.dart file2.dart file3.dart
  final String contents = await fs.file(depfilePath).readAsString();
  final String dependencies = contents.split(': ')[1];
  return dependencies
      .split(' ')
      .map((String path) => path.trim())
      .where((String path) => path.isNotEmpty)
      .toSet();
}

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
    final int result = await _createSnapshot(
      mainPath: mainPath,
      snapshotPath: snapshotPath,
      depfilePath: depfilePath,
      packages: packagesPath
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
