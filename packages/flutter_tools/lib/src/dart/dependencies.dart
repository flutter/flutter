// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analyzer.dart' as analyzer;

import '../base/file_system.dart';
import '../dart/package_map.dart';

// List of flutter specific environment configurations.
// See https://github.com/munificent/dep-interface-libraries/blob/master/Proposal.md
// We will populate this list as required. Potentially, all of dart:* libraries
// supported by flutter would end up here.
final List<String> _configurationConstants = <String>['dart.library.io'];

String _dottedNameToString(analyzer.DottedName dottedName) {
  String result = '';
  for (analyzer.SimpleIdentifier identifier in dottedName.components) {
    if (result.isEmpty) {
      result += identifier.token.lexeme;
    } else {
      result += '.' + identifier.token.lexeme;
    }
  }
  return result;
}

class DartDependencySetBuilder {
  DartDependencySetBuilder(String mainScriptPath, String packagesFilePath) :
    _mainScriptPath = canonicalizePath(mainScriptPath),
    _mainScriptUri = fs.path.toUri(mainScriptPath),
    _packagesFilePath = canonicalizePath(packagesFilePath);

  final String _mainScriptPath;
  final String _packagesFilePath;

  final Uri _mainScriptUri;

  Set<String> build() {
    final List<String> dependencies = <String>[_mainScriptPath, _packagesFilePath];
    final List<Uri> toProcess = <Uri>[_mainScriptUri];
    final PackageMap packageMap = PackageMap(_packagesFilePath);

    while (toProcess.isNotEmpty) {
      final Uri currentUri = toProcess.removeLast();
      final analyzer.CompilationUnit unit = _parse(currentUri.toFilePath());
      for (analyzer.Directive directive in unit.directives) {
        if (!(directive is analyzer.UriBasedDirective))
          continue;

        String uriAsString;
        if (directive is analyzer.NamespaceDirective) {
          final analyzer.NamespaceDirective namespaceDirective = directive;
          // If the directive is a conditional import directive, we should
          // select the imported uri based on the condition.
          for (analyzer.Configuration configuration in namespaceDirective.configurations) {
            if (_configurationConstants.contains(_dottedNameToString(configuration.name))) {
              uriAsString = configuration.uri.stringValue;
              break;
            }
          }
        }
        if (uriAsString == null) {
          final analyzer.UriBasedDirective uriBasedDirective = directive;
          uriAsString = uriBasedDirective.uri.stringValue;
        }

        Uri uri;
        try {
          uri = Uri.parse(uriAsString);
        } on FormatException {
          throw DartDependencyException('Unable to parse URI: $uriAsString');
        }
        Uri resolvedUri = analyzer.resolveRelativeUri(currentUri, uri);
        if (resolvedUri.scheme.startsWith('dart'))
          continue;
        if (resolvedUri.scheme == 'package') {
          final Uri newResolvedUri = packageMap.uriForPackage(resolvedUri);
          if (newResolvedUri == null) {
            throw DartDependencyException(
              'The following Dart file:\n'
              '  ${currentUri.toFilePath()}\n'
              '...refers, in an import, to the following library:\n'
              '  $resolvedUri\n'
              'That library is in a package that is not known. Maybe you forgot to '
              'mention it in your pubspec.yaml file?'
            );
          }
          resolvedUri = newResolvedUri;
        }
        final String path = canonicalizePath(resolvedUri.toFilePath());
        if (!dependencies.contains(path)) {
          if (!fs.isFileSync(path)) {
            throw DartDependencyException(
              'The following Dart file:\n'
              '  ${currentUri.toFilePath()}\n'
              '...refers, in an import, to the following library:\n'
              '  $path\n'
              'Unfortunately, that library does not appear to exist on your file system.'
            );
          }
          dependencies.add(path);
          toProcess.add(resolvedUri);
        }
      }
    }
    return dependencies.toSet();
  }

  analyzer.CompilationUnit _parse(String path) {
    String body;
    try {
      body = fs.file(path).readAsStringSync();
    } on FileSystemException catch (error) {
      throw DartDependencyException(
        'Could not read "$path" when determining Dart dependencies.',
        error,
      );
    }
    try {
      return analyzer.parseDirectives(body, name: path);
    } on analyzer.AnalyzerError catch (error) {
      throw DartDependencyException(
        'When trying to parse this Dart file to find its dependencies:\n'
        '  $path\n'
        '...the analyzer failed with the following error:\n'
        '  ${error.toString().trimRight()}',
        error,
      );
    } on analyzer.AnalyzerErrorGroup catch (error) {
      throw DartDependencyException(
        'When trying to parse this Dart file to find its dependencies:\n'
        '  $path\n'
        '...the analyzer failed with the following error:\n'
        '  ${error.toString().trimRight()}',
        error,
      );
    }
  }
}

class DartDependencyException implements Exception {
  DartDependencyException(this.message, [this.parent]);
  final String message;
  final Exception parent;
  @override
  String toString() => message;
}
