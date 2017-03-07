// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analyzer.dart';

import '../base/file_system.dart';
import '../dart/package_map.dart';

class DartDependencySetBuilder {
  DartDependencySetBuilder(String mainScriptPath, String packagesFilePath) :
        this._mainScriptPath = fs.path.canonicalize(mainScriptPath),
        this._mainScriptUri = fs.path.toUri(mainScriptPath),
        this._packagesFilePath = fs.path.canonicalize(packagesFilePath);

  final String _mainScriptPath;
  final String _packagesFilePath;

  final Uri _mainScriptUri;

  Set<String> build() {
    final List<String> dependencies = <String>[_mainScriptPath, _packagesFilePath];
    final List<Uri> toProcess = <Uri>[_mainScriptUri];
    final PackageMap packageMap = new PackageMap(_packagesFilePath);

    while (toProcess.isNotEmpty) {
      final Uri currentUri = toProcess.removeLast();
      final CompilationUnit unit = _parse(currentUri.toFilePath());
      for (Directive directive in unit.directives) {
        if (!(directive is UriBasedDirective))
          continue;
        final UriBasedDirective uriBasedDirective = directive;
        final String uriAsString = uriBasedDirective.uri.stringValue;
        Uri resolvedUri = resolveRelativeUri(currentUri, Uri.parse(uriAsString));
        if (resolvedUri.scheme.startsWith('dart'))
          continue;
        if (resolvedUri.scheme == 'package')
          resolvedUri = packageMap.uriForPackage(resolvedUri);
        final String path = fs.path.canonicalize(resolvedUri.toFilePath());
        if (!dependencies.contains(path)) {
          dependencies.add(path);
          toProcess.add(resolvedUri);
        }
      }
    }
    return dependencies.toSet();
  }

  CompilationUnit _parse(String path) => parseDirectives(fs.file(path).readAsStringSync(), name: path);
}
