// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:extension_discovery/extension_discovery.dart' as ext_discovery;
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:yaml/yaml.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../dart/package_map.dart';

/// Metadata for a project-scoped tool extension discovered via
/// `.dart_tool/package_config.json` and `extension/flutter_tools/config.yaml`.
@immutable
final class DiscoveredProjectExtension {
  const DiscoveredProjectExtension({
    required this.config,
    required this.name,
    required this.packageConfigUri,
    required this.packageUri,
    required this.rootUri,
    required this.workspaceRootPath,
  });

  /// The Dart package name of the extension.
  final String name;

  /// Absolute directory URI of the extension package root.
  final Uri rootUri;

  /// Absolute directory URI of the extension package's `lib/` directory.
  final Uri packageUri;

  /// Absolute file URI of the `.dart_tool/package_config.json` used to resolve the extension.
  final Uri packageConfigUri;

  /// File system path of the workspace or project root containing `.dart_tool/package_config.json`.
  final String workspaceRootPath;

  /// Parsed static metadata from `extension/flutter_tools/config.yaml`.
  final ExtensionPackageConfig config;

  /// Absolute file URI of the extension's isolate entrypoint script.
  Uri get entrypointUri => rootUri.resolve(config.entrypoint);
}

/// Discovers Flutter Tool Extensions declared as direct dependencies of the
/// active project or Pub workspace using `package:extension_discovery`.
class ProjectExtensionFinder {
  ProjectExtensionFinder({required this._fileSystem, required this._logger});

  /// Target package name passed to `findExtensions`.
  static const String kTargetPackageName = 'flutter_tools';

  static const String _kPubspecFileName = 'pubspec.yaml';
  static const String _kDependenciesKey = 'dependencies';
  static const String _kDevDependenciesKey = 'dev_dependencies';

  final FileSystem _fileSystem;
  final Logger _logger;

  /// Discovers tool extensions starting from [startDirectory] (defaults to
  /// `fileSystem.currentDirectory`).
  ///
  /// Returns an empty list if `.dart_tool/package_config.json` does not exist
  /// yet, without caching failure so subsequent calls after `pub.get()` succeed.
  /// Only extensions declared in the active project's or workspace root's
  /// direct `dependencies` or `dev_dependencies` are returned.
  Future<List<DiscoveredProjectExtension>> findProjectExtensions({
    Directory? startDirectory,
  }) async {
    final Directory searchDir = startDirectory ?? _fileSystem.currentDirectory;
    if (!searchDir.existsSync()) {
      return const <DiscoveredProjectExtension>[];
    }

    final File? packageConfigFile = findPackageConfigFile(searchDir);
    if (packageConfigFile == null || !packageConfigFile.existsSync()) {
      _logger.printTrace(
        'ProjectExtensionFinder: no .dart_tool/package_config.json found from "${searchDir.path}".',
      );
      return const <DiscoveredProjectExtension>[];
    }

    final Directory workspaceRoot = packageConfigFile.parent.parent;
    final Set<String> directDependencies = _collectDirectDependencies(
      searchDir: searchDir,
      workspaceRoot: workspaceRoot,
    );
    if (directDependencies.isEmpty) {
      return const <DiscoveredProjectExtension>[];
    }

    final Uri packageConfigUri = packageConfigFile.absolute.uri;
    if (_isBackedByLocalFileSystem(_fileSystem)) {
      try {
        final List<ext_discovery.Extension> rawExtensions = await ext_discovery.findExtensions(
          kTargetPackageName,
          packageConfig: packageConfigUri,
        );
        return _filterAndValidateDiscoveredExtensions(
          rawExtensions: <({String package, Uri rootUri, Uri packageUri, Object? config})>[
            for (final ext_discovery.Extension ext in rawExtensions)
              (
                package: ext.package,
                rootUri: ext.rootUri,
                packageUri: ext.rootUri.resolveUri(ext.packageUri),
                config: ext.config,
              ),
          ],
          directDependencies: directDependencies,
          packageConfigUri: packageConfigUri,
          workspaceRootPath: workspaceRoot.path,
        );
      } on Exception catch (error) {
        _logger.printTrace(
          'ProjectExtensionFinder: findExtensions failed for "$packageConfigUri" ($error); '
          'falling back to FileSystem scan.',
        );
      }
    }

    return _findExtensionsFromFileSystem(
      packageConfigFile: packageConfigFile,
      directDependencies: directDependencies,
      workspaceRootPath: workspaceRoot.path,
    );
  }

  static bool _isBackedByLocalFileSystem(FileSystem fs) {
    if (fs is LocalFileSystem) {
      return true;
    }
    if (fs is ErrorHandlingFileSystem) {
      return _isBackedByLocalFileSystem(fs.fileSystem);
    }
    return false;
  }

