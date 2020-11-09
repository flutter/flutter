// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'cache.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'flutter_manifest.dart';
import 'globals.dart' as globals;
import 'project.dart';

const AssetBundleFactory _kManifestFactory = _ManifestAssetBundleFactory();

const String defaultManifestPath = 'pubspec.yaml';

const String kFontManifestJson = 'FontManifest.json';

/// Injected factory class for spawning [AssetBundle] instances.
abstract class AssetBundleFactory {
  /// The singleton instance, pulled from the [AppContext].
  static AssetBundleFactory get instance => context.get<AssetBundleFactory>();

  static AssetBundleFactory get defaultInstance => _kManifestFactory;

  /// Creates a new [AssetBundle].
  AssetBundle createBundle();
}

abstract class AssetBundle {
  Map<String, DevFSContent> get entries;

  /// Additional files that this bundle depends on that are not included in the
  /// output result.
  List<File> get additionalDependencies;

  bool wasBuiltOnce();

  bool needsBuild({ String manifestPath = defaultManifestPath });

  /// Returns 0 for success; non-zero for failure.
  Future<int> build({
    String manifestPath = defaultManifestPath,
    String assetDirPath,
    @required String packagesPath,
    bool includeDefaultFonts = true,
    bool reportLicensedPackages = false,
  });
}

class _ManifestAssetBundleFactory implements AssetBundleFactory {
  const _ManifestAssetBundleFactory();

  @override
  AssetBundle createBundle() => ManifestAssetBundle();
}

/// An asset bundle based on a pubspec.yaml file.
class ManifestAssetBundle implements AssetBundle {
  /// Constructs an [ManifestAssetBundle] that gathers the set of assets from the
  /// pubspec.yaml manifest.
  ManifestAssetBundle();

  @override
  final Map<String, DevFSContent> entries = <String, DevFSContent>{};

  // If an asset corresponds to a wildcard directory, then it may have been
  // updated without changes to the manifest. These are only tracked for
  // the current project.
  final Map<Uri, Directory> _wildcardDirectories = <Uri, Directory>{};

  final LicenseCollector licenseCollector = LicenseCollector(fileSystem: globals.fs);

  DateTime _lastBuildTimestamp;

  static const String _kAssetManifestJson = 'AssetManifest.json';
  static const String _kFontSetMaterial = 'material';
  static const String _kNoticeFile = 'NOTICES';

  @override
  bool wasBuiltOnce() => _lastBuildTimestamp != null;

  @override
  bool needsBuild({ String manifestPath = defaultManifestPath }) {
    if (_lastBuildTimestamp == null) {
      return true;
    }

    final FileStat stat = globals.fs.file(manifestPath).statSync();
    if (stat.type == FileSystemEntityType.notFound) {
      return true;
    }

    for (final Directory directory in _wildcardDirectories.values) {
      if (!directory.existsSync()) {
        return true; // directory was deleted.
      }
      for (final File file in directory.listSync().whereType<File>()) {
        final DateTime dateTime = file.statSync().modified;
        if (dateTime == null) {
          continue;
        }
        if (dateTime.isAfter(_lastBuildTimestamp)) {
          return true;
        }
      }
    }

    return stat.modified.isAfter(_lastBuildTimestamp);
  }

  @override
  Future<int> build({
    String manifestPath = defaultManifestPath,
    String assetDirPath,
    @required String packagesPath,
    bool includeDefaultFonts = true,
    bool reportLicensedPackages = false,
  }) async {
    assetDirPath ??= getAssetBuildDirectory();
    FlutterProject flutterProject;
    try {
      flutterProject = FlutterProject.fromDirectory(globals.fs.file(manifestPath).parent);
    } on Exception catch (e) {
      globals.printStatus('Error detected in pubspec.yaml:', emphasis: true);
      globals.printError('$e');
      return 1;
    }
    if (flutterProject == null) {
      return 1;
    }
    final FlutterManifest flutterManifest = flutterProject.manifest;
    // If the last build time isn't set before this early return, empty pubspecs will
    // hang on hot reload, as the incremental dill files will never be copied to the
    // device.
    _lastBuildTimestamp = DateTime.now();
    if (flutterManifest.isEmpty) {
      entries[_kAssetManifestJson] = DevFSStringContent('{}');
      return 0;
    }

    final String assetBasePath = globals.fs.path.dirname(globals.fs.path.absolute(manifestPath));
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      globals.fs.file(packagesPath),
      logger: globals.logger,
    );
    final List<Uri> wildcardDirectories = <Uri>[];

