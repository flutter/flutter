// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart' show ensureDirectoryExists;
import 'base/process.dart';
import 'cache.dart';
import 'dart/package_map.dart';
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

const String _kFontSetMaterial = 'material';
const String _kFontSetRoboto = 'roboto';

Future<int> createSnapshot({
  String mainPath,
  String snapshotPath,
  String depfilePath,
  String buildOutputPath
}) {
  assert(mainPath != null);
  assert(snapshotPath != null);

  final List<String> args = <String>[
    tools.getHostToolPath(HostTool.SkySnapshot),
    mainPath,
    '--packages=${path.absolute(PackageMap.globalPackagesPath)}',
    '--snapshot=$snapshotPath'
  ];
  if (depfilePath != null)
    args.add('--depfile=$depfilePath');
  if (buildOutputPath != null)
    args.add('--build-output=$buildOutputPath');
  return runCommandAndStreamOutput(args);
}

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

  File get assetFile {
    return new File(source != null ? '$base/$source' : '$base/$relativePath');
  }

  bool get assetFileExists => assetFile.existsSync();

  /// The delta between what the assetEntry is and the relativePath (e.g.,
  /// packages/flutter_gallery).
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
  String fontsPath = path.join(path.absolute(Cache.flutterRoot),
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
        base: '${Cache.flutterRoot}/bin/cache/artifacts/material_fonts',
        source: path.basename(assetKey),
        relativePath: assetKey
      ));
    }
  }

  return result;
}

/// Given an assetBase location and a flutter.yaml manifest, return a map of
/// assets to asset variants.
///
/// Returns `null` on missing assets.
Map<_Asset, List<_Asset>> _parseAssets(
  PackageMap packageMap,
  Map<String, dynamic> manifestDescriptor,
  String assetBase,
  Map<String, String> assetPathOverrides, {
  List<String> excludeDirs: const <String>[]
}) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};

  if (manifestDescriptor == null)
    return result;

  excludeDirs = excludeDirs.map(
    (String exclude) => path.absolute(exclude) + Platform.pathSeparator).toList();

  if (manifestDescriptor.containsKey('assets')) {
    for (String asset in manifestDescriptor['assets']) {
      _Asset baseAsset = _resolveAsset(packageMap, assetBase, assetPathOverrides, asset);

      if (!baseAsset.assetFileExists) {
        printError('Error: unable to locate asset entry in flutter.yaml: "$asset".');
        return null;
      }

      List<_Asset> variants = <_Asset>[];
      result[baseAsset] = variants;

      // Find asset variants
      String assetPath = baseAsset.assetFile.path;
      String assetFilename = path.basename(assetPath);
      Directory assetDir = new Directory(path.dirname(assetPath));

      List<FileSystemEntity> files = assetDir.listSync(recursive: true);

      for (FileSystemEntity entity in files) {
        if (!FileSystemEntity.isFileSync(entity.path))
          continue;

        // Exclude any files in the given directories.
        if (excludeDirs.any((String exclude) => entity.path.startsWith(exclude)))
          continue;

        if (path.basename(entity.path) == assetFilename && entity.path != assetPath) {
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

        _Asset baseAsset = _resolveAsset(packageMap, assetBase, assetPathOverrides, asset);
        if (!baseAsset.assetFileExists) {
          printError('Error: unable to locate asset entry in flutter.yaml: "$asset".');
          return null;
        }

        result[baseAsset] = <_Asset>[];
      }
    }
  }

  return result;
}

_Asset _resolveAsset(
  PackageMap packageMap,
  String assetBase,
  Map<String, String> assetPathOverrides,
  String asset
) {
  String overridePath = assetPathOverrides[asset];
  if (overridePath != null) {
    return new _Asset(
      base: path.dirname(overridePath),
      source: path.basename(overridePath),
      relativePath: asset
    );
  }

  if (asset.startsWith('packages/') && !FileSystemEntity.isFileSync(path.join(assetBase, asset))) {
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
  String schemaPath = path.join(path.absolute(Cache.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'flutter_yaml.json');
  Schema schema = await Schema.createSchemaFromUrl('file://$schemaPath');

  Validator validator = new Validator(schema);
  if (validator.validate(manifest)) {
    return 0;
  } else {
    if (validator.errors.length == 1) {
      printError('Error in flutter.yaml: ${validator.errors.first}');
    } else {
      printError('Error in flutter.yaml:');
      printError('  ' + validator.errors.join('\n  '));
    }

    return 1;
  }
}

/// Create a [ZipEntry] from the given [_Asset]; the asset must exist.
ZipEntry _createAssetEntry(_Asset asset) {
  assert(asset.assetFileExists);
  return new ZipEntry.fromFile(asset.assetEntry, asset.assetFile);
}

ZipEntry _createAssetManifest(Map<_Asset, List<_Asset>> assetVariants) {
  Map<String, List<String>> json = <String, List<String>>{};
  for (_Asset main in assetVariants.keys) {
    List<String> variants = <String>[];
    for (_Asset variant in assetVariants[main])
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
///
/// Return `null` on failure.
Future<String> buildFlx({
  String mainPath: defaultMainPath,
  bool precompiledSnapshot: false,
  bool includeRobotoFonts: true
}) async {
  int result;
  String localBundlePath = path.join('build', 'app.flx');
  String localSnapshotPath = path.join('build', 'snapshot_blob.bin');
  result = await build(
    snapshotPath: localSnapshotPath,
    outputPath: localBundlePath,
    mainPath: mainPath,
    precompiledSnapshot: precompiledSnapshot,
    includeRobotoFonts: includeRobotoFonts
  );
  return result == 0 ? localBundlePath : null;
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

Future<int> build({
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
    int result = await createSnapshot(
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
  Map<String, String> assetPathOverrides: const <String, String>{},
  String outputPath: defaultFlxOutputPath,
  String privateKeyPath: defaultPrivateKeyPath,
  String workingDirPath: defaultWorkingDirPath,
  bool includeRobotoFonts: true
}) async {
  printTrace('Building $outputPath');

  Map<_Asset, List<_Asset>> assetVariants = _parseAssets(
    new PackageMap(path.join(assetBasePath, '.packages')),
    manifestDescriptor,
    assetBasePath,
    assetPathOverrides,
    excludeDirs: <String>[workingDirPath, path.join(assetBasePath, 'build')]
  );

  if (assetVariants == null)
    return 1;

  final bool usesMaterialDesign = manifestDescriptor != null &&
    manifestDescriptor['uses-material-design'] == true;

  ZipBuilder zipBuilder = new ZipBuilder();

  if (snapshotFile != null)
    zipBuilder.addEntry(new ZipEntry.fromFile(_kSnapshotKey, snapshotFile));

  for (_Asset asset in assetVariants.keys) {
    ZipEntry assetEntry = _createAssetEntry(asset);
    if (assetEntry == null)
      return 1;
    zipBuilder.addEntry(assetEntry);

    for (_Asset variant in assetVariants[asset]) {
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

  zipBuilder.addEntry(_createAssetManifest(assetVariants));

  ZipEntry fontManifest = _createFontManifest(manifestDescriptor, usesMaterialDesign, includeRobotoFonts);
  if (fontManifest != null)
    zipBuilder.addEntry(fontManifest);

  ensureDirectoryExists(outputPath);

  printTrace('Encoding zip file to $outputPath');
  zipBuilder.createZip(new File(outputPath), new Directory(workingDirPath));

  printTrace('Built $outputPath.');

  return 0;
}
