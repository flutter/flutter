// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' hide DirectiveUri;
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
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
import 'package:analyzer/src/summary2/field_promotability.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/macro_application.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class DefiningLinkingUnit extends LinkingUnit {
  DefiningLinkingUnit({
    required super.reference,
    required super.node,
    required super.element,
    required super.container,
  });
}

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
  final LibraryFileKind kind;
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
    required this.kind,
    required this.uri,
    required this.reference,
    required this.element,
    required this.units,
  });

  SourceFactory get _sourceFactory {
    return linker.elementFactory.analysisContext.sourceFactory;
  }

  void addExporters() {
    final containers = [element, ...element.augmentations];
    for (var containerIndex = 0;
        containerIndex < containers.length;
        containerIndex++) {
      final container = containers[containerIndex];
      final exportElements = container.libraryExports;
      for (var exportIndex = 0;
          exportIndex < exportElements.length;
          exportIndex++) {
        final exportElement = exportElements[exportIndex];

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

        final export = Export(
          exporter: this,
          location: ExportLocation(
            containerIndex: containerIndex,
            exportIndex: exportIndex,
          ),
          combinators: combinators,
        );
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
  }

  /// Build elements for declarations in the library units, add top-level
  /// declarations to the local scope, for combining into export scopes.
  void buildElements() {
    _buildDirectives(
      kind: kind,
      container: element,
    );

    for (var linkingUnit in units) {
      var elementBuilder = ElementBuilder(
        libraryBuilder: this,
        container: linkingUnit.container,
        unitReference: linkingUnit.reference,
        unitElement: linkingUnit.element,
      );
      if (linkingUnit is DefiningLinkingUnit) {
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
        element.typeSystem.instantiateInterfaceToBounds(
          element: enum_.element,
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
        if (declaration is ast.MixinDeclarationImpl) {
          var names = <String>{};
          var collector = MixinSuperInvokedNamesCollector(names);
          for (var executable in declaration.members) {
            if (executable is ast.MethodDeclarationImpl) {
              executable.body.accept(collector);
            }
          }
          var element = declaration.declaredElement as MixinElementImpl;
          element.superInvokedNames = names.toList();
        }
      }
    }
  }

  /// Computes which fields in this library are promotable.
  void computeFieldPromotability() {
    if (!element.featureSet.isEnabled(Feature.inference_update_2)) {
      return;
    }

    FieldPromotability(this).perform();
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
      container: element,
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
      final augmented = element.getClass(augmentation.name);
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
    final unitSource = _sourceFactory.forUri2(unitUri)!;
    var unitElement = CompilationUnitElementImpl(
      source: unitSource,
      librarySource: element.source,
      lineInfo: parseResult.lineInfo,
    )
      ..enclosingElement = element
      ..isSynthetic = true
      ..uri = unitUri.toString();

    var unitReference = reference.getChild('@unit').getChild('$unitUri');
    _bindReference(unitReference, unitElement);

    element.parts = [
      ...element.parts,
      PartElementImpl(
        uri: DirectiveUriWithUnitImpl(
          relativeUriString: '_macro_types.dart',
          relativeUri: unitUri,
          unit: unitElement,
        ),
      ),
    ];

    ElementBuilder(
      libraryBuilder: this,
      container: element,
      unitReference: unitReference,
      unitElement: unitElement,
    ).buildDeclarationElements(unitNode);

    // We move elements, so they don't have real offsets.
    unitElement.accept(_FlushElementOffsets());

    units.add(
      LinkingUnit(
        reference: unitReference,
        node: unitNode,
        container: element,
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
      var resolver = ReferenceResolver(
        linker,
        nodesToBuildType,
        linkingUnit.container,
      );
      linkingUnit.node.accept(resolver);
    }
  }

  void storeExportScope() {
    element.exportedReferences = exportScope.toReferences();

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

  AugmentationImportElementImpl _buildAugmentationImport(
    LibraryOrAugmentationElementImpl augmentationTarget,
    AugmentationImportState state,
  ) {
    final DirectiveUri uri;
    if (state is AugmentationImportWithFile) {
      final importedAugmentation = state.importedAugmentation;
      if (importedAugmentation != null) {
        final importedFile = importedAugmentation.file;

        final unitNode = importedFile.parse();
        final unitElement = CompilationUnitElementImpl(
          source: importedFile.source,
          // TODO(scheglov) Remove this parameter.
          librarySource: importedFile.source,
          lineInfo: unitNode.lineInfo,
        );
        unitElement.setCodeRange(0, unitNode.length);

        final unitReference =
            reference.getChild('@augmentation').getChild(importedFile.uriStr);
        _bindReference(unitReference, unitElement);

        final augmentation = LibraryAugmentationElementImpl(
          augmentationTarget: augmentationTarget,
          nameOffset: importedAugmentation.unlinked.libraryKeywordOffset,
        );
        augmentation.definingCompilationUnit = unitElement;
        augmentation.reference = unitElement.reference!;

        _buildDirectives(
          kind: importedAugmentation,
          container: augmentation,
        );

        uri = DirectiveUriWithAugmentationImpl(
          relativeUriString: state.uri.relativeUriStr,
          relativeUri: state.uri.relativeUri,
          source: importedFile.source,
          augmentation: augmentation,
        );

        units.add(
          DefiningLinkingUnit(
            reference: unitReference,
            node: unitNode,
            element: unitElement,
            container: augmentation,
          ),
        );
      } else {
        uri = DirectiveUriWithSourceImpl(
          relativeUriString: state.uri.relativeUriStr,
          relativeUri: state.uri.relativeUri,
          source: state.importedSource,
        );
      }
    } else {
      final selectedUri = state.uri;
      if (selectedUri is file_state.DirectiveUriWithUri) {
        uri = DirectiveUriWithRelativeUriImpl(
          relativeUriString: selectedUri.relativeUriStr,
          relativeUri: selectedUri.relativeUri,
        );
      } else if (selectedUri is file_state.DirectiveUriWithString) {
        uri = DirectiveUriWithRelativeUriStringImpl(
          relativeUriString: selectedUri.relativeUriStr,
        );
      } else {
        uri = DirectiveUriImpl();
      }
    }

    return AugmentationImportElementImpl(
      importKeywordOffset: state.unlinked.importKeywordOffset,
      uri: uri,
    );
  }

  List<NamespaceCombinator> _buildCombinators(
    List<UnlinkedCombinator> combinators2,
  ) {
    return combinators2.map((unlinked) {
      if (unlinked.isShow) {
        return ShowElementCombinatorImpl()
          ..offset = unlinked.keywordOffset
          ..end = unlinked.endOffset
          ..shownNames = unlinked.names;
      } else {
        // TODO(scheglov) Why no offsets?
        return HideElementCombinatorImpl()..hiddenNames = unlinked.names;
      }
    }).toFixedList();
  }

  /// Builds directive elements, for the library and recursively for its
  /// augmentations.
  void _buildDirectives({
    required LibraryOrAugmentationFileKind kind,
    required LibraryOrAugmentationElementImpl container,
  }) {
    container.libraryExports = kind.libraryExports.map((state) {
      return _buildExport(state);
    }).toFixedList();

    container.libraryImports = kind.libraryImports.map((state) {
      return _buildImport(
        container: container,
        state: state,
      );
    }).toFixedList();

    container.augmentationImports = kind.augmentationImports.map((state) {
      return _buildAugmentationImport(container, state);
    }).toFixedList();
  }

  LibraryExportElementImpl _buildExport(LibraryExportState state) {
    final combinators = _buildCombinators(
      state.unlinked.combinators,
    );

    final DirectiveUri uri;
    if (state is LibraryExportWithFile) {
      final exportedLibraryKind = state.exportedLibrary;
      if (exportedLibraryKind != null) {
        final exportedFile = exportedLibraryKind.file;
        final exportedUri = exportedFile.uri;
        final elementFactory = linker.elementFactory;
        final exportedLibrary = elementFactory.libraryOfUri2(exportedUri);
        uri = DirectiveUriWithLibraryImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: exportedLibrary.source,
          library: exportedLibrary,
        );
      } else {
        uri = DirectiveUriWithSourceImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: state.exportedSource,
        );
      }
    } else if (state is LibraryExportWithInSummarySource) {
      final exportedLibrarySource = state.exportedLibrarySource;
      if (exportedLibrarySource != null) {
        final exportedUri = exportedLibrarySource.uri;
        final elementFactory = linker.elementFactory;
        final exportedLibrary = elementFactory.libraryOfUri2(exportedUri);
        uri = DirectiveUriWithLibraryImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: exportedLibrary.source,
          library: exportedLibrary,
        );
      } else {
        uri = DirectiveUriWithSourceImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: state.exportedSource,
        );
      }
    } else {
      final selectedUri = state.selectedUri;
      if (selectedUri is file_state.DirectiveUriWithUri) {
        uri = DirectiveUriWithRelativeUriImpl(
          relativeUriString: selectedUri.relativeUriStr,
          relativeUri: selectedUri.relativeUri,
        );
      } else if (selectedUri is file_state.DirectiveUriWithString) {
        uri = DirectiveUriWithRelativeUriStringImpl(
          relativeUriString: selectedUri.relativeUriStr,
        );
      } else {
        uri = DirectiveUriImpl();
      }
    }

    return LibraryExportElementImpl(
      combinators: combinators,
      exportKeywordOffset: state.unlinked.exportKeywordOffset,
      uri: uri,
    );
  }

  LibraryImportElementImpl _buildImport({
    required LibraryOrAugmentationElementImpl container,
    required LibraryImportState state,
  }) {
    final importPrefix = state.unlinked.prefix.mapOrNull((unlinked) {
      final prefix = _buildPrefix(
        name: unlinked.name,
        nameOffset: unlinked.nameOffset,
        container: container,
      );
      if (unlinked.deferredOffset != null) {
        return DeferredImportElementPrefixImpl(
          element: prefix,
        );
      } else {
        return ImportElementPrefixImpl(
          element: prefix,
        );
      }
    });

    final combinators = _buildCombinators(
      state.unlinked.combinators,
    );

    final DirectiveUri uri;
    if (state is LibraryImportWithFile) {
      final importedLibraryKind = state.importedLibrary;
      if (importedLibraryKind != null) {
        final importedFile = importedLibraryKind.file;
        final importedUri = importedFile.uri;
        final elementFactory = linker.elementFactory;
        final importedLibrary = elementFactory.libraryOfUri2(importedUri);
        uri = DirectiveUriWithLibraryImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: importedLibrary.source,
          library: importedLibrary,
        );
      } else {
        uri = DirectiveUriWithSourceImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: state.importedSource,
        );
      }
    } else if (state is LibraryImportWithInSummarySource) {
      final importedLibrarySource = state.importedLibrarySource;
      if (importedLibrarySource != null) {
        final importedUri = importedLibrarySource.uri;
        final elementFactory = linker.elementFactory;
        final importedLibrary = elementFactory.libraryOfUri2(importedUri);
        uri = DirectiveUriWithLibraryImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: importedLibrary.source,
          library: importedLibrary,
        );
      } else {
        uri = DirectiveUriWithSourceImpl(
          relativeUriString: state.selectedUri.relativeUriStr,
          relativeUri: state.selectedUri.relativeUri,
          source: state.importedSource,
        );
      }
    } else {
      final selectedUri = state.selectedUri;
      if (selectedUri is file_state.DirectiveUriWithUri) {
        uri = DirectiveUriWithRelativeUriImpl(
          relativeUriString: selectedUri.relativeUriStr,
          relativeUri: selectedUri.relativeUri,
        );
      } else if (selectedUri is file_state.DirectiveUriWithString) {
        uri = DirectiveUriWithRelativeUriStringImpl(
          relativeUriString: selectedUri.relativeUriStr,
        );
      } else {
        uri = DirectiveUriImpl();
      }
    }

    return LibraryImportElementImpl(
      combinators: combinators,
      importKeywordOffset: state.unlinked.importKeywordOffset,
      prefix: importPrefix,
      uri: uri,
    )..isSynthetic = state.isSyntheticDartCore;
  }

  PrefixElementImpl _buildPrefix({
    required String name,
    required int nameOffset,
    required LibraryOrAugmentationElementImpl container,
  }) {
    // TODO(scheglov) Make reference required.
    final containerRef = container.reference!;
    final reference = containerRef.getChild('@prefix').getChild(name);
    final existing = reference.element;
    if (existing is PrefixElementImpl) {
      return existing;
    } else {
      final result = PrefixElementImpl(
        name,
        nameOffset,
        reference: reference,
      );
      container.encloseElement(result);
      return result;
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

  static void build(Linker linker, LibraryFileKind inputLibrary) {
    final elementFactory = linker.elementFactory;
    final rootReference = linker.rootReference;

    final libraryFile = inputLibrary.file;
    final libraryUriStr = libraryFile.uriStr;
    final libraryReference = rootReference.getChild(libraryUriStr);

    final libraryUnitNode = libraryFile.parse();

    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (final directive in libraryUnitNode.directives) {
      if (directive is ast.LibraryDirectiveImpl) {
        final nameIdentifier = directive.name2;
        if (nameIdentifier != null) {
          name = nameIdentifier.components.map((e) => e.name).join('.');
          nameOffset = nameIdentifier.offset;
          nameLength = nameIdentifier.length;
        }
        break;
      }
    }

    final libraryElement = LibraryElementImpl(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      name,
      nameOffset,
      nameLength,
      libraryUnitNode.featureSet,
    );
    libraryElement.isSynthetic = !libraryFile.exists;
    libraryElement.languageVersion = libraryUnitNode.languageVersion!;
    _bindReference(libraryReference, libraryElement);
    elementFactory.setLibraryTypeSystem(libraryElement);

    final unitContainerRef = libraryReference.getChild('@unit');

    final linkingUnits = <LinkingUnit>[];
    {
      final unitElement = CompilationUnitElementImpl(
        source: libraryFile.source,
        librarySource: libraryFile.source,
        lineInfo: libraryUnitNode.lineInfo,
      );
      unitElement.isSynthetic = !libraryFile.exists;
      unitElement.setCodeRange(0, libraryUnitNode.length);

      final unitReference = unitContainerRef.getChild(libraryFile.uriStr);
      _bindReference(unitReference, unitElement);

      linkingUnits.add(
        DefiningLinkingUnit(
          reference: unitReference,
          node: libraryUnitNode,
          element: unitElement,
          container: libraryElement,
        ),
      );

      libraryElement.definingCompilationUnit = unitElement;
    }

    libraryElement.parts = inputLibrary.parts.map((partState) {
      final uriState = partState.uri;
      final DirectiveUri directiveUri;
      if (partState is PartWithFile) {
        final includedPart = partState.includedPart;
        if (includedPart != null) {
          final partFile = includedPart.file;
          final partUnitNode = partFile.parse();
          final unitElement = CompilationUnitElementImpl(
            source: partFile.source,
            librarySource: libraryFile.source,
            lineInfo: partUnitNode.lineInfo,
          );
          unitElement.isSynthetic = !partFile.exists;
          unitElement.uri = partFile.uriStr;
          unitElement.setCodeRange(0, partUnitNode.length);

          final unitReference = unitContainerRef.getChild(partFile.uriStr);
          _bindReference(unitReference, unitElement);

          linkingUnits.add(
            LinkingUnit(
              reference: unitReference,
              node: partUnitNode,
              container: libraryElement,
              element: unitElement,
            ),
          );

          directiveUri = DirectiveUriWithUnitImpl(
            relativeUriString: partState.uri.relativeUriStr,
            relativeUri: partState.uri.relativeUri,
            unit: unitElement,
          );
        } else {
          directiveUri = DirectiveUriWithSourceImpl(
            relativeUriString: partState.uri.relativeUriStr,
            relativeUri: partState.uri.relativeUri,
            source: partState.includedFile.source,
          );
        }
      } else if (uriState is file_state.DirectiveUriWithSource) {
        directiveUri = DirectiveUriWithSourceImpl(
          relativeUriString: uriState.relativeUriStr,
          relativeUri: uriState.relativeUri,
          source: uriState.source,
        );
      } else if (uriState is file_state.DirectiveUriWithUri) {
        directiveUri = DirectiveUriWithRelativeUriImpl(
          relativeUriString: uriState.relativeUriStr,
          relativeUri: uriState.relativeUri,
        );
      } else if (uriState is file_state.DirectiveUriWithString) {
        directiveUri = DirectiveUriWithRelativeUriStringImpl(
          relativeUriString: uriState.relativeUriStr,
        );
      } else {
        directiveUri = DirectiveUriImpl();
      }
      return directiveUri;
    }).map((directiveUri) {
      return PartElementImpl(
        uri: directiveUri,
      );
    }).toFixedList();

    final builder = LibraryBuilder._(
      linker: linker,
      kind: inputLibrary,
      uri: libraryFile.uri,
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
  final Reference reference;
  final ast.CompilationUnitImpl node;
  final LibraryOrAugmentationElementImpl container;
  final CompilationUnitElementImpl element;

  LinkingUnit({
    required this.reference,
    required this.node,
    required this.container,
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

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}
