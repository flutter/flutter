// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';

/// Verifier for [CollectionElement]s in list, set, or map literals.
class LiteralElementVerifier {
  final TypeProvider typeProvider;
  final TypeSystemImpl typeSystem;
  final ErrorReporter errorReporter;
  final FeatureSet featureSet;
  final ErrorVerifier _errorVerifier;

  final bool forList;
  final bool forSet;
  final DartType? elementType;

  final bool forMap;
  final DartType? mapKeyType;
  final DartType? mapValueType;

  LiteralElementVerifier(
    this.typeProvider,
    this.typeSystem,
    this.errorReporter,
    this._errorVerifier, {
    this.forList = false,
    this.forSet = false,
    this.elementType,
    this.forMap = false,
    this.mapKeyType,
    this.mapValueType,
    required this.featureSet,
  });

  void verify(CollectionElement element) {
    _verifyElement(element);
  }

  /// Check that the given [type] is assignable to the [elementType], otherwise
  /// report the list or set error on the [errorNode].
  void _checkAssignableToElementType(DartType type, AstNode errorNode) {
    var elementType = this.elementType;
    if (!typeSystem.isAssignableTo(type, elementType!)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.reportErrorForNode(
        errorCode,
        errorNode,
        [type, elementType],
      );
    }
  }

  /// Verify that the given [element] can be assigned to the [elementType] of
  /// the enclosing list, set, of map literal.
  void _verifyElement(CollectionElement? element) {
    if (element is Expression) {
      if (forList || forSet) {
        if (!elementType!.isVoid &&
            _errorVerifier.checkForUseOfVoidResult(element)) {
          return;
        }
        _checkAssignableToElementType(element.typeOrThrow, element);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.EXPRESSION_IN_MAP, element);
      }
    } else if (element is ForElement) {
      _verifyElement(element.body);
    } else if (element is IfElement) {
      _verifyElement(element.thenElement);
      _verifyElement(element.elseElement);
    } else if (element is MapLiteralEntry) {
      if (forMap) {
        _verifyMapLiteralEntry(element);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP, element);
      }
    } else if (element is SpreadElement) {
      var isNullAware = element.isNullAware;
      Expression expression = element.expression;
      if (forList || forSet) {
        _verifySpreadForListOrSet(isNullAware, expression);
      } else if (forMap) {
        _verifySpreadForMap(isNullAware, expression);
      }
    }
  }

  /// Verify that the [entry]'s key and value are assignable to [mapKeyType]
  /// and [mapValueType].
  void _verifyMapLiteralEntry(MapLiteralEntry entry) {
    var mapKeyType = this.mapKeyType;
    if (!mapKeyType!.isVoid &&
        _errorVerifier.checkForUseOfVoidResult(entry.key)) {
      return;
    }

    var mapValueType = this.mapValueType;
    if (!mapValueType!.isVoid &&
        _errorVerifier.checkForUseOfVoidResult(entry.value)) {
      return;
    }

    var keyType = entry.key.typeOrThrow;
    if (!typeSystem.isAssignableTo(keyType, mapKeyType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        entry.key,
        [keyType, mapKeyType],
      );
    }

    var valueType = entry.value.typeOrThrow;
    if (!typeSystem.isAssignableTo(valueType, mapValueType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        entry.value,
        [valueType, mapValueType],
      );
    }
  }

  /// Verify that the type of the elements of the given [expression] can be
  /// assigned to the [elementType] of the enclosing collection.
  void _verifySpreadForListOrSet(bool isNullAware, Expression expression) {
    var expressionType = expression.typeOrThrow;
    if (expressionType.isDynamic) {
      if (typeSystem.strictCasts) {
        return errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
          expression,
        );
      }
      return;
    }

    if (typeSystem.isNonNullableByDefault) {
      if (typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
        return;
      }
      if (typeSystem.isSubtypeOf(expressionType, typeSystem.nullNone)) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    } else {
      if (expressionType.isDartCoreNull) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    }

    var iterableType = expressionType.asInstanceOf(
      typeProvider.iterableElement,
    );

    if (iterableType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
        expression,
      );
    }

    var iterableElementType = iterableType.typeArguments[0];
    var elementType = this.elementType;
    if (!typeSystem.isAssignableTo(iterableElementType, elementType!)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      // Also check for an "implicit tear-off conversion" which would be applied
      // after desugaring a spread element.
      var implicitCallMethod = _errorVerifier.getImplicitCallMethod(
          iterableElementType, elementType, expression);
      if (implicitCallMethod == null) {
        errorReporter.reportErrorForNode(
          errorCode,
          expression,
          [iterableElementType, elementType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        if (featureSet.isEnabled(Feature.constructor_tearoffs)) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            elementType as FunctionType,
            tearoffType,
            errorReporter: errorReporter,
            errorNode: expression,
            genericMetadataIsEnabled: true,
          );
          if (typeArguments.isNotEmpty) {
            tearoffType = tearoffType.instantiate(typeArguments);
          }
        }

        if (!typeSystem.isAssignableTo(tearoffType, elementType)) {
          errorReporter.reportErrorForNode(
            errorCode,
            expression,
            [iterableElementType, elementType],
          );
        }
      }
    }
  }

  /// Verify that the [expression] is a subtype of `Map<Object, Object>`, and
  /// its key and values are assignable to [mapKeyType] and [mapValueType].
  void _verifySpreadForMap(bool isNullAware, Expression expression) {
    var expressionType = expression.typeOrThrow;
    if (expressionType.isDynamic) {
      if (typeSystem.strictCasts) {
        return errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_MAP_SPREAD,
          expression,
        );
      }
      return;
    }

    if (typeSystem.isNonNullableByDefault) {
      if (typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
        return;
      }
      if (typeSystem.isSubtypeOf(expressionType, typeSystem.nullNone)) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    } else {
      if (expressionType.isDartCoreNull) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    }

    var mapType = expressionType.asInstanceOf(
      typeProvider.mapElement,
    );

    if (mapType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_MAP_SPREAD,
        expression,
      );
    }

    var keyType = mapType.typeArguments[0];
    var mapKeyType = this.mapKeyType;
    if (!typeSystem.isAssignableTo(keyType, mapKeyType!)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        expression,
        [keyType, mapKeyType],
      );
    }

    var valueType = mapType.typeArguments[1];
    var mapValueType = this.mapValueType;
    if (!typeSystem.isAssignableTo(valueType, mapValueType!)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        expression,
        [valueType, mapValueType],
      );
    }
  }
}
