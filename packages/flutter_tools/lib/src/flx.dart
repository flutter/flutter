// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flx/bundle.dart';
import 'package:flx/signing.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'artifacts.dart';
import 'base/file_system.dart' show ensureDirectoryExists;
import 'globals.dart';
import 'toolchain.dart';
import 'zip.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'flutter.yaml';
const String defaultFlxOutputPath = 'build/app.flx';
const String defaultSnapshotPath = 'build/snapshot_blob.bin';
const String defaultDepfilePath = 'build/snapshot_blob.bin.d';
const String defaultPrivateKeyPath = 'privatekey.der';
const String defaultWorkingDirPath = 'build/flx';

const String _kSnapshotKey = 'snapshot_blob.bin';

class _Asset {
  final String source;
  final String base;
  final String key;

  _Asset({ this.source, this.base, this.key });
}

const String _kMaterialIconsKey = 'fonts/MaterialIcons-Regular.ttf';

List<Map<String, dynamic>> _getMaterialFonts() {
  return [{
    'family': 'MaterialIcons',
    'fonts': [{
      'asset': _kMaterialIconsKey
    }]
  }];
}

List<_Asset> _getMaterialAssets() {
  return <_Asset>[
    new _Asset(
      base: '${ArtifactStore.flutterRoot}/bin/cache/artifacts/material_fonts',
      source: 'MaterialIcons-Regular.ttf',
      key: _kMaterialIconsKey
    )
  ];
}

Map<_Asset, List<_Asset>> _parseAssets(Map<String, dynamic> manifestDescriptor, String assetBase) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};
  if (manifestDescriptor == null)
    return result;
  if (manifestDescriptor.containsKey('assets')) {
    for (String asset in manifestDescriptor['assets']) {
      _Asset baseAsset = new _Asset(base: assetBase, key: asset);
      List<_Asset> variants = <_Asset>[];
      result[baseAsset] = variants;
      // Find asset variants
      String assetPath = path.join(assetBase, asset);
      String assetFilename = path.basename(assetPath);
      Directory assetDir = new Directory(path.dirname(assetPath));
      List<FileSystemEntity> files = assetDir.listSync(recursive: true);
      for (FileSystemEntity entity in files) {
        if (path.basename(entity.path) == assetFilename &&
            FileSystemEntity.isFileSync(entity.path) &&
            entity.path != assetPath) {
          String key = path.relative(entity.path, from: assetBase);
          variants.add(new _Asset(base: assetBase, key: key));
        }
      }
    }
  }

  // Add assets referenced in the fonts section of the manifest.
  if (manifestDescriptor.containsKey('fonts')) {
    for (Map<String, dynamic> family in manifestDescriptor['fonts']) {
      List<Map<String, dynamic>> fonts = family['fonts'];
      if (fonts == null) continue;

      for (Map<String, dynamic> font in fonts) {
        String asset = font['asset'];
        if (asset == null) continue;

        _Asset baseAsset = new _Asset(base: assetBase, key: asset);
        result[baseAsset] = <_Asset>[];
      }
    }
  }

  return result;
}