  /// Collects direct `dependencies` and `dev_dependencies` package names from
  /// the active project's `pubspec.yaml` and the workspace root's `pubspec.yaml`.
  Set<String> _collectDirectDependencies({
    required Directory searchDir,
    required Directory workspaceRoot,
  }) {
    final dependencies = <String>{};

    final File? projectPubspec = _findNearestPubspec(startDir: searchDir, stopAtDir: workspaceRoot);
    if (projectPubspec != null) {
      _extractPubspecDependencies(projectPubspec, dependencies);
    }

    final File workspacePubspec = workspaceRoot.childFile(_kPubspecFileName);
    if (workspacePubspec.existsSync() &&
        (projectPubspec == null ||
            !_fileSystem.path.equals(projectPubspec.path, workspacePubspec.path))) {
      _extractPubspecDependencies(workspacePubspec, dependencies);
    }

    return dependencies;
  }

  File? _findNearestPubspec({required Directory startDir, required Directory stopAtDir}) {
    Directory current = _fileSystem.directory(_fileSystem.path.normalize(startDir.absolute.path));
    final String normalizedStopPath = _fileSystem.path.normalize(stopAtDir.absolute.path);

    while (true) {
      final File candidate = current.childFile(_kPubspecFileName);
      if (candidate.existsSync()) {
        return candidate;
      }
      if (_fileSystem.path.equals(current.path, normalizedStopPath)) {
        return null;
      }
      final Directory parent = current.parent;
      if (_fileSystem.path.equals(parent.path, current.path)) {
        return null;
      }
      current = parent;
    }
  }

  void _extractPubspecDependencies(File pubspecFile, Set<String> outDependencies) {
    try {
      final Object? parsed = loadYaml(pubspecFile.readAsStringSync());
      if (parsed is! YamlMap) {
        return;
      }
      for (final sectionKey in const <String>[_kDependenciesKey, _kDevDependenciesKey]) {
        if (parsed[sectionKey] case final YamlMap sectionMap) {
          for (final Object? key in sectionMap.keys) {
            if (key is String && key.isNotEmpty) {
              outDependencies.add(key);
            }
          }
        }
      }
    } on Exception catch (error) {
      _logger.printTrace('ProjectExtensionFinder: failed to parse "${pubspecFile.path}": $error');
    }
  }

  Future<List<DiscoveredProjectExtension>> _findExtensionsFromFileSystem({
    required Set<String> directDependencies,
    required File packageConfigFile,
    required String workspaceRootPath,
  }) async {
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: _logger,
      throwOnError: false,
    );
    final rawExtensions = <({String package, Uri rootUri, Uri packageUri, Object? config})>[];
    for (final Package pkg in packageConfig.packages) {
      final Directory rootDir = _fileSystem.directory(pkg.root);
      final File configFile = rootDir
          .childDirectory('extension')
          .childDirectory(kTargetPackageName)
          .childFile('config.yaml');
      if (!configFile.existsSync()) {
        continue;
      }
      try {
        final Object? rawYaml = loadYaml(configFile.readAsStringSync());
        rawExtensions.add((
          package: pkg.name,
          rootUri: rootDir.absolute.uri,
          packageUri: _fileSystem.directory(pkg.packageUriRoot).absolute.uri,
          config: rawYaml,
        ));
      } on Exception catch (error) {
        _logger.printWarning(
          'Skipping extension "${pkg.name}": malformed extension/flutter_tools/config.yaml ($error).',
        );
      }
    }
    return _filterAndValidateDiscoveredExtensions(
      rawExtensions: rawExtensions,
      directDependencies: directDependencies,
      packageConfigUri: packageConfigFile.absolute.uri,
      workspaceRootPath: workspaceRootPath,
    );
  }

  List<DiscoveredProjectExtension> _filterAndValidateDiscoveredExtensions({
    required Set<String> directDependencies,
    required Uri packageConfigUri,
    required List<({String package, Uri rootUri, Uri packageUri, Object? config})> rawExtensions,
    required String workspaceRootPath,
  }) {
    final discovered = <DiscoveredProjectExtension>[];
    final seenNames = <String>{};

    for (final (:String package, :Uri rootUri, :Uri packageUri, :Object? config) in rawExtensions) {
      if (!directDependencies.contains(package)) {
        _logger.printTrace(
          'ProjectExtensionFinder: ignoring transitive extension package "$package".',
        );
        continue;
      }
      if (seenNames.contains(package)) {
        continue;
      }
      if (config is! Map<Object?, Object?>) {
        _logger.printWarning(
          'Skipping extension "$package": extension/flutter_tools/config.yaml must be a YAML map.',
        );
        continue;
      }
      try {
        final parsedConfig = ExtensionPackageConfig.fromMap(
          config.cast<String, Object?>(),
          packageName: package,
        );
        seenNames.add(package);
        discovered.add(
          DiscoveredProjectExtension(
            name: package,
            rootUri: rootUri,
            packageUri: packageUri,
            packageConfigUri: packageConfigUri,
            workspaceRootPath: workspaceRootPath,
            config: parsedConfig,
          ),
        );
      } on FormatException catch (error) {
        _logger.printWarning(
          'Skipping extension "$package": invalid extension/flutter_tools/config.yaml (${error.message}).',
        );
      }
    }

    return discovered;
  }
}
