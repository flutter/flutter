// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/element_builder.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/macro_application.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

class ImplicitEnumNodes {
  final EnumElementImpl element;
  final ast.NamedTypeImpl valuesTypeNode;
  final ConstFieldElementImpl valuesField;

  ImplicitEnumNodes({
    required this.element,
    required this.valuesTypeNode,
    required this.valuesField,
  });
}

class LibraryBuilder {
  final Linker linker;
  final Uri uri;
  final Reference reference;
  final LibraryElementImpl element;
  final List<LinkingUnit> units;

  final List<ImplicitEnumNodes> implicitEnumNodes = [];

  /// Local declarations.
  final Map<String, Reference> _declaredReferences = {};

  /// The export scope of the library.
  final ExportScope exportScope = ExportScope();

  /// The `export` directives that export this library.
  final List<Export> exports = [];

  late final LibraryMacroApplier? _macroApplier = () {
    if (!element.featureSet.isEnabled(Feature.macros)) {
      return null;
    }

    final macroExecutor = linker.macroExecutor;
    if (macroExecutor == null) {
      return null;
    }

    return LibraryMacroApplier(
      macroExecutor: macroExecutor,
      declarationBuilder: linker.macroDeclarationBuilder,
      libraryBuilder: this,
    );
  }();

  LibraryBuilder._({
    required this.linker,
    required this.uri,
    required this.reference,
    required this.element,
    required this.units,
  });

  SourceFactory get _sourceFactory {
    return linker.elementFactory.analysisContext.sourceFactory;
  }

  void addExporters() {
    final exportElements = element.exports;
    for (var i = 0; i < exportElements.length; i++) {
      final exportElement = exportElements[i];

      final exportedLibrary = exportElement.exportedLibrary;
      if (exportedLibrary is! LibraryElementImpl) {
        continue;
      }

      final combinators = exportElement.combinators.map((combinator) {
        if (combinator is ShowElementCombinator) {
          return Combinator.show(combinator.shownNames);
        } else if (combinator is HideElementCombinator) {
          return Combinator.hide(combinator.hiddenNames);
        } else {
          throw UnimplementedError();
        }
      }).toList();

      final exportedUri = exportedLibrary.source.uri;
      final exportedBuilder = linker.builders[exportedUri];

      final export = Export(this, i, combinators);
      if (exportedBuilder != null) {
        exportedBuilder.exports.add(export);
      } else {
        final exportedReferences = exportedLibrary.exportedReferences;
        for (final exported in exportedReferences) {
          final reference = exported.reference;
          final name = reference.name;
          if (reference.isSetter) {
            export.addToExportScope('$name=', exported);
          } else {
            export.addToExportScope(name, exported);
          }
        }
      }
    }
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
    var typeProvider = element.typeProvider;
    for (var enum_ in implicitEnumNodes) {
      enum_.element.supertype =
          typeProvider.enumType ?? typeProvider.objectType;
      var valuesType = typeProvider.listType(
        element.typeSystem.instantiateToBounds2(
          classElement: enum_.element,
          nullabilitySuffix: typeProvider.objectType.nullabilitySuffix,
        ),
      );
      enum_.valuesTypeNode.type = valuesType;
      enum_.valuesField.type = valuesType;
    }
  }