dynamic _loadManifest(String manifestPath) {
  if (manifestPath == null || !FileSystemEntity.isFileSync(manifestPath))
    return null;
  String manifestDescriptor = new File(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

Future<int> _validateManifest(Object manifest) async {
  String schemaPath = path.join(path.absolute(ArtifactStore.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'flutter_yaml.json');
  Schema schema = await Schema.createSchemaFromUrl('file://$schemaPath');

  Validator validator = new Validator(schema);
  if (validator.validate(manifest))
    return 0;

  printError('Error in flutter.yaml:');
  printError(validator.errors.join('\n'));
  return 1;
}

ZipEntry _createAssetEntry(_Asset asset) {
  String source = asset.source ?? asset.key;
  File file = new File('${asset.base}/$source');
  if (!file.existsSync()) {
    printError('Cannot find asset "$source" in directory "${path.absolute(asset.base)}".');
    return null;
  }
  return new ZipEntry.fromFile(asset.key, file);
}

ZipEntry _createAssetManifest(Map<_Asset, List<_Asset>> assets) {
  Map<String, List<String>> json = <String, List<String>>{};
  for (_Asset main in assets.keys) {
    List<String> variants = <String>[];
    for (_Asset variant in assets[main])
      variants.add(variant.key);
    json[main.key] = variants;
  }
  return new ZipEntry.fromString('AssetManifest.json', JSON.encode(json));
}

ZipEntry _createFontManifest(Map<String, dynamic> manifestDescriptor, List<Map<String, dynamic>> additionalFonts) {
  List<Map<String, dynamic>> fonts = <Map<String, dynamic>>[];
  if (additionalFonts != null)
    fonts.addAll(additionalFonts);
  if (manifestDescriptor != null && manifestDescriptor.containsKey('fonts'))
    fonts.addAll(manifestDescriptor['fonts']);
  if (fonts.isEmpty)
    return null;
  return new ZipEntry.fromString('FontManifest.json', JSON.encode(fonts));
}

/// Build the flx in the build/ directory and return `localBundlePath` on success.
Future<String> buildFlx(
  Toolchain toolchain, {
  String mainPath: defaultMainPath
}) async {
  int result;
  String localBundlePath = path.join('build', 'app.flx');
  String localSnapshotPath = path.join('build', 'snapshot_blob.bin');
  result = await build(
    toolchain,
    snapshotPath: localSnapshotPath,
    outputPath: localBundlePath,
    mainPath: mainPath
  );
  if (result == 0)
    return localBundlePath;
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
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String outputPath: defaultFlxOutputPath,
  String snapshotPath: defaultSnapshotPath,
  String depfilePath: defaultDepfilePath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath: defaultWorkingDirPath,
  bool precompiledSnapshot: false
}) async {
  Object manifest = _loadManifest(manifestPath);
  if (manifest != null) {
    int result = await _validateManifest(manifest);
    if (result != 0)
      return result;
  }
  Map<String, dynamic> manifestDescriptor = manifest;

  String assetBasePath = path.dirname(path.absolute(manifestPath));

  File snapshotFile;

  if (!precompiledSnapshot) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    int result = await toolchain.compiler.createSnapshot(
      mainPath: mainPath,
      snapshotPath: snapshotPath,
      depfilePath: depfilePath
    );
    if (result != 0) {
      printError('Failed to run the Flutter compiler. Exit code: $result');
      return result;
    }

    snapshotFile = new File(snapshotPath);
  }

  return assemble(
      manifestDescriptor: manifestDescriptor,
      snapshotFile: snapshotFile,
      assetBasePath: assetBasePath,
      outputPath: outputPath,
      privateKeyPath: privateKeyPath,
      workingDirPath: workingDirPath
  );
}

Future<int> assemble({
  Map<String, dynamic> manifestDescriptor: const <String, dynamic>{},
  File snapshotFile,
  String assetBasePath: defaultAssetBasePath,
  String outputPath: defaultFlxOutputPath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath: defaultWorkingDirPath
}) async {
  printTrace('Building $outputPath');

  Map<_Asset, List<_Asset>> assets = _parseAssets(manifestDescriptor, assetBasePath);

  final bool usesMaterialDesign = manifestDescriptor != null && manifestDescriptor['uses-material-design'] == true;

  ZipBuilder zipBuilder = new ZipBuilder();

  if (snapshotFile != null)
    zipBuilder.addEntry(new ZipEntry.fromFile(_kSnapshotKey, snapshotFile));

  for (_Asset asset in assets.keys) {
    ZipEntry assetEntry = _createAssetEntry(asset);
    if (assetEntry == null)
      return 1;
    zipBuilder.addEntry(assetEntry);

    for (_Asset variant in assets[asset]) {
      ZipEntry variantEntry = _createAssetEntry(variant);
      if (variantEntry == null)
        return 1;
      zipBuilder.addEntry(variantEntry);
    }
  }

  if (usesMaterialDesign) {
    for (_Asset asset in _getMaterialAssets()) {
      ZipEntry assetEntry = _createAssetEntry(asset);
      if (assetEntry == null)
        return 1;
      zipBuilder.addEntry(assetEntry);
    }
  }

  zipBuilder.addEntry(_createAssetManifest(assets));

  ZipEntry fontManifest = _createFontManifest(manifestDescriptor, usesMaterialDesign ? _getMaterialFonts() : null);
  if (fontManifest != null)
    zipBuilder.addEntry(fontManifest);

  AsymmetricKeyPair<PublicKey, PrivateKey> keyPair = keyPairFromPrivateKeyFileSync(privateKeyPath);
  printTrace('KeyPair from $privateKeyPath: $keyPair.');

  if (keyPair != null) {
    printTrace('Calling CipherParameters.seedRandom().');
    CipherParameters.get().seedRandom();
  }

  File zipFile = new File(outputPath.substring(0, outputPath.length - 4) + '.zip');
  printTrace('Encoding zip file to ${zipFile.path}');
  zipBuilder.createZip(zipFile, new Directory(workingDirPath));
  List<int> zipBytes = zipFile.readAsBytesSync();

  ensureDirectoryExists(outputPath);

  printTrace('Creating flx at $outputPath.');
  Bundle bundle = new Bundle.fromContent(
    path: outputPath,
    manifest: manifestDescriptor,
    contentBytes: zipBytes,
    keyPair: keyPair
  );
  bundle.writeSync();

  printTrace('Built $outputPath.');

  return 0;
}
