// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:collection/collection.dart';

class UseResultVerifier {
  final ErrorReporter _errorReporter;

  UseResultVerifier(this._errorReporter);

  void checkMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.staticElement;
    if (element == null) {
      return null;
    }

    _check(node, element);
  }

  void checkSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }

    var parent = node.parent;
    // Covered by checkPropertyAccess and checkMethodInvocation respectively.
    if (parent is PropertyAccess || parent is MethodInvocation) {
      return;
    }

    var element = node.staticElement;
    if (element == null) {
      return null;
    }

    _check(node, element);
  }

  void _check(AstNode node, Element element) {
    if (node.parent is CommentReference) {
      // Don't flag references in comments.
      return;
    }

    var annotation = _getUseResultMetadata(element);
    if (annotation == null) {
      return;
    }

    if (_passesUsingParam(node, annotation)) {
      return;
    }

    if (_isUsed(node)) {
      return;
    }

    var displayName = element.displayName;

    var message = _getUseResultMessage(annotation);
    if (message == null || message.isEmpty) {
      _errorReporter.reportErrorForNode(
          HintCode.UNUSED_RESULT, _getNodeToAnnotate(node), [displayName]);
    } else {
      _errorReporter.reportErrorForNode(HintCode.UNUSED_RESULT_WITH_MESSAGE,
          _getNodeToAnnotate(node), [displayName, message]);
    }
  }

  bool _passesUsingParam(AstNode node, ElementAnnotation annotation) {
    if (node is! MethodInvocation) {
      return false;
    }

    var unlessParam = _getUseResultUnlessParam(annotation);
    if (unlessParam == null) {
      return false;
    }

    var argumentList = node.argumentList as ArgumentListImpl;
    var parameters = argumentList.correspondingStaticParameters;
    if (parameters == null) {
      return false;
    }

    for (var param in parameters) {
      var name = param?.name;
      if (unlessParam == name) {
        return true;
      }
    }

    return false;
  }

  static AstNode _getNodeToAnnotate(AstNode node) {
    if (node is MethodInvocation) {
      return node.methodName;
    }
    if (node is PropertyAccess) {
      return node.propertyName;
    }
    return node;
  }

  static String? _getUseResultMessage(ElementAnnotation annotation) {
    if (annotation.element is PropertyAccessorElement) {
      return null;
    }
    var constantValue = annotation.computeConstantValue();
    return constantValue?.getField('message')?.toStringValue();
  }

  static ElementAnnotation? _getUseResultMetadata(Element element) {
    // Implicit getters/setters.
    if (element.isSynthetic && element is PropertyAccessorElement) {
      element = element.variable;
    }
    return element.metadata.firstWhereOrNull((e) => e.isUseResult);
  }

  static String? _getUseResultUnlessParam(ElementAnnotation annotation) {
    var constantValue = annotation.computeConstantValue();
    return constantValue?.getField('parameterDefined')?.toStringValue();
  }

  static bool _isUsed(AstNode node) {
    var parent = node.parent;
    if (parent == null) {
      return false;
    }

    if (parent is CascadeExpression) {
      return parent.target == node;
    }

    if (parent is ParenthesizedExpression ||
        parent is ConditionalExpression ||
        parent is AwaitExpression) {
      return _isUsed(parent);
    }

    return parent is ArgumentList ||
        // Node should always be RHS so no need to check for a property assignment.
        parent is AssignmentExpression ||
        parent is VariableDeclaration ||
        parent is MethodInvocation ||
        parent is PropertyAccess ||
        parent is ExpressionFunctionBody ||
        parent is ReturnStatement ||
        parent is FunctionExpressionInvocation ||
        parent is ListLiteral ||
        parent is SetOrMapLiteral ||
        parent is MapLiteralEntry;
  }
}
