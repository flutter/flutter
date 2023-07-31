// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Visitor that collects super-invoked names in a mixin declaration.
class MixinSuperInvokedNamesCollector extends RecursiveAstVisitor<void> {
  final Set<String> _names;

  MixinSuperInvokedNamesCollector(this._names);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.leftOperand is SuperExpression) {
      _names.add(node.operator.lexeme);
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.target is SuperExpression) {
      if (node.inGetterContext()) {
        _names.add('[]');
      }
      if (node.inSetterContext()) {
        _names.add('[]=');
      }
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target is SuperExpression) {
      _names.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operand is SuperExpression) {
      TokenType operatorType = node.operator.type;
      if (operatorType == TokenType.MINUS) {
        _names.add('unary-');
      } else if (operatorType == TokenType.TILDE) {
        _names.add('~');
      }
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target is SuperExpression) {
      var name = node.propertyName.name;
      if (node.propertyName.inGetterContext()) {
        _names.add(name);
      }
      if (node.propertyName.inSetterContext()) {
        _names.add('$name=');
      }
    }
    super.visitPropertyAccess(node);
  }
}
