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
import 'package_map.dart';
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

const String _kFontSetMaterial = 'material';
const String _kFontSetRoboto = 'roboto';

class _Asset {
  _Asset({ this.base, String assetEntry, this.relativePath, this.source }) {
    this._assetEntry = assetEntry;
  }

  String _assetEntry;

  final String base;

  /// The entry to list in the generated asset manifest.
  String get assetEntry => _assetEntry ?? relativePath;

  /// Where the resource is on disk realtive to [base].
  final String relativePath;

  final String source;

  /// The delta between what the assetEntry is and the relativePath (e.g.,
  /// packages/material_gallery).
  String get symbolicPrefix {
    if (_assetEntry == null || _assetEntry == relativePath)
      return null;
    int index = _assetEntry.indexOf(relativePath);
    return index == -1 ? null : _assetEntry.substring(0, index);
  }

  @override
  String toString() => 'asset: $assetEntry';
}

Map<String, dynamic> _readMaterialFontsManifest() {
  String fontsPath = path.join(path.absolute(ArtifactStore.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'material_fonts.yaml');

  return loadYaml(new File(fontsPath).readAsStringSync());
}

final Map<String, dynamic> _materialFontsManifest = _readMaterialFontsManifest();

List<Map<String, dynamic>> _getMaterialFonts(String fontSet) {
  return _materialFontsManifest[fontSet];
}

List<_Asset> _getMaterialAssets(String fontSet) {
  List<_Asset> result = <_Asset>[];

  for (Map<String, dynamic> family in _getMaterialFonts(fontSet)) {
    for (Map<String, dynamic> font in family['fonts']) {
      String assetKey = font['asset'];
      result.add(new _Asset(
        base: '${ArtifactStore.flutterRoot}/bin/cache/artifacts/material_fonts',
        source: path.basename(assetKey),
        relativePath: assetKey
      ));
    }
  }

  return result;
}

Map<_Asset, List<_Asset>> _parseAssets(
  PackageMap packageMap,
  Map<String, dynamic> manifestDescriptor,
  String assetBase
) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};
  if (manifestDescriptor == null)
    return result;
  if (manifestDescriptor.containsKey('assets')) {
    for (String asset in manifestDescriptor['assets']) {
      _Asset baseAsset = _resolveAsset(packageMap, assetBase, asset);

      List<_Asset> variants = <_Asset>[];
      result[baseAsset] = variants;

      // Find asset variants
      String assetPath = path.join(baseAsset.base, baseAsset.relativePath);
      String assetFilename = path.basename(assetPath);
      Directory assetDir = new Directory(path.dirname(assetPath));

      List<FileSystemEntity> files = assetDir.listSync(recursive: true);

      final String buildDirPath = path.absolute(path.join(assetBase, 'build'));

      for (FileSystemEntity entity in files) {
        // Exclude files from the `build/` directory.
        if (entity.path.startsWith(buildDirPath))
          continue;

        if (path.basename(entity.path) == assetFilename &&
            FileSystemEntity.isFileSync(entity.path) &&
            entity.path != assetPath) {
          String key = path.relative(entity.path, from: baseAsset.base);
          String assetEntry;
          if (baseAsset.symbolicPrefix != null)
            assetEntry = path.join(baseAsset.symbolicPrefix, key);
          variants.add(new _Asset(base: baseAsset.base, assetEntry: assetEntry, relativePath: key));
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

        _Asset baseAsset = new _Asset(base: assetBase, relativePath: asset);
        result[baseAsset] = <_Asset>[];
      }
    }
  }

  return result;
}

_Asset _resolveAsset(PackageMap packageMap, String assetBase, String asset) {
  if (asset.startsWith('packages/')) {
    // Convert packages/flutter_gallery_assets/clouds-0.png to clouds-0.png.
    String packageKey = asset.substring(9);
    String relativeAsset = asset;

    int index = packageKey.indexOf('/');
    if (index != -1) {
      relativeAsset = packageKey.substring(index + 1);
      packageKey = packageKey.substring(0, index);
    }

    Uri uri = packageMap.map[packageKey];
    if (uri != null && uri.scheme == 'file') {
      File file = new File.fromUri(uri);
      return new _Asset(base: file.path, assetEntry: asset, relativePath: relativeAsset);
    }
  }

  return new _Asset(base: assetBase, relativePath: asset);
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
  String source = asset.source ?? asset.relativePath;
  File file = new File('${asset.base}/$source');
  if (!file.existsSync()) {
    printError('Cannot find asset "$source" in directory "${path.absolute(asset.base)}".');
    return null;
  }
  return new ZipEntry.fromFile(asset.assetEntry, file);
}

