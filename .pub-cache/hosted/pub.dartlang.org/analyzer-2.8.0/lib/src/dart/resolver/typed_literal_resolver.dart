// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// Helper for resolving [ListLiteral]s and [SetOrMapLiteral]s.
class TypedLiteralResolver {
  final ResolverVisitor _resolver;
  final TypeSystemImpl _typeSystem;
  final TypeProviderImpl _typeProvider;
  final ErrorReporter _errorReporter;
  final MigratableAstInfoProvider _migratableAstInfoProvider;

  final bool _strictInference;
  final bool _uiAsCodeEnabled;

  final bool _isNonNullableByDefault;

  factory TypedLiteralResolver(ResolverVisitor resolver, FeatureSet featureSet,
      TypeSystemImpl typeSystem, TypeProviderImpl typeProvider,
      {MigratableAstInfoProvider migratableAstInfoProvider =
          const MigratableAstInfoProvider()}) {
    var library = resolver.definingLibrary;
    var analysisOptions = library.context.analysisOptions;
    var analysisOptionsImpl = analysisOptions as AnalysisOptionsImpl;
    return TypedLiteralResolver._(
        resolver,
        typeSystem,
        typeProvider,
        resolver.errorReporter,
        analysisOptionsImpl.strictInference,
        featureSet.isEnabled(Feature.control_flow_collections) ||
            featureSet.isEnabled(Feature.spread_collections),
        featureSet.isEnabled(Feature.non_nullable),
        migratableAstInfoProvider);
  }

  TypedLiteralResolver._(
      this._resolver,
      this._typeSystem,
      this._typeProvider,
      this._errorReporter,
      this._strictInference,
      this._uiAsCodeEnabled,
      this._isNonNullableByDefault,
      this._migratableAstInfoProvider);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  bool get _genericMetadataIsEnabled =>
      _resolver.definingLibrary.featureSet.isEnabled(Feature.generic_metadata);

  NullabilitySuffix get _noneOrStarSuffix {
    return _isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  void resolveListLiteral(ListLiteralImpl node) {
    InterfaceType? listType;

    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null) {
      if (typeArguments.length == 1) {
        DartType elementType = typeArguments[0].typeOrThrow;
        if (!elementType.isDynamic) {
          listType = _typeProvider.listType(elementType);
        }
      }
    } else {
      listType = _inferListType(node, downwards: true);
    }
    if (listType != null) {
      DartType elementType = listType.typeArguments[0];
      DartType iterableType = _typeProvider.iterableType(elementType);
      _pushCollectionTypesDownToAll(_getListElements(node),
          elementType: elementType, iterableType: iterableType);
      InferenceContext.setType(node, listType);
    } else {
      InferenceContext.clearType(node);
    }

    node.visitChildren(_resolver);
    _insertImplicitCallReferences(node);
    _resolveListLiteral2(node);
  }

  void resolveSetOrMapLiteral(SetOrMapLiteral node) {
    (node as SetOrMapLiteralImpl).becomeUnresolved();
    var typeArguments = node.typeArguments?.arguments;

    InterfaceType? literalType;
    var literalResolution = _computeSetOrMapResolution(node);
    if (literalResolution.kind == _LiteralResolutionKind.set) {
      if (typeArguments != null && typeArguments.length == 1) {
        var elementType = typeArguments[0].typeOrThrow;
        literalType = _typeProvider.setType(elementType);
      } else {
        literalType =
            _inferSetTypeDownwards(node, literalResolution.contextType);
      }
    } else if (literalResolution.kind == _LiteralResolutionKind.map) {
      if (typeArguments != null && typeArguments.length == 2) {
        var keyType = typeArguments[0].typeOrThrow;
        var valueType = typeArguments[1].typeOrThrow;
        literalType = _typeProvider.mapType(keyType, valueType);
      } else {
        literalType =
            _inferMapTypeDownwards(node, literalResolution.contextType);
      }
    } else {
      assert(literalResolution.kind == _LiteralResolutionKind.ambiguous);
      literalType = null;
    }
    if (literalType is InterfaceType) {
      List<DartType> typeArguments = literalType.typeArguments;
      if (typeArguments.length == 1) {
        DartType elementType = literalType.typeArguments[0];
        DartType iterableType = _typeProvider.iterableType(elementType);
        _pushCollectionTypesDownToAll(_getSetOrMapElements(node),
            elementType: elementType, iterableType: iterableType);
        if (!_uiAsCodeEnabled &&
            _getSetOrMapElements(node).isEmpty &&
            node.typeArguments == null &&
            node.isMap) {
          // The node is really an empty set literal with no type arguments.
          node.becomeMap();
        }
      } else if (typeArguments.length == 2) {
        DartType keyType = typeArguments[0];
        DartType valueType = typeArguments[1];
        _pushCollectionTypesDownToAll(_getSetOrMapElements(node),
            iterableType: literalType, keyType: keyType, valueType: valueType);
      }
      node.contextType = literalType;
    } else {
      node.contextType = null;
    }

    node.visitChildren(_resolver);
    _insertImplicitCallReferences(node);
    _resolveSetOrMapLiteral2(node);
  }

