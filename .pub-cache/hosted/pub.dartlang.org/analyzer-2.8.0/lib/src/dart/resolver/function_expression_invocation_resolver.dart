// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [FunctionExpressionInvocation]s.
class FunctionExpressionInvocationResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  FunctionExpressionInvocationResolver({
    required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  NullableDereferenceVerifier get _nullableDereferenceVerifier =>
      _resolver.nullableDereferenceVerifier;

  void resolve(FunctionExpressionInvocationImpl node,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    var function = node.function;

    if (function is ExtensionOverrideImpl) {
      _resolveReceiverExtensionOverride(node, function, whyNotPromotedList);
      return;
    }

    var receiverType = function.typeOrThrow;
    if (receiverType is InterfaceType) {
      // Note: in this circumstance it's not necessary to call
      // `_nullableDereferenceVerifier.expression` because
      // `_resolveReceiverInterfaceType` calls `TypePropertyResolver.resolve`,
      // which does the necessary null checking.
      _resolveReceiverInterfaceType(
          node, function, receiverType, whyNotPromotedList);
      return;
    }

    if (_checkForUseOfVoidResult(function, receiverType)) {
      _unresolved(node, DynamicTypeImpl.instance, whyNotPromotedList);
      return;
    }

    _nullableDereferenceVerifier.expression(
      CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE,
      function,
    );

    if (receiverType is FunctionType) {
      _resolve(node, receiverType, whyNotPromotedList);
      return;
    }

    if (identical(receiverType, NeverTypeImpl.instance)) {
      _errorReporter.reportErrorForNode(
          HintCode.RECEIVER_OF_TYPE_NEVER, function);
      _unresolved(node, NeverTypeImpl.instance, whyNotPromotedList);
      return;
    }

    _unresolved(node, DynamicTypeImpl.instance, whyNotPromotedList);
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.USE_OF_VOID_RESULT].
  ///
  /// TODO(scheglov) this is duplicate
  bool _checkForUseOfVoidResult(Expression expression, DartType type) {
    if (!identical(type, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, methodName, []);
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, expression, []);
    }

    return true;
  }

  void _resolve(FunctionExpressionInvocationImpl node, FunctionType rawType,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    _inferenceHelper.resolveFunctionExpressionInvocation(
      node: node,
      rawType: rawType,
      whyNotPromotedList: whyNotPromotedList,
    );

    var returnType = _inferenceHelper.computeInvokeReturnType(
      node.staticInvokeType,
    );
    _inferenceHelper.recordStaticType(node, returnType);
  }

  void _resolveArguments(FunctionExpressionInvocationImpl node,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    _resolver.visitArgumentList(node.argumentList,
        whyNotPromotedList: whyNotPromotedList);
  }

  void _resolveReceiverExtensionOverride(
    FunctionExpressionInvocationImpl node,
    ExtensionOverride function,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    var result = _extensionResolver.getOverrideMember(
      function,
      FunctionElement.CALL_METHOD_NAME,
    );
    var callElement = result.getter;
    node.staticElement = callElement;

    if (callElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL,
        function,
        [function.extensionName.name],
      );
      return _unresolved(node, DynamicTypeImpl.instance, whyNotPromotedList);
    }

    if (callElement.isStatic) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        node.argumentList,
      );
    }

    var rawType = callElement.type;
    _resolve(node, rawType, whyNotPromotedList);
  }

  void _resolveReceiverInterfaceType(
    FunctionExpressionInvocationImpl node,
    Expression function,
    InterfaceType receiverType,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    var result = _typePropertyResolver.resolve(
      receiver: function,
      receiverType: receiverType,
      name: FunctionElement.CALL_METHOD_NAME,
      propertyErrorEntity: function,
      nameErrorEntity: function,
    );
    var callElement = result.getter;

    if (callElement == null) {
      if (result.needsGetterError) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
          function,
        );
      }
      _unresolved(node, DynamicTypeImpl.instance, whyNotPromotedList);
      return;
    }

    if (callElement.kind != ElementKind.METHOD) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
        function,
      );
      _unresolved(node, DynamicTypeImpl.instance, whyNotPromotedList);
      return;
    }

    node.staticElement = callElement;
    var rawType = callElement.type;
    _resolve(node, rawType, whyNotPromotedList);
  }

  void _unresolved(FunctionExpressionInvocationImpl node, DartType type,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    _setExplicitTypeArgumentTypes(node);
    _resolveArguments(node, whyNotPromotedList);
    node.staticInvokeType = DynamicTypeImpl.instance;
    node.staticType = type;
  }

  /// Inference cannot be done, we still want to fill type argument types.
  static void _setExplicitTypeArgumentTypes(
    FunctionExpressionInvocationImpl node,
  ) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      node.typeArgumentTypes = typeArguments.arguments
          .map((typeArgument) => typeArgument.typeOrThrow)
          .toList();
    } else {
      node.typeArgumentTypes = const <DartType>[];
    }
  }
}
