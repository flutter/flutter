// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/return_type_verifier.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:collection/collection.dart';

/// Reports on invalid functions passed as error handlers.
///
/// Functions must either accept exactly one positional parameter, or exactly
/// two positional parameters. The one parameter (or the first parameter) must
/// have a type of `dynamic`, `Object`, or `Object?`. If a second parameter is
/// accepted, it must have a type of `StackTrace`.
///
/// A function is checked if it is passed as:
/// * as the first argument to [Future.catchError],
/// * as the 'onError' named argument to [Future.then],
/// * as the first argument to [Stream.handleError],
/// * as the 'onError' named argument to [Future.onError],
/// * as the first argument to [StreamSubscription.onError],
///
/// Additionally, a function passed as the first argument to
/// [Future<T>.catchError] must return `FutureOr<T>`, and any return statements in a
/// function literal must return a value of type `FutureOr<T>`.
class ErrorHandlerVerifier {
  final ErrorReporter _errorReporter;

  final TypeProviderImpl _typeProvider;

  final TypeSystemImpl _typeSystem;

  final ReturnTypeVerifier _returnTypeVerifier;

  ErrorHandlerVerifier(
      this._errorReporter, this._typeProvider, this._typeSystem)
      : _returnTypeVerifier = ReturnTypeVerifier(
          typeProvider: _typeProvider,
          typeSystem: _typeSystem,
          errorReporter: _errorReporter,
        );

  void verifyMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    if (target == null) {
      return;
    }

    if (node.argumentList.arguments.isEmpty) {
      return;
    }

    var targetType = target.staticType;
    if (targetType == null) {
      return;
    }
    var methodName = node.methodName.name;
    if (methodName == 'catchError' && targetType.isDartAsyncFuture) {
      var callback = node.argumentList.arguments.first;
      if (callback is NamedExpression) {
        // This implies that no positional arguments are passed.
        return;
      }
      _checkFutureCatchErrorOnError(target, callback);
      return;
    }

    if (methodName == 'then' && targetType.isDartAsyncFuture) {
      var callback = node.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull(
              (argument) => argument.name.label.name == 'onError');
      if (callback == null) {
        return;
      }
      var callbackType = callback.staticType;
      if (callbackType == null) {
        return;
      }
      if (callbackType is FunctionType) {
        // TODO(srawlins): Also check return type of the 'onError' named
        // argument to [Future<T>.then].
        _checkErrorHandlerFunctionType(
            callback, callbackType, _typeProvider.voidType,
            checkFirstParameterType: callback.expression is FunctionExpression);
        return;
      }
      // [callbackType] might be dart:core's Function, or something not
      // assignable to Function, in which case an error is reported elsewhere.
    }

    if (methodName == 'handleError' &&
        _isDartCoreAsyncType(targetType, 'Stream')) {
      var callback = node.argumentList.arguments.first;
      if (callback is NamedExpression) {
        // This implies that no positional arguments are passed.
        return;
      }
      var callbackType = callback.staticType;
      if (callbackType == null) {
        return;
      }
      if (callbackType is FunctionType) {
        _checkErrorHandlerFunctionType(
            callback, callbackType, _typeProvider.voidType,
            checkFirstParameterType: callback is FunctionExpression);
        return;
      }
      // [callbackType] might be dart:core's Function, or something not
      // assignable to Function, in which case an error is reported elsewhere.
    }

    if (methodName == 'listen' && _isDartCoreAsyncType(targetType, 'Stream')) {
      var callback = node.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull(
              (argument) => argument.name.label.name == 'onError');
      if (callback == null) {
        return;
      }
      var callbackType = callback.staticType;
      if (callbackType == null) {
        return;
      }
      if (callbackType is FunctionType) {
        _checkErrorHandlerFunctionType(
            callback, callbackType, _typeProvider.voidType,
            checkFirstParameterType: callback.expression is FunctionExpression);
        return;
      }
      // [callbackType] might be dart:core's Function, or something not
      // assignable to Function, in which case an error is reported elsewhere.
    }