  DartType _computeElementType(CollectionElement element) {
    if (element is Expression) {
      return element.typeOrThrow;
    } else if (element is ForElement) {
      return _computeElementType(element.body);
    } else if (element is IfElement) {
      var thenElement = element.thenElement;
      var elseElement = element.elseElement;

      var thenType = _computeElementType(thenElement);
      if (elseElement == null) {
        return thenType;
      }

      var elseType = _computeElementType(elseElement);
      return _typeSystem.getLeastUpperBound(thenType, elseType);
    } else if (element is MapLiteralEntry) {
      // This error will be reported elsewhere.
      return _typeProvider.dynamicType;
    } else if (element is SpreadElement) {
      var expressionType = element.expression.typeOrThrow;

      var iterableType = expressionType.asInstanceOf(
        _typeProvider.iterableElement,
      );
      if (iterableType != null) {
        return iterableType.typeArguments[0];
      }

      if (expressionType.isDynamic) {
        return _typeProvider.dynamicType;
      }

      if (_typeSystem.isNonNullableByDefault) {
        if (_typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
          return NeverTypeImpl.instance;
        }
        if (_typeSystem.isSubtypeOf(expressionType, _typeSystem.nullNone)) {
          if (element.isNullAware) {
            return NeverTypeImpl.instance;
          }
          return _typeProvider.dynamicType;
        }
      } else {
        if (expressionType.isDartCoreNull) {
          if (element.isNullAware) {
            return expressionType;
          }
          return _typeProvider.dynamicType;
        }
      }

      // TODO(brianwilkerson) Report this as an error.
      return _typeProvider.dynamicType;
    }
    throw StateError('Unhandled element type ${element.runtimeType}');
  }

