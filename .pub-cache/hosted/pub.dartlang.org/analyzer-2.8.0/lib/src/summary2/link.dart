// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/detach_nodes.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/simply_bounded.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';
import 'package:analyzer/src/summary2/type_alias.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/summary2/variance_builder.dart';

var timerLinkingLinkingBundle = Stopwatch();

/// Note that AST units and tokens of [inputLibraries] will be damaged.
LinkResult link(
  LinkedElementFactory elementFactory,
  List<LinkInputLibrary> inputLibraries,
) {
  var linker = Linker(elementFactory);
  linker.link(inputLibraries);
  return LinkResult(
    resolutionBytes: linker.resolutionBytes,
  );
}

class Linker {
  final LinkedElementFactory elementFactory;

  /// Libraries that are being linked.
  final Map<Uri, LibraryBuilder> builders = {};

  final Map<ElementImpl, ast.AstNode> elementNodes = Map.identity();

  late InheritanceManager3 inheritance; // TODO(scheglov) cache it

  late Uint8List resolutionBytes;

  Linker(this.elementFactory);

  AnalysisContextImpl get analysisContext {
    return elementFactory.analysisContext;
  }

  DeclaredVariables get declaredVariables {
    return analysisContext.declaredVariables;
  }

  Reference get rootReference => elementFactory.rootReference;

  /// If the [element] is part of a library being linked, return the node
  /// from which it was created.
  ast.AstNode? getLinkingNode(Element element) {
    return elementNodes[element];
  }

  void link(List<LinkInputLibrary> inputLibraries) {
    for (var inputLibrary in inputLibraries) {
      LibraryBuilder.build(this, inputLibrary);
    }

    _buildOutlines();

    timerLinkingLinkingBundle.start();
    _writeLibraries();
    timerLinkingLinkingBundle.stop();
  }

  void _buildEnumChildren() {
    for (var library in builders.values) {
      library.buildEnumChildren();
    }
  }

  void _buildOutlines() {
    _computeLibraryScopes();
    _createTypeSystem();
    _buildEnumChildren();
    _resolveTypes();
    _performTopLevelInference();
    _resolveConstructors();
    _resolveConstantInitializers();
    _resolveDefaultValues();
    _resolveMetadata();
    _collectMixinSuperInvokedNames();
    _detachNodes();
  }

  void _collectMixinSuperInvokedNames() {
    for (var library in builders.values) {
      library.collectMixinSuperInvokedNames();
    }
  }

  void _computeLibraryScopes() {
    for (var library in builders.values) {
      library.buildElements();
    }

    for (var library in builders.values) {
      library.buildInitialExportScope();
    }

    var exporters = <LibraryBuilder>{};
    var exportees = <LibraryBuilder>{};

    for (var library in builders.values) {
      library.addExporters();
    }

    for (var library in builders.values) {
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (var exporter in library.exporters) {
          exporters.add(exporter.exporter);
        }
      }
    }

    var both = <LibraryBuilder>{};
    for (var exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported);
      }
      for (var export in exported.exporters) {
        exported.exportScope.forEach(export.addToExportScope);
      }
    }

    while (true) {
      var hasChanges = false;
      for (var exported in both) {
        for (var export in exported.exporters) {
          exported.exportScope.forEach((name, member) {
            if (export.addToExportScope(name, member)) {
              hasChanges = true;
            }
          });
        }
      }
      if (!hasChanges) break;
    }

    for (var library in builders.values) {
      library.storeExportScope();
    }
  }

  void _createTypeSystem() {
    var coreLib = elementFactory.libraryOfUri2('dart:core');
    var asyncLib = elementFactory.libraryOfUri2('dart:async');
    elementFactory.createTypeProviders(coreLib, asyncLib);

    inheritance = InheritanceManager3();
  }

  void _detachNodes() {
    for (var builder in builders.values) {
      detachElementsFromNodes(builder.element);
    }
  }

  void _performTopLevelInference() {
    TopLevelInference(this).infer();
  }

  void _resolveConstantInitializers() {
    ConstantInitializersResolver(this).perform();
  }

  void _resolveConstructors() {
    for (var library in builders.values) {
      library.resolveConstructors();
    }
  }

  void _resolveDefaultValues() {
    for (var library in builders.values) {
      library.resolveDefaultValues();
    }
  }

  void _resolveMetadata() {
    for (var library in builders.values) {
      library.resolveMetadata();
    }
  }

  void _resolveTypes() {
    var nodesToBuildType = NodesToBuildType();
    for (var library in builders.values) {
      library.resolveTypes(nodesToBuildType);
    }
    VarianceBuilder(this).perform();
    computeSimplyBounded(this);
    TypeAliasSelfReferenceFinder().perform(this);
    TypesBuilder(this).build(nodesToBuildType);
  }

  void _writeLibraries() {
    var bundleWriter = BundleWriter(
      elementFactory.dynamicRef,
    );

    for (var builder in builders.values) {
      bundleWriter.writeLibraryElement(
        builder.element,
        builder.exports,
      );
    }

    var writeWriterResult = bundleWriter.finish();
    resolutionBytes = writeWriterResult.resolutionBytes;
  }
}

class LinkInputLibrary {
  final Source source;
  final List<LinkInputUnit> units;

  LinkInputLibrary({
    required this.source,
    required this.units,
  });

  Uri get uri => source.uri;

  String get uriStr => '$uri';
}

class LinkInputUnit {
  final int? partDirectiveIndex;
  final String? partUriStr;
  final Source source;
  final String? sourceContent;
  final bool isSynthetic;
  final ast.CompilationUnit unit;

  LinkInputUnit({
    required this.partDirectiveIndex,
    this.partUriStr,
    required this.source,
    this.sourceContent,
    required this.isSynthetic,
    required this.unit,
  });

  Uri get uri => source.uri;

  String get uriStr => '$uri';
}

class LinkResult {
  final Uint8List resolutionBytes;

  LinkResult({
    required this.resolutionBytes,
  });
}
