// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import 'base/context.dart';
import 'base/deferred_component.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'build_info.dart';
import 'cache.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'flutter_manifest.dart';
import 'license_collector.dart';
import 'project.dart';

const String defaultManifestPath = 'pubspec.yaml';

const String kFontManifestJson = 'FontManifest.json';

/// The effect of adding `uses-material-design: true` to the pubspec is to insert
/// the following snippet into the asset manifest:
///
///```yaml
/// material:
///   - family: MaterialIcons
///     fonts:
///       - asset: fonts/MaterialIcons-Regular.otf
///```
const List<Map<String, Object>> kMaterialFonts = <Map<String, Object>>[
  <String, Object>{
    'family': 'MaterialIcons',
    'fonts': <Map<String, Object>>[
      <String, Object>{
        'asset': 'fonts/MaterialIcons-Regular.otf',
      },
    ],
  },
];

/// Injected factory class for spawning [AssetBundle] instances.
abstract class AssetBundleFactory {
  /// The singleton instance, pulled from the [AppContext].
  static AssetBundleFactory get instance => context.get<AssetBundleFactory>();

  static AssetBundleFactory defaultInstance({
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    bool splitDeferredAssets = false,
  }) => _ManifestAssetBundleFactory(logger: logger, fileSystem: fileSystem, platform: platform, splitDeferredAssets: splitDeferredAssets);

  /// Creates a new [AssetBundle].
  AssetBundle createBundle();
}

abstract class AssetBundle {
  Map<String, DevFSContent> get entries;

  /// The files that were specified under the deferred components assets sections
  /// in pubspec.
  Map<String, Map<String, DevFSContent>> get deferredComponentsEntries;

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
    bool deferredComponentsEnabled = false,
  });
}

class _ManifestAssetBundleFactory implements AssetBundleFactory {
  _ManifestAssetBundleFactory({
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    bool splitDeferredAssets = false,
  }) : _logger = logger,
       _fileSystem = fileSystem,
       _platform = platform,
       _splitDeferredAssets = splitDeferredAssets;

  final Logger _logger;
  final FileSystem _fileSystem;
  final Platform _platform;
  final bool _splitDeferredAssets;

  @override
  AssetBundle createBundle() => ManifestAssetBundle(logger: _logger, fileSystem: _fileSystem, platform: _platform, splitDeferredAssets: _splitDeferredAssets);
}

/// An asset bundle based on a pubspec.yaml file.
class ManifestAssetBundle implements AssetBundle {
  /// Constructs an [ManifestAssetBundle] that gathers the set of assets from the
  /// pubspec.yaml manifest.
  ManifestAssetBundle({
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    bool splitDeferredAssets = false,
  }) : _logger = logger,
       _fileSystem = fileSystem,
       _platform = platform,
       _splitDeferredAssets = splitDeferredAssets,
       _licenseCollector = LicenseCollector(fileSystem: fileSystem);

  final Logger _logger;
  final FileSystem _fileSystem;
  final LicenseCollector _licenseCollector;
  final Platform _platform;
  final bool _splitDeferredAssets;

  @override
  final Map<String, DevFSContent> entries = <String, DevFSContent>{};

  @override
  final Map<String, Map<String, DevFSContent>> deferredComponentsEntries = <String, Map<String, DevFSContent>>{};

  // If an asset corresponds to a wildcard directory, then it may have been
  // updated without changes to the manifest. These are only tracked for
  // the current project.
  final Map<Uri, Directory> _wildcardDirectories = <Uri, Directory>{};

  DateTime _lastBuildTimestamp;

  static const String _kAssetManifestJson = 'AssetManifest.json';
  static const String _kNoticeFile = 'NOTICES';

  @override
  bool wasBuiltOnce() => _lastBuildTimestamp != null;

