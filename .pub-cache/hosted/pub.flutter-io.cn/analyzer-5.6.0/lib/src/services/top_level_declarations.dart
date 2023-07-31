// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';

class TopLevelDeclarations {
  final ResolvedUnitResult resolvedUnit;

  TopLevelDeclarations(this.resolvedUnit);

  DriverBasedAnalysisContext get _analysisContext {
    var analysisContext = resolvedUnit.session.analysisContext;
    return analysisContext as DriverBasedAnalysisContext;
  }

  /// Return the first public library that exports (but does not necessary
  /// declare) [element].
  Future<LibraryElement?> publiclyExporting(Element element,
      {Map<Element, LibraryElement?>? resultCache}) async {
    if (resultCache?.containsKey(element) ?? false) {
      return resultCache![element];
    }

    var declarationFilePath = element.source?.fullName;
    if (declarationFilePath == null) {
      return null;
    }

    var analysisDriver = _analysisContext.driver;
    var fsState = analysisDriver.fsState;
    await analysisDriver.discoverAvailableFiles();

    var declarationFile = fsState.getFileForPath(declarationFilePath);
    var declarationPackage = declarationFile.uriProperties.packageName;

    for (var file in fsState.knownFiles.toList()) {
      var uri = file.uriProperties;
      // Only search the package that contains the declaration and its public
      // libraries.
      if (uri.packageName != declarationPackage || uri.isSrc) {
        continue;
      }

      var elementResult = await analysisDriver.getLibraryByUri(file.uriStr);
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      if (_findElement(elementResult.element, element.displayName) != null) {
        resultCache?[element] = elementResult.element;
        return elementResult.element;
      }
    }

    return null;
  }

  /// Return the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name. For getters and setters the
  /// corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> withName(String baseName) async {
    var analysisDriver = _analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(resolvedUnit.path),
    );

    var result = <LibraryElement, Element>{};

    for (var file in fsState.knownFiles.toList()) {
      if (!filter.shouldInclude(file)) {
        continue;
      }

      var elementResult = await analysisDriver.getLibraryByUri(file.uriStr);
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      addElement(result, elementResult.element, baseName);
    }

    return result;
  }

  static void addElement(
    Map<LibraryElement, Element> result,
    LibraryElement libraryElement,
    String baseName,
  ) {
    var element = _findElement(libraryElement, baseName);
    if (element != null) {
      result[libraryElement] = element;
    }
  }

  static Element? _findElement(LibraryElement libraryElement, String name) {
    var element = libraryElement.exportNamespace.get(name) ??
        libraryElement.exportNamespace.get('$name=');
    return element is PropertyAccessorElement ? element.variable : element;
  }
}