  void buildInitialExportScope() {
    _declaredReferences.forEach((name, reference) {
      if (name.startsWith('_')) return;
      if (reference.isPrefix) return;
      exportScope.declare(name, reference);
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

  void declare(String name, Reference reference) {
    _declaredReferences[name] = reference;
  }

  Future<void> executeMacroDeclarationsPhase() async {
    final macroApplier = _macroApplier;
    if (macroApplier == null) {
      return;
    }

    final augmentationLibrary = await macroApplier.executeDeclarationsPhase();
    if (augmentationLibrary == null) {
      return;
    }

    final parseResult = parseString(
      content: augmentationLibrary,
      featureSet: element.featureSet,
      throwIfDiagnostics: false,
    );
    final unitNode = parseResult.unit as ast.CompilationUnitImpl;

    // We don't actually keep this unit, but we need it for now as a container.
    // Eventually we will use actual augmentation libraries.
    final unitUri = uri.resolve('_macro_declarations.dart');
    final unitReference = reference.getChild('@unit').getChild('$unitUri');
    final unitElement = CompilationUnitElementImpl(
      source: _sourceFactory.forUri2(unitUri)!,
      librarySource: element.source,
      lineInfo: parseResult.lineInfo,
    )
      ..enclosingElement = element
      ..isSynthetic = true
      ..uri = unitUri.toString();

    final elementBuilder = ElementBuilder(
      libraryBuilder: this,
      unitReference: unitReference,
      unitElement: unitElement,
    );
    elementBuilder.buildDeclarationElements(unitNode);

    // We move elements, so they don't have real offsets.
    unitElement.accept(_FlushElementOffsets());

    final nodesToBuildType = NodesToBuildType();
    final resolver = ReferenceResolver(linker, nodesToBuildType, element);
    unitNode.accept(resolver);
    TypesBuilder(linker).build(nodesToBuildType);

    // Transplant built elements as if the augmentation was applied.
    final augmentedUnitElement = element.definingCompilationUnit;
    for (final augmentation in unitElement.classes) {
      // TODO(scheglov) if augmentation
      final augmented = element.getType(augmentation.name);
      if (augmented is ClassElementImpl) {
        augmented.accessors = [
          ...augmented.accessors,
          ...augmentation.accessors,
        ];
        augmented.constructors = [
          ...augmented.constructors,
          ...augmentation.constructors.where((e) => !e.isSynthetic),
        ];
        augmented.fields = [
          ...augmented.fields,
          ...augmentation.fields,
        ];
        augmented.methods = [
          ...augmented.methods,
          ...augmentation.methods,
        ];
      }
    }
    augmentedUnitElement.accessors = [
      ...augmentedUnitElement.accessors,
      ...unitElement.accessors,
    ];
    augmentedUnitElement.topLevelVariables = [
      ...augmentedUnitElement.topLevelVariables,
      ...unitElement.topLevelVariables,
    ];
  }

  Future<void> executeMacroTypesPhase({
    required OperationPerformanceImpl performance,
  }) async {
    final macroApplier = _macroApplier;
    if (macroApplier == null) {
      return;
    }

    await performance.runAsync(
      'buildApplications',
      (performance) async {
        await macroApplier.buildApplications(
          performance: performance,
        );
      },
    );

    final augmentationLibrary = await performance.runAsync(
      'executeTypesPhase',
      (performance) async {
        return await macroApplier.executeTypesPhase();
      },
    );

    if (augmentationLibrary == null) {
      return;
    }

    var parseResult = parseString(
      content: augmentationLibrary,
      featureSet: element.featureSet,
      throwIfDiagnostics: false,
    );
    var unitNode = parseResult.unit as ast.CompilationUnitImpl;

    // For now we model augmentation libraries as parts.
    var unitUri = uri.resolve('_macro_types.dart');
    var unitElement = CompilationUnitElementImpl(
      source: _sourceFactory.forUri2(unitUri)!,
      librarySource: element.source,
      lineInfo: parseResult.lineInfo,
    )
      ..enclosingElement = element
      ..isSynthetic = true
      ..uri = unitUri.toString();

    var unitReference = reference.getChild('@unit').getChild('$unitUri');
    _bindReference(unitReference, unitElement);

    element.parts.add(unitElement);

    ElementBuilder(
      libraryBuilder: this,
      unitReference: unitReference,
      unitElement: unitElement,
    ).buildDeclarationElements(unitNode);

    // We move elements, so they don't have real offsets.
    unitElement.accept(_FlushElementOffsets());

    units.add(
      LinkingUnit(
        isDefiningUnit: false,
        reference: unitReference,
        node: unitNode,
        element: unitElement,
      ),
    );

    linker.macroGeneratedUnits.add(
      LinkMacroGeneratedUnit(
        uri: unitUri,
        content: parseResult.content,
        unit: parseResult.unit,
      ),
    );
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
    element.exportedReferences = exportScope.map.values.toList();

    var definedNames = <String, Element>{};
    for (var entry in exportScope.map.entries) {
      var reference = entry.value.reference;
      var element = linker.elementFactory.elementOfReference(reference);
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
      declare('dynamic', dynamicRef);

      var neverRef = reference.getChild('Never');
      neverRef.element = NeverElementImpl.instance;
      declare('Never', neverRef);
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

      var unitElement = CompilationUnitElementImpl(
        source: inputUnit.source,
        librarySource: inputLibrary.source,
        lineInfo: unitNode.lineInfo,
      );
      unitElement.isSynthetic = inputUnit.isSynthetic;
      unitElement.uri = inputUnit.partUriStr;
      unitElement.setCodeRange(0, unitNode.length);

      var unitReference = unitContainerRef.getChild(inputUnit.uriStr);
      _bindReference(unitReference, unitElement);

      unitElements.add(unitElement);
      linkingUnits.add(
        LinkingUnit(
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
  final bool isDefiningUnit;
  final Reference reference;
  final ast.CompilationUnitImpl node;
  final CompilationUnitElementImpl element;

  LinkingUnit({
    required this.isDefiningUnit,
    required this.reference,
    required this.node,
    required this.element,
  });
}

class _FlushElementOffsets extends GeneralizingElementVisitor<void> {
  @override
  void visitElement(covariant ElementImpl element) {
    element.isTempAugmentation = true;
    element.nameOffset = -1;
    if (element is ConstructorElementImpl) {
      element.periodOffset = null;
      element.nameEnd = null;
    }
    super.visitElement(element);
  }
}
