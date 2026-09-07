// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:package_config/package_config.dart';

import '../base/file_system.dart';
import '../base/logger.dart';

/// Validates that a `flutter_driver` test file and its transitive project-local
/// imports do not import libraries that require the device Flutter engine runtime
/// (such as `dart:ui`, `package:flutter`, or `package:flutter_test`).
///
/// `flutter_driver` test scripts execute on the host machine using the standard
/// standalone Dart VM, whereas the Flutter framework and `dart:ui` require the
/// Flutter engine runtime on the target device. Importing libraries dependent on
/// `dart:ui` into a host-side driver test results in hundreds of thousands of
/// confusing compilation errors during test execution.
///
/// This validator performs static AST analysis using [parseString] on the driver
/// test file and recursively inspects referenced files located within the project
/// root. It avoids traversing third-party package dependencies outside the project
/// root to ensure rapid validation (< 10 ms).
class DriverTestImportValidator {
  /// Creates a validator for driver test imports.
  ///
  /// Required arguments:
  /// * [fileSystem]: Used to read files and resolve canonical paths.
  /// * [logger]: Used to log trace messages during parsing failures.
  /// * [packageConfig]: Used to resolve `package:` URIs within the project.
  /// * [projectRootPath]: The root directory of the Flutter project, used as a
  ///   boundary to restrict transitive analysis to project-local sources.
  DriverTestImportValidator({
    required FileSystem fileSystem,
    required Logger logger,
    required PackageConfig packageConfig,
    required String projectRootPath,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _packageConfig = packageConfig,
       _projectRootPath = fileSystem.path.canonicalize(projectRootPath);

  final FileSystem _fileSystem;
  final Logger _logger;
  final PackageConfig _packageConfig;
  final String _projectRootPath;

  /// Tracks canonical file paths already visited during recursive traversal to
  /// prevent infinite loops caused by circular import dependencies.
  final Set<String> _visitedFiles = <String>{};

  /// Package prefixes forbidden in host-side driver tests.
  static const List<String> _forbiddenPrefixes = <String>[
    'package:flutter/',
    'package:flutter_test/',
  ];

  /// Direct library imports forbidden in host-side driver tests.
  static const List<String> _forbiddenImports = <String>['dart:ui'];

  /// Validates the [driverTestFile] and all its transitive imports within the
  /// project root.
  ///
  /// Returns a list of error descriptions. If the returned list is empty, all
  /// imports are valid.
  List<String> validate(File driverTestFile) {
    _visitedFiles.clear();
    final errors = <String>[];
    _validateFile(driverTestFile, errors);
    return errors;
  }

  /// Recursively inspects [file] and its import/export directives for forbidden
  /// dependencies.
  void _validateFile(File file, List<String> errors) {
    final String canonicalPath = _fileSystem.path.canonicalize(file.path);
    if (_visitedFiles.contains(canonicalPath)) {
      return;
    }
    _visitedFiles.add(canonicalPath);

    if (!file.existsSync()) {
      return;
    }

    try {
      final String content = file.readAsStringSync();
      final ParseStringResult result = parseString(
        content: content,
        path: file.path,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      final CompilationUnit unit = result.unit;
      for (final Directive directive in unit.directives) {
        if (directive is UriBasedDirective) {
          final String? uriString = directive.uri.stringValue;
          if (uriString == null) {
            continue;
          }
          if (_isForbidden(uriString)) {
            errors.add('Forbidden import/export "$uriString" found in ${file.path}');
            continue;
          }

          final File? resolvedFile = _resolveUri(uriString, file);
          if (resolvedFile != null && _isWithinProjectRoot(resolvedFile)) {
            _validateFile(resolvedFile, errors);
          }
        }
      }
    } on Exception catch (e) {
      _logger.printTrace('Failed to parse ${file.path}: $e');
    }
  }

  /// Checks whether [uriString] references a forbidden library or package prefix.
  bool _isForbidden(String uriString) {
    if (_forbiddenImports.contains(uriString)) {
      return true;
    }
    for (final String prefix in _forbiddenPrefixes) {
      if (uriString.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// Resolves [uriString] relative to [referencingFile] or via [_packageConfig].
  ///
  /// Returns a [File] if the URI resolves to a local file path, or `null` otherwise.
  File? _resolveUri(String uriString, File referencingFile) {
    final Uri uri = Uri.parse(uriString);
    if (uri.scheme == 'package') {
      final Uri? resolvedUri = _packageConfig.resolve(uri);
      if (resolvedUri != null && resolvedUri.scheme == 'file') {
        return _fileSystem.file(resolvedUri);
      }
    } else if (uri.scheme == '' || uri.scheme == 'file') {
      final String dir = _fileSystem.path.dirname(referencingFile.path);
      final String resolvedPath = _fileSystem.path.canonicalize(
        _fileSystem.path.join(dir, uri.path),
      );
      return _fileSystem.file(resolvedPath);
    }
    return null;
  }

  /// Determines whether [file] resides within [_projectRootPath].
  bool _isWithinProjectRoot(File file) {
    final String canonicalPath = _fileSystem.path.canonicalize(file.path);
    return _fileSystem.path.isWithin(_projectRootPath, canonicalPath);
  }
}
