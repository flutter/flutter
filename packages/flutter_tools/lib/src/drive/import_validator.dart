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

/// Validates that a driver test file and its transitive imports do not import
/// libraries that are not supported on the host VM (like `dart:ui` or `package:flutter`).
class DriverTestImportValidator {
  DriverTestImportValidator({
    required FileSystem fileSystem,
    required PackageConfig packageConfig,
    required String projectRootPath,
    required Logger logger,
  }) : _fileSystem = fileSystem,
       _packageConfig = packageConfig,
       _projectRootPath = projectRootPath,
       _logger = logger;

  final FileSystem _fileSystem;
  final PackageConfig _packageConfig;
  final String _projectRootPath;
  final Logger _logger;

  final Set<String> _visitedFiles = <String>{};

  static const List<String> _forbiddenPrefixes = <String>[
    'package:flutter/',
    'package:flutter_test/',
  ];

  static const List<String> _forbiddenImports = <String>['dart:ui'];

  /// Validates the [driverTestFile] and its transitive imports.
  ///
  /// Returns a list of error messages. If empty, validation passed.
  List<String> validate(File driverTestFile) {
    _visitedFiles.clear();
    final errors = <String>[];
    _validateFile(driverTestFile, errors);
    return errors;
  }

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
          if (resolvedFile != null) {
            if (_isWithinProjectRoot(resolvedFile)) {
              _validateFile(resolvedFile, errors);
            }
          }
        }
      }
    } on Exception catch (e) {
      _logger.printTrace('Failed to parse ${file.path}: $e');
    }
  }

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

  bool _isWithinProjectRoot(File file) {
    final String canonicalPath = _fileSystem.path.canonicalize(file.path);
    final String canonicalRoot = _fileSystem.path.canonicalize(_projectRootPath);
    return _fileSystem.path.isWithin(canonicalRoot, canonicalPath);
  }
}
