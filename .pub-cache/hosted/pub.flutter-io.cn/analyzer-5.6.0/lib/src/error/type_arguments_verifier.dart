// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;

class TypeArgumentsVerifier {
  final AnalysisOptionsImpl _options;
  final LibraryElement _libraryElement;
  final ErrorReporter _errorReporter;

  TypeArgumentsVerifier(
    this._options,
    this._libraryElement,
    this._errorReporter,
  );

  TypeSystemImpl get _typeSystem =>
      _libraryElement.typeSystem as TypeSystemImpl;

  void checkConstructorReference(ConstructorReference node) {
    var classElement = node.constructorName.type.name.staticElement;
    List<TypeParameterElement> typeParameters;
    if (classElement is TypeAliasElement) {
      typeParameters = classElement.typeParameters;
    } else if (classElement is InterfaceElement) {
      typeParameters = classElement.typeParameters;
    } else {
      return;
    }

    if (typeParameters.isEmpty) {
      return;
    }
    var typeArgumentList = node.constructorName.type.typeArguments;
    if (typeArgumentList == null) {
      return;
    }
    var constructorType = node.staticType;
    if (constructorType is DynamicType) {
      // An erroneous constructor reference.
      return;
    }
    if (constructorType is! FunctionType) {
      return;
    }
    var typeArguments = [
      for (var type in typeArgumentList.arguments) type.type!,
    ];
    if (typeArguments.length != typeParameters.length) {
      // Wrong number of type arguments to be reported elsewhere.
      return;
    }
    var typeArgumentListLength = typeArgumentList.arguments.length;
    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = _libraryElement.toLegacyTypeIfOptOut(bound);
      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        var errorNode =
            i < typeArgumentListLength ? typeArgumentList.arguments[i] : node;
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
          errorNode,
          [typeArgument, typeParameter.name, bound],
        );
      }
    }
  }

  void checkEnumConstantDeclaration(EnumConstantDeclaration node) {
    var constructorElement = node.constructorElement;
    if (constructorElement == null) {
      return;
    }

    var enumElement = constructorElement.enclosingElement;
    var typeParameters = enumElement.typeParameters;

    var typeArgumentList = node.arguments?.typeArguments;
    var typeArgumentNodes = typeArgumentList?.arguments;
    if (typeArgumentList != null &&
        typeArgumentNodes != null &&
        typeArgumentNodes.length != typeParameters.length) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM,
        typeArgumentList,
        [typeParameters.length, typeArgumentNodes.length],
      );
    }

    if (typeParameters.isEmpty) {
      return;
    }

    // Check that type arguments are regular-bounded.
    var typeArguments = constructorElement.returnType.typeArguments;
    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        final errorTarget = typeArgumentNodes?[i] ?? node.name;
        _errorReporter.reportErrorForOffset(
          CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
          errorTarget.offset,
          errorTarget.length,
          [typeArgument, typeParameter.name, bound],
        );
      }
    }
  }

  void checkFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      node.function.staticType,
      node.staticInvokeType,
    );
    _checkForImplicitDynamicInvoke(node);
  }

  void checkFunctionReference(FunctionReference node) {
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      node.function.staticType,
      node.staticType,
    );
  }

  void checkListLiteral(ListLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST,
        );
      }
      _checkTypeArgumentCount(typeArguments, 1,
          CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void checkMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP,
        );
      }
      _checkTypeArgumentCount(typeArguments, 2,
          CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void checkMethodInvocation(MethodInvocation node) {
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      node.function.staticType,
      node.staticInvokeType,
    );
    _checkForImplicitDynamicInvoke(node);
  }

  void checkNamedType(NamedType node) {
    _checkForTypeArgumentNotMatchingBounds(node);
    var parent = node.parent;
    if (parent is! ConstructorName ||
        parent.parent is! InstanceCreationExpression) {
      _checkForRawTypeName(node);
    }
  }

  void checkSetLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET,
        );
      }
      _checkTypeArgumentCount(typeArguments, 1,
          CompileTimeErrorCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void _checkForImplicitDynamicInvoke(InvocationExpression node) {
    if (_options.implicitDynamic || node.typeArguments != null) {
      return;
    }
    var invokeType = node.staticInvokeType;
    var declaredType = node.function.staticType;
    if (invokeType is FunctionType &&
        declaredType is FunctionType &&
        declaredType.typeFormals.isNotEmpty) {
      List<DartType> typeArgs = node.typeArgumentTypes!;
      if (typeArgs.any((t) => t.isDynamic)) {
        // Issue an error depending on what we're trying to call.
        Expression function = node.function;
        if (function is Identifier) {
          var element = function.staticElement;
          if (element is MethodElement) {
            _errorReporter.reportErrorForNode(
                LanguageCode.IMPLICIT_DYNAMIC_METHOD,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }

          if (element is FunctionElement) {
            _errorReporter.reportErrorForNode(
                LanguageCode.IMPLICIT_DYNAMIC_FUNCTION,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }
        }

        // The catch all case if neither of those matched.
        // For example, invoking a function expression.
        _errorReporter.reportErrorForNode(LanguageCode.IMPLICIT_DYNAMIC_INVOKE,
            node.function, [declaredType]);
      }
    }
  }

  void _checkForImplicitDynamicTypedLiteral(TypedLiteral node) {
    if (_options.implicitDynamic || node.typeArguments != null) {
      return;
    }
    DartType type = node.typeOrThrow;
    // It's an error if either the key or value was inferred as dynamic.
    if (type is InterfaceType && type.typeArguments.any((t) => t.isDynamic)) {
      // TODO(brianwilkerson) Add StrongModeCode.IMPLICIT_DYNAMIC_SET_LITERAL
      ErrorCode errorCode = node is ListLiteral
          ? LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL
          : LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL;
      _errorReporter.reportErrorForNode(errorCode, node);
    }
  }

  /// Checks a type annotation for a raw generic type, and reports the
  /// appropriate error if [AnalysisOptionsImpl.strictRawTypes] is set.
  ///
  /// This checks if [node] refers to a generic type and does not have explicit
  /// or inferred type arguments. When that happens, it reports error code
  /// [HintCode.STRICT_RAW_TYPE].
  void _checkForRawTypeName(NamedType node) {
    AstNode parentEscapingTypeArguments(NamedType node) {
      var parent = node.parent!;
      while (parent is TypeArgumentList || parent is NamedType) {
        if (parent.parent == null) {
          return parent;
        }
        parent = parent.parent!;
      }
      return parent;
    }

    if (!_options.strictRawTypes) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    var type = node.typeOrThrow;
    if (_isMissingTypeArguments(node, type, node.name.staticElement)) {
      AstNode unwrappedParent = parentEscapingTypeArguments(node);
      if (unwrappedParent is AsExpression || unwrappedParent is IsExpression) {
        // Do not report a "Strict raw type" error in this case; too noisy.
        // See https://github.com/dart-lang/language/blob/master/resources/type-system/strict-raw-types.md#conditions-for-a-raw-type-hint
      } else {
        _errorReporter
            .reportErrorForNode(HintCode.STRICT_RAW_TYPE, node, [type]);
      }
    }
  }

  /// Verify that the type arguments in the given [namedType] are all within
  /// their bounds.
  void _checkForTypeArgumentNotMatchingBounds(NamedType namedType) {
    final type = namedType.type;
    if (type == null) {
      return;
    }

    final List<TypeParameterElement> typeParameters;
    final String elementName;
    final List<DartType> typeArguments;
    final alias = type.alias;
    if (alias != null) {
      elementName = alias.element.name;
      typeParameters = alias.element.typeParameters;
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceType) {
      elementName = type.element.name;
      typeParameters = type.element.typeParameters;
      typeArguments = type.typeArguments;
    } else {
      return;
    }

    if (typeParameters.isEmpty) {
      return;
    }

    // Check for regular-bounded.
    List<_TypeArgumentIssue>? issues;
    final substitution = Substitution.fromPairs(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      if (typeArgument is FunctionType && typeArgument.typeFormals.isNotEmpty) {
        if (!_libraryElement.featureSet.isEnabled(Feature.generic_metadata)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
            _typeArgumentErrorNode(namedType, i),
          );
          continue;
        }
      }

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = _libraryElement.toLegacyTypeIfOptOut(bound);
      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        issues ??= <_TypeArgumentIssue>[];
        issues.add(
          _TypeArgumentIssue(i, typeParameter, bound, typeArgument),
        );
      }
    }

    // If regular-bounded, we are done.
    if (issues == null) {
      return;
    }

    List<DiagnosticMessage>? buildContextMessages({
      List<DartType>? invertedTypeArguments,
    }) {
      final messages = <DiagnosticMessage>[];

      void addMessage(String message) {
        messages.add(
          DiagnosticMessageImpl(
            filePath: _errorReporter.source.fullName,
            length: namedType.length,
            message: message,
            offset: namedType.offset,
            url: null,
          ),
        );
      }

      String typeArgumentsToString(List<DartType> typeArguments) {
        return typeArguments
            .map((e) => e.getDisplayString(withNullability: true))
            .join(', ');
      }

      if (namedType.typeArguments == null) {
        var typeStr = '$elementName<${typeArgumentsToString(typeArguments)}>';
        addMessage(
          "The raw type was instantiated as '$typeStr', "
          "and is not regular-bounded.",
        );
      }

      if (invertedTypeArguments != null) {
        var invertedTypeStr =
            '$elementName<${typeArgumentsToString(invertedTypeArguments)}>';
        addMessage(
          "The inverted type '$invertedTypeStr' is also not regular-bounded, "
          "so the type is not well-bounded.",
        );
      }

      return messages.isNotEmpty ? messages : null;
    }

    // If not allowed to be super-bounded, report issues.
    if (!_shouldAllowSuperBoundedTypes(namedType)) {
      for (var issue in issues) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
          _typeArgumentErrorNode(namedType, issue.index),
          [issue.argument, issue.parameter.name, issue.parameterBound],
          buildContextMessages(),
        );
      }
      return;
    }

    // Prepare type arguments for checking for super-bounded.
    final invertedType = _typeSystem.replaceTopAndBottom(type);
    final List<DartType> invertedTypeArguments;
    final invertedAlias = invertedType.alias;
    if (invertedAlias != null) {
      invertedTypeArguments = invertedAlias.typeArguments;
    } else if (invertedType is InterfaceType) {
      invertedTypeArguments = invertedType.typeArguments;
    } else {
      return;
    }

    // Check for super-bounded.
    final invertedSubstitution = Substitution.fromPairs(
      typeParameters,
      invertedTypeArguments,
    );
    for (var i = 0; i < invertedTypeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = invertedTypeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = _libraryElement.toLegacyTypeIfOptOut(bound);
      bound = invertedSubstitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
          _typeArgumentErrorNode(namedType, i),
          [typeArgument, typeParameter.name, bound],
          buildContextMessages(
            invertedTypeArguments: invertedTypeArguments,
          ),
        );
      }
    }
  }

  /// Verify that each type argument in [typeArgumentList] is within its bounds,
  /// as defined by [genericType].
  void _checkInvocationTypeArguments(
    List<TypeAnnotation>? typeArgumentList,
    DartType? genericType,
    DartType? instantiatedType,
  ) {
    if (typeArgumentList == null) {
      return;
    }

    if (genericType is! FunctionType || instantiatedType is! FunctionType) {
      return;
    }

    var fnTypeParams = genericType.typeFormals;
    var typeArgs = typeArgumentList.map((t) => t.typeOrThrow).toList();

    // If the amount mismatches, clean up the lists to be substitutable. The
    // mismatch in size is reported elsewhere, but we must successfully
    // perform substitution to validate bounds on mismatched lists.
    var providedLength = math.min(typeArgs.length, fnTypeParams.length);
    fnTypeParams = fnTypeParams.sublist(0, providedLength);
    typeArgs = typeArgs.sublist(0, providedLength);

    for (int i = 0; i < providedLength; i++) {
      // Check the `extends` clause for the type parameter, if any.
      //
      // Also substitute to handle cases like this:
      //
      //     <TFrom, TTo extends TFrom>
      //     <TFrom, TTo extends Iterable<TFrom>>
      //     <T extends Cloneable<T>>
      //
      DartType argType = typeArgs[i];

      if (argType is FunctionType && argType.typeFormals.isNotEmpty) {
        if (!_libraryElement.featureSet.isEnabled(Feature.generic_metadata)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
            typeArgumentList[i],
          );
          continue;
        }
      }

      var fnTypeParam = fnTypeParams[i];
      var rawBound = fnTypeParam.bound;
      if (rawBound == null) {
        continue;
      }

      var substitution = Substitution.fromPairs(fnTypeParams, typeArgs);
      var bound = substitution.substituteType(rawBound);
      if (!_typeSystem.isSubtypeOf(argType, bound)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
            typeArgumentList[i],
            [argType, fnTypeParam.name, bound]);
      }
    }
  }

  /// Checks to ensure that the given list of type [arguments] does not have a
  /// type parameter as a type argument. The [errorCode] is either
  /// [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST] or
  /// [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP].
  void _checkTypeArgumentConst(
      NodeList<TypeAnnotation> arguments, ErrorCode errorCode) {
    for (TypeAnnotation type in arguments) {
      if (type is NamedType && type.type is TypeParameterType) {
        _errorReporter
            .reportErrorForNode(errorCode, type, [type.name.toSource()]);
      }
    }
  }

  /// Verify that the given list of [typeArguments] contains exactly the
  /// [expectedCount] of elements, reporting an error with the [errorCode]
  /// if not.
  void _checkTypeArgumentCount(
    TypeArgumentList typeArguments,
    int expectedCount,
    ErrorCode errorCode,
  ) {
    int actualCount = typeArguments.arguments.length;
    if (actualCount != expectedCount) {
      _errorReporter.reportErrorForNode(
        errorCode,
        typeArguments,
        [actualCount],
      );
    }
  }

  /// Given a [node] without type arguments that refers to [element], issues
  /// an error if [type] is a generic type, and the type arguments were not
  /// supplied from inference or a non-dynamic default instantiation.
  ///
  /// This function is used by other node-specific type checking functions, and
  /// should only be called when [node] has no explicit `typeArguments`.
  ///
  /// [inferenceContextNode] is the node that has the downwards context type,
  /// if any. For example an [InstanceCreationExpression].
  ///
  /// This function will return false if any of the following are true:
  ///
  /// - [inferenceContextNode] has an inference context type that does not
  ///   contain `_`
  /// - [type] does not have any `dynamic` type arguments.
  /// - the element is marked with `@optionalTypeArgs` from "package:meta".
  bool _isMissingTypeArguments(AstNode node, DartType type, Element? element) {
    List<DartType> typeArguments;
    var alias = type.alias;
    if (alias != null) {
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceType) {
      typeArguments = type.typeArguments;
    } else {
      return false;
    }

    // Check if this type has type arguments and at least one is dynamic.
    // If so, we may need to issue a strict-raw-types error.
    if (typeArguments.any((t) => t.isDynamic)) {
      if (element != null && element.hasOptionalTypeArgs) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Determines if the given [namedType] occurs in a context where
  /// super-bounded types are allowed.
  bool _shouldAllowSuperBoundedTypes(NamedType namedType) {
    var parent = namedType.parent;
    if (parent is ExtendsClause) return false;
    if (parent is OnClause) return false;
    if (parent is ClassTypeAlias) return false;
    if (parent is WithClause) return false;
    if (parent is ConstructorName) return false;
    if (parent is ImplementsClause) return false;
    if (parent is GenericTypeAlias) return false;
    return true;
  }

  /// Return the type arguments at [index] from [node], or the [node] itself.
  static TypeAnnotation _typeArgumentErrorNode(NamedType node, int index) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && index < typeArguments.length) {
      return typeArguments[index];
    }
    return node;
  }
}

class _TypeArgumentIssue {
  /// The index for type argument within the passed type arguments.
  final int index;

  /// The type parameter with the bound that was violated.
  final TypeParameterElement parameter;

  /// The substituted bound of the [parameter].
  final DartType parameterBound;

  /// The type argument that violated the [parameterBound].
  final DartType argument;

  _TypeArgumentIssue(
    this.index,
    this.parameter,
    this.parameterBound,
    this.argument,
  );

  @override
  String toString() {
    return 'TypeArgumentIssue(index=$index, parameter=$parameter, '
        'parameterBound=$parameterBound, argument=$argument)';
  }
}
