// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
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
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/simply_bounded.dart';
import 'package:analyzer/src/summary2/super_constructor_resolver.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';
import 'package:analyzer/src/summary2/type_alias.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/summary2/variance_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Note that AST units and tokens of [inputLibraries] will be damaged.
@Deprecated('Use link2() instead')
Future<LinkResult> link(
  LinkedElementFactory elementFactory,
  List<LinkInputLibrary> inputLibraries, {
  macro.MultiMacroExecutor? macroExecutor,
  OperationPerformanceImpl? performance,
}) async {
  return await link2(
    elementFactory: elementFactory,
    inputLibraries: inputLibraries,
    performance: OperationPerformanceImpl('<root>'),
  );
}

/// Note that AST units and tokens of [inputLibraries] will be damaged.
Future<LinkResult> link2({
  required LinkedElementFactory elementFactory,
  required OperationPerformanceImpl performance,
  required List<LinkInputLibrary> inputLibraries,
  macro.MultiMacroExecutor? macroExecutor,
}) async {
  final linker = Linker(elementFactory, macroExecutor);
  await linker.link(
    performance: performance,
    inputLibraries: inputLibraries,
  );
  return LinkResult(
    resolutionBytes: linker.resolutionBytes,
    macroGeneratedUnits: linker.macroGeneratedUnits,
  );
}

class Linker {
  final LinkedElementFactory elementFactory;
  final macro.MultiMacroExecutor? macroExecutor;
  final DeclarationBuilder macroDeclarationBuilder = DeclarationBuilder();

  /// Libraries that are being linked.
  final Map<Uri, LibraryBuilder> builders = {};

  final Map<ElementImpl, ast.AstNode> elementNodes = Map.identity();

  late InheritanceManager3 inheritance; // TODO(scheglov) cache it

  late Uint8List resolutionBytes;

  final List<LinkMacroGeneratedUnit> macroGeneratedUnits = [];

  Linker(this.elementFactory, this.macroExecutor);

  AnalysisContextImpl get analysisContext {
    return elementFactory.analysisContext;
  }

  DeclaredVariables get declaredVariables {
    return analysisContext.declaredVariables;
  }

  Reference get rootReference => elementFactory.rootReference;

  bool get _isLinkingDartCore {
    var dartCoreUri = Uri.parse('dart:core');
    return builders.containsKey(dartCoreUri);
  }

  /// If the [element] is part of a library being linked, return the node
  /// from which it was created.
  ast.AstNode? getLinkingNode(Element element) {
    return elementNodes[element];
  }

  Future<void> link({
    required OperationPerformanceImpl performance,
    required List<LinkInputLibrary> inputLibraries,
  }) async {
    for (var inputLibrary in inputLibraries) {
      LibraryBuilder.build(this, inputLibrary);
    }

    await _buildOutlines(
      performance: performance,
    );

    _writeLibraries();
  }

  void _buildEnumChildren() {
    for (var library in builders.values) {
      library.buildEnumChildren();
    }
  }

  Future<void> _buildOutlines({
    required OperationPerformanceImpl performance,
  }) async {
    _createTypeSystemIfNotLinkingDartCore();

    await performance.runAsync(
      'computeLibraryScopes',
      (performance) async {
        await _computeLibraryScopes(
          performance: performance,
        );
      },
    );

    _createTypeSystem();
    _resolveTypes();
    _buildEnumChildren();

    await performance.runAsync(
      'executeMacroDeclarationsPhase',
      (_) async {
        await _executeMacroDeclarationsPhase();
      },
    );

    SuperConstructorResolver(this).perform();
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

  Future<void> _computeLibraryScopes({
    required OperationPerformanceImpl performance,
  }) async {
    for (var library in builders.values) {
      library.buildElements();
    }

    await performance.runAsync(
      'executeMacroTypesPhase',
      (performance) async {
        for (var library in builders.values) {
          await library.executeMacroTypesPhase(
            performance: performance,
          );
        }
      },
    );

    macroDeclarationBuilder.transferToElements();

    for (var library in builders.values) {
      library.buildInitialExportScope();
    }

    var exportingBuilders = <LibraryBuilder>{};
    var exportedBuilders = <LibraryBuilder>{};

    for (var library in builders.values) {
      library.addExporters();
    }

    for (var library in builders.values) {
      if (library.exports.isNotEmpty) {
        exportedBuilders.add(library);
        for (var export in library.exports) {
          exportingBuilders.add(export.exporter);
        }
      }
    }

    var both = <LibraryBuilder>{};
    for (var exported in exportedBuilders) {
      if (exportingBuilders.contains(exported)) {
        both.add(exported);
      }
      for (var export in exported.exports) {
        exported.exportScope.forEach(export.addToExportScope);
      }
    }

    while (true) {
      var hasChanges = false;
      for (var exported in both) {
        for (var export in exported.exports) {
          exported.exportScope.forEach((name, reference) {
            if (export.addToExportScope(name, reference)) {
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
    elementFactory.createTypeProviders(
      elementFactory.dartCoreElement,
      elementFactory.dartAsyncElement,
    );

    inheritance = InheritanceManager3();
  }

  /// To resolve macro annotations we need to access exported namespaces of
  /// imported (and already linked) libraries. While computing it we might
  /// need `Null` from `dart:core` (to convert null safe types to legacy).
  void _createTypeSystemIfNotLinkingDartCore() {
    if (!_isLinkingDartCore) {
      _createTypeSystem();
    }
  }

  void _detachNodes() {
    for (var builder in builders.values) {
      detachElementsFromNodes(builder.element);
    }
  }

  Future<void> _executeMacroDeclarationsPhase() async {
    for (final library in builders.values) {
      await library.executeMacroDeclarationsPhase();
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
      bundleWriter.writeLibraryElement(builder.element);
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

class LinkMacroGeneratedUnit {
  final Uri uri;
  final String content;
  final ast.CompilationUnit unit;

  LinkMacroGeneratedUnit({
    required this.uri,
    required this.content,
    required this.unit,
  });
}

class LinkResult {
  final Uint8List resolutionBytes;
  final List<LinkMacroGeneratedUnit> macroGeneratedUnits;

  LinkResult({
    required this.resolutionBytes,
    required this.macroGeneratedUnits,
  });
}