    if (methodName == 'onError' &&
        _isDartCoreAsyncType(targetType, 'StreamSubscription')) {
      var callback = node.argumentList.arguments.first;
      if (callback is NamedExpression) {
        // This implies that no positional arguments are passed.
        return;
      }
      var callbackType = callback.staticType;
      if (callbackType == null) {
        return;
      }
      if (callbackType is FunctionType) {
        _checkErrorHandlerFunctionType(
            callback, callbackType, _typeProvider.voidType,
            checkFirstParameterType: callback is FunctionExpression);
        return;
      }
      // [callbackType] might be dart:core's Function, or something not
      // assignable to Function, in which case an error is reported elsewhere.
    }
  }

  /// Checks that [expression], a function with static type [expressionType], is
  /// a valid error handler.
  ///
  /// Only checks the first parameter type if [checkFirstParameterType] is true.
  /// Certain error handlers are allowed to specify a different type for their
  /// first parameter.
  void _checkErrorHandlerFunctionType(Expression expression,
      FunctionType expressionType, DartType expectedFunctionReturnType,
      {bool checkFirstParameterType = true}) {
    void report() {
      _errorReporter.reportErrorForNode(
        HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER,
        expression,
        [expressionType, expectedFunctionReturnType],
      );
    }

    var parameters = expressionType.parameters;
    if (parameters.isEmpty) {
      return report();
    }
    var firstParameter = parameters.first;
    if (firstParameter.isNamed) {
      return report();
    } else if (checkFirstParameterType) {
      if (!_typeSystem.isSubtypeOf(
          _typeProvider.objectType, firstParameter.type)) {
        return report();
      }
    }
    if (parameters.length == 2) {
      var secondParameter = parameters[1];
      if (secondParameter.isNamed) {
        return report();
      } else {
        if (!_typeSystem.isSubtypeOf(
            _typeProvider.stackTraceType, secondParameter.type)) {
          return report();
        }
      }
    } else if (parameters.length > 2) {
      return report();
    }
  }

  /// Check the 'onError' argument given to [Future.catchError].
  void _checkFutureCatchErrorOnError(Expression target, Expression callback) {
    var targetType = target.staticType as InterfaceType;
    var targetFutureType = targetType.typeArguments.first;
    var expectedReturnType = _typeProvider.futureOrType(targetFutureType);
    if (callback is FunctionExpression) {
      // TODO(migration): should be FunctionType, not nullable
      var callbackType = callback.staticType as FunctionType;
      _checkErrorHandlerFunctionType(
          callback, callbackType, expectedReturnType);
      var catchErrorOnErrorExecutable = EnclosingExecutableContext(
          callback.declaredElement,
          isAsynchronous: true,
          catchErrorOnErrorReturnType: expectedReturnType);
      var returnStatementVerifier =
          _ReturnStatementVerifier(_returnTypeVerifier);
      _returnTypeVerifier.enclosingExecutable = catchErrorOnErrorExecutable;
      callback.body.accept(returnStatementVerifier);
    } else {
      var callbackType = callback.staticType;
      if (callbackType is FunctionType) {
        _checkReturnType(expectedReturnType, callbackType.returnType, callback);
        _checkErrorHandlerFunctionType(
            callback, callbackType, expectedReturnType);
      } else {
        // If [callback] is not even a Function, then ErrorVerifier will have
        // reported this.
      }
    }
  }

  void _checkReturnType(
      DartType expectedType, DartType functionReturnType, Expression callback) {
    if (!_typeSystem.isAssignableTo(functionReturnType, expectedType)) {
      _errorReporter.reportErrorForNode(
        HintCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR,
        callback,
        [functionReturnType, expectedType],
      );
    }
  }

  /// Returns whether [element] represents the []
  bool _isDartCoreAsyncType(DartType type, String typeName) =>
      type is InterfaceType &&
      type.element.name == typeName &&
      type.element.library.isDartAsync;
}

/// Visits a function body, looking for return statements.
class _ReturnStatementVerifier extends RecursiveAstVisitor<void> {
  final ReturnTypeVerifier _returnTypeVerifier;

  _ReturnStatementVerifier(this._returnTypeVerifier);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _returnTypeVerifier.verifyExpressionFunctionBody(node);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Do not visit within [node]. We have no interest in return statements
    // within.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _returnTypeVerifier.verifyReturnStatement(node);
    super.visitReturnStatement(node);
  }
}
