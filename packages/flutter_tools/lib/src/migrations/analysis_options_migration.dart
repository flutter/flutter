// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../base/file_system.dart';
import '../base/project_migrator.dart';
import '../dart/package_map.dart';
import '../project.dart';

/// Migrates analysis_options.yaml to exclude build and platform directories.
class AnalysisOptionsMigration extends ProjectMigrator {
  AnalysisOptionsMigration(FlutterProject project, super.logger, {PackageConfig? packageConfig})
    : _project = project,
      _analysisOptionsFile = project.directory.childFile('analysis_options.yaml'),
      _packageConfig = packageConfig;

  final FlutterProject _project;
  final File _analysisOptionsFile;
  final PackageConfig? _packageConfig;
  PackageConfig? _loadedPackageConfig;

  @override
  Future<void> migrate() async {
    if (!_analysisOptionsFile.existsSync()) {
      return;
    }

    final String originalContent = _analysisOptionsFile.readAsStringSync();
    final YamlNode root;
    try {
      root = loadYamlNode(originalContent);
    } on YamlException catch (e) {
      logger.printTrace('Failed to parse analysis_options.yaml: $e');
      return;
    }

    if (root is! YamlMap) {
      logger.printTrace('analysis_options.yaml is not a YAML map, skipping migration.');
      return;
    }

    const excludesToExclude = <String>[
      'build/**',
      'android/**',
      'ios/**',
      'web/**',
      'windows/**',
      'macos/**',
      'linux/**',
    ];

    final Set<String> activeExcludes = await _collectExcludes(_analysisOptionsFile);
    final missingExcludes = <String>[];
    for (final requiredExclude in excludesToExclude) {
      if (!activeExcludes.contains(requiredExclude)) {
        missingExcludes.add(requiredExclude);
      }
    }

    if (missingExcludes.isEmpty) {
      return;
    }

    logger.printStatus(
      'Upgrading analysis_options.yaml to exclude build and platform directories.',
    );

    final editor = YamlEditor(originalContent);
    final Object? analyzer = root['analyzer'];

    try {
      if (analyzer is! YamlMap) {
        editor.update(<String>['analyzer'], <String, Object>{'exclude': missingExcludes});
      } else {
        final exclude = analyzer['exclude'] as Object?;
        if (exclude is! YamlList) {
          editor.update(<String>['analyzer', 'exclude'], missingExcludes);
        } else {
          for (final missingExclude in missingExcludes) {
            if (!exclude.contains(missingExclude)) {
              editor.appendToList(<String>['analyzer', 'exclude'], missingExclude);
            }
          }
        }
      }
      _analysisOptionsFile.writeAsStringSync(editor.toString());
    } on Exception catch (e) {
      logger.printError('Failed to migrate analysis_options.yaml: $e');
    }
  }

  /// Recursively collects analyzer `exclude:` patterns from [file] and any
  /// configuration files referenced via `include:` directives.
  ///
  /// Supports both relative paths and `package:` URIs, handling single string
  /// or list-based include directives while tracking [visited] canonical paths
  /// to prevent infinite recursion on cyclic includes.
  Future<Set<String>> _collectExcludes(File file, {Set<String> visited = const <String>{}}) async {
    final String canonicalPath = file.fileSystem.path.canonicalize(file.path);
    if (visited.contains(canonicalPath)) {
      return <String>{}; // Avoid cycles
    }
    if (!file.existsSync()) {
      return <String>{};
    }
    final String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      return <String>{};
    }
    final YamlNode root;
    try {
      root = loadYamlNode(content);
    } on YamlException {
      return <String>{};
    }
    if (root is! YamlMap) {
      return <String>{};
    }

    final excludes = <String>{};
    final Object? analyzer = root['analyzer'];
    if (analyzer is YamlMap) {
      final Object? exclude = analyzer['exclude'];
      if (exclude is YamlList) {
        excludes.addAll(exclude.whereType<String>());
      }
    }

    final Object? include = root['include'];
    final includes = <String>[];
    if (include is String) {
      includes.add(include);
    } else if (include is YamlList) {
      includes.addAll(include.whereType<String>());
    }

    for (final includeUri in includes) {
      final File? includedFile = await _resolveInclude(includeUri, file);
      if (includedFile != null) {
        excludes.addAll(
          await _collectExcludes(includedFile, visited: <String>{...visited, canonicalPath}),
        );
      }
    }

    return excludes;
  }

  Future<File?> _resolveInclude(String includeUri, File referringFile) async {
    if (includeUri.startsWith('package:')) {
      final PackageConfig? packageConfig = await _getPackageConfig();
      if (packageConfig == null) {
        return null;
      }
      try {
        final Uri? resolvedUri = packageConfig.resolve(Uri.parse(includeUri));
        if (resolvedUri != null && resolvedUri.scheme == 'file') {
          return referringFile.fileSystem.file(resolvedUri);
        }
      } on FormatException {
        // Invalid URI
      }
      return null;
    } else {
      // Relative path
      final String path = referringFile.fileSystem.path.join(referringFile.parent.path, includeUri);
      return referringFile.fileSystem.file(path);
    }
  }

  Future<PackageConfig?> _getPackageConfig() async {
    if (_packageConfig != null) {
      return _packageConfig;
    }
    if (_loadedPackageConfig != null) {
      return _loadedPackageConfig;
    }
    final File? configFile = findPackageConfigFile(_project.directory);
    if (configFile == null) {
      return null;
    }
    try {
      _loadedPackageConfig = await loadPackageConfigWithLogging(
        configFile,
        logger: logger,
        throwOnError: false,
      );
      return _loadedPackageConfig;
    } on Exception {
      // Ignore errors loading package config during migration checks.
      return null;
    }
  }
}
