// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'cache.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'flutter_manifest.dart';
import 'globals.dart';

const AssetBundleFactory _kManifestFactory = const _ManifestAssetBundleFactory();

/// Injected factory class for spawning [AssetBundle] instances.
abstract class AssetBundleFactory {
  /// The singleton instance, pulled from the [AppContext].
  static AssetBundleFactory get instance => context == null
      ? _kManifestFactory
      : context.putIfAbsent(AssetBundleFactory, () => _kManifestFactory);

  /// Creates a new [AssetBundle].
  AssetBundle createBundle();
}

abstract class AssetBundle {
  Map<String, DevFSContent> get entries;

  bool wasBuiltOnce();

  bool needsBuild({String manifestPath: _ManifestAssetBundle.defaultManifestPath});

  /// Returns 0 for success; non-zero for failure.
  Future<int> build({
    String manifestPath: _ManifestAssetBundle.defaultManifestPath,
    String workingDirPath,
    String packagesPath,
    bool includeDefaultFonts: true,
    bool reportLicensedPackages: false
  });
}

class _ManifestAssetBundleFactory implements AssetBundleFactory {
  const _ManifestAssetBundleFactory();

  @override
  AssetBundle createBundle() => new _ManifestAssetBundle();
}

class _ManifestAssetBundle implements AssetBundle {
  @override
  final Map<String, DevFSContent> entries = <String, DevFSContent>{};

  static const String defaultManifestPath = 'pubspec.yaml';
  static const String _kAssetManifestJson = 'AssetManifest.json';
  static const String _kFontManifestJson = 'FontManifest.json';
  static const String _kFontSetMaterial = 'material';
  static const String _kLICENSE = 'LICENSE';

  DateTime _lastBuildTimestamp;

  /// Constructs an [_ManifestAssetBundle] that gathers the set of assets from the
  /// pubspec.yaml manifest.
  _ManifestAssetBundle();

  @override
  bool wasBuiltOnce() => _lastBuildTimestamp != null;

  @override
  bool needsBuild({String manifestPath: defaultManifestPath}) {
    if (_lastBuildTimestamp == null)
      return true;

    final FileStat stat = fs.file(manifestPath).statSync();
    if (stat.type == FileSystemEntityType.NOT_FOUND)
      return true;

    return stat.modified.isAfter(_lastBuildTimestamp);
  }