    // The _assetVariants map contains an entry for each asset listed
    // in the pubspec.yaml file's assets and font and sections. The
    // value of each image asset is a list of resolution-specific "variants",
    // see _AssetDirectoryCache.
    final Map<_Asset, List<_Asset>> assetVariants = _parseAssets(
      packageConfig,
      flutterManifest,
      wildcardDirectories,
      assetBasePath,
      excludeDirs: <String>[
        assetDirPath,
        getBuildDirectory(),
        if (flutterProject.ios.existsSync())
          flutterProject.ios.hostAppRoot.path,
        if (flutterProject.macos.existsSync())
          flutterProject.macos.managedDirectory.path,
        if (flutterProject.windows.existsSync())
          flutterProject.windows.managedDirectory.path,
        if (flutterProject.linux.existsSync())
          flutterProject.linux.managedDirectory.path,
      ],
    );

    if (assetVariants == null) {
      return 1;
    }

    final bool includesMaterialFonts = flutterManifest.usesMaterialDesign;
    final List<Map<String, dynamic>> fonts = _parseFonts(
      flutterManifest,
      includeDefaultFonts,
      packageConfig,
      primary: true,
    );

    // Add fonts and assets from packages.
    for (final Package package in packageConfig.packages) {
      final Uri packageUri = package.packageUriRoot;
      if (packageUri != null && packageUri.scheme == 'file') {
        final String packageManifestPath = globals.fs.path.fromUri(packageUri.resolve('../pubspec.yaml'));
        final FlutterManifest packageFlutterManifest = FlutterManifest.createFromPath(
          packageManifestPath,
          logger: globals.logger,
          fileSystem: globals.fs,
        );
        if (packageFlutterManifest == null) {
          continue;
        }
        // Skip the app itself
        if (packageFlutterManifest.appName == flutterManifest.appName) {
          continue;
        }
        final String packageBasePath = globals.fs.path.dirname(packageManifestPath);

        final Map<_Asset, List<_Asset>> packageAssets = _parseAssets(
          packageConfig,
          packageFlutterManifest,
          // Do not track wildcard directories for dependencies.
          <Uri>[],
          packageBasePath,
          packageName: package.name,
          attributedPackage: package,
        );

        if (packageAssets == null) {
          return 1;
        }
        assetVariants.addAll(packageAssets);
        if (!includesMaterialFonts && packageFlutterManifest.usesMaterialDesign) {
          globals.printError(
            'package:${package.name} has `uses-material-design: true` set but '
            'the primary pubspec contains `uses-material-design: false`. '
            'If the application needs material icons, then `uses-material-design` '
            ' must be set to true.'
          );
        }
        fonts.addAll(_parseFonts(
          packageFlutterManifest,
          includeDefaultFonts,
          packageConfig,
          packageName: package.name,
          primary: false,
        ));
      }
    }

    // Save the contents of each image, image variant, and font
    // asset in entries.
    for (final _Asset asset in assetVariants.keys) {
      if (!asset.assetFileExists && assetVariants[asset].isEmpty) {
        globals.printStatus('Error detected in pubspec.yaml:', emphasis: true);
        globals.printError('No file or variants found for $asset.\n');
        if (asset.package != null) {
          globals.printError('This asset was included from package ${asset.package.name}.');
        }
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
      for (final _Asset variant in assetVariants[asset]) {
        assert(variant.assetFileExists);
        entries[variant.entryUri.path] ??= DevFSFileContent(variant.assetFile);
      }
    }
    final List<_Asset> materialAssets = <_Asset>[
      if (flutterManifest.usesMaterialDesign && includeDefaultFonts)
        ..._getMaterialAssets(_kFontSetMaterial),
    ];
    for (final _Asset asset in materialAssets) {
      assert(asset.assetFileExists);
      entries[asset.entryUri.path] ??= DevFSFileContent(asset.assetFile);
    }

    // Update wildcard directories we we can detect changes in them.
    for (final Uri uri in wildcardDirectories) {
      _wildcardDirectories[uri] ??= globals.fs.directory(uri);
    }

    final DevFSStringContent assetManifest  = _createAssetManifest(assetVariants);
    final DevFSStringContent fontManifest = DevFSStringContent(json.encode(fonts));
    final LicenseResult licenseResult = licenseCollector.obtainLicenses(packageConfig);
    final DevFSStringContent licenses = DevFSStringContent(licenseResult.combinedLicenses);
    additionalDependencies = licenseResult.dependencies;

    if (wildcardDirectories.isNotEmpty) {
      // Force the depfile to contain missing files so that Gradle does not skip
      // the task. Wildcard directories are not compatible with full incremental
      // builds. For more context see https://github.com/flutter/flutter/issues/56466 .
      globals.printTrace(
        'Manifest contained wildcard assets. Inserting missing file into '
        'build graph to force rerun. for more information see #56466.'
      );
      final int suffix = Object().hashCode;
      additionalDependencies.add(
        globals.fs.file('DOES_NOT_EXIST_RERUN_FOR_WILDCARD$suffix').absolute);
    }

    _setIfChanged(_kAssetManifestJson, assetManifest);
    _setIfChanged(kFontManifestJson, fontManifest);
    _setIfChanged(_kNoticeFile, licenses);
    return 0;
  }

