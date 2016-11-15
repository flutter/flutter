// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'build_info.dart';
import 'cache.dart';
import 'dart/package_map.dart';
import 'globals.dart';

/// An entry in an asset bundle.
class AssetBundleEntry {
  /// An entry backed by a File.
  AssetBundleEntry.fromFile(this.archivePath, this.file)
      : _contents = null;

  /// An entry backed by a String.
  AssetBundleEntry.fromString(this.archivePath, this._contents)
      : file = null;

  /// The path within the bundle.
  final String archivePath;

  /// The payload.
  List<int> contentsAsBytes() {
    if (_contents != null) {
      return UTF8.encode(_contents);
    } else {
      return file.readAsBytesSync();
    }
  }

  bool get isStringEntry => _contents != null;
  int get contentsLength => _contents.length;

  final File file;
  final String _contents;
}

/// A bundle of assets.
class AssetBundle {
  final Set<AssetBundleEntry> entries = new Set<AssetBundleEntry>();

  static const String defaultManifestPath = 'flutter.yaml';
  static const String _kFontSetMaterial = 'material';
  static const String _kFontSetRoboto = 'roboto';

  bool _fixed = false;
  DateTime _lastBuildTimestamp;

  /// Constructs an [AssetBundle] that gathers the set of assets from the
  /// flutter.yaml manifest.
  AssetBundle();

  /// Constructs an [AssetBundle] with a fixed set of assets.
  /// [projectRoot] The absolute path to the project root.
  /// [projectAssets] comma separated list of assets.
  AssetBundle.fixed(String projectRoot, String projectAssets) {
    _fixed = true;
    if ((projectRoot == null) || (projectAssets == null))
      return;

    List<String> assets = projectAssets.split(',');
    for (String asset in assets) {
      if (asset == '')
        continue;
      final String assetPath = path.join(projectRoot, asset);
      final String archivePath = asset;
      entries.add(
          new AssetBundleEntry.fromFile(archivePath, new File(assetPath)));
    }
  }

  bool needsBuild({String manifestPath: defaultManifestPath}) {
    if (_fixed)
      return false;
    if (_lastBuildTimestamp == null)
      return true;

    FileStat stat = new File(manifestPath).statSync();
    if (stat.type == FileSystemEntityType.NOT_FOUND)
      return true;

    return stat.modified.isAfter(_lastBuildTimestamp);
  }

  Future<int> build({
    String manifestPath: defaultManifestPath,
    String workingDirPath,
    String packagesPath,
    bool includeDefaultFonts: true,
    bool includeRobotoFonts: true,
    bool reportLicensedPackages: false
  }) async {
    workingDirPath ??= getAssetBuildDirectory();
    packagesPath ??= path.absolute(PackageMap.globalPackagesPath);
    Object manifest;
    try {
      manifest = _loadFlutterYamlManifest(manifestPath);
    } catch (e) {
      printStatus('Error detected in flutter.yaml:', emphasis: true);
      printError(e);
      return 1;
    }
    if (manifest == null) {
      // No manifest file found for this application.
      return 0;
    }
    if (manifest != null) {
     int result = await _validateFlutterYamlManifest(manifest);
     if (result != 0)
       return result;
    }
    Map<String, dynamic> manifestDescriptor = manifest;
    assert(manifestDescriptor != null);
    String assetBasePath = path.dirname(path.absolute(manifestPath));

    _lastBuildTimestamp = new DateTime.now();

    final PackageMap packageMap = new PackageMap(packagesPath);

    Map<_Asset, List<_Asset>> assetVariants = _parseAssets(
      packageMap,
      manifestDescriptor,
      assetBasePath,
      excludeDirs: <String>[workingDirPath, getBuildDirectory()]
    );

    if (assetVariants == null)
      return 1;

    final bool usesMaterialDesign = (manifestDescriptor != null) &&
        manifestDescriptor['uses-material-design'];

    for (_Asset asset in assetVariants.keys) {
      AssetBundleEntry assetEntry = _createAssetEntry(asset);
      if (assetEntry == null)
        return 1;
      entries.add(assetEntry);

      for (_Asset variant in assetVariants[asset]) {
        AssetBundleEntry variantEntry = _createAssetEntry(variant);
        if (variantEntry == null)
          return 1;
        entries.add(variantEntry);
      }
    }

    List<_Asset> materialAssets = <_Asset>[];
    if (usesMaterialDesign && includeDefaultFonts) {
      materialAssets.addAll(_getMaterialAssets(_kFontSetMaterial));
      if (includeRobotoFonts)
        materialAssets.addAll(_getMaterialAssets(_kFontSetRoboto));
    }
    for (_Asset asset in materialAssets) {
      AssetBundleEntry assetEntry = _createAssetEntry(asset);
      if (assetEntry == null)
        return 1;
      entries.add(assetEntry);
    }

    entries.add(_createAssetManifest(assetVariants));

    AssetBundleEntry fontManifest =
        _createFontManifest(manifestDescriptor, usesMaterialDesign, includeDefaultFonts, includeRobotoFonts);
    if (fontManifest != null)
      entries.add(fontManifest);

    // TODO(ianh): Only do the following line if we've changed packages or if our LICENSE file changed
    entries.add(await _obtainLicenses(packageMap, assetBasePath, reportPackages: reportLicensedPackages));

    return 0;
  }

