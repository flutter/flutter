// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flx/bundle.dart';
import 'package:flx/signing.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'toolchain.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBase = 'packages/material_design_icons/icons';
const String defaultManifestPath = 'flutter.yaml';
const String defaultFlxOutputPath = 'build/app.flx';
const String defaultSnapshotPath = 'build/snapshot_blob.bin';
const String defaultPrivateKeyPath = 'privatekey.der';

const String _kSnapshotKey = 'snapshot_blob.bin';
const List<String> _kDensities = const ['drawable-xxhdpi'];
const List<String> _kThemes = const ['white', 'black'];
const List<int> _kSizes = const [18, 24, 36, 48];

class _Asset {
  final String base;
  final String key;

  _Asset({ this.base, this.key });
}

Iterable<_Asset> _parseAssets(Map manifestDescriptor, String manifestPath) sync* {
  if (manifestDescriptor == null || !manifestDescriptor.containsKey('assets'))
    return;
  String basePath = path.dirname(path.absolute(manifestPath));
  for (String asset in manifestDescriptor['assets'])
    yield new _Asset(base: basePath, key: asset);
}

class _MaterialAsset {
  final String name;
  final String density;
  final String theme;
  final int size;

  _MaterialAsset(Map descriptor)
    : name = descriptor['name'],
      density = descriptor['density'],
      theme = descriptor['theme'],
      size = descriptor['size'];

  String get key {
    List<String> parts = name.split('/');
    String category = parts[0];
    String subtype = parts[1];
    return '$category/$density/ic_${subtype}_${theme}_${size}dp.png';
  }
}

List _generateValues(Map assetDescriptor, String key, List defaults) {
  if (assetDescriptor.containsKey(key))
    return [assetDescriptor[key]];
  return defaults;
}

Iterable<_MaterialAsset> _generateMaterialAssets(Map assetDescriptor) sync* {
  Map currentAssetDescriptor = new Map.from(assetDescriptor);
  for (String density in _generateValues(assetDescriptor, 'density', _kDensities)) {
    currentAssetDescriptor['density'] = density;
    for (String theme in _generateValues(assetDescriptor, 'theme', _kThemes)) {
      currentAssetDescriptor['theme'] = theme;
      for (int size in _generateValues(assetDescriptor, 'size', _kSizes)) {
        currentAssetDescriptor['size'] = size;
        yield new _MaterialAsset(currentAssetDescriptor);
      }
    }
  }
}

Iterable<_MaterialAsset> _parseMaterialAssets(Map manifestDescriptor) sync* {
  if (manifestDescriptor == null || !manifestDescriptor.containsKey('material-design-icons'))
    return;
  for (Map assetDescriptor in manifestDescriptor['material-design-icons']) {
    for (_MaterialAsset asset in _generateMaterialAssets(assetDescriptor)) {
      yield asset;
    }
  }
}

dynamic _loadManifest(String manifestPath) {
  if (manifestPath == null || !FileSystemEntity.isFileSync(manifestPath))
    return null;
  String manifestDescriptor = new File(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

ArchiveFile _createFile(String key, String assetBase) {
  File file = new File('$assetBase/$key');
  if (!file.existsSync())
    return null;
  List<int> content = file.readAsBytesSync();
  return new ArchiveFile.noCompress(key, content.length, content);
}

ArchiveFile _createSnapshotFile(String snapshotPath) {
  File file = new File(snapshotPath);
  List<int> content = file.readAsBytesSync();
  return new ArchiveFile(_kSnapshotKey, content.length, content);
}

/// Build the flx in a temp dir and return `localBundlePath` on success.
Future<DirectoryResult> buildInTempDir(
  Toolchain toolchain, {
  String mainPath: defaultMainPath
}) async {
  int result;
  Directory tempDir = await Directory.systemTemp.createTemp('flutter_tools');
  String localBundlePath = path.join(tempDir.path, 'app.flx');
  String localSnapshotPath = path.join(tempDir.path, 'snapshot_blob.bin');
  result = await build(
    toolchain,
    snapshotPath: localSnapshotPath,
    outputPath: localBundlePath,
    mainPath: mainPath
  );
  if (result == 0)
    return new DirectoryResult(tempDir, localBundlePath);
  else
    throw result;
}

/// The result from [buildInTempDir]. Note that this object should be disposed after use.
class DirectoryResult {
  final Directory directory;
  final String localBundlePath;

  DirectoryResult(this.directory, this.localBundlePath);

  /// Call this to delete the temporary directory.
  void dispose() {
    directory.deleteSync(recursive: true);
  }
}

Future<int> build(
  Toolchain toolchain, {
  String assetBase: defaultAssetBase,
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String outputPath: defaultFlxOutputPath,
  String snapshotPath: defaultSnapshotPath,
  String privateKeyPath: defaultPrivateKeyPath,
  bool precompiledSnapshot: false
}) async {
  printTrace('Building $outputPath');

  Map manifestDescriptor = _loadManifest(manifestPath);

  Iterable<_Asset> assets = _parseAssets(manifestDescriptor, manifestPath);
  Iterable<_MaterialAsset> materialAssets = _parseMaterialAssets(manifestDescriptor);

  Archive archive = new Archive();

  if (!precompiledSnapshot) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    int result = await toolchain.compiler.compile(mainPath: mainPath, snapshotPath: snapshotPath);
    if (result != 0) {
      printError('Failed to run the Flutter compiler. Exit code: $result');
      return result;
    }

    archive.addFile(_createSnapshotFile(snapshotPath));
  }

  for (_Asset asset in assets) {
    ArchiveFile file = _createFile(asset.key, asset.base);
    if (file == null) {
      printError('Cannot find asset "${asset.key}" in directory "${path.absolute(asset.base)}".');
      return 1;
    }
    archive.addFile(file);
  }

  for (_MaterialAsset asset in materialAssets) {
    ArchiveFile file = _createFile(asset.key, assetBase);
    if (file != null)
      archive.addFile(file);
  }

  await CipherParameters.get().seedRandom();

  AsymmetricKeyPair keyPair = keyPairFromPrivateKeyFileSync(privateKeyPath);
  Uint8List zipBytes = new Uint8List.fromList(new ZipEncoder().encode(archive));
  ensureDirectoryExists(outputPath);
  Bundle bundle = new Bundle.fromContent(
    path: outputPath,
    manifest: manifestDescriptor,
    contentBytes: zipBytes,
    keyPair: keyPair
  );
  bundle.writeSync();
  return 0;
}