  @override
  List<File> additionalDependencies = <File>[];

  void _setIfChanged(String key, DevFSStringContent content) {
    if (!entries.containsKey(key)) {
      entries[key] = content;
      return;
    }
    final DevFSStringContent oldContent = entries[key] as DevFSStringContent;
    if (oldContent.string != content.string) {
      entries[key] = content;
    }
  }
}

@immutable
class _Asset {
  const _Asset({ this.baseDir, this.relativeUri, this.entryUri, @required this.package });

  final String baseDir;

  final Package package;

  /// A platform-independent URL where this asset can be found on disk on the
  /// host system relative to [baseDir].
  final Uri relativeUri;

  /// A platform-independent URL representing the entry for the asset manifest.
  final Uri entryUri;

  File get assetFile {
    return globals.fs.file(globals.fs.path.join(baseDir, globals.fs.path.fromUri(relativeUri)));
  }

  bool get assetFileExists => assetFile.existsSync();

  /// The delta between what the entryUri is and the relativeUri (e.g.,
  /// packages/flutter_gallery).
  Uri get symbolicPrefixUri {
    if (entryUri == relativeUri) {
      return null;
    }
    final int index = entryUri.path.indexOf(relativeUri.path);
    return index == -1 ? null : Uri(path: entryUri.path.substring(0, index));
  }

  @override
  String toString() => 'asset: $entryUri';

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _Asset
        && other.baseDir == baseDir
        && other.relativeUri == relativeUri
        && other.entryUri == entryUri;
  }

  @override
  int get hashCode {
    return baseDir.hashCode
        ^ relativeUri.hashCode
        ^ entryUri.hashCode;
  }
}

