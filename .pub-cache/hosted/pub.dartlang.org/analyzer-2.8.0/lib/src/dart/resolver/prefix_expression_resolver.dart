// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [PrefixExpression]s.
class PrefixExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;
  final AssignmentExpressionShared _assignmentShared;

  PrefixExpressionResolver({
    required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper,
        _assignmentShared = AssignmentExpressionShared(
          resolver: resolver,
        );

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(PrefixExpressionImpl node) {
    var operator = node.operator.type;

    if (operator == TokenType.BANG) {
      _resolveNegation(node);
      return;
    }

    if (operator.isIncrementOperator) {
      var operandResolution = _resolver.resolveForWrite(
        node: node.operand,
        hasRead: true,
      );

      var readElement = operandResolution.readElement;
      var writeElement = operandResolution.writeElement;

      var operand = node.operand;
      _resolver.setReadElement(operand, readElement);
      _resolver.setWriteElement(operand, writeElement);
      _resolver.migrationResolutionHooks
          ?.setCompoundAssignmentExpressionTypes(node);

      _assignmentShared.checkFinalAlreadyAssigned(node.operand);
    } else {
      node.operand.accept(_resolver);
    }

    _resolve1(node);
    _resolve2(node);
  }

  /// Check that the result [type] of a prefix or postfix `++` or `--`
  /// expression is assignable to the write type of the operand.
  ///
  /// TODO(scheglov) this is duplicate
  void _checkForInvalidAssignmentIncDec(
      PrefixExpressionImpl node, DartType type) {
    var operandWriteType = node.writeType!;
    if (!_typeSystem.isAssignableTo(type, operandWriteType)) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ASSIGNMENT,
        node,
        [type, operandWriteType],
      );
    }
  }

  /// Compute the static return type of the method or function represented by the given element.
  ///
  /// @param element the element representing the method or function invoked by the given node
  /// @return the static return type that was computed
  ///
  /// TODO(scheglov) this is duplicate
  DartType _computeStaticReturnType(Element? element) {
    if (element is PropertyAccessorElement) {
      //
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      //
      var propertyType = element.type;
      return _resolver.inferenceHelper.computeInvokeReturnType(
        propertyType.returnType,
      );
    } else if (element is ExecutableElement) {
      return _resolver.inferenceHelper.computeInvokeReturnType(element.type);
    }
    return DynamicTypeImpl.instance;
  }

  /// Return the name of the method invoked by the given postfix [expression].
  String _getPrefixOperator(PrefixExpression expression) {
    var operator = expression.operator;
    var operatorType = operator.type;
    if (operatorType == TokenType.PLUS_PLUS) {
      return TokenType.PLUS.lexeme;
    } else if (operatorType == TokenType.MINUS_MINUS) {
      return TokenType.MINUS.lexeme;
    } else if (operatorType == TokenType.MINUS) {
      return "unary-";
    } else {
      return operator.lexeme;
    }
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplicate
  void _recordStaticType(ExpressionImpl expression, DartType type) {
    _inferenceHelper.recordStaticType(expression, type);
  }

  void _resolve1(PrefixExpressionImpl node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator ||
        operatorType.isIncrementOperator) {
      Expression operand = node.operand;
      String methodName = _getPrefixOperator(node);
      if (operand is ExtensionOverride) {
        var element = operand.extensionName.staticElement as ExtensionElement;
        var member = element.getMethod(methodName);
        if (member == null) {
          // Extension overrides always refer to named extensions, so we can
          // safely assume `element.name` is non-`null`.
          _errorReporter.reportErrorForToken(
              CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
              node.operator,
              [methodName, element.name!]);
        }
        node.staticElement = member;
        return;
      }

      var readType = node.readType ?? operand.typeOrThrow;
      if (identical(readType, NeverTypeImpl.instance)) {
        _resolver.errorReporter.reportErrorForNode(
          HintCode.RECEIVER_OF_TYPE_NEVER,
          operand,
        );
        return;
      }

      var result = _typePropertyResolver.resolve(
        receiver: operand,
        receiverType: readType,
        name: methodName,
        propertyErrorEntity: node.operator,
        nameErrorEntity: operand,
      );
      node.staticElement = result.getter as MethodElement?;
      if (result.needsGetterError) {
        if (operand is SuperExpression) {
          _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR,
            operator,
            [methodName, readType],
          );
        } else {
          _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.UNDEFINED_OPERATOR,
            operator,
            [methodName, readType],
          );
        }
      }
    }
  }

  void _resolve2(PrefixExpressionImpl node) {
    TokenType operator = node.operator.type;
    if (identical(node.readType, NeverTypeImpl.instance)) {
      _recordStaticType(node, NeverTypeImpl.instance);
    } else {
      // The other cases are equivalent to invoking a method.
      var staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      Expression operand = node.operand;
      if (operand is ExtensionOverride) {
        // No special handling for incremental operators.
      } else if (operator.isIncrementOperator) {
        if (node.readType!.isDartCoreInt) {
          staticType = _typeProvider.intType;
        } else {
          _checkForInvalidAssignmentIncDec(node, staticType);
        }
        if (operand is SimpleIdentifier) {
          var element = operand.staticElement;
          if (element is PromotableElement) {
            _resolver.flowAnalysis.flow?.write(node, element, staticType, null);
          }
        }
      }
      _recordStaticType(node, staticType);
    }
    _resolver.nullShortingTermination(node);
  }

  void _resolveNegation(PrefixExpressionImpl node) {
    var operand = node.operand;
    InferenceContext.setType(operand, _typeProvider.boolType);

    operand.accept(_resolver);
    operand = node.operand;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(operand);

    _resolver.boolExpressionVerifier.checkForNonBoolNegationExpression(operand,
        whyNotPromoted: whyNotPromoted);

    _recordStaticType(node, _typeProvider.boolType);

    _resolver.flowAnalysis.flow?.logicalNot_end(node, operand);
  }
}
