// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:yaml/yaml.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../dart/package_map.dart';

/// Metadata for a project-scoped tool extension discovered via the project's
/// `.dart_tool/package_config.json` and the extension package's
/// `extension/flutter_tools/extension.dart` entrypoint.
@immutable
final class DiscoveredProjectExtension {
  const DiscoveredProjectExtension({
    required this.entrypointUri,
    required this.name,
    required this.packageConfigUri,
    required this.packageUri,
    required this.rootUri,
    required this.workspaceRootUri,
  });

  /// Absolute file URI of the extension's isolate entrypoint script
  /// (`<rootUri>/extension/flutter_tools/extension.dart`).
  final Uri entrypointUri;

  /// The Dart package name of the extension.
  final String name;

  /// Absolute file URI of the `.dart_tool/package_config.json` used to resolve the extension.
  final Uri packageConfigUri;

  /// Absolute directory URI of the extension package's `lib/` directory.
  final Uri packageUri;

  /// Absolute directory URI of the extension package root.
  final Uri rootUri;

  /// Absolute directory URI of the workspace or project root containing
  /// `.dart_tool/package_config.json`.
  final Uri workspaceRootUri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredProjectExtension &&
          other.entrypointUri == entrypointUri &&
          other.name == name &&
          other.packageConfigUri == packageConfigUri &&
          other.packageUri == packageUri &&
          other.rootUri == rootUri &&
          other.workspaceRootUri == workspaceRootUri;

  @override
  int get hashCode =>
      Object.hash(entrypointUri, name, packageConfigUri, packageUri, rootUri, workspaceRootUri);

  @override
  String toString() =>
      'DiscoveredProjectExtension('
      'name: $name, '
      'rootUri: $rootUri, '
      'packageUri: $packageUri, '
      'entrypointUri: $entrypointUri, '
      'packageConfigUri: $packageConfigUri, '
      'workspaceRootUri: $workspaceRootUri'
      ')';
}

/// Discovers Flutter Tool Extensions declared as direct dependencies of the
/// active project or Pub workspace.
class ProjectExtensionFinder {
  ProjectExtensionFinder({required this._fileSystem, required this._logger});

  /// Target subdirectory name under `extension/` for Flutter tool extensions.
  static const String kTargetPackageName = 'flutter_tools';

  /// Conventional entrypoint filename under `extension/flutter_tools/`.
  static const String kEntrypointFileName = 'extension.dart';

  static const String _kExtensionDirectoryName = 'extension';
  static const String _kPubspecFileName = 'pubspec.yaml';
  static const _kDependencyKeys = <String>['dependencies', 'dev_dependencies'];

  final FileSystem _fileSystem;
  final Logger _logger;

  /// Discovers tool extensions starting from [startDirectory] (if null, falls back to
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

    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: _logger,
      throwOnError: false,
    );
    final Uri packageConfigUri = packageConfigFile.absolute.uri;
    final Uri workspaceRootUri = workspaceRoot.absolute.uri;
    final discovered = <DiscoveredProjectExtension>[];

    for (final Package pkg in packageConfig.packages) {
      if (!directDependencies.contains(pkg.name)) {
        continue;
      }

      final Directory rootDir = _fileSystem.directory(pkg.root);
      final File entrypointFile = rootDir
          .childDirectory(_kExtensionDirectoryName)
          .childDirectory(kTargetPackageName)
          .childFile(kEntrypointFileName);

      if (!entrypointFile.existsSync()) {
        final FileSystemEntityType entityType = ErrorHandlingFileSystem.noExitOnFailure(
          () => _fileSystem.typeSync(entrypointFile.path, followLinks: false),
        );
        if (entityType == FileSystemEntityType.link) {
          _logger.printWarning(
            'Skipping extension "${pkg.name}": broken symlink at "${entrypointFile.path}".',
          );
        }
        continue;
      }

      final String resolvedRootPath;
      final String resolvedEntrypointPath;
      try {
        resolvedRootPath = _fileSystem.path.normalize(
          ErrorHandlingFileSystem.noExitOnFailure(rootDir.resolveSymbolicLinksSync),
        );
        resolvedEntrypointPath = _fileSystem.path.normalize(
          ErrorHandlingFileSystem.noExitOnFailure(entrypointFile.resolveSymbolicLinksSync),
        );
      } on FileSystemException catch (error) {
        _logger.printWarning(
          'Skipping extension "${pkg.name}": failed to resolve "${entrypointFile.path}" (${error.message}).',
        );
        continue;
      }

      if (!_fileSystem.path.isWithin(resolvedRootPath, resolvedEntrypointPath)) {
        _logger.printWarning(
          'Skipping extension "${pkg.name}": entrypoint "${entrypointFile.path}" resolves outside package root "${rootDir.path}".',
        );
        continue;
      }

      discovered.add(
        DiscoveredProjectExtension(
          entrypointUri: entrypointFile.absolute.uri,
          name: pkg.name,
          packageConfigUri: packageConfigUri,
          packageUri: _fileSystem.directory(pkg.packageUriRoot).absolute.uri,
          rootUri: rootDir.absolute.uri,
          workspaceRootUri: workspaceRootUri,
        ),
      );
    }

    return discovered;
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
      if (_fileSystem.path.equals(current.path, normalizedStopPath) ||
          _fileSystem.path.equals(current.parent.path, current.path)) {
        return null;
      }
      current = current.parent;
    }
  }

  void _extractPubspecDependencies(File pubspecFile, Set<String> outDependencies) {
    try {
      final String content = ErrorHandlingFileSystem.noExitOnFailure(pubspecFile.readAsStringSync);
      final Object? parsed = loadYaml(content);
      if (parsed is YamlMap) {
        for (final String key in _kDependencyKeys) {
          final Object? section = parsed[key];
          if (section is YamlMap) {
            outDependencies.addAll(section.keys.whereType<String>());
          }
        }
      }
    } on YamlException catch (error) {
      _logger.printTrace('ProjectExtensionFinder: failed to parse "${pubspecFile.path}": $error');
    } on FileSystemException catch (error) {
      _logger.printTrace('ProjectExtensionFinder: failed to read "${pubspecFile.path}": $error');
    }
  }
}
