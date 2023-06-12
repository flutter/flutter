// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/element_builder.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/scope.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

class LibraryBuilder {
  final Linker linker;
  final Uri uri;
  final Reference reference;
  final LibraryElementImpl element;
  final List<LinkingUnit> units;

  /// Local declarations.
  final Scope localScope = Scope.top();

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  final List<Export> exporters = [];
  late final List<Reference> exports;

  LibraryBuilder._({
    required this.linker,
    required this.uri,
    required this.reference,
    required this.element,
    required this.units,
  });

  void addExporters() {
    for (var element in element.exports) {
      var exportedLibrary = element.exportedLibrary;
      if (exportedLibrary == null) {
        continue;
      }

      var combinators = element.combinators.map((combinator) {
        if (combinator is ShowElementCombinator) {
          return Combinator.show(combinator.shownNames);
        } else if (combinator is HideElementCombinator) {
          return Combinator.hide(combinator.hiddenNames);
        } else {
          throw UnimplementedError();
        }
      }).toList();

      var exportedUri = exportedLibrary.source.uri;
      var exportedBuilder = linker.builders[exportedUri];

      var export = Export(this, exportedBuilder, combinators);
      if (exportedBuilder != null) {
        exportedBuilder.exporters.add(export);
      } else {
        var references = linker.elementFactory.exportsOfLibrary('$exportedUri');
        for (var reference in references) {
          var name = reference.name;
          if (reference.isSetter) {
            export.addToExportScope('$name=', reference);
          } else {
            export.addToExportScope(name, reference);
          }
        }
      }
    }
  }

  /// Return `true` if the export scope was modified.
  bool addToExportScope(String name, Reference reference) {
    if (name.startsWith('_')) return false;
    if (reference.isPrefix) return false;

    var existing = exportScope.map[name];
    if (existing == reference) return false;

    // Ambiguous declaration detected.
    if (existing != null) return false;

    exportScope.map[name] = reference;
    return true;
  }

  /// Build elements for declarations in the library units, add top-level
  /// declarations to the local scope, for combining into export scopes.
  void buildElements() {
    for (var linkingUnit in units) {
      var elementBuilder = ElementBuilder(
        libraryBuilder: this,
        unitReference: linkingUnit.reference,
        unitElement: linkingUnit.element,
      );
      if (linkingUnit.isDefiningUnit) {
        elementBuilder.buildLibraryElementChildren(linkingUnit.node);
      }
      elementBuilder.buildDeclarationElements(linkingUnit.node);
    }
    _declareDartCoreDynamicNever();
  }

  void buildEnumChildren() {
    ElementBuilder.buildEnumChildren(linker, element);
  }

  void buildInitialExportScope() {
    localScope.forEach((name, reference) {
      addToExportScope(name, reference);
    });
  }

  void collectMixinSuperInvokedNames() {
    for (var linkingUnit in units) {
      for (var declaration in linkingUnit.node.declarations) {
        if (declaration is ast.MixinDeclaration) {
          var names = <String>{};
          var collector = MixinSuperInvokedNamesCollector(names);
          for (var executable in declaration.members) {
            if (executable is ast.MethodDeclaration) {
              executable.body.accept(collector);
            }
          }
          var element = declaration.declaredElement as MixinElementImpl;
          element.superInvokedNames = names.toList();
        }
      }
    }
  }

  void resolveConstructors() {
    ConstructorInitializerResolver(linker, element).resolve();
  }

  void resolveDefaultValues() {
    DefaultValueResolver(linker, element).resolve();
  }

  void resolveMetadata() {
    for (var linkingUnit in units) {
      var resolver = MetadataResolver(linker, element, linkingUnit.element);
      linkingUnit.node.accept(resolver);
    }
  }

  void resolveTypes(NodesToBuildType nodesToBuildType) {
    for (var linkingUnit in units) {
      var resolver = ReferenceResolver(linker, nodesToBuildType, element);
      linkingUnit.node.accept(resolver);
    }
  }