  @override
  Future<int> build({
    String manifestPath: defaultManifestPath,
    String workingDirPath,
    String packagesPath,
    bool includeDefaultFonts: true,
    bool reportLicensedPackages: false
  }) async {
    workingDirPath ??= getAssetBuildDirectory();
    packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
    FlutterManifest flutterManifest;
    try {
      flutterManifest = await FlutterManifest.createFromPath(manifestPath);
    } catch (e) {
      printStatus('Error detected in pubspec.yaml:', emphasis: true);
      printError('$e');
      return 1;
    }
    if (flutterManifest == null)
      return 1;

    if (flutterManifest.isEmpty) {
      entries[_kAssetManifestJson] = new DevFSStringContent('{}');
      return 0;
    }

    final String assetBasePath = fs.path.dirname(fs.path.absolute(manifestPath));

    _lastBuildTimestamp = new DateTime.now();

    final PackageMap packageMap = new PackageMap(packagesPath);

    // The _assetVariants map contains an entry for each asset listed
    // in the pubspec.yaml file's assets and font and sections. The
    // value of each image asset is a list of resolution-specific "variants",
    // see _AssetDirectoryCache.
    final Map<_Asset, List<_Asset>> assetVariants = _parseAssets(
      packageMap,
      flutterManifest,
      assetBasePath,
      excludeDirs: <String>[workingDirPath, getBuildDirectory()]
    );

    if (assetVariants == null)
      return 1;

    final List<Map<String, dynamic>> fonts = _parseFonts(
      flutterManifest,
      includeDefaultFonts,
      packageMap,
    );

    // Add fonts and assets from packages.
    for (String packageName in packageMap.map.keys) {
      final Uri package = packageMap.map[packageName];
      if (package != null && package.scheme == 'file') {
        final String packageManifestPath = fs.path.fromUri(package.resolve('../pubspec.yaml'));
        final FlutterManifest packageFlutterManifest = await FlutterManifest.createFromPath(packageManifestPath);
        if (packageFlutterManifest == null)
          continue;
        // Skip the app itself
        if (packageFlutterManifest.appName == flutterManifest.appName)
          continue;
        final String packageBasePath = fs.path.dirname(packageManifestPath);

        final Map<_Asset, List<_Asset>> packageAssets = _parseAssets(
          packageMap,
          packageFlutterManifest,
          packageBasePath,
          packageName: packageName,
        );

        if (packageAssets == null)
          return 1;
        assetVariants.addAll(packageAssets);

        fonts.addAll(_parseFonts(
          packageFlutterManifest,
          includeDefaultFonts,
          packageMap,
          packageName: packageName,
        ));
      }
    }

    // Save the contents of each image, image variant, and font
    // asset in entries.
    for (_Asset asset in assetVariants.keys) {
      if (!asset.assetFileExists && assetVariants[asset].isEmpty) {
        printStatus('Error detected in pubspec.yaml:', emphasis: true);
        printError('No file or variants found for $asset.\n');
        return 1;
      }
      // The file name for an asset's "main" entry is whatever appears in
      // the pubspec.yaml file. The main entry's file must always exist for
      // font assets. It need not exist for an image if resolution-specific
      // variant files exist. An image's main entry is treated the same as a
      // "1x" resolution variant and if both exist then the explicit 1x
      // variant is preferred.
      if (asset.assetFileExists) {
        assert(!assetVariants[asset].contains(asset));
        assetVariants[asset].insert(0, asset);
      }
      for (_Asset variant in assetVariants[asset]) {
        assert(variant.assetFileExists);
        entries[variant.entryUri.path] = new DevFSFileContent(variant.assetFile);
      }
    }

    final List<_Asset> materialAssets = <_Asset>[];
    if (flutterManifest.usesMaterialDesign && includeDefaultFonts) {
      materialAssets.addAll(_getMaterialAssets(_kFontSetMaterial));
    }
    for (_Asset asset in materialAssets) {
      assert(asset.assetFileExists);
      entries[asset.entryUri.path] = new DevFSFileContent(asset.assetFile);
    }

    entries[_kAssetManifestJson] = _createAssetManifest(assetVariants);


    if (fonts.isNotEmpty)
      entries[_kFontManifestJson] = new DevFSStringContent(json.encode(fonts));

    // TODO(ianh): Only do the following line if we've changed packages or if our LICENSE file changed
    entries[_kLICENSE] = await _obtainLicenses(packageMap, assetBasePath, reportPackages: reportLicensedPackages);

    return 0;
  }
}

class _Asset {
  _Asset({ this.baseDir, this.relativeUri, this.entryUri });

  final String baseDir;

  /// A platform-independent Uri where this asset can be found on disk on the
  /// host system relative to [baseDir].
  final Uri relativeUri;

  /// A platform-independent Uri representing the entry for the asset manifest.
  final Uri entryUri;

  File get assetFile {
    return fs.file(fs.path.join(baseDir, fs.path.fromUri(relativeUri)));
  }

  bool get assetFileExists => assetFile.existsSync();

  /// The delta between what the entryUri is and the relativeUri (e.g.,
  /// packages/flutter_gallery).
  Uri get symbolicPrefixUri {
    if (entryUri == relativeUri)
      return null;
    final int index = entryUri.path.indexOf(relativeUri.path);
    return index == -1 ? null : new Uri(path: entryUri.path.substring(0, index));
  }

  @override
  String toString() => 'asset: $entryUri';

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final _Asset otherAsset = other;
    return otherAsset.baseDir == baseDir
        && otherAsset.relativeUri == relativeUri
        && otherAsset.entryUri == entryUri;
  }

  @override
  int get hashCode {
    return baseDir.hashCode
        ^relativeUri.hashCode
        ^ entryUri.hashCode;
  }
}