ZipEntry _createAssetManifest(Map<_Asset, List<_Asset>> assets) {
  Map<String, List<String>> json = <String, List<String>>{};
  for (_Asset main in assets.keys) {
    List<String> variants = <String>[];
    for (_Asset variant in assets[main])
      variants.add(variant.relativePath);
    json[main.relativePath] = variants;
  }
  return new ZipEntry.fromString('AssetManifest.json', JSON.encode(json));
}

ZipEntry _createFontManifest(Map<String, dynamic> manifestDescriptor,
                             bool usesMaterialDesign,
                             bool includeRobotoFonts) {
  List<Map<String, dynamic>> fonts = <Map<String, dynamic>>[];
  if (usesMaterialDesign) {
    fonts.addAll(_getMaterialFonts(_kFontSetMaterial));
    if (includeRobotoFonts)
      fonts.addAll(_getMaterialFonts(_kFontSetRoboto));
  }
  if (manifestDescriptor != null && manifestDescriptor.containsKey('fonts'))
    fonts.addAll(manifestDescriptor['fonts']);
  if (fonts.isEmpty)
    return null;
  return new ZipEntry.fromString('FontManifest.json', JSON.encode(fonts));
}

/// Build the flx in the build/ directory and return `localBundlePath` on success.
Future<String> buildFlx(
  Toolchain toolchain, {
  String mainPath: defaultMainPath,
  bool includeRobotoFonts: true
}) async {
  int result;
  String localBundlePath = path.join('build', 'app.flx');
  String localSnapshotPath = path.join('build', 'snapshot_blob.bin');
  result = await build(
    toolchain,
    snapshotPath: localSnapshotPath,
    outputPath: localBundlePath,
    mainPath: mainPath,
    includeRobotoFonts: includeRobotoFonts
  );
  if (result == 0)
    return localBundlePath;
  else
    throw result;
}

/// The result from [buildInTempDir]. Note that this object should be disposed after use.
class DirectoryResult {
  DirectoryResult(this.directory, this.localBundlePath);

  final Directory directory;
  final String localBundlePath;

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
  bool precompiledSnapshot: false,
  bool includeRobotoFonts: true
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
      workingDirPath: workingDirPath,
      includeRobotoFonts: includeRobotoFonts
  );
}

Future<int> assemble({
  Map<String, dynamic> manifestDescriptor: const <String, dynamic>{},
  File snapshotFile,
  String assetBasePath: defaultAssetBasePath,
  String outputPath: defaultFlxOutputPath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath: defaultWorkingDirPath,
  bool includeRobotoFonts: true
}) async {
  printTrace('Building $outputPath');

  PackageMap packageMap = new PackageMap(path.join(assetBasePath, '.packages'));
  Map<_Asset, List<_Asset>> assets = _parseAssets(packageMap, manifestDescriptor, assetBasePath);

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

  List<_Asset> materialAssets = <_Asset>[];
  if (usesMaterialDesign) {
    materialAssets.addAll(_getMaterialAssets(_kFontSetMaterial));
    if (includeRobotoFonts)
      materialAssets.addAll(_getMaterialAssets(_kFontSetRoboto));
  }
  for (_Asset asset in materialAssets) {
    ZipEntry assetEntry = _createAssetEntry(asset);
    if (assetEntry == null)
      return 1;
    zipBuilder.addEntry(assetEntry);
  }

  zipBuilder.addEntry(_createAssetManifest(assets));

  ZipEntry fontManifest = _createFontManifest(manifestDescriptor, usesMaterialDesign, includeRobotoFonts);
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
