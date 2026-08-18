// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../base/file_system.dart';
import '../base/project_migrator.dart';
import '../project.dart';

/// Migrates analysis_options.yaml to exclude build and platform directories.
class AnalysisOptionsMigration extends ProjectMigrator {
  AnalysisOptionsMigration(FlutterProject project, super.logger)
    : _project = project,
      _analysisOptionsFile = project.directory.childFile('analysis_options.yaml');

  final FlutterProject _project;
  final File _analysisOptionsFile;

  @override
  Future<void> migrate() async {
    if (!_analysisOptionsFile.existsSync()) {
      return;
    }

    // A pure Dart package (no `flutter` dependency) has no platform scaffold
    // directories, so `web/`, `android/`, etc. are ordinary source or asset
    // directories rather than generated platform code. Excluding them here
    // would silently drop them from analysis.
    if (!_project.manifest.dependencies.contains('flutter')) {
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

    final excludesToExclude = <String>[
      'build/**',
      if (_project.android.existsSync()) 'android/**',
      if (_project.ios.existsSync()) 'ios/**',
      if (_project.web.existsSync()) 'web/**',
      if (_project.windows.existsSync()) 'windows/**',
      if (_project.macos.existsSync()) 'macos/**',
      if (_project.linux.existsSync()) 'linux/**',
    ];

    var needsMigration = false;
    final Object? analyzer = root['analyzer'];
    if (analyzer is! YamlMap) {
      needsMigration = true;
    } else {
      final exclude = analyzer['exclude'] as Object?;
      if (exclude is! YamlList) {
        needsMigration = true;
      } else {
        for (final requiredExclude in excludesToExclude) {
          if (!exclude.contains(requiredExclude)) {
            needsMigration = true;
            break;
          }
        }
      }
    }

    if (!needsMigration) {
      return;
    }

    logger.printStatus(
      'Upgrading analysis_options.yaml to exclude build and platform directories.',
    );

    final editor = YamlEditor(originalContent);

    try {
      if (analyzer is! YamlMap) {
        editor.update(<String>['analyzer'], <String, Object>{'exclude': excludesToExclude});
      } else {
        final exclude = analyzer['exclude'] as Object?;
        if (exclude is! YamlList) {
          editor.update(<String>['analyzer', 'exclude'], excludesToExclude);
        } else {
          for (final requiredExclude in excludesToExclude) {
            if (!exclude.contains(requiredExclude)) {
              editor.appendToList(<String>['analyzer', 'exclude'], requiredExclude);
            }
          }
        }
      }
      _analysisOptionsFile.writeAsStringSync(editor.toString());
    } on Exception catch (e) {
      logger.printError('Failed to migrate analysis_options.yaml: $e');
    }
  }
}
