// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Verifies usages of `Future.value` and `Completer.complete` when null-safety
/// is enabled.
///
/// `Future.value` and `Completer.complete` both accept a `FutureOr<T>?` as an
/// optional argument but throw an exception when `T` is non-nullable and `null`
/// is passed as an argument.
///
/// This verifier detects and reports those scenarios.
class NullSafeApiVerifier {
  final ErrorReporter _errorReporter;
  final TypeSystemImpl _typeSystem;

  NullSafeApiVerifier(this._errorReporter, this._typeSystem);

  /// Reports an error if the expression creates a `Future<T>.value` with a non-
  /// nullable value `T` and an argument that is effectively `null`.
  void instanceCreation(InstanceCreationExpression expression) {
    if (!_typeSystem.isNonNullableByDefault) return;

    final constructor = expression.constructorName.staticElement;
    if (constructor == null) return;

    final type = constructor.returnType;
    final isFutureValue = type.isDartAsyncFuture && constructor.name == 'value';

    if (isFutureValue) {
      _checkTypes(expression, 'Future.value', type.typeArguments.single,
          expression.argumentList);
    }
  }

  /// Reports an error if `Completer<T>.complete` is invoked with a non-nullable
  /// `T` and an argument that is effectively `null`.
  void methodInvocation(MethodInvocation node) {
    if (!_typeSystem.isNonNullableByDefault) return;

    final targetType = node.realTarget?.staticType;
    if (targetType is! InterfaceType) return;

    final targetClass = targetType.element;

    if (targetClass.library.isDartAsync == true &&
        targetClass.name == 'Completer' &&
        node.methodName.name == 'complete') {
      _checkTypes(node, 'Completer.complete', targetType.typeArguments.single,
          node.argumentList);
    }
  }

  void _checkTypes(
      Expression node, String memberName, DartType type, ArgumentList args) {
    // If there's more than one argument, something else is wrong (and will
    // generate another diagnostic). Also, only check the argument type if we
    // expect a non-nullable type in the first place.
    if (args.arguments.length > 1 || !_typeSystem.isNonNullable(type)) return;

    final argument = args.arguments.isEmpty ? null : args.arguments.single;
    final argumentType = argument?.staticType;
    // Skip if the type is not currently resolved.
    if (argument != null && argumentType == null) return;

    final argumentIsNull =
        argument == null || _typeSystem.isNull(argumentType!);

    if (argumentIsNull) {
      _errorReporter.reportErrorForNode(
          WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE,
          argument ?? node,
          [memberName, type.getDisplayString(withNullability: true)]);
    }
  }
}