Map<String, dynamic> _readMaterialFontsManifest() {
  final String fontsPath = globals.fs.path.join(globals.fs.path.absolute(Cache.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'material_fonts.yaml');

  return castStringKeyedMap(loadYaml(globals.fs.file(fontsPath).readAsStringSync()));
}

final Map<String, dynamic> _materialFontsManifest = _readMaterialFontsManifest();

List<Map<String, dynamic>> _getMaterialFonts(String fontSet) {
  final List<dynamic> fontsList = _materialFontsManifest[fontSet] as List<dynamic>;
  return fontsList?.map<Map<String, dynamic>>(castStringKeyedMap)?.toList();
}

List<_Asset> _getMaterialAssets(String fontSet) {
  final List<_Asset> result = <_Asset>[];

  for (final Map<String, dynamic> family in _getMaterialFonts(fontSet)) {
    for (final Map<dynamic, dynamic> font in (family['fonts'] as List<dynamic>).cast<Map<dynamic, dynamic>>()) {
      final Uri entryUri = globals.fs.path.toUri(font['asset'] as String);
      result.add(_Asset(
        baseDir: globals.fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
        relativeUri: Uri(path: entryUri.pathSegments.last),
        entryUri: entryUri,
        package: null,
      ));
    }
  }

  return result;
}


/// Processes dependencies into a string representing the NOTICES file.
///
/// Reads the NOTICES or LICENSE file from each package in the .packages file,
/// splitting each one into each component license so that it can be de-duped
/// if possible. If the NOTICES file exists, it is preferred over the LICENSE
/// file.
///
/// Individual licenses inside each LICENSE file should be separated by 80
/// hyphens on their own on a line.
///
/// If a LICENSE or NOTICES file contains more than one component license,
/// then each component license must start with the names of the packages to
/// which the component license applies, with each package name on its own line
/// and the list of package names separated from the actual license text by a
/// blank line. The packages need not match the names of the pub package. For
/// example, a package might itself contain code from multiple third-party
/// sources, and might need to include a license for each one.
class LicenseCollector {
  LicenseCollector({
    @required FileSystem fileSystem
  }) : _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  /// The expected separator for multiple licenses.
  static final String licenseSeparator = '\n' + ('-' * 80) + '\n';

  /// Obtain licenses from the `packageMap` into a single result.
  LicenseResult obtainLicenses(
    PackageConfig packageConfig,
  ) {
    final Map<String, Set<String>> packageLicenses = <String, Set<String>>{};
    final Set<String> allPackages = <String>{};
    final List<File> dependencies = <File>[];

    for (final Package package in packageConfig.packages) {
      final Uri packageUri = package.packageUriRoot;
      if (packageUri == null || packageUri.scheme != 'file') {
        continue;
      }
      // First check for NOTICES, then fallback to LICENSE
      File file = _fileSystem.file(packageUri.resolve('../NOTICES'));
      if (!file.existsSync()) {
        file = _fileSystem.file(packageUri.resolve('../LICENSE'));
      }
      if (!file.existsSync()) {
        continue;
      }

      dependencies.add(file);
      final List<String> rawLicenses = file
        .readAsStringSync()
        .split(licenseSeparator);
      for (final String rawLicense in rawLicenses) {
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
          packageNames = <String>[package.name];
          licenseText = rawLicense;
        }
        packageLicenses.putIfAbsent(licenseText, () => <String>{})
          .addAll(packageNames);
        allPackages.addAll(packageNames);
      }
    }
    final List<String> combinedLicensesList = packageLicenses.keys
      .map<String>((String license) {
        final List<String> packageNames = packageLicenses[license].toList()
          ..sort();
        return packageNames.join('\n') + '\n\n' + license;
      }).toList();
    combinedLicensesList.sort();
    final String combinedLicenses = combinedLicensesList.join(licenseSeparator);

    return LicenseResult(
      combinedLicenses: combinedLicenses,
      dependencies: dependencies,
    );
  }
}

/// The result of processing licenses with a [LicenseCollector].
class LicenseResult {
  const LicenseResult({
    @required this.combinedLicenses,
    @required this.dependencies,
  });

  /// The raw text of the consumed licenses.
  final String combinedLicenses;

  /// Each license file that was consumed as input.
  final List<File> dependencies;
}

int _byBasename(_Asset a, _Asset b) {
  return a.assetFile.basename.compareTo(b.assetFile.basename);
}

DevFSStringContent _createAssetManifest(Map<_Asset, List<_Asset>> assetVariants) {
  final Map<String, List<String>> jsonObject = <String, List<String>>{};

  // necessary for making unit tests deterministic
  final List<_Asset> sortedKeys = assetVariants
      .keys.toList()
    ..sort(_byBasename);

  for (final _Asset main in sortedKeys) {
    jsonObject[main.entryUri.path] = <String>[
      for (final _Asset variant in assetVariants[main])
        variant.entryUri.path,
    ];
  }
  return DevFSStringContent(json.encode(jsonObject));
}

List<Map<String, dynamic>> _parseFonts(
  FlutterManifest manifest,
  bool includeDefaultFonts,
  PackageConfig packageConfig, {
  String packageName,
  @required bool primary,
}) {
  return <Map<String, dynamic>>[
    if (primary && manifest.usesMaterialDesign && includeDefaultFonts)
      ..._getMaterialFonts(ManifestAssetBundle._kFontSetMaterial),
    if (packageName == null)
      ...manifest.fontsDescriptor
    else
      ..._createFontsDescriptor(_parsePackageFonts(
        manifest,
        packageName,
        packageConfig,
      )),
  ];
}