  /// Compute the context type for the given set or map [literal].
  _LiteralResolution _computeSetOrMapResolution(SetOrMapLiteral literal) {
    _LiteralResolution typeArgumentsResolution =
        _fromTypeArguments(literal.typeArguments?.arguments);
    var contextType = InferenceContext.getContext(literal);
    _LiteralResolution contextResolution = _fromContextType(contextType);
    _LeafElements elementCounts = _LeafElements(_getSetOrMapElements(literal));
    _LiteralResolution elementResolution = elementCounts.resolution;

    List<_LiteralResolution> unambiguousResolutions = [];
    Set<_LiteralResolutionKind> kinds = <_LiteralResolutionKind>{};
    if (typeArgumentsResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(typeArgumentsResolution);
      kinds.add(typeArgumentsResolution.kind);
    }
    if (contextResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(contextResolution);
      kinds.add(contextResolution.kind);
    }
    if (elementResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(elementResolution);
      kinds.add(elementResolution.kind);
    }

    if (kinds.length == 2) {
      // It looks like it needs to be both a map and a set. Attempt to recover.
      if (elementResolution.kind == _LiteralResolutionKind.ambiguous &&
          elementResolution.contextType != null) {
        return elementResolution;
      } else if (typeArgumentsResolution.kind !=
              _LiteralResolutionKind.ambiguous &&
          typeArgumentsResolution.contextType != null) {
        return typeArgumentsResolution;
      } else if (contextResolution.kind != _LiteralResolutionKind.ambiguous &&
          contextResolution.contextType != null) {
        return contextResolution;
      }
    } else if (unambiguousResolutions.length >= 2) {
      // If there are three resolutions, the last resolution is guaranteed to be
      // from the elements, which always has a context type of `null` (when it
      // is not ambiguous). So, whether there are 2 or 3 resolutions only the
      // first two are potentially interesting.
      return unambiguousResolutions[0].contextType == null
          ? unambiguousResolutions[1]
          : unambiguousResolutions[0];
    } else if (unambiguousResolutions.length == 1) {
      return unambiguousResolutions[0];
    } else if (_getSetOrMapElements(literal).isEmpty) {
      return _LiteralResolution(_LiteralResolutionKind.map,
          _typeProvider.mapType(_dynamicType, _dynamicType));
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// If [contextType] implements `Iterable`, but not `Map`, then *e* is a set
  /// literal.
  ///
  /// If [contextType] implements `Map`, but not `Iterable`, then *e* is a map
  /// literal.
  _LiteralResolution _fromContextType(DartType? contextType) {
    if (contextType != null) {
      var unwrappedContextType = _typeSystem.futureOrBase(contextType);
      // TODO(brianwilkerson) Find out what the "greatest closure" is and use that
      // where [unwrappedContextType] is used below.
      var iterableType = unwrappedContextType.asInstanceOf(
        _typeProvider.iterableElement,
      );
      var mapType = unwrappedContextType.asInstanceOf(
        _typeProvider.mapElement,
      );
      var isIterable = iterableType != null;
      var isMap = mapType != null;

      // When `S` implements `Iterable` but not `Map`, `e` is a set literal.
      if (isIterable && !isMap) {
        return _LiteralResolution(
          _LiteralResolutionKind.set,
          unwrappedContextType,
        );
      }

      // When `S` implements `Map` but not `Iterable`, `e` is a map literal.
      if (isMap && !isIterable) {
        return _LiteralResolution(
          _LiteralResolutionKind.map,
          unwrappedContextType,
        );
      }
    }

    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return the resolution that is indicated by the given [arguments].
  _LiteralResolution _fromTypeArguments(List<TypeAnnotation>? arguments) {
    if (arguments != null) {
      if (arguments.length == 1) {
        return _LiteralResolution(_LiteralResolutionKind.set,
            _typeProvider.setType(arguments[0].typeOrThrow));
      } else if (arguments.length == 2) {
        return _LiteralResolution(
            _LiteralResolutionKind.map,
            _typeProvider.mapType(
                arguments[0].typeOrThrow, arguments[1].typeOrThrow));
      }
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  List<CollectionElement> _getListElements(ListLiteral node) =>
      _migratableAstInfoProvider.getListElements(node);

  List<CollectionElement> _getSetOrMapElements(SetOrMapLiteral node) =>
      _migratableAstInfoProvider.getSetOrMapElements(node);

  _InferredCollectionElementTypeInformation _inferCollectionElementType(
      CollectionElement? element) {
    if (element is Expression) {
      return _InferredCollectionElementTypeInformation(
          elementType: element.typeOrThrow, keyType: null, valueType: null);
    } else if (element is ForElement) {
      return _inferCollectionElementType(element.body);
    } else if (element is IfElement) {
      _InferredCollectionElementTypeInformation thenType =
          _inferCollectionElementType(element.thenElement);
      if (element.elseElement == null) {
        return thenType;
      }
      _InferredCollectionElementTypeInformation elseType =
          _inferCollectionElementType(element.elseElement);
      return _InferredCollectionElementTypeInformation.forIfElement(
          _typeSystem, thenType, elseType);
    } else if (element is MapLiteralEntry) {
      return _InferredCollectionElementTypeInformation(
          elementType: null,
          keyType: element.key.staticType,
          valueType: element.value.staticType);
    } else if (element is SpreadElement) {
      var expressionType = element.expression.typeOrThrow;

      var iterableType = expressionType.asInstanceOf(
        _typeProvider.iterableElement,
      );
      if (iterableType != null) {
        return _InferredCollectionElementTypeInformation(
          elementType: iterableType.typeArguments[0],
          keyType: null,
          valueType: null,
        );
      }

      var mapType = expressionType.asInstanceOf(
        _typeProvider.mapElement,
      );
      if (mapType != null) {
        return _InferredCollectionElementTypeInformation(
          elementType: null,
          keyType: mapType.typeArguments[0],
          valueType: mapType.typeArguments[1],
        );
      }

      if (expressionType.isDynamic) {
        return _InferredCollectionElementTypeInformation(
          elementType: expressionType,
          keyType: expressionType,
          valueType: expressionType,
        );
      }

      if (_typeSystem.isNonNullableByDefault) {
        if (_typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
          return _InferredCollectionElementTypeInformation(
            elementType: NeverTypeImpl.instance,
            keyType: NeverTypeImpl.instance,
            valueType: NeverTypeImpl.instance,
          );
        }
        if (_typeSystem.isSubtypeOf(expressionType, _typeSystem.nullNone)) {
          if (element.isNullAware) {
            return _InferredCollectionElementTypeInformation(
              elementType: NeverTypeImpl.instance,
              keyType: NeverTypeImpl.instance,
              valueType: NeverTypeImpl.instance,
            );
          }
        }
      } else {
        if (expressionType.isDartCoreNull && element.isNullAware) {
          return _InferredCollectionElementTypeInformation(
            elementType: expressionType,
            keyType: expressionType,
            valueType: expressionType,
          );
        }
      }

      return _InferredCollectionElementTypeInformation(
        elementType: null,
        keyType: null,
        valueType: null,
      );
    } else {
      throw StateError('Unknown element type ${element.runtimeType}');
    }
  }

  InterfaceType? _inferListType(ListLiteral node, {bool downwards = false}) {
    var contextType = InferenceContext.getContext(node);

    var element = _typeProvider.listElement;
    var typeParameters = element.typeParameters;
    var genericElementType = typeParameters[0].instantiate(
      nullabilitySuffix: _noneOrStarSuffix,
    );

    List<DartType> elementTypes;
    List<ParameterElement> parameters;

    if (downwards) {
      if (contextType == null) {
        return null;
      }
      elementTypes = [];
      parameters = [];
    } else {
      // Also use upwards information to infer the type.
      elementTypes = _getListElements(node).map(_computeElementType).toList();
      var syntheticParameter = ParameterElementImpl.synthetic(
          'element', genericElementType, ParameterKind.POSITIONAL);
      parameters = List.filled(elementTypes.length, syntheticParameter);
    }
    if (_strictInference && parameters.isEmpty && contextType == null) {
      // We cannot infer the type of a collection literal with no elements, and
      // no context type. If there are any elements, inference has not failed,
      // as the types of those elements are considered resolved.
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL, node, ['List']);
    }

    var typeArguments = _typeSystem.inferGenericFunctionOrType(
      typeParameters: typeParameters,
      parameters: parameters,
      declaredReturnType: element.thisType,
      argumentTypes: elementTypes,
      contextReturnType: contextType,
      downwards: downwards,
      isConst: node.isConst,
      errorReporter: _errorReporter,
      errorNode: node,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    )!;
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  InterfaceType? _inferMapTypeDownwards(
      SetOrMapLiteral node, DartType? contextType) {
    if (contextType == null) {
      return null;
    }

    var element = _typeProvider.mapElement;
    var typeArguments = _typeSystem.inferGenericFunctionOrType(
      typeParameters: element.typeParameters,
      parameters: const [],
      declaredReturnType: element.thisType,
      argumentTypes: const [],
      contextReturnType: contextType,
      downwards: true,
      isConst: node.isConst,
      errorReporter: _errorReporter,
      errorNode: node,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    )!;
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  DartType _inferSetOrMapLiteralType(SetOrMapLiteral literal) {
    var literalImpl = literal as SetOrMapLiteralImpl;
    var contextType = literalImpl.contextType;
    literalImpl.contextType = null; // Not needed anymore.
    List<CollectionElement> elements = _getSetOrMapElements(literal);
    List<_InferredCollectionElementTypeInformation> inferredTypes = [];
    bool canBeAMap = true;
    bool mustBeAMap = false;
    bool canBeASet = true;
    bool mustBeASet = false;
    for (CollectionElement element in elements) {
      _InferredCollectionElementTypeInformation inferredType =
          _inferCollectionElementType(element);
      inferredTypes.add(inferredType);
      canBeAMap = canBeAMap && inferredType.canBeMap;
      mustBeAMap = mustBeAMap || inferredType.mustBeMap;
      canBeASet = canBeASet && inferredType.canBeSet;
      mustBeASet = mustBeASet || inferredType.mustBeSet;
    }
    if (canBeASet && mustBeASet) {
      return _toSetType(literal, contextType, inferredTypes);
    } else if (canBeAMap && mustBeAMap) {
      return _toMapType(literal, contextType, inferredTypes);
    }

    // Note: according to the spec, the following computations should be based
    // on the greatest closure of the context type (unless the context type is
    // `_`).  In practice, we can just use the context type directly, because
    // the only way the greatest closure of the context type could possibly have
    // a different subtype relationship to `Iterable<Object>` and
    // `Map<Object, Object>` is if the context type is `_`.
    if (contextType != null) {
      var contextIterableType = contextType.asInstanceOf(
        _typeProvider.iterableElement,
      );
      var contextMapType = contextType.asInstanceOf(
        _typeProvider.mapElement,
      );
      var contextIsIterable = contextIterableType != null;
      var contextIsMap = contextMapType != null;

      // When `S` implements `Iterable` but not `Map`, `e` is a set literal.
      if (contextIsIterable && !contextIsMap) {
        return _toSetType(literal, contextType, inferredTypes);
      }

      // When `S` implements `Map` but not `Iterable`, `e` is a map literal.
      if (contextIsMap && !contextIsIterable) {
        return _toMapType(literal, contextType, inferredTypes);
      }
    }

    // When `e` is of the form `{}` and `S` is undefined, `e` is a map literal.
    if (elements.isEmpty && contextType == null) {
      return _typeProvider.mapType(
        DynamicTypeImpl.instance,
        DynamicTypeImpl.instance,
      );
    }

    // Ambiguous.  We're not going to get any more information to resolve the
    // ambiguity.  We don't want to make an arbitrary decision at this point
    // because it will interfere with future type inference (see
    // dartbug.com/36210), so we return a type of `dynamic`.
    if (mustBeAMap && mustBeASet) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, literal);
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, literal);
    }
    return _typeProvider.dynamicType;
  }

  InterfaceType? _inferSetTypeDownwards(
      SetOrMapLiteral node, DartType? contextType) {
    if (contextType == null) {
      return null;
    }

    var element = _typeProvider.setElement;
    var typeArguments = _typeSystem.inferGenericFunctionOrType(
      typeParameters: element.typeParameters,
      parameters: const [],
      declaredReturnType: element.thisType,
      argumentTypes: const [],
      contextReturnType: contextType,
      downwards: true,
      isConst: node.isConst,
      errorReporter: _errorReporter,
      errorNode: node,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    )!;
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  void _insertImplicitCallReference(CollectionElement? node) {
    if (node is Expression) {
      _resolver.insertImplicitCallReference(node);
    } else if (node is MapLiteralEntry) {
      _insertImplicitCallReference(node.key);
      _insertImplicitCallReference(node.value);
    } else if (node is IfElement) {
      _insertImplicitCallReference(node.thenElement);
      _insertImplicitCallReference(node.elseElement);
    } else if (node is ForElement) {
      _insertImplicitCallReference(node.body);
    }
    // Nothing to do for [SpreadElement] as analyzer does not desugar this
    // element.
  }

  void _insertImplicitCallReferences(TypedLiteral node) {
    if (node is ListLiteral) {
      for (var element in node.elements) {
        _insertImplicitCallReference(element);
      }
    } else if (node is SetOrMapLiteral) {
      for (var element in node.elements) {
        _insertImplicitCallReference(element);
      }
    }
  }

  void _pushCollectionTypesDown(CollectionElement? element,
      {DartType? elementType,
      required DartType iterableType,
      DartType? keyType,
      DartType? valueType}) {
    if (element is Expression) {
      InferenceContext.setType(element, elementType);
    } else if (element is ForElement) {
      _pushCollectionTypesDown(element.body,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is IfElement) {
      _pushCollectionTypesDown(element.thenElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
      _pushCollectionTypesDown(element.elseElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is MapLiteralEntry) {
      InferenceContext.setType(element.key, keyType);
      InferenceContext.setType(element.value, valueType);
    } else if (element is SpreadElement) {
      if (_isNonNullableByDefault && element.isNullAware) {
        iterableType = _typeSystem.makeNullable(iterableType);
      }
      InferenceContext.setType(element.expression, iterableType);
    }
  }

  void _pushCollectionTypesDownToAll(List<CollectionElement> elements,
      {DartType? elementType,
      required DartType iterableType,
      DartType? keyType,
      DartType? valueType}) {
    for (CollectionElement element in elements) {
      _pushCollectionTypesDown(element,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    }
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) Inline this.
  void _recordStaticType(ExpressionImpl expression, DartType type) {
    expression.staticType = type;
//    if (type == null) {
//      expression.staticType = _dynamicType;
//    } else {
//      expression.staticType = type;
//      if (identical(type, NeverTypeImpl.instance)) {
//        _flowAnalysis?.flow?.handleExit();
//      }
//    }
  }

  void _resolveListLiteral2(ListLiteralImpl node) {
    var typeArguments = node.typeArguments?.arguments;

    // If we have explicit arguments, use them.
    if (typeArguments != null) {
      DartType elementType = _dynamicType;
      if (typeArguments.length == 1) {
        elementType = typeArguments[0].typeOrThrow;
      }
      _recordStaticType(
        node,
        _typeProvider.listElement.instantiate(
          typeArguments: [elementType],
          nullabilitySuffix: _noneOrStarSuffix,
        ),
      );
      return;
    }

    DartType listDynamicType = _typeProvider.listType(_dynamicType);

    // If there are no type arguments, try to infer some arguments.
    var inferred = _inferListType(node);

    if (inferred != listDynamicType) {
      // TODO(brianwilkerson) Determine whether we need to make the inferred
      //  type non-nullable here or whether it will already be non-nullable.
      _recordStaticType(node, inferred!);
      return;
    }

    // If we have no type arguments and couldn't infer any, use dynamic.
    _recordStaticType(node, listDynamicType);
  }

  void _resolveSetOrMapLiteral2(SetOrMapLiteralImpl node) {
    var typeArguments = node.typeArguments?.arguments;

    // If we have type arguments, use them.
    // TODO(paulberry): this logic seems redundant with
    //  ResolverVisitor._fromTypeArguments
    if (typeArguments != null) {
      if (typeArguments.length == 1) {
        node.becomeSet();
        var elementType = typeArguments[0].typeOrThrow;
        _recordStaticType(
          node,
          _typeProvider.setElement.instantiate(
            typeArguments: [elementType],
            nullabilitySuffix: _noneOrStarSuffix,
          ),
        );
        return;
      } else if (typeArguments.length == 2) {
        node.becomeMap();
        var keyType = typeArguments[0].typeOrThrow;
        var valueType = typeArguments[1].typeOrThrow;
        _recordStaticType(
          node,
          _typeProvider.mapElement.instantiate(
            typeArguments: [keyType, valueType],
            nullabilitySuffix: _noneOrStarSuffix,
          ),
        );
        return;
      }
      // If we get here, then a nonsense number of type arguments were provided,
      // so treat it as though no type arguments were provided.
    }
    DartType literalType = _inferSetOrMapLiteralType(node);
    if (literalType.isDynamic) {
      // The literal is ambiguous, and further analysis won't resolve the
      // ambiguity.  Leave it as neither a set nor a map.
    } else if (literalType.element == _typeProvider.mapElement) {
      node.becomeMap();
    } else {
      assert(literalType.element == _typeProvider.setElement);
      node.becomeSet();
    }
    if (_strictInference &&
        _getSetOrMapElements(node).isEmpty &&
        InferenceContext.getContext(node) == null) {
      // We cannot infer the type of a collection literal with no elements, and
      // no context type. If there are any elements, inference has not failed,
      // as the types of those elements are considered resolved.
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL,
          node,
          [node.isMap ? 'Map' : 'Set']);
    }
    // TODO(brianwilkerson) Decide whether the literalType needs to be made
    //  non-nullable here or whether that will have happened in
    //  _inferSetOrMapLiteralType.
    _recordStaticType(node, literalType);
  }

  DartType _toMapType(SetOrMapLiteral node, DartType? contextType,
      List<_InferredCollectionElementTypeInformation> inferredTypes) {
    DartType dynamicType = _typeProvider.dynamicType;

    var element = _typeProvider.mapElement;
    var typeParameters = element.typeParameters;
    var genericKeyType = typeParameters[0].instantiate(
      nullabilitySuffix: _noneOrStarSuffix,
    );
    var genericValueType = typeParameters[1].instantiate(
      nullabilitySuffix: _noneOrStarSuffix,
    );

    var parameters = <ParameterElement>[];
    var argumentTypes = <DartType>[];
    for (var i = 0; i < inferredTypes.length; i++) {
      parameters.add(ParameterElementImpl.synthetic(
          'key', genericKeyType, ParameterKind.POSITIONAL));
      parameters.add(ParameterElementImpl.synthetic(
          'value', genericValueType, ParameterKind.POSITIONAL));
      argumentTypes.add(inferredTypes[i].keyType ?? dynamicType);
      argumentTypes.add(inferredTypes[i].valueType ?? dynamicType);
    }

    var typeArguments = _typeSystem.inferGenericFunctionOrType(
      typeParameters: typeParameters,
      parameters: parameters,
      declaredReturnType: element.thisType,
      argumentTypes: argumentTypes,
      contextReturnType: contextType,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    )!;
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  DartType _toSetType(SetOrMapLiteral node, DartType? contextType,
      List<_InferredCollectionElementTypeInformation> inferredTypes) {
    DartType dynamicType = _typeProvider.dynamicType;

    var element = _typeProvider.setElement;
    var typeParameters = element.typeParameters;
    var genericElementType = typeParameters[0].instantiate(
      nullabilitySuffix: _noneOrStarSuffix,
    );

    var parameters = <ParameterElement>[];
    var argumentTypes = <DartType>[];
    for (var i = 0; i < inferredTypes.length; i++) {
      parameters.add(ParameterElementImpl.synthetic(
          'element', genericElementType, ParameterKind.POSITIONAL));
      argumentTypes.add(inferredTypes[i].elementType ?? dynamicType);
    }

    var typeArguments = _typeSystem.inferGenericFunctionOrType(
      typeParameters: typeParameters,
      parameters: parameters,
      declaredReturnType: element.thisType,
      argumentTypes: argumentTypes,
      contextReturnType: contextType,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    )!;
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }
}

class _InferredCollectionElementTypeInformation {
  final DartType? elementType;
  final DartType? keyType;
  final DartType? valueType;

  _InferredCollectionElementTypeInformation(
      {this.elementType, this.keyType, this.valueType});

  factory _InferredCollectionElementTypeInformation.forIfElement(
      TypeSystemImpl typeSystem,
      _InferredCollectionElementTypeInformation thenInfo,
      _InferredCollectionElementTypeInformation elseInfo) {
    if (thenInfo.isDynamic) {
      var dynamic = thenInfo.elementType!;
      return _InferredCollectionElementTypeInformation(
          elementType: _dynamicOrNull(elseInfo.elementType, dynamic),
          keyType: _dynamicOrNull(elseInfo.keyType, dynamic),
          valueType: _dynamicOrNull(elseInfo.valueType, dynamic));
    } else if (elseInfo.isDynamic) {
      DartType dynamic = elseInfo.elementType!;
      return _InferredCollectionElementTypeInformation(
          elementType: _dynamicOrNull(thenInfo.elementType, dynamic),
          keyType: _dynamicOrNull(thenInfo.keyType, dynamic),
          valueType: _dynamicOrNull(thenInfo.valueType, dynamic));
    }
    return _InferredCollectionElementTypeInformation(
        elementType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.elementType, elseInfo.elementType),
        keyType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.keyType, elseInfo.keyType),
        valueType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.valueType, elseInfo.valueType));
  }

  bool get canBeMap => keyType != null || valueType != null;

  bool get canBeSet => elementType != null;

  bool get isDynamic =>
      elementType != null &&
      elementType!.isDynamic &&
      keyType != null &&
      keyType!.isDynamic &&
      valueType != null &&
      valueType!.isDynamic;

  bool get mustBeMap => canBeMap && elementType == null;

  bool get mustBeSet => canBeSet && keyType == null && valueType == null;

  @override
  String toString() {
    return '($elementType, $keyType, $valueType)';
  }

  static DartType? _dynamicOrNull(DartType? type, DartType dynamic) {
    if (type == null) {
      return null;
    }
    return dynamic;
  }

  static DartType? _leastUpperBoundOfTypes(
      TypeSystemImpl typeSystem, DartType? first, DartType? second) {
    if (first == null) {
      return second;
    } else if (second == null) {
      return first;
    } else {
      return typeSystem.getLeastUpperBound(first, second);
    }
  }
}

/// A set of counts of the kinds of leaf elements in a collection, used to help
/// disambiguate map and set literals.
class _LeafElements {
  /// The number of expressions found in the collection.
  int expressionCount = 0;

  /// The number of map entries found in the collection.
  int mapEntryCount = 0;

  /// Initialize a newly created set of counts based on the given collection
  /// [elements].
  _LeafElements(List<CollectionElement> elements) {
    for (CollectionElement element in elements) {
      _count(element);
    }
  }

  /// Return the resolution suggested by the set elements.
  _LiteralResolution get resolution {
    if (expressionCount > 0 && mapEntryCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.set, null);
    } else if (mapEntryCount > 0 && expressionCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.map, null);
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Recursively add the given collection [element] to the counts.
  void _count(CollectionElement? element) {
    if (element is Expression) {
      if (_isComplete(element)) {
        expressionCount++;
      }
    } else if (element is ForElement) {
      _count(element.body);
    } else if (element is IfElement) {
      _count(element.thenElement);
      _count(element.elseElement);
    } else if (element is MapLiteralEntry) {
      if (_isComplete(element)) {
        mapEntryCount++;
      }
    }
  }

  /// Return `true` if the given collection [element] does not contain any
  /// synthetic tokens.
  bool _isComplete(CollectionElement element) {
    // TODO(paulberry,brianwilkerson): the code below doesn't work because it
    // assumes access to token offsets, which aren't available when working with
    // expressions resynthesized from summaries.  For now we just assume the
    // collection element is complete.
    return true;
//    Token token = element.beginToken;
//    int endOffset = element.endToken.offset;
//    while (token != null && token.offset <= endOffset) {
//      if (token.isSynthetic) {
//        return false;
//      }
//      token = token.next;
//    }
//    return true;
  }
}

/// An indication of the way in which a set or map literal should be resolved to
/// be either a set literal or a map literal.
class _LiteralResolution {
  /// The kind of collection that the literal should be.
  final _LiteralResolutionKind kind;

  /// The type that should be used as the inference context when performing type
  /// inference for the literal.
  DartType? contextType;

  /// Initialize a newly created resolution.
  _LiteralResolution(this.kind, this.contextType);

  @override
  String toString() {
    return '$kind ($contextType)';
  }
}

/// The kind of literal to which an unknown literal should be resolved.
enum _LiteralResolutionKind { ambiguous, map, set }