  @override
  bool needsBuild({ String manifestPath = defaultManifestPath }) {
    if (_lastBuildTimestamp == null) {
      return true;
    }

    final FileStat stat = _fileSystem.file(manifestPath).statSync();
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
    bool deferredComponentsEnabled = false,
  }) async {
    assetDirPath ??= getAssetBuildDirectory();
    FlutterProject flutterProject;
    try {
      flutterProject = FlutterProject.fromDirectory(_fileSystem.file(manifestPath).parent);
    } on Exception catch (e) {
      _logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
      _logger.printError('$e');
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

    final String assetBasePath = _fileSystem.path.dirname(_fileSystem.path.absolute(manifestPath));
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      _fileSystem.file(packagesPath),
      logger: _logger,
    );
    final List<Uri> wildcardDirectories = <Uri>[];

    // The _assetVariants map contains an entry for each asset listed
    // in the pubspec.yaml file's assets and font and sections. The
    // value of each image asset is a list of resolution-specific "variants",
    // see _AssetDirectoryCache.
    final List<String> excludeDirs = <String>[
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
    ];
    final Map<_Asset, List<_Asset>> assetVariants = _parseAssets(
      packageConfig,
      flutterManifest,
      wildcardDirectories,
      assetBasePath,
      excludeDirs: excludeDirs,
    );

    if (assetVariants == null) {
      return 1;
    }

    // Parse assets for  deferred components.
    final Map<String, Map<_Asset, List<_Asset>>> deferredComponentsAssetVariants = _parseDeferredComponentsAssets(
      flutterManifest,
      packageConfig,
      assetBasePath,
      wildcardDirectories,
      flutterProject.directory,
      excludeDirs: excludeDirs,
    );
    if (!_splitDeferredAssets || !deferredComponentsEnabled) {
      // Include the assets in the regular set of assets if not using deferred
      // components.
      for (final String componentName in deferredComponentsAssetVariants.keys) {
        assetVariants.addAll(deferredComponentsAssetVariants[componentName]);
      }
      deferredComponentsAssetVariants.clear();
      deferredComponentsEntries.clear();
    }

    final bool includesMaterialFonts = flutterManifest.usesMaterialDesign;
    final List<Map<String, dynamic>> fonts = _parseFonts(
      flutterManifest,
      packageConfig,
      primary: true,
    );

    // Add fonts, assets, and licenses from packages.
    final Map<String, List<File>> additionalLicenseFiles = <String, List<File>>{};
    for (final Package package in packageConfig.packages) {
      final Uri packageUri = package.packageUriRoot;
      if (packageUri != null && packageUri.scheme == 'file') {
        final String packageManifestPath = _fileSystem.path.fromUri(packageUri.resolve('../pubspec.yaml'));
        final FlutterManifest packageFlutterManifest = FlutterManifest.createFromPath(
          packageManifestPath,
          logger: _logger,
          fileSystem: _fileSystem,
        );
        if (packageFlutterManifest == null) {
          continue;
        }
        // Collect any additional licenses from each package.
        final List<File> licenseFiles = <File>[];
        for (final String relativeLicensePath in packageFlutterManifest.additionalLicenses) {
          final String absoluteLicensePath = _fileSystem.path.fromUri(package.root.resolve(relativeLicensePath));
          licenseFiles.add(_fileSystem.file(absoluteLicensePath).absolute);
        }
        additionalLicenseFiles[packageFlutterManifest.appName] = licenseFiles;

        // Skip the app itself
        if (packageFlutterManifest.appName == flutterManifest.appName) {
          continue;
        }
        final String packageBasePath = _fileSystem.path.dirname(packageManifestPath);

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
          _logger.printError(
            'package:${package.name} has `uses-material-design: true` set but '
            'the primary pubspec contains `uses-material-design: false`. '
            'If the application needs material icons, then `uses-material-design` '
            ' must be set to true.'
          );
        }
        fonts.addAll(_parseFonts(
          packageFlutterManifest,
          packageConfig,
          packageName: package.name,
          primary: false,
        ));
      }
    }

    // Save the contents of each image, image variant, and font
    // asset in entries.
    for (final _Asset asset in assetVariants.keys) {
      final File assetFile = asset.lookupAssetFile(_fileSystem);
      if (!assetFile.existsSync() && assetVariants[asset].isEmpty) {
        _logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
        _logger.printError('No file or variants found for $asset.\n');
        if (asset.package != null) {
          _logger.printError('This asset was included from package ${asset.package.name}.');
        }
        return 1;
      }
      // The file name for an asset's "main" entry is whatever appears in
      // the pubspec.yaml file. The main entry's file must always exist for
      // font assets. It need not exist for an image if resolution-specific
      // variant files exist. An image's main entry is treated the same as a
      // "1x" resolution variant and if both exist then the explicit 1x
      // variant is preferred.
      if (assetFile.existsSync()) {
        assert(!assetVariants[asset].contains(asset));
        assetVariants[asset].insert(0, asset);
      }
      for (final _Asset variant in assetVariants[asset]) {
        final File variantFile = variant.lookupAssetFile(_fileSystem);
        assert(variantFile.existsSync());
        entries[variant.entryUri.path] ??= DevFSFileContent(variantFile);
      }
    }
    // Save the contents of each deferred component image, image variant, and font
    // asset in deferredComponentsEntries.
    if (deferredComponentsAssetVariants != null) {
      for (final String componentName in deferredComponentsAssetVariants.keys) {
        deferredComponentsEntries[componentName] = <String, DevFSContent>{};
        for (final _Asset asset in deferredComponentsAssetVariants[componentName].keys) {
          final File assetFile = asset.lookupAssetFile(_fileSystem);
          if (!assetFile.existsSync() && deferredComponentsAssetVariants[componentName][asset].isEmpty) {
            _logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
            _logger.printError('No file or variants found for $asset.\n');
            if (asset.package != null) {
              _logger.printError('This asset was included from package ${asset.package.name}.');
            }
            return 1;
          }
          // The file name for an asset's "main" entry is whatever appears in
          // the pubspec.yaml file. The main entry's file must always exist for
          // font assets. It need not exist for an image if resolution-specific
          // variant files exist. An image's main entry is treated the same as a
          // "1x" resolution variant and if both exist then the explicit 1x
          // variant is preferred.
          if (assetFile.existsSync()) {
            assert(!deferredComponentsAssetVariants[componentName][asset].contains(asset));
            deferredComponentsAssetVariants[componentName][asset].insert(0, asset);
          }
          for (final _Asset variant in deferredComponentsAssetVariants[componentName][asset]) {
            final File variantFile = variant.lookupAssetFile(_fileSystem);
            assert(variantFile.existsSync());
            deferredComponentsEntries[componentName][variant.entryUri.path] ??= DevFSFileContent(variantFile);
          }
        }
      }
    }
    final List<_Asset> materialAssets = <_Asset>[
      if (flutterManifest.usesMaterialDesign)
        ..._getMaterialAssets(),
    ];
    for (final _Asset asset in materialAssets) {
      final File assetFile = asset.lookupAssetFile(_fileSystem);
      assert(assetFile.existsSync());
      entries[asset.entryUri.path] ??= DevFSFileContent(assetFile);
    }

    // Update wildcard directories we we can detect changes in them.
    for (final Uri uri in wildcardDirectories) {
      _wildcardDirectories[uri] ??= _fileSystem.directory(uri);
    }

    final DevFSStringContent assetManifest  = _createAssetManifest(assetVariants, deferredComponentsAssetVariants);
    final DevFSStringContent fontManifest = DevFSStringContent(json.encode(fonts));
    final LicenseResult licenseResult = _licenseCollector.obtainLicenses(packageConfig, additionalLicenseFiles);
    if (licenseResult.errorMessages.isNotEmpty) {
      licenseResult.errorMessages.forEach(_logger.printError);
      return 1;
    }

    final DevFSStringContent licenses = DevFSStringContent(licenseResult.combinedLicenses);
    additionalDependencies = licenseResult.dependencies;

    if (wildcardDirectories.isNotEmpty) {
      // Force the depfile to contain missing files so that Gradle does not skip
      // the task. Wildcard directories are not compatible with full incremental
      // builds. For more context see https://github.com/flutter/flutter/issues/56466 .
      _logger.printTrace(
        'Manifest contained wildcard assets. Inserting missing file into '
        'build graph to force rerun. for more information see #56466.'
      );
      final int suffix = Object().hashCode;
      additionalDependencies.add(
        _fileSystem.file('DOES_NOT_EXIST_RERUN_FOR_WILDCARD$suffix').absolute);
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

  List<_Asset> _getMaterialAssets() {
    final List<_Asset> result = <_Asset>[];
    for (final Map<String, Object> family in kMaterialFonts) {
      for (final Map<String, Object> font in family['fonts'] as List<Map<String, Object>>) {
        final Uri entryUri = _fileSystem.path.toUri(font['asset'] as String);
        result.add(_Asset(
          baseDir: _fileSystem.path.join(Cache.flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
          relativeUri: Uri(path: entryUri.pathSegments.last),
          entryUri: entryUri,
          package: null,
        ));
      }
    }

    return result;
  }

  List<Map<String, dynamic>> _parseFonts(
    FlutterManifest manifest,
    PackageConfig packageConfig, {
    String packageName,
    @required bool primary,
  }) {
    return <Map<String, dynamic>>[
      if (primary && manifest.usesMaterialDesign)
        ...kMaterialFonts,
      if (packageName == null)
        ...manifest.fontsDescriptor
      else
        for (Font font in _parsePackageFonts(
          manifest,
          packageName,
          packageConfig,
        )) font.descriptor,
    ];
  }

  Map<String, Map<_Asset, List<_Asset>>> _parseDeferredComponentsAssets(
    FlutterManifest flutterManifest,
    PackageConfig packageConfig,
    String assetBasePath,
    List<Uri> wildcardDirectories,
    Directory projectDirectory, {
    List<String> excludeDirs = const <String>[],
  }) {
    final List<DeferredComponent> components = flutterManifest.deferredComponents;
    final Map<String, Map<_Asset, List<_Asset>>> deferredComponentsAssetVariants = <String, Map<_Asset, List<_Asset>>>{};
    if (components == null) {
      return deferredComponentsAssetVariants;
    }
    for (final DeferredComponent component in components) {
      deferredComponentsAssetVariants[component.name] = <_Asset, List<_Asset>>{};
      final _AssetDirectoryCache cache = _AssetDirectoryCache(<String>[], _fileSystem);
      for (final Uri assetUri in component.assets) {
        if (assetUri.path.endsWith('/')) {
          wildcardDirectories.add(assetUri);
          _parseAssetsFromFolder(
            packageConfig,
            flutterManifest,
            assetBasePath,
            cache,
            deferredComponentsAssetVariants[component.name],
            assetUri,
            excludeDirs: excludeDirs,
          );
        } else {
          _parseAssetFromFile(
            packageConfig,
            flutterManifest,
            assetBasePath,
            cache,
            deferredComponentsAssetVariants[component.name],
            assetUri,
            excludeDirs: excludeDirs,
          );
        }
      }
    }
    return deferredComponentsAssetVariants;
  }

  DevFSStringContent _createAssetManifest(
    Map<_Asset, List<_Asset>> assetVariants,
    Map<String, Map<_Asset, List<_Asset>>> deferredComponentsAssetVariants
  ) {
    final Map<String, List<String>> jsonObject = <String, List<String>>{};
    final List<_Asset> assets = assetVariants.keys.toList();
    final Map<_Asset, List<String>> jsonEntries = <_Asset, List<String>>{};
    for (final _Asset main in assets) {
      jsonEntries[main] = <String>[
        for (final _Asset variant in assetVariants[main])
          variant.entryUri.path,
      ];
    }
    if (deferredComponentsAssetVariants != null) {
      for (final Map<_Asset, List<_Asset>> componentAssets in deferredComponentsAssetVariants.values) {
        for (final _Asset main in componentAssets.keys) {
          jsonEntries[main] = <String>[
            for (final _Asset variant in componentAssets[main])
              variant.entryUri.path,
          ];
        }
      }
    }
    final List<_Asset> sortedKeys = jsonEntries.keys.toList()
        ..sort((_Asset left, _Asset right) => left.entryUri.path.compareTo(right.entryUri.path));
    for (final _Asset main in sortedKeys) {
      jsonObject[main.entryUri.path] = jsonEntries[main];
    }
    return DevFSStringContent(json.encode(jsonObject));
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
            !_fileSystem.isFileSync(_fileSystem.path.fromUri(
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

    final _AssetDirectoryCache cache = _AssetDirectoryCache(excludeDirs, _fileSystem);
    for (final Uri assetUri in flutterManifest.assets) {
      if (assetUri.path.endsWith('/')) {
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
        final File baseAssetFile = baseAsset.lookupAssetFile(_fileSystem);
        if (!baseAssetFile.existsSync()) {
          _logger.printError('Error: unable to locate asset entry in pubspec.yaml: "${fontAsset.assetUri}".');
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
    final String directoryPath = _fileSystem.path.join(
        assetBase, assetUri.toFilePath(windows: _platform.isWindows));

    if (!_fileSystem.directory(directoryPath).existsSync()) {
      _logger.printError('Error: unable to find directory entry in pubspec.yaml: $directoryPath');
      return;
    }

    final Iterable<File> files = _fileSystem
      .directory(directoryPath)
      .listSync()
      .whereType<File>();
    for (final File file in files) {
      final String relativePath = _fileSystem.path.relative(file.path, from: assetBase);
      final Uri uri = Uri.file(relativePath, windows: _platform.isWindows);

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
    final File assetFile = asset.lookupAssetFile(_fileSystem);
    for (final String path in cache.variantsFor(assetFile.path)) {
      final String relativePath = _fileSystem.path.relative(path, from: asset.baseDir);
      final Uri relativeUri = _fileSystem.path.toUri(relativePath);
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
    final String assetPath = _fileSystem.path.fromUri(assetUri);
    if (assetUri.pathSegments.first == 'packages'
      && !_fileSystem.isFileSync(_fileSystem.path.join(assetsBaseDir, assetPath))) {
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
          baseDir: _fileSystem.path.fromUri(packageUri),
          entryUri: assetUri,
          relativeUri: Uri(pathSegments: assetUri.pathSegments.sublist(2)),
          package: attributedPackage,
        );
      }
    }
    _logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
    _logger.printError('Could not resolve package for asset $assetUri.\n');
    if (attributedPackage != null) {
      _logger.printError('This asset was included from package ${attributedPackage.name}');
    }
    return null;
  }
}

@immutable
class _Asset {
  const _Asset({
    this.baseDir,
    this.relativeUri,
    this.entryUri,
    @required this.package,
  });

  final String baseDir;

  final Package package;

  /// A platform-independent URL where this asset can be found on disk on the
  /// host system relative to [baseDir].
  final Uri relativeUri;

  /// A platform-independent URL representing the entry for the asset manifest.
  final Uri entryUri;

  File lookupAssetFile(FileSystem fileSystem) {
    return fileSystem.file(fileSystem.path.join(baseDir, fileSystem.path.fromUri(relativeUri)));
  }

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
  _AssetDirectoryCache(Iterable<String> excluded, this._fileSystem)
    : _excluded = excluded
        .map<String>(_fileSystem.path.absolute)
        .toList();

  final FileSystem _fileSystem;
  final List<String> _excluded;
  final Map<String, Map<String, List<String>>> _cache = <String, Map<String, List<String>>>{};

  List<String> variantsFor(String assetPath) {
    final String assetName = _fileSystem.path.basename(assetPath);
    final String directory = _fileSystem.path.dirname(assetPath);

    if (!_fileSystem.directory(directory).existsSync()) {
      return const <String>[];
    }

    if (_cache[directory] == null) {
      final List<String> paths = <String>[];
      for (final FileSystemEntity entity in _fileSystem.directory(directory).listSync(recursive: true)) {
        final String path = entity.path;
        if (_fileSystem.isFileSync(path)
          && assetPath != path
          && !_excluded.any((String exclude) => _fileSystem.path.isWithin(exclude, path))) {
          paths.add(path);
        }
      }

      final Map<String, List<String>> variants = <String, List<String>>{};
      for (final String path in paths) {
        final String variantName = _fileSystem.path.basename(path);
        if (directory == _fileSystem.path.dirname(path)) {
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