Map<String, dynamic> _readMaterialFontsManifest() {
  final String fontsPath = fs.path.join(fs.path.absolute(Cache.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'material_fonts.yaml');

  return loadYaml(fs.file(fontsPath).readAsStringSync());
}

final Map<String, dynamic> _materialFontsManifest = _readMaterialFontsManifest();

List<Map<String, dynamic>> _getMaterialFonts(String fontSet) {
  return _materialFontsManifest[fontSet];
}

List<_Asset> _getMaterialAssets(String fontSet) {
  final List<_Asset> result = <_Asset>[];

  for (Map<String, dynamic> family in _getMaterialFonts(fontSet)) {
    for (Map<String, dynamic> font in family['fonts']) {
      final Uri entryUri = fs.path.toUri(font['asset']);
      result.add(new _Asset(
        baseDir: fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
        relativeUri: new Uri(path: entryUri.pathSegments.last),
        entryUri: entryUri
      ));
    }
  }

  return result;
}

final String _licenseSeparator = '\n' + ('-' * 80) + '\n';

/// Returns a DevFSContent representing the license file.
Future<DevFSContent> _obtainLicenses(
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
      final File file = fs.file(package.resolve('../LICENSE'));
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
      final List<String> packageNames = packageLicenses[license].toList()
       ..sort();
      return packageNames.join('\n') + '\n\n' + license;
    }
  ).toList();
  combinedLicensesList.sort();

  final String combinedLicenses = combinedLicensesList.join(_licenseSeparator);

  return new DevFSStringContent(combinedLicenses);
}

DevFSContent _createAssetManifest(Map<_Asset, List<_Asset>> assetVariants) {
  final Map<String, List<String>> jsonObject = <String, List<String>>{};
  for (_Asset main in assetVariants.keys) {
    final List<String> variants = <String>[];
    for (_Asset variant in assetVariants[main])
      variants.add(variant.entryUri.path);
    jsonObject[main.entryUri.path] = variants;
  }
  return new DevFSStringContent(json.encode(jsonObject));
}

List<Map<String, dynamic>> _parseFonts(
  FlutterManifest manifest,
  bool includeDefaultFonts,
  PackageMap packageMap, {
  String packageName
}) {
  final List<Map<String, dynamic>> fonts = <Map<String, dynamic>>[];
  if (manifest.usesMaterialDesign && includeDefaultFonts) {
    fonts.addAll(_getMaterialFonts(_ManifestAssetBundle._kFontSetMaterial));
  }
  if (packageName == null) {
    fonts.addAll(manifest.fontsDescriptor);
  } else {
    fonts.addAll(_createFontsDescriptor(_parsePackageFonts(
      manifest,
      packageName,
      packageMap,
    )));
  }
  return fonts;
}

/// Prefixes family names and asset paths of fonts included from packages with
/// 'packages/<package_name>'
List<Font> _parsePackageFonts(
  FlutterManifest manifest,
  String packageName,
  PackageMap packageMap,
) {
  final List<Font> packageFonts = <Font>[];
  for (Font font in manifest.fonts) {
    final List<FontAsset> packageFontAssets = <FontAsset>[];
    for (FontAsset fontAsset in font.fontAssets) {
      final Uri assetUri = fontAsset.assetUri;
      if (assetUri.pathSegments.first == 'packages' &&
          !fs.isFileSync(fs.path.fromUri(packageMap.map[packageName].resolve('../${assetUri.path}')))) {
        packageFontAssets.add(new FontAsset(
          fontAsset.assetUri,
          weight: fontAsset.weight,
          style: fontAsset.style,
        ));
      } else {
        packageFontAssets.add(new FontAsset(
          new Uri(pathSegments: <String>['packages', packageName]..addAll(assetUri.pathSegments)),
          weight: fontAsset.weight,
          style: fontAsset.style,
        ));
      }
    }
    packageFonts.add(new Font('packages/$packageName/${font.familyName}', packageFontAssets));
  }
  return packageFonts;
}

List<Map<String, dynamic>> _createFontsDescriptor(List<Font> fonts) {
  return fonts.map((Font font) => font.descriptor).toList();
}

// Given an assets directory like this:
//
// assets/foo
// assets/var1/foo
// assets/var2/foo
// assets/bar
//
// variantsFor('assets/foo') => ['/assets/var1/foo', '/assets/var2/foo']
// variantsFor('assets/bar') => []
class _AssetDirectoryCache {
  _AssetDirectoryCache(Iterable<String> excluded) {
    _excluded = excluded.map<String>((String path) => fs.path.absolute(path) + fs.path.separator);
  }

  Iterable<String> _excluded;
  final Map<String, Map<String, List<String>>> _cache = <String, Map<String, List<String>>>{};

