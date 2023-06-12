// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for verifying expression that should be of type bool.
class BoolExpressionVerifier {
  final ResolverVisitor _resolver;
  final ErrorReporter _errorReporter;
  final NullableDereferenceVerifier _nullableDereferenceVerifier;

  final InterfaceType _boolType;

  BoolExpressionVerifier({
    required ResolverVisitor resolver,
    required ErrorReporter errorReporter,
    required NullableDereferenceVerifier nullableDereferenceVerifier,
  })  : _resolver = resolver,
        _errorReporter = errorReporter,
        _nullableDereferenceVerifier = nullableDereferenceVerifier,
        _boolType = resolver.typeSystem.typeProvider.boolType;

  /// Check to ensure that the [condition] is of type bool, are. Otherwise an
  /// error is reported on the expression.
  ///
  /// See [CompileTimeErrorCode.NON_BOOL_CONDITION].
  void checkForNonBoolCondition(Expression condition,
      {required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    checkForNonBoolExpression(
      condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_CONDITION,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Verify that the given [expression] is of type 'bool', and report
  /// [errorCode] if not, or a nullability error if its improperly nullable.
  void checkForNonBoolExpression(Expression expression,
      {required ErrorCode errorCode,
      List<Object>? arguments,
      required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    var type = expression.typeOrThrow;
    if (!_checkForUseOfVoidResult(expression) &&
        !_resolver.typeSystem.isAssignableTo(type, _boolType)) {
      if (type.isDartCoreBool) {
        _nullableDereferenceVerifier.report(
            CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION,
            expression,
            type,
            messages: _resolver.computeWhyNotPromotedMessages(
                expression, whyNotPromoted?.call()));
      } else {
        _errorReporter.reportErrorForNode(errorCode, expression, arguments);
      }
    } else if (!_resolver.definingLibrary.isNonNullableByDefault) {
      if (expression is InstanceCreationExpression) {
        // In pre-null safety code, an implicit cast from a supertype is allowed
        // unless the expression is an explicit instance creation expression,
        // with the idea that the cast would likely fail at runtime.
        var constructor = expression.constructorName.staticElement;
        if (constructor == null || !constructor.isFactory) {
          _errorReporter.reportErrorForNode(errorCode, expression, arguments);
          return;
        }
      }
    }
  }

  /// Checks to ensure that the given [expression] is assignable to bool.
  void checkForNonBoolNegationExpression(Expression expression,
      {required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    checkForNonBoolExpression(
      expression,
      errorCode: CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  // TODO(scheglov) Move this in a separate verifier.
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression,
      );
    }

    return true;
  }
}
