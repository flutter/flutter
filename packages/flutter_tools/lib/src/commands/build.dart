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

import '../base/file_system.dart';
import '../base/logging.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';

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

const String _kDefaultAssetBase = 'packages/material_design_icons/icons';
const String _kDefaultMainPath = 'lib/main.dart';
const String _kDefaultManifestPath = 'flutter.yaml';
const String _kDefaultOutputPath = 'build/app.flx';
const String _kDefaultSnapshotPath = 'build/snapshot_blob.bin';
const String _kDefaultPrivateKeyPath = 'privatekey.der';

class BuildCommand extends FlutterCommand {
  final String name = 'build';
  final String description = 'Packages your Flutter app into an FLX.';

  BuildCommand() {
    argParser.addFlag('precompiled', negatable: false);
    argParser.addOption('asset-base', defaultsTo: _kDefaultAssetBase);
    argParser.addOption('compiler');
    argParser.addOption('main', defaultsTo: _kDefaultMainPath);
    argParser.addOption('manifest', defaultsTo: _kDefaultManifestPath);
    argParser.addOption('private-key', defaultsTo: _kDefaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: _kDefaultOutputPath);
    argParser.addOption('snapshot', defaultsTo: _kDefaultSnapshotPath);
  }

  @override
  Future<int> runInProject() async {
    String compilerPath = argResults['compiler'];

    if (compilerPath == null)
      await downloadToolchain();
    else
      toolchain = new Toolchain(compiler: new Compiler(compilerPath));

    return await build(
      assetBase: argResults['asset-base'],
      mainPath: argResults['main'],
      manifestPath: argResults['manifest'],
      outputPath: argResults['output-file'],
      snapshotPath: argResults['snapshot'],
      privateKeyPath: argResults['private-key'],
      precompiledSnapshot: argResults['precompiled']
    );
  }

  Future<int> buildInTempDir({
    String mainPath: _kDefaultMainPath,
    void onBundleAvailable(String bundlePath)
  }) async {
    int result;
    Directory tempDir = await Directory.systemTemp.createTemp('flutter_tools');
    try {
      String localBundlePath = path.join(tempDir.path, 'app.flx');
      String localSnapshotPath = path.join(tempDir.path, 'snapshot_blob.bin');
      result = await build(
        snapshotPath: localSnapshotPath,
        outputPath: localBundlePath,
        mainPath: mainPath
      );
      onBundleAvailable(localBundlePath);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
    return result;
  }

  Future<int> build({
    String assetBase: _kDefaultAssetBase,
    String mainPath: _kDefaultMainPath,
    String manifestPath: _kDefaultManifestPath,
    String outputPath: _kDefaultOutputPath,
    String snapshotPath: _kDefaultSnapshotPath,
    String privateKeyPath: _kDefaultPrivateKeyPath,
    bool precompiledSnapshot: false
  }) async {
    logging.fine('Building $outputPath');

    Map manifestDescriptor = _loadManifest(manifestPath);

    Iterable<_Asset> assets = _parseAssets(manifestDescriptor, manifestPath);
    Iterable<_MaterialAsset> materialAssets = _parseMaterialAssets(manifestDescriptor);

    Archive archive = new Archive();

    if (!precompiledSnapshot) {
      ensureDirectoryExists(snapshotPath);

      // In a precompiled snapshot, the instruction buffer contains script
      // content equivalents
      int result = await toolchain.compiler.compile(mainPath: mainPath, snapshotPath: snapshotPath);
      if (result != 0)
        return result;

      archive.addFile(_createSnapshotFile(snapshotPath));
    }

    for (_Asset asset in assets) {
      ArchiveFile file = _createFile(asset.key, asset.base);
      if (file == null) {
        stderr.writeln('Cannot find asset "${asset.key}" in directory "${path.absolute(asset.base)}".');
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
}
