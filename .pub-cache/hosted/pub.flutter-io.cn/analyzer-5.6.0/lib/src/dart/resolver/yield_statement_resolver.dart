// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [YieldStatement]s.
class YieldStatementResolver {
  final ResolverVisitor _resolver;

  YieldStatementResolver({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(YieldStatement node) {
    var bodyContext = _resolver.inferenceContext.bodyContext;
    if (bodyContext != null && bodyContext.isGenerator) {
      _resolve_generator(bodyContext, node);
    } else {
      _resolve_notGenerator(node);
    }
  }

  /// Check for situations where the result of a method or function is used, when
  /// it returns 'void'. Or, in rare cases, when other types of expressions are
  /// void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.USE_OF_VOID_RESULT].
  ///
  /// TODO(scheglov) This is duplicate
  /// TODO(scheglov) Also in [BoolExpressionVerifier]
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression.methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression,
      );
    }

    return true;
  }

  /// Check for a type mis-match between the yielded type and the declared
  /// return type of a generator function.
  ///
  /// This method should only be called in generator functions.
  void _checkForYieldOfInvalidType(
    BodyInferenceContext bodyContext,
    YieldStatement node, {
    required bool isYieldEach,
  }) {
    var expression = node.expression;
    var expressionType = expression.typeOrThrow;

    DartType impliedReturnType;
    if (isYieldEach) {
      impliedReturnType = expressionType;
    } else if (bodyContext.isSynchronous) {
      impliedReturnType = _typeProvider.iterableType(expressionType);
    } else {
      impliedReturnType = _typeProvider.streamType(expressionType);
    }

    var imposedReturnType = bodyContext.imposedType;
    if (imposedReturnType != null &&
        !_typeSystem.isAssignableTo(impliedReturnType, imposedReturnType)) {
      if (isYieldEach) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE,
          expression,
          [impliedReturnType, imposedReturnType],
        );
        return;
      }
      var imposedSequenceType = imposedReturnType.asInstanceOf(
        bodyContext.isSynchronous
            ? _typeProvider.iterableElement
            : _typeProvider.streamElement,
      );
      if (imposedSequenceType != null) {
        var imposedValueType = imposedSequenceType.typeArguments[0];
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.YIELD_OF_INVALID_TYPE,
          expression,
          [expressionType, imposedValueType],
        );
      }
      return;
    }

    if (isYieldEach) {
      // Since the declared return type might have been "dynamic", we need to
      // also check that the implied return type is assignable to generic
      // Iterable/Stream.
      DartType requiredReturnType;
      if (bodyContext.isSynchronous) {
        requiredReturnType = _typeProvider.iterableDynamicType;
      } else {
        requiredReturnType = _typeProvider.streamDynamicType;
      }

      if (!_typeSystem.isAssignableTo(impliedReturnType, requiredReturnType)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE,
          expression,
          [impliedReturnType, requiredReturnType],
        );
      }
    }
  }

  DartType? _computeContextType(
    BodyInferenceContext bodyContext,
    YieldStatement node,
  ) {
    var elementType = bodyContext.contextType;
    if (elementType != null) {
      var contextType = elementType;
      if (node.star != null) {
        contextType = bodyContext.isSynchronous
            ? _typeProvider.iterableType(elementType)
            : _typeProvider.streamType(elementType);
      }
      return contextType;
    } else {
      return null;
    }
  }

  void _resolve_generator(
    BodyInferenceContext bodyContext,
    YieldStatement node,
  ) {
    _resolver.analyzeExpression(
        node.expression, _computeContextType(bodyContext, node));
    _resolver.popRewrite();

    if (node.star != null) {
      _resolver.nullableDereferenceVerifier.expression(
        CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH,
        node.expression,
      );
    }

    bodyContext.addYield(node);

    _checkForYieldOfInvalidType(bodyContext, node,
        isYieldEach: node.star != null);
    _checkForUseOfVoidResult(node.expression);
  }

  void _resolve_notGenerator(YieldStatement node) {
    node.expression.accept(_resolver);

    _errorReporter.reportErrorForNode(
      node.star != null
          ? CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR
          : CompileTimeErrorCode.YIELD_IN_NON_GENERATOR,
      node,
    );

    _checkForUseOfVoidResult(node.expression);
  }
}