  void dump() {
    printTrace('Dumping AssetBundle:');
    for (AssetBundleEntry entry in entries) {
      printTrace(entry.archivePath);
    }
  }
}

class _Asset {
  _Asset({ this.base, String assetEntry, this.relativePath, this.source }) {
    this._assetEntry = assetEntry;
  }

  String _assetEntry;

  final String base;

  /// The entry to list in the generated asset manifest.
  String get assetEntry => _assetEntry ?? relativePath;

  /// Where the resource is on disk relative to [base].
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

final String _licenseSeparator = '\n' + ('-' * 80) + '\n';

/// Returns a AssetBundleEntry representing the license file.
Future<AssetBundleEntry> _obtainLicenses(
  PackageMap packageMap,
  String assetBase,
  { bool reportPackages }
) async {
  // Read the LICENSE file from each package in the .packages file, splitting
  // each one into each component license (so that we can de-dupe if possible).
  //
  // Individual licenses inside each LICENSE file should be separated by 80
  // hyphens on their own on a line.
  //
  // If a LICENSE file contains more than one component license, then each
  // component license must start with the names of the packages to which the
  // component license applies, with each package name on its own line, and the
  // list of package names separated from the actual license text by a blank
  // line. (The packages need not match the names of the pub package. For
  // example, a package might itself contain code from multiple third-party
  // sources, and might need to include a license for each one.)
  final Map<String, Set<String>> packageLicenses = <String, Set<String>>{};
  final Set<String> allPackages = new Set<String>();
  for (String packageName in packageMap.map.keys) {
    final Uri package = packageMap.map[packageName];
    if (package != null && package.scheme == 'file') {
      final File file = new File.fromUri(package.resolve('../LICENSE'));
      if (file.existsSync()) {
        final List<String> rawLicenses =
            (await file.readAsString()).split(_licenseSeparator);
        for (String rawLicense in rawLicenses) {
          List<String> packageNames;
          String licenseText;
          if (rawLicenses.length > 1) {
            final int split = rawLicense.indexOf('\n\n');
            if (split >= 0) {
              packageNames = rawLicense.substring(0, split).split('\n');
              licenseText = rawLicense.substring(split + 2);
            }
          }
          if (licenseText == null) {
            packageNames = <String>[packageName];
            licenseText = rawLicense;
          }
          packageLicenses.putIfAbsent(licenseText, () => new Set<String>())
            ..addAll(packageNames);
          allPackages.addAll(packageNames);
        }
      }
    }
  }

  if (reportPackages) {
    final List<String> allPackagesList = allPackages.toList()..sort();
    printStatus('Licenses were found for the following packages:');
    printStatus(allPackagesList.join(', '));
  }

  final List<String> combinedLicensesList = packageLicenses.keys.map(
    (String license) {
      List<String> packageNames = packageLicenses[license].toList()
       ..sort();
      return packageNames.join('\n') + '\n\n' + license;
    }
  ).toList();
  combinedLicensesList.sort();

  final String combinedLicenses = combinedLicensesList.join(_licenseSeparator);

  return new AssetBundleEntry.fromString('LICENSE', combinedLicenses);
}


/// Create a [AssetBundleEntry] from the given [_Asset]; the asset must exist.
AssetBundleEntry _createAssetEntry(_Asset asset) {
  assert(asset.assetFileExists);
  return new AssetBundleEntry.fromFile(asset.assetEntry, asset.assetFile);
}

AssetBundleEntry _createAssetManifest(Map<_Asset, List<_Asset>> assetVariants) {
  Map<String, List<String>> json = <String, List<String>>{};
  for (_Asset main in assetVariants.keys) {
    List<String> variants = <String>[];
    for (_Asset variant in assetVariants[main])
      variants.add(variant.relativePath);
    json[main.relativePath] = variants;
  }
  return new AssetBundleEntry.fromString('AssetManifest.json', JSON.encode(json));
}

AssetBundleEntry _createFontManifest(Map<String, dynamic> manifestDescriptor,
                             bool usesMaterialDesign,
                             bool includeDefaultFonts,
                             bool includeRobotoFonts) {
  List<Map<String, dynamic>> fonts = <Map<String, dynamic>>[];
  if (usesMaterialDesign && includeDefaultFonts) {
    fonts.addAll(_getMaterialFonts(AssetBundle._kFontSetMaterial));
    if (includeRobotoFonts)
      fonts.addAll(_getMaterialFonts(AssetBundle._kFontSetRoboto));
  }
  if (manifestDescriptor != null && manifestDescriptor.containsKey('fonts'))
    fonts.addAll(manifestDescriptor['fonts']);
  if (fonts.isEmpty)
    return null;
  return new AssetBundleEntry.fromString('FontManifest.json', JSON.encode(fonts));
}

/// Given an assetBase location and a flutter.yaml manifest, return a map of
/// assets to asset variants.
///
/// Returns `null` on missing assets.
Map<_Asset, List<_Asset>> _parseAssets(
  PackageMap packageMap,
  Map<String, dynamic> manifestDescriptor,
  String assetBase, {
  List<String> excludeDirs: const <String>[]
}) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};

  if (manifestDescriptor == null)
    return result;

  excludeDirs = excludeDirs.map(
    (String exclude) => path.absolute(exclude) + Platform.pathSeparator).toList();

  if (manifestDescriptor.containsKey('assets')) {
    for (String asset in manifestDescriptor['assets']) {
      _Asset baseAsset = _resolveAsset(packageMap, assetBase, asset);

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

        _Asset baseAsset = _resolveAsset(packageMap, assetBase, asset);
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
  String asset
) {
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

dynamic _loadFlutterYamlManifest(String manifestPath) {
  if (manifestPath == null || !FileSystemEntity.isFileSync(manifestPath))
    return null;
  String manifestDescriptor = new File(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

Future<int> _validateFlutterYamlManifest(Object manifest) async {
  String schemaPath = path.join(path.absolute(Cache.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'flutter_yaml.json');
  Schema schema = await Schema.createSchemaFromUrl('file://$schemaPath');

  Validator validator = new Validator(schema);
  if (validator.validate(manifest)) {
    return 0;
  } else {
    printStatus('Error detected in flutter.yaml:', emphasis: true);
    printError(validator.errors.join('\n'));
    return 1;
  }
}