  void storeExportScope() {
    exports = exportScope.map.values.toList();
    linker.elementFactory.setExportsOfLibrary('$uri', exports);

    var definedNames = <String, Element>{};
    for (var entry in exportScope.map.entries) {
      var element = linker.elementFactory.elementOfReference(entry.value);
      if (element != null) {
        definedNames[entry.key] = element;
      }
    }

    var namespace = Namespace(definedNames);
    element.exportNamespace = namespace;

    var entryPoint = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      element.entryPoint = entryPoint;
    }
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (reference.name == 'dart:core') {
      var dynamicRef = reference.getChild('dynamic');
      dynamicRef.element = DynamicElementImpl.instance;
      localScope.declare('dynamic', dynamicRef);

      var neverRef = reference.getChild('Never');
      neverRef.element = NeverElementImpl.instance;
      localScope.declare('Never', neverRef);
    }
  }

  static void build(Linker linker, LinkInputLibrary inputLibrary) {
    var elementFactory = linker.elementFactory;

    var rootReference = linker.rootReference;
    var libraryUriStr = inputLibrary.uriStr;
    var libraryReference = rootReference.getChild(libraryUriStr);

    var definingUnit = inputLibrary.units[0];
    var definingUnitNode = definingUnit.unit as ast.CompilationUnitImpl;

    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in definingUnitNode.directives) {
      if (directive is ast.LibraryDirective) {
        name = directive.name.components.map((e) => e.name).join('.');
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }

    var libraryElement = LibraryElementImpl(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      name,
      nameOffset,
      nameLength,
      definingUnitNode.featureSet,
    );
    libraryElement.isSynthetic = definingUnit.isSynthetic;
    libraryElement.languageVersion = definingUnitNode.languageVersion!;
    _bindReference(libraryReference, libraryElement);
    elementFactory.setLibraryTypeSystem(libraryElement);

    var unitContainerRef = libraryReference.getChild('@unit');
    var unitElements = <CompilationUnitElementImpl>[];
    var isDefiningUnit = true;
    var linkingUnits = <LinkingUnit>[];
    for (var inputUnit in inputLibrary.units) {
      var unitNode = inputUnit.unit as ast.CompilationUnitImpl;

      var unitElement = CompilationUnitElementImpl();
      unitElement.isSynthetic = inputUnit.isSynthetic;
      unitElement.librarySource = inputLibrary.source;
      unitElement.lineInfo = unitNode.lineInfo;
      unitElement.source = inputUnit.source;
      unitElement.uri = inputUnit.partUriStr;
      unitElement.setCodeRange(0, unitNode.length);

      var unitReference = unitContainerRef.getChild(inputUnit.uriStr);
      _bindReference(unitReference, unitElement);

      unitElements.add(unitElement);
      linkingUnits.add(
        LinkingUnit(
          input: inputUnit,
          isDefiningUnit: isDefiningUnit,
          reference: unitReference,
          node: unitNode,
          element: unitElement,
        ),
      );
      isDefiningUnit = false;
    }

    libraryElement.definingCompilationUnit = unitElements[0];
    libraryElement.parts = unitElements.skip(1).toList();

    var builder = LibraryBuilder._(
      linker: linker,
      uri: inputLibrary.uri,
      reference: libraryReference,
      element: libraryElement,
      units: linkingUnits,
    );

    linker.builders[builder.uri] = builder;
  }

  static void _bindReference(Reference reference, ElementImpl element) {
    reference.element = element;
    element.reference = reference;
  }
}

class LinkingUnit {
  final LinkInputUnit input;
  final bool isDefiningUnit;
  final Reference reference;
  final ast.CompilationUnitImpl node;
  final CompilationUnitElementImpl element;

  LinkingUnit({
    required this.input,
    required this.isDefiningUnit,
    required this.reference,
    required this.node,
    required this.element,
  });
}