  List<String> variantsFor(String assetPath) {
    final String assetName = fs.path.basename(assetPath);
    final String directory = fs.path.dirname(assetPath);

    if (!fs.directory(directory).existsSync())
      return const <String>[];

    if (_cache[directory] == null) {
      final List<String> paths = <String>[];
      for (FileSystemEntity entity in fs.directory(directory).listSync(recursive: true)) {
        final String path = entity.path;
        if (fs.isFileSync(path) && !_excluded.any((String exclude) => path.startsWith(exclude)))
          paths.add(path);
      }

      final Map<String, List<String>> variants = <String, List<String>>{};
      for (String path in paths) {
        final String variantName = fs.path.basename(path);
        if (directory == fs.path.dirname(path))
          continue;
        variants[variantName] ??= <String>[];
        variants[variantName].add(path);
      }
      _cache[directory] = variants;
    }

    return _cache[directory][assetName] ?? const <String>[];
  }
}

/// Given an assetBase location and a pubspec.yaml Flutter manifest, return a
/// map of assets to asset variants.
///
/// Returns null on missing assets.
Map<_Asset, List<_Asset>> _parseAssets(
  PackageMap packageMap,
  FlutterManifest flutterManifest,
  String assetBase, {
  List<String> excludeDirs: const <String>[],
  String packageName
}) {
  final Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};

  final _AssetDirectoryCache cache = new _AssetDirectoryCache(excludeDirs);
  for (Uri assetUri in flutterManifest.assets) {
    final _Asset asset = _resolveAsset(
      packageMap,
      assetBase,
      assetUri,
      packageName,
    );
    final List<_Asset> variants = <_Asset>[];
    for (String path in cache.variantsFor(asset.assetFile.path)) {
      final String relativePath = fs.path.relative(path, from: asset.baseDir);
      final Uri relativeUri = fs.path.toUri(relativePath);
      final Uri entryUri = asset.symbolicPrefixUri == null
          ? relativeUri
          : asset.symbolicPrefixUri.resolveUri(relativeUri);
      variants.add(new _Asset(
        baseDir: asset.baseDir,
        entryUri: entryUri,
        relativeUri: relativeUri,
      ));
    }

    result[asset] = variants;
  }

  // Add assets referenced in the fonts section of the manifest.
  for (Font font in flutterManifest.fonts) {
    for (FontAsset fontAsset in font.fontAssets) {
      final _Asset baseAsset = _resolveAsset(
        packageMap,
        assetBase,
        fontAsset.assetUri,
        packageName,
      );
      if (!baseAsset.assetFileExists) {
        printError('Error: unable to locate asset entry in pubspec.yaml: "${fontAsset.assetUri}".');
        return null;
      }

      result[baseAsset] = <_Asset>[];
    }
  }

  return result;
}

_Asset _resolveAsset(
  PackageMap packageMap,
  String assetsBaseDir,
  Uri assetUri,
  String packageName,
) {
  final String assetPath = fs.path.fromUri(assetUri);
  if (assetUri.pathSegments.first == 'packages' && !fs.isFileSync(fs.path.join(assetsBaseDir, assetPath))) {
    // The asset is referenced in the pubspec.yaml as
    // 'packages/PACKAGE_NAME/PATH/TO/ASSET .
    final _Asset packageAsset = _resolvePackageAsset(assetUri, packageMap);
    if (packageAsset != null)
      return packageAsset;
  }

  return new _Asset(
    baseDir: assetsBaseDir,
    entryUri: packageName == null
        ? assetUri // Asset from the current application.
        : new Uri(pathSegments: <String>['packages', packageName]..addAll(assetUri.pathSegments)), // Asset from, and declared in $packageName.
    relativeUri: assetUri,
  );
}

_Asset _resolvePackageAsset(Uri assetUri, PackageMap packageMap) {
  assert(assetUri.pathSegments.first == 'packages');
  if (assetUri.pathSegments.length > 1) {
    final String packageName = assetUri.pathSegments[1];
    final Uri packageUri = packageMap.map[packageName];
    if (packageUri != null && packageUri.scheme == 'file') {
      return new _Asset(
        baseDir: fs.path.fromUri(packageUri),
        entryUri: assetUri,
        relativeUri: new Uri(pathSegments: assetUri.pathSegments.sublist(2)),
      );
    }
  }
  printStatus('Error detected in pubspec.yaml:', emphasis: true);
  printError('Could not resolve package for asset $assetUri.\n');
  return null;
}