/// Prefixes family names and asset paths of fonts included from packages with
/// 'packages/<package_name>'
List<Font> _parsePackageFonts(
  FlutterManifest manifest,
  String packageName,
  PackageConfig packageConfig,
) {
  final List<Font> packageFonts = <Font>[];
  for (final Font font in manifest.fonts) {
    final List<FontAsset> packageFontAssets = <FontAsset>[];
    for (final FontAsset fontAsset in font.fontAssets) {
      final Uri assetUri = fontAsset.assetUri;
      if (assetUri.pathSegments.first == 'packages' &&
          !globals.fs.isFileSync(globals.fs.path.fromUri(
            packageConfig[packageName].packageUriRoot.resolve('../${assetUri.path}')))) {
        packageFontAssets.add(FontAsset(
          fontAsset.assetUri,
          weight: fontAsset.weight,
          style: fontAsset.style,
        ));
      } else {
        packageFontAssets.add(FontAsset(
          Uri(pathSegments: <String>['packages', packageName, ...assetUri.pathSegments]),
          weight: fontAsset.weight,
          style: fontAsset.style,
        ));
      }
    }
    packageFonts.add(Font('packages/$packageName/${font.familyName}', packageFontAssets));
  }
  return packageFonts;
}

List<Map<String, dynamic>> _createFontsDescriptor(List<Font> fonts) {
  return fonts.map<Map<String, dynamic>>((Font font) => font.descriptor).toList();
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
  _AssetDirectoryCache(Iterable<String> excluded)
    : _excluded = excluded
        .map<String>(globals.fs.path.absolute)
        .toList();

  final List<String> _excluded;
  final Map<String, Map<String, List<String>>> _cache = <String, Map<String, List<String>>>{};

  List<String> variantsFor(String assetPath) {
    final String assetName = globals.fs.path.basename(assetPath);
    final String directory = globals.fs.path.dirname(assetPath);

    if (!globals.fs.directory(directory).existsSync()) {
      return const <String>[];
    }

    if (_cache[directory] == null) {
      final List<String> paths = <String>[];
      for (final FileSystemEntity entity in globals.fs.directory(directory).listSync(recursive: true)) {
        final String path = entity.path;
        if (globals.fs.isFileSync(path)
          && assetPath != path
          && !_excluded.any((String exclude) => globals.fs.path.isWithin(exclude, path))) {
          paths.add(path);
        }
      }

      final Map<String, List<String>> variants = <String, List<String>>{};
      for (final String path in paths) {
        final String variantName = globals.fs.path.basename(path);
        if (directory == globals.fs.path.dirname(path)) {
          continue;
        }
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
///
/// Given package: 'test_package' and an assets directory like this:
///
/// - assets/foo
/// - assets/var1/foo
/// - assets/var2/foo
/// - assets/bar
///
/// This will return:
/// ```
/// {
///   asset: packages/test_package/assets/foo: [
///     asset: packages/test_package/assets/foo,
///     asset: packages/test_package/assets/var1/foo,
///     asset: packages/test_package/assets/var2/foo,
///   ],
///   asset: packages/test_package/assets/bar: [
///     asset: packages/test_package/assets/bar,
///   ],
/// }
/// ```

Map<_Asset, List<_Asset>> _parseAssets(
  PackageConfig packageConfig,
  FlutterManifest flutterManifest,
  List<Uri> wildcardDirectories,
  String assetBase, {
  List<String> excludeDirs = const <String>[],
  String packageName,
  Package attributedPackage,
}) {
  final Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};

  final _AssetDirectoryCache cache = _AssetDirectoryCache(excludeDirs);
  for (final Uri assetUri in flutterManifest.assets) {
    if (assetUri.toString().endsWith('/')) {
      wildcardDirectories.add(assetUri);
      _parseAssetsFromFolder(
        packageConfig,
        flutterManifest,
        assetBase,
        cache,
        result,
        assetUri,
        excludeDirs: excludeDirs,
        packageName: packageName,
        attributedPackage: attributedPackage,
      );
    } else {
      _parseAssetFromFile(
        packageConfig,
        flutterManifest,
        assetBase,
        cache,
        result,
        assetUri,
        excludeDirs: excludeDirs,
        packageName: packageName,
        attributedPackage: attributedPackage,
      );
    }
  }

  // Add assets referenced in the fonts section of the manifest.
  for (final Font font in flutterManifest.fonts) {
    for (final FontAsset fontAsset in font.fontAssets) {
      final _Asset baseAsset = _resolveAsset(
        packageConfig,
        assetBase,
        fontAsset.assetUri,
        packageName,
        attributedPackage,
      );
      if (!baseAsset.assetFileExists) {
        globals.printError('Error: unable to locate asset entry in pubspec.yaml: "${fontAsset.assetUri}".');
        return null;
      }

      result[baseAsset] = <_Asset>[];
    }
  }

  return result;
}

void _parseAssetsFromFolder(
  PackageConfig packageConfig,
  FlutterManifest flutterManifest,
  String assetBase,
  _AssetDirectoryCache cache,
  Map<_Asset, List<_Asset>> result,
  Uri assetUri, {
  List<String> excludeDirs = const <String>[],
  String packageName,
  Package attributedPackage,
}) {
  final String directoryPath = globals.fs.path.join(
      assetBase, assetUri.toFilePath(windows: globals.platform.isWindows));

  if (!globals.fs.directory(directoryPath).existsSync()) {
    globals.printError('Error: unable to find directory entry in pubspec.yaml: $directoryPath');
    return;
  }

  final List<FileSystemEntity> lister = globals.fs.directory(directoryPath).listSync();

  for (final FileSystemEntity entity in lister) {
    if (entity is File) {
      final String relativePath = globals.fs.path.relative(entity.path, from: assetBase);
      final Uri uri = Uri.file(relativePath, windows: globals.platform.isWindows);

      _parseAssetFromFile(
        packageConfig,
        flutterManifest,
        assetBase,
        cache,
        result,
        uri,
        packageName: packageName,
        attributedPackage: attributedPackage,
      );
    }
  }
}

void _parseAssetFromFile(
  PackageConfig packageConfig,
  FlutterManifest flutterManifest,
  String assetBase,
  _AssetDirectoryCache cache,
  Map<_Asset, List<_Asset>> result,
  Uri assetUri, {
  List<String> excludeDirs = const <String>[],
  String packageName,
  Package attributedPackage,
}) {
  final _Asset asset = _resolveAsset(
    packageConfig,
    assetBase,
    assetUri,
    packageName,
    attributedPackage,
  );
  final List<_Asset> variants = <_Asset>[];
  for (final String path in cache.variantsFor(asset.assetFile.path)) {
    final String relativePath = globals.fs.path.relative(path, from: asset.baseDir);
    final Uri relativeUri = globals.fs.path.toUri(relativePath);
    final Uri entryUri = asset.symbolicPrefixUri == null
        ? relativeUri
        : asset.symbolicPrefixUri.resolveUri(relativeUri);

    variants.add(
      _Asset(
        baseDir: asset.baseDir,
        entryUri: entryUri,
        relativeUri: relativeUri,
        package: attributedPackage,
      ),
    );
  }

  result[asset] = variants;
}

_Asset _resolveAsset(
  PackageConfig packageConfig,
  String assetsBaseDir,
  Uri assetUri,
  String packageName,
  Package attributedPackage,
) {
  final String assetPath = globals.fs.path.fromUri(assetUri);
  if (assetUri.pathSegments.first == 'packages' && !globals.fs.isFileSync(globals.fs.path.join(assetsBaseDir, assetPath))) {
    // The asset is referenced in the pubspec.yaml as
    // 'packages/PACKAGE_NAME/PATH/TO/ASSET .
    final _Asset packageAsset = _resolvePackageAsset(
      assetUri,
      packageConfig,
      attributedPackage,
    );
    if (packageAsset != null) {
      return packageAsset;
    }
  }

  return _Asset(
    baseDir: assetsBaseDir,
    entryUri: packageName == null
        ? assetUri // Asset from the current application.
        : Uri(pathSegments: <String>['packages', packageName, ...assetUri.pathSegments]), // Asset from, and declared in $packageName.
    relativeUri: assetUri,
    package: attributedPackage,
  );
}

_Asset _resolvePackageAsset(Uri assetUri, PackageConfig packageConfig, Package attributedPackage) {
  assert(assetUri.pathSegments.first == 'packages');
  if (assetUri.pathSegments.length > 1) {
    final String packageName = assetUri.pathSegments[1];
    final Package package = packageConfig[packageName];
    final Uri packageUri = package?.packageUriRoot;
    if (packageUri != null && packageUri.scheme == 'file') {
      return _Asset(
        baseDir: globals.fs.path.fromUri(packageUri),
        entryUri: assetUri,
        relativeUri: Uri(pathSegments: assetUri.pathSegments.sublist(2)),
        package: attributedPackage,
      );
    }
  }
  globals.printStatus('Error detected in pubspec.yaml:', emphasis: true);
  globals.printError('Could not resolve package for asset $assetUri.\n');
  if (attributedPackage != null) {
    globals.printError('This asset was included from package ${attributedPackage.name}');
  }
  return null;
}
